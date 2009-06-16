use strict;
use warnings;
use Test::More tests => 4;
use FindBin;

BEGIN { use_ok 'Engage::DOD::DBIC' }

BEGIN { $ENV{'CONFIG_PATH'} = "$FindBin::Bin/conf" }

{
    package Engage::DOD::DBIC::Schema;
    use base 'DBIx::Class::Schema::Loader';
    __PACKAGE__->load_classes;
    package Engage::DAO;
    use Moose;
    with 'Engage::Config';
    with 'Engage::Class::Loader';
    has '+config_prefix' => (
        default => 'dao'
    );
    has '+class_for_loading' => (
        default => sub { [ 'DOD' ] },
    );
}

#=============================================================================
# new
#=============================================================================
ok( my $o = Engage::DAO->new, 'new' );

#=============================================================================
# schema
#=============================================================================
isa_ok( $o->dod('DBIC')->schema('dsn1'), 'Engage::DOD::DBIC::Schema', 'schema' );

#=============================================================================
# dbh
#=============================================================================
isa_ok( $o->dod('DBIC')->dbh('dsn1'), 'DBI::db', 'dbh' );

