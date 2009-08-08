use inc::Module::Install;

name     'Engage';
all_from 'lib/Engage.pm';
author   'Craftworks <craftwork at cpan org>';
license  'perl';

build_requires 'Test::More';
build_requires 'Test::File::Contents';
build_requires 'DBD::Mock';

requires 'Moose';
requires 'MooseX::Singleton';
requires 'MooseX::LogDispatch';
requires 'MooseX::Types::Path::Class';
requires 'MooseX::App::Cmd';
requires 'Catalyst';
requires 'namespace::clean';
requires 'Scalar::Alias';
requires 'Config::Any';
requires 'Hash::Merge';
requires 'Data::Visitor::Callback';
requires 'FCGI';
requires 'FCGI::ProcManager';
requires 'Parallel::Prefork';
requires 'TheSchwartz';
requires 'Text::SimpleTable';
requires 'Term::Size::Any';

install_script glob('script/*.pl');

auto_install;

WriteAll;

