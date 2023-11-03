#<<<
use strict; use warnings;
#>>>

package Time::Out;

our $VERSION = '0.20';

use Exporter                    qw( import );
use Time::Out::ParamConstraints qw( assert_non_negative_number assert_plain_coderef );
use Try::Tiny                   qw( try catch );

sub _timeout( $$@ );

BEGIN {
  # if possible use Time::HiRes drop-in replacements
  for ( qw( alarm time ) ) {
    Time::HiRes->import( $_ ) if Time::HiRes->can( $_ );
  }
}

our @EXPORT_OK = qw( timeout );

sub timeout( $@ ) {
  my $context = wantarray;
  # wallclock seconds
  my $timeout   = assert_non_negative_number shift;
  my $code      = assert_plain_coderef pop;
  my @code_args = @_;

  my $error_at;
  # in scalar context store the result in the first array element
  my @result;

  # disable previous timer and save the amount of time remaining on it
  my $remaining_time_on_previous_timer = alarm 0;
  my $start_time                       = time;

  {
# https://stackoverflow.com/questions/1194113/whats-the-difference-between-ignoring-a-signal-and-telling-it-to-do-nothing-in
# disable ALRM handling to prevent possible race condition between end of
# eval and execution of alarm(0) after eval
    local $SIG{ ALRM } = 'IGNORE';
    try {
      local $SIG{ ALRM } = sub { die $code }; ## no critic (RequireCarping)
      if ( $remaining_time_on_previous_timer and $remaining_time_on_previous_timer < $timeout ) {
        # a shorter timer was pending, let's use it instead
        alarm $remaining_time_on_previous_timer;
      } else {
        alarm $timeout;
      }
      defined $context
        ? $context
          ? @result = $code->( @code_args )         # list context
          : $result[ 0 ] = $code->( @code_args )    # scalar context
        : $code->( @code_args );                    # void context
      alarm 0;
    } catch {
      $error_at = $_
    };
    alarm 0;
  }

  my $elapsed_time = time() - $start_time;
  my $new_timeout  = $remaining_time_on_previous_timer - $elapsed_time;

  if ( $new_timeout > 0 ) {
    # rearm previous timer with new timeout
    alarm $new_timeout;
  } elsif ( $remaining_time_on_previous_timer ) {
    # previous timer has already expired; send ALRM
    kill 'ALRM', $$;
  }

  if ( $error_at ) {
    if ( ( ref $error_at ) && ( $error_at eq $code ) ) {
      $@ = 'timeout';
    } else {
      if ( !ref $error_at ) {
        chomp $error_at;
        die "$error_at\n";
      } else {
        die $error_at;
      }
    }
  }

  return
      defined $context
    ? $context
      ? return @result    # list context
      : $result[ 0 ]      # scalar context
    : ();                 # void context
}

1;
