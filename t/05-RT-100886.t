#<<<
use strict; use warnings;
#>>>

use Time::HiRes qw();
use Time::Out   qw( timeout );

use Test::More tests => 1;

timeout 0.1 => sub {
  sleep 1;
};

if ( $@ ) {
  pass 'Timeout happened';
} else {
  fail 'No timeout';
}
