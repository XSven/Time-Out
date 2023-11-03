#<<<
use strict; use warnings;
#>>>

use Test::More import => [ qw( plan ) ];

plan skip_all => 'Criticise code (RELEASE_TESTING environment variable not set)'
  unless $ENV{ RELEASE_TESTING };

eval 'use Test::Perl::Critic';
plan skip_all => "Criticise code (Test::Perl::Critic required)"
  if $@;

all_critic_ok( 'lib' );
