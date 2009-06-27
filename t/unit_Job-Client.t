use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More tests => 5;
use Data::Dumper;

BEGIN { use_ok 'Engage::Job::Client' }

$ENV{'CONFIG_PATH'} = "$FindBin::Bin/conf";

use MyApp::API::Foo;

#=============================================================================
# new
#=============================================================================
my $o = new_ok( 'MyApp::API::Foo' );
isa_ok( $o->job, 'Engage::Job::Client' );

#=============================================================================
# job
#=============================================================================
isa_ok( $o->job->job, 'TheSchwartz' );

#=============================================================================
# assign
#=============================================================================
isa_ok( $o->job->assign( 'Foo' => {
        msg => 'assigned by foo',
        now => scalar localtime,
}), 'TheSchwartz::JobHandle' );

