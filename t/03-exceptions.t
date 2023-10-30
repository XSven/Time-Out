#<<<
use strict; use warnings;
#>>>

use Test::More tests => 3;

use Time::Out qw( timeout );

# exception
eval {
  timeout 3 => sub {
    die( "allo\n" );
  };
};
is( $@, "allo\n" );

# exception
eval {
  timeout 3 => sub {
    die( "allo" );
  };
};
like( $@, qr/^allo/ );

# exception
eval {
  timeout 3 => sub {
    die( [ 56 ] );
  };
};
is( $@->[ 0 ], 56 );
