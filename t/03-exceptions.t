#<<<
use strict; use warnings;
#>>>

# Load Time::Out before Test::More: Recent version of Test::More load
# Time::HiRes. This should be avoided.
use Time::Out qw( timeout );

use Test::More import => [ qw( is like ) ], tests => 4;
use Test::Fatal qw( exception );

is exception {
  timeout 3 => sub { die( "allo\n" ); };
},
  "allo\n",
  'no timeout: code dies (exception is a string with trailing newline)';

like exception {
  timeout 3 => sub { die( 'allo' ) }; ## no critic (RequireCarping)
}, qr/\A allo /x, 'no timeout: code dies (exception is a string without trailing newline)';

is exception {
  timeout 3 => sub { die( [ 56 ] ) }; ## no critic (RequireCarping)
}
->[ 0 ], 56, 'no timeout: code dies (exception is a plain array reference)';

my $foo = bless {}, 'Foo::Exception';
is exception {
  timeout 3 => sub { die $foo }; ## no critic (RequireCarping)
}, $foo, 'no timeout: code dies (exception is an object)';
