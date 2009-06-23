use strict;
use warnings;
use Test::More tests => 4;
use FindBin;
use lib "$FindBin::Bin/lib";

BEGIN { use_ok 'Engage::Class::Loader' }

$ENV{'CONFIG_PATH'} = "$FindBin::Bin/conf";
$ENV{'CONFIG_LOCAL_SUFFIX'} = 'log';

use MyApp::API::Foo;
use MyApp::DAO::Bar;

#=============================================================================
# new
#=============================================================================
ok( my $o = MyApp::API::Foo->new, 'new' );

#=============================================================================
# add method
#=============================================================================
can_ok( $o => 'dao' );

#=============================================================================
# return instance
#=============================================================================
isa_ok( $o->dao('Bar') => 'MyApp::DAO::Bar', 'valid instance' );

