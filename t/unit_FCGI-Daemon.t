use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More tests => 3;

BEGIN { use_ok 'Engage::FCGI::Daemon' }

$ENV{'CONFIG_PATH'} = "$FindBin::Bin/conf";

{
    package MyApp::FCGI::Daemon;
    use Moose;
    extends 'Engage::FCGI::Daemon';
}

#=============================================================================
# new
#=============================================================================
ok( my $o = MyApp::FCGI::Daemon->new( site => 'Service' ), 'new' );

#=============================================================================
# run
#=============================================================================
ok( $o->can('run'), 'can run' );

