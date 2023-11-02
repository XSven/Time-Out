#<<<
use strict; use warnings;
#>>>

# Load Time::Out before Test::More: Recent version of Test::More load
# Time::HiRes. This should be avoided.
use Time::Out qw( timeout );

use Test::More import => [ qw( diag is ok plan skip subtest ) ], tests => 13;

diag( "\nThe following tests use sleep() so please be patient...\n" );

subtest 'void context; timeout' => sub {
  plan tests => 1;

  timeout 2 => sub {
    sleep( 3 );
  };
  is $@, 'timeout', 'eval error was set to "timeout"';
};

subtest 'scalar context; no timeout' => sub {
  plan tests => 2;

  my $result = timeout 3 => sub {
    sleep( 1 );
    56;
  };
  is $@,      '', 'empty eval error';
  is $result, 56, 'expected result';
};

sub test_no_args {
  timeout 2 => sub {
    return $_[ 0 ];
  };
}
is( test_no_args( 5 ), undef );

sub test_args {
  timeout 2, @_ => sub {
    $_[ 0 ];
  };
}
is( test_args( 5 ), 5 );

# repeats
timeout 2 => sub {
  sleep( 3 );
};
sleep( 3 );
ok( 1 );

# CPU
timeout 1 => sub {
  while ( 1 ) { }
};
ok( 1 );

# blocking I/O
if ( $^O eq 'MSWin32' ) {
  skip( "alarm() doesn't interrupt blocking I/O on Win32" );
} else {
  require IO::Handle;
  my $r = new IO::Handle();
  my $w = new IO::Handle();
  pipe( $r, $w );
  $w->autoflush( 1 );
  print $w "\n";
  my $nb   = 2;
  my $line = <$r>;
  timeout $nb => sub {
    $line = <$r>;
  };
  ok( $@ eq 'timeout' );
}

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
