use inc::Module::Install;

name     'Engage';
all_from 'lib/Engage.pm';
author   'Craftworks <craftworks at cpan org>';
license  'perl';

requires 'Moose';
requires 'MooseX::LogDispatch';
requires 'MooseX::Types::Path::Class';
requires 'MooseX::App::Cmd';
requires 'Config::Any';
requires 'Hash::Merge';

build_requires 'Test::More';
build_requires 'Test::File::Contents';
build_requires 'DBD::Mock';

auto_install;

WriteAll;

