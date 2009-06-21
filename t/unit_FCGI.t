use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More tests => 3;

BEGIN { use_ok 'Engage::FCGI' }

$ENV{'CONFIG_PATH'} = "$FindBin::Bin/conf";

{
    package MyApp::FCGI;
    use Moose;
    extends 'Engage::FCGI';
}

#=============================================================================
# new
#=============================================================================
ok( my $o = MyApp::FCGI->new( site => 'Service' ), 'new' );

#=============================================================================
# run
#=============================================================================
ok( $o->can('run'), 'can run' );

