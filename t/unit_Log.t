use strict;
use warnings;
use Test::More tests => 7;
use Test::File::Contents;
use FindBin;
use lib "$FindBin::Bin/lib";
use Data::Dumper;

BEGIN { use_ok 'Engage::Log' }

$ENV{'CONFIG_PATH'} = "$FindBin::Bin/conf";
$ENV{'CONFIG_LOCAL_SUFFIX'} = 'log';

use MyApp::API::Foo;

#=============================================================================
# new
#=============================================================================
my $o = new_ok( 'MyApp::API::Foo' => [ config_prefix => 'api' ] );

#=============================================================================
# isa
#=============================================================================
isa_ok( $o->logger, 'Log::Dispatch::Config', 'logger' );
isa_ok( $o->log,    'Log::Dispatch::Config', 'log' );

#=============================================================================
# debug
#=============================================================================
{
    is( $o->debug, 0, 'debug disable' );
}
{
    local $ENV{'MYAPP_DEBUG'} = 1;
    my $o = MyApp::API::Foo->new;
    $o->log_dispatch_conf;
    is( $o->debug, 1, 'debug enable' );
}

#=============================================================================
# logging
#=============================================================================
{
    $o->log->debug('debug');
    my $file = $o->log->{'outputs'}{'default'}{'filename'};
    file_contents_like( $file, qr/^[\w: ]{25}\[debug\]/, 'logging' );
    diag( "remove temporary file $file" );
    unlink $file;
}

