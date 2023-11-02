#<<<
use strict; use warnings;
#>>>

use Time::Out qw( timeout );
use Test::More import => [ qw( is ) ], tests => 2;

my $sub = sub {
  wantarray ? 'array' : 'scalar';
};

{
  my $ret = $sub->();
  is $ret, 'scalar';
}

{
  my $ret = timeout 100 => $sub;
  is $ret, 'scalar';    # array is returned here
}
