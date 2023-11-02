#<<<
use strict; use warnings;
#>>>

# Load Time::Out before Test::More: Recent version of Test::More load
# Time::HiRes. This should be avoided.
use Time::Out qw( timeout );

use Test::More import => [ qw( diag is ok plan skip subtest ) ], tests => 6;

diag( "\nThe following tests use sleep() so please be patient...\n" );

# Nested timeouts
timeout 5 => sub {
  timeout 2 => sub {
    sleep( 3 );
  };
  ok( $@ eq 'timeout' );
  sleep( 4 );
};
ok( $@ eq 'timeout' );

# Nested timeouts (already expired)
my $seen = 0;
timeout 2 => sub {
  timeout 5 => sub {
    sleep( 6 );
  };
  # We should never get here...
  $seen = 1;
};
ok( $@ eq 'timeout' );
ok( !$seen );

# Nested timeouts (passthru)
timeout 5 => sub {
  timeout 2 => sub {
    sleep( 3 );
  };
  # We should never get here...
  ok( $@ eq 'timeout' );
};
ok( !$@ );
