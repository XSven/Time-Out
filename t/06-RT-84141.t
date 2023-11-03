#<<<
use strict; use warnings;
#>>>

use Time::HiRes qw();
my $minimum_th_version = 1.9726;
eval "use Time::HiRes $minimum_th_version";
my $th_check = $@;
use Time::Out qw( timeout );

use Test::More import => [ qw( is plan ) ];

plan $th_check ? ( skip_all => "Nested timeouts (Time::HiRes $minimum_th_version required)" ) : ( tests => 2 );

for my $timeout ( ( 2148, 86400 ) ) {
  my $result = timeout $timeout => sub {
    alarm 0;
  };
  is $result, $timeout, "disable timer and return the amount of time remaining on it ($timeout seconds)";
}
