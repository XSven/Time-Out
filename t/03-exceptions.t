#<<<
use strict; use warnings;
#>>>

# Load Time::Out before Test::More: Recent version of Test::More load
# Time::HiRes. This should be avoided.
use Time::Out qw( timeout );

use Test::More import => [ qw( is like ) ], tests => 3;
use Test::Fatal qw( exception );

is exception {
  timeout 3 => sub { die( "allo\n" ); };
},
  "allo\n",
  'no timeout: code dies (exception is a string with trailing newline)';

like exception {
  timeout 3 => sub { die( 'allo' ); };
}, qr/\Aallo/, 'no timeout: code dies (exception is a string without trailing newline)';

is exception {
  timeout 3 => sub { die( [ 56 ] ); };
}
->[ 0 ], 56, 'no timeout: code dies (exception is a plain array reference)';
