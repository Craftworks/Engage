use strict;
use warnings;
use Test::More tests => 7;
use FindBin;
use lib "$FindBin::Bin/lib";
use Data::Dumper;

BEGIN { use_ok 'Engage::DOD::DBIC' }

$ENV{'CONFIG_PATH'} = "$FindBin::Bin/conf";

use MyApp::DAO;
#use MyApp::DOD::DBIC::Schema;

#=============================================================================
# new
#=============================================================================
ok( my $o = MyApp::DAO->new, 'new' );

#=============================================================================
# schema
#=============================================================================
isa_ok( $o->dod('DBIC')->schema('dsn1'), 'MyApp::DOD::DBIC::Schema', 'schema' );

#=============================================================================
# dbh
#=============================================================================
isa_ok( $o->dod('DBIC')->dbh('dsn1'), 'DBI::db', 'dbh' );

#=============================================================================
# resultset
#=============================================================================
{
    my $schema = $o->dod('DBIC')->schema('dsn1');
    can_ok( $schema, 'resultset' );
    my $rs = $schema->resultset('User')->find(1);
    isa_ok( $rs, 'MyApp::DOD::DBIC::Schema::User' );
    is( $rs->name, 'Michael', 'SELECT' );
}
