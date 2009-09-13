use inc::Module::Install;

name     'Engage';
all_from 'lib/Engage.pm';
author   'Craftworks <craftwork at cpan org>';
license  'perl';

author_tests 'xt';

build_requires 'Test::More';
build_requires 'Test::File::Contents';
build_requires 'DBIx::Class::Schema::Loader';

requires 'parent';
requires 'Moose';
requires 'Moose::Role';
requires 'MooseX::Singleton';
requires 'MooseX::Types::Path::Class';
requires 'Catalyst';
requires 'Catalyst::Exception';
requires 'Catalyst::Runtime';
requires 'Catalyst::Utils';
requires 'Catalyst::Test';
requires 'HTTP::Status';
requires 'Class::Accessor::Fast';
requires 'Data::Dump';
requires 'namespace::clean';
requires 'Scalar::Alias';
requires 'Config::Any';
requires 'Path::Class';
requires 'Hash::Merge';
requires 'Data::Visitor::Callback';
requires 'Parallel::Prefork';
requires 'Template';
requires 'TheSchwartz';
requires 'Text::SimpleTable';
requires 'Term::Size::Any';

install_script glob('script/*.pl');

auto_install;

WriteAll;
