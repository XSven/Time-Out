#<<<
use strict; use warnings;
#>>>

# Load Time::Out before Test::More: Recent version of Test::More load
# Time::HiRes. This should be avoided.
use Time::Out qw( timeout );

use Test::More tests => 3;

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
