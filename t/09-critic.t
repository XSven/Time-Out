#<<<
use strict; use warnings;
#>>>

use Test::More qw();

use Test::Needs qw( Test::Perl::Critic );

Test::Perl::Critic::all_critic_ok( 'lib', 't' );
