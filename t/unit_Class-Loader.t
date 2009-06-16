use strict;
use warnings;
use Test::More tests => 7;
use FindBin;
use lib "$FindBin::Bin/lib";

BEGIN { use_ok 'Engage::Class::Loader' }

$ENV{'CONFIG_PATH'} = "$FindBin::Bin/conf";
$ENV{'CONFIG_LOCAL_SUFFIX'} = 'log';

{
    package MyApp::API;
    use Moose;
    package MyApp::DAO;
    use Moose;
    package MyApp;
    use Moose;
    with 'Engage::Class::Loader';
    has '+class_for_loading' => (
        default => sub { [ qw(API DAO) ] },
    );
}

#=============================================================================
# new
#=============================================================================
ok( my $o = MyApp->new, 'new' );

#=============================================================================
# add method
#=============================================================================
ok( $o->can('api'), 'add method' );
ok( $o->can('dao'), 'add method' );

#=============================================================================
# return instance
#=============================================================================
isa_ok( $o->api('Foo'), 'MyApp::API::Foo', 'valid instance' );
isa_ok( $o->dao('Bar'), 'MyApp::DAO::Bar', 'valid instance' );
ok( $o->api('Foo')->can('foo'), 'valid instance' );

