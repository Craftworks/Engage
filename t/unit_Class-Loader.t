use strict;
use warnings;
use Test::More tests => 7;

BEGIN { use_ok 'Engage::Class::Loader' }

{
    package Engage::API;
    use Moose;

    package Engage::API::Foo;
    use Moose;
    extends 'Engage::API';
    sub foo {}

    package Engage::DAO;
    use Moose;

    package Engage::DAO::Bar;
    use Moose;
    extends 'Engage::DAO';

    package Engage;
    use Moose;
    with 'Engage::Class::Loader';
    has '+class_for_loading' => (
        default => sub { [ qw(API DAO) ] },
    );
}

#=============================================================================
# new
#=============================================================================
ok( my $o = Engage->new, 'new' );

#=============================================================================
# add method
#=============================================================================
ok( $o->can('api'), 'add method' );
ok( $o->can('dao'), 'add method' );

#=============================================================================
# return instance
#=============================================================================
isa_ok( $o->api('Foo'), 'Engage::API::Foo', 'valid instance' );
isa_ok( $o->dao('Bar'), 'Engage::DAO::Bar', 'valid instance' );
ok( $o->api('Foo')->can('foo'), 'valid instance' );

