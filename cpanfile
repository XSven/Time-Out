#<<<
use strict; use warnings;
#>>>

on 'configure' => sub {
  requires 'Config'                        => '0';
  requires 'ExtUtils::MakeMaker::CPANfile' => '0';
  requires 'File::Spec'                    => '0';
  requires 'lib'                           => '0';
  requires 'strict'                        => '0';
  requires 'subs'                          => '0';
  requires 'warnings'                      => '0';
};

on 'runtime' => sub {
  requires 'Carp'     => '0';
  requires 'Exporter' => '0';
  requires 'strict'   => '0';
  recommends 'Time::HiRes' => '>= 1.9726';
};

on 'test' => sub {
  requires 'Test::More' => '0';
  requires 'warnings'   => '0';
  suggests 'Test::Pod' => '>= 1.26';
};

on 'develop' => sub {
  suggests 'App::cpanminus' => '>= 1.7046';
};
