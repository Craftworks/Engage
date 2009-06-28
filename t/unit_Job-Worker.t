use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More tests => 3;
use TheSchwartz;
use Data::Dumper;

BEGIN { use_ok 'Engage::Job::Worker' }

$ENV{'CONFIG_PATH'} = "$FindBin::Bin/conf";

use MyApp::API::Foo;

#=============================================================================
# use
#=============================================================================
use_ok( 'MyApp::Job::Worker::Foo' );

my $client = MyApp::API::Foo->new->job;

ok( $client->can_do('MyApp::Job::Worker::Foo'), 'can_do' );

$client->work_once;

