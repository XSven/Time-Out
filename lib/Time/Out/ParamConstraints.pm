#<<<
use strict; use warnings;
#>>>
package Time::Out::ParamConstraints;

our $VERSION = '0.11';

use Exporter     qw( import );
use Scalar::Util qw( blessed looks_like_number reftype );

our @EXPORT_OK = qw( assert_non_negative_number assert_plain_coderef );

sub _croakf ( $@ );
sub _is_plain_coderef ( $ );
sub _is_string ( $ );

sub assert_non_negative_number( $ ) {
  _is_string $_[ 0 ]
    and looks_like_number $_[ 0 ]
    and $_[ 0 ] !~ /\A (?: Inf (?: inity )? | NaN ) \z/xi
    and $_[ 0 ] >= 0 ? $_[ 0 ] : _croakf 'value is not a non-negative number';
}

sub assert_plain_coderef( $ ) {
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
