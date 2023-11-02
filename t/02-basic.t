#<<<
use strict; use warnings;
#>>>

# Load Time::Out before Test::More: Recent version of Test::More load
# Time::HiRes. This should be avoided.
use Time::Out qw( timeout );

use Test::More import => [ qw( diag is ok plan skip subtest ) ], tests => 3;

subtest 'timeout: void context' => sub {
  plan tests => 1;

  timeout 2 => sub {
    # CPU
    while ( 1 ) { }
  };
  is $@, 'timeout', 'eval error was set to "timeout"';
};

subtest 'timeout: scalar context; echo argument passed to code' => sub {
  plan tests => 2;

  my $expected_result = 42;
  my $got_result      = timeout 3, $expected_result => sub {
    select( undef, undef, undef, 1 );
    $_[ 0 ];
  };
  is $@,          '',               'empty eval error';
  is $got_result, $expected_result, 'expected result';
};

SKIP: {
  skip "alarm() doesn't interrupt blocking I/O on $^O", 1 if $^O eq 'MSWin32';
  require IO::Handle;
  my $rh = new IO::Handle();
  my $wh = new IO::Handle();
  pipe( $rh, $wh );
  $wh->autoflush( 1 );
  print $wh "\n";
  my $line = <$rh>;
  timeout 2 => sub {
    $line = <$rh>;
  };
  is $@, 'timeout', 'timeout: blocking I/O; eval error was set to "timeout"';
}
