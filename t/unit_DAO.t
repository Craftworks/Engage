use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More tests => 3;

BEGIN { use_ok 'Engage::DAO' }

$ENV{'CONFIG_PATH'} = "$FindBin::Bin/conf";

use MyApp::DAO::Bar;

my $o = MyApp::DAO::Bar->new;

is( $o->data_class, 'Bar', 'data_class' );
is( $o->data_name, 'bar', 'data_name' );
