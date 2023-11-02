#<<<
use strict; use warnings;
#>>>

package Time::Out;

our $VERSION = '0.11';

use Exporter                    qw( import );
use Time::Out::ParamConstraints qw( assert_non_negative_number assert_plain_coderef );

sub _timeout( $$@ );

BEGIN {
  # if possible use Time::HiRes drop-in replacements
  for ( qw( alarm time ) ) {
    Time::HiRes->import( $_ ) if Time::HiRes->can( $_ );
  }
}

our @EXPORT_OK = qw( timeout );

sub timeout( $@ ) {
  _timeout shift, pop, @_;
}

sub _timeout( $$@ ) {
  my $context = wantarray();
  # wallclock seconds
  my $seconds   = assert_non_negative_number shift;
  my $code      = assert_plain_coderef shift;
  my @code_args = @_;

  # disable previous timer and save the amount of time remaining on it
  my $prev_alarm = alarm( 0 );
  my $prev_time  = time();
  my $error_at   = undef;
  my @result     = ();
  {
    # TODO: What about using "IGNORE" instead of an empty subroutine?
    # disable ALRM handling to prevent possible race condition between end of
    # eval and execution of alarm(0) after eval
    local $SIG{ ALRM } = sub { };
    eval {
      local $SIG{ ALRM } = sub { die $code };
      if ( ( $prev_alarm ) && ( $prev_alarm < $seconds ) ) {
        # A shorter alarm was pending, let's use it instead.
        alarm( $prev_alarm );
      } else {
        alarm( $seconds );
      }
      defined $context
        ? $context
          ? @result = $code->( @code_args )         # list context
          : $result[ 0 ] = $code->( @code_args )    # scalar context
        : $code->( @code_args );                    # void context
      alarm( 0 );
    };
    # TODO: Should we save the eval error before disabling the timer?
    alarm( 0 );
    $error_at = $@;
  }

  my $new_time  = time();
  my $new_alarm = $prev_alarm - ( $new_time - $prev_time );
  if ( $new_alarm > 0 ) {
    # Rearm old alarm with remaining time.
    alarm( $new_alarm );
  } elsif ( $prev_alarm ) {
    # Old alarm has already expired.
    kill 'ALRM', $$;
  }

  if ( $error_at ) {
    if ( ( ref( $error_at ) ) && ( $error_at eq $code ) ) {
      $@ = 'timeout';
    } else {
      if ( !ref( $error_at ) ) {
        chomp( $error_at );
        die( "$error_at\n" );
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
