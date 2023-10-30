#<<<
use strict; use warnings;
#>>>

use Test::More;

plan skip_all => 'POD files checking (RELEASE_TESTING environment variable not set)'
  unless $ENV{ RELEASE_TESTING };

# ensure a recent version of Test::Pod; consider updating the cpanfile too
my $minimum_tp_version = 1.26;
eval "use Test::Pod $minimum_tp_version";
plan skip_all => "POD files checking (Test::Pod $minimum_tp_version required)"
  if $@;

all_pod_files_ok();
