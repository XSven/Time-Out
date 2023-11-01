#<<<
use strict; use warnings;
#>>>

package Time::Out;

our $VERSION = '0.11';

use Carp         qw( carp );
use Exporter     qw( import );
use Scalar::Util qw( blessed looks_like_number reftype );

sub _croakf ( $@ );
sub _assert_non_negative_number ( $ );
sub _assert_plain_coderef ( $ );
sub _is_plain_coderef ( $ );
sub _is_string ( $ );
sub _timeout( $$@ );

BEGIN {
  #  If possible use Time::HiRes drop-in replacements.
  for ( qw( alarm time ) ) {
    Time::HiRes->import( $_ ) if Time::HiRes->can( $_ );
  }
}

our @EXPORT_OK = qw( timeout );

sub timeout( $@ ) {
  _timeout shift, pop, @_;
}

sub _timeout( $$@ ) {
  my $secs      = _assert_non_negative_number shift;
  my $code      = _assert_plain_coderef shift;
  my @code_args = @_;

  # Disable any pending alarms.
  my $prev_alarm = alarm( 0 );
  my $prev_time  = time();
  my $dollar_at  = undef;
  my @ret        = ();
  {
    # Disable alarm to prevent possible race condition between end of eval and execution of alarm(0) after eval.
    local $SIG{ ALRM } = sub { };
    @ret = eval {
      local $SIG{ ALRM } = sub { die $code };
      if ( ( $prev_alarm ) && ( $prev_alarm < $secs ) ) {
        # A shorter alarm was pending, let's use it instead.
        alarm( $prev_alarm );
      } else {
        alarm( $secs );
      }
      my @ret = $code->( @code_args );
      alarm( 0 );
      @ret;
    };
    alarm( 0 );
    $dollar_at = $@;
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

  if ( $dollar_at ) {
    if ( ( ref( $dollar_at ) ) && ( $dollar_at eq $code ) ) {
      $@ = 'timeout';
    } else {
      if ( !ref( $dollar_at ) ) {
        chomp( $dollar_at );
        die( "$dollar_at\n" );
      } else {
        die $dollar_at;
      }
    }
  }

  return wantarray ? @ret : $ret[ 0 ];
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
