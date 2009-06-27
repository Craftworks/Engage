use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More tests => 3;

BEGIN { use_ok 'Engage::Job::Daemon' }

$ENV{'CONFIG_PATH'} = "$FindBin::Bin/conf";

use MyApp::Job::Daemon;

#=============================================================================
# new
#=============================================================================
my $o = new_ok( 'MyApp::Job::Daemon' );

#=============================================================================
# worker_classes
#=============================================================================
is_deeply( $o->worker_classes, [qw/MyApp::Job::Worker::Foo/], 'worker_classes' );

#$o->run;

