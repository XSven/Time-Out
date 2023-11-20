#<<<
use strict; use warnings;
#>>>

use Time::Out                   qw( timeout );
use Time::Out::ParamConstraints qw( is_InstanceOf );
use Try::Tiny                   qw( catch try );

use Test::More import => [ qw( fail is ) ], tests => 1;

timeout 1, sub {
  try {
    select( undef, undef, undef, 5 );
    die "bad\n";
  } catch {
    die $_ if is_InstanceOf( $_, 'Time::Out::Exception' ); ## no critic (RequireCarping)
    fail( 'timeout should fire before die' );
  }
};

is $@, 'timeout', 'eval error was set to "timeout"';
