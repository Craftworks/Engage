use strict;
use warnings;
use ExtUtils::MakeMaker;
use Test::More;
use Test::Dependencies
    exclude => [qw/
        Test::Dependencies Test::More inc::Module::Install
        Engage MyApp
    /],
    style   => 'light';

ok_dependencies();
