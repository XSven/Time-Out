#<<<
use strict; use warnings;
#>>>

package Time::Out;

our $VERSION = '0.11';

use Exporter     qw( import );
use Scalar::Util qw( blessed looks_like_number reftype );

sub _croakf ( $@ );
sub _assert_non_negative_number ( $ );
sub _assert_plain_coderef ( $ );
sub _is_plain_coderef ( $ );
sub _is_string ( $ );
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
  my $seconds   = _assert_non_negative_number shift;
  my $code      = _assert_plain_coderef shift;
  my @code_args = @_;

  # disable previous timer and save the amount of time remaining on it
  my $prev_alarm = alarm( 0 );
  my $prev_time  = time();
  my $eval_error = undef;
  my @ret        = ();
  {
    # Disable alarm to prevent possible race condition between end of eval and execution of alarm(0) after eval.
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
          ? @ret = $code->( @code_args )         # list context
          : $ret[ 0 ] = $code->( @code_args )    # scalar context
        : $code->( @code_args );                 # void context
      alarm( 0 );
    };
    alarm( 0 );
    $eval_error = $@;
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

  if ( $eval_error ) {
    if ( ( ref( $eval_error ) ) && ( $eval_error eq $code ) ) {
      $@ = 'timeout';
    } else {
      if ( !ref( $eval_error ) ) {
        chomp( $eval_error );
        die( "$eval_error\n" );
      } else {
        die $eval_error;
      }
    }
  }

  return
      defined $context
    ? $context
      ? return @ret    # list context
      : $ret[ 0 ]      # scalar context
    : ();              # void context
}

sub _assert_non_negative_number( $ ) {
  _is_string $_[ 0 ]
    and looks_like_number $_[ 0 ]
    and $_[ 0 ] !~ /\A(?:Inf(?:inity)?|NaN)\z/i
    and $_[ 0 ] >= 0 ? $_[ 0 ] : _croakf 'value is not a non-negative number';
}

sub _assert_plain_coderef( $ ) {
  _is_plain_coderef $_[ 0 ] ? $_[ 0 ] : _croakf 'value is not a code reference';
}

sub _is_plain_coderef( $ ) {
  not defined blessed $_[ 0 ] and ref $_[ 0 ] eq 'CODE';
}

sub _is_string( $ ) {
  defined $_[ 0 ] and reftype \$_[ 0 ] eq 'SCALAR';
}

sub _croakf( $@ ) {
  # load Carp lazily
  require Carp;
  @_ = ( ( @_ == 1 ? shift : sprintf shift, @_ ) . ', stopped' );
  goto &Carp::croak;
}

1;
