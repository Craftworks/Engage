use strict;
use warnings;
use Test::More tests => 10;
use FindBin;
use lib "$FindBin::Bin/lib";

BEGIN { use_ok 'Engage::Config' }

$ENV{'CONFIG_PATH'} = "$FindBin::Bin/conf";

use MyApp::API::Foo;
use MyApp::API::Email;

my $class = 'MyApp::API::Foo';

#=============================================================================
# new
#=============================================================================
ok( $class->new, 'new' );

#=============================================================================
# loaded_config
#=============================================================================
is_deeply( $class->new( config_prefix => 'dod' )->loaded_config, [
    "$FindBin::Bin/conf/dod.dbic.yml",
    "$FindBin::Bin/conf/dod.general.yml",
    "$FindBin::Bin/conf/dod.general-local.yml",
], 'loaded config include local' );

#=============================================================================
# config_suffix
#=============================================================================
is_deeply( $class->new(
        config_prefix => 'dod',
        config_suffix => 'product'
    )->loaded_config, [
        "$FindBin::Bin/conf/dod.dbic.yml",
        "$FindBin::Bin/conf/dod.general.yml",
], 'loaded config exclude local' );

#=============================================================================
# merge
#=============================================================================
{
    my $config = MyApp::API::Email->new( config_suffix => 'product' )->config;
    is_deeply( $config, {
        'sender' => {
            'mailer' =>  'SMTP',
            'mailer_args' => { 
                'Host' => 'product.example.com',
                'Hello' => 'smtp_host',
            },
        },
    }, 'merge product' );
}
{
    my $config = MyApp::API::Email->new( config_suffix => 'staging' )->config;
    is_deeply( $config, {
        'sender' => {
            'mailer' =>  'SMTP',
            'mailer_args' => { 
                'Host' => 'staging.example.com',
                'Hello' => 'smtp_host',
            },
        },
    }, 'merge staging' );
}

#=============================================================================
# substitute
#=============================================================================
{
    $ENV{'MYAPP_FOO'} = 'env_foo';
    my $home = $class->new->home;
    my $config = $class->new( config_prefix => 'test' )->config;
    is_deeply( $config->{'substitute'}, {
        'env_value' => 'env_foo',
        'path_to' => "$home/somewhere",
        'home' => "$home",
    }, 'substitute' );
}

#=============================================================================
# config_switch
#=============================================================================
{
    local $ENV{'HOSTNAME'} = 'prod001';
    my $config = $class->new( config_prefix => 'test', config_switch => 1 )->config;
    is( $config->{'nproc'}, 5, "config_switch $ENV{HOSTNAME}" );
}
{
    local $ENV{'HOSTNAME'} = 'develop';
    my $config = $class->new( config_prefix => 'test', config_switch => 1 )->config;
    is( $config->{'nproc'}, 3, "config_switch $ENV{HOSTNAME}" );
}
{
    local $ENV{'HOSTNAME'} = 'somewhere';
    my $config = $class->new( config_prefix => 'test', config_switch => 1 )->config;
    is( $config->{'nproc'}, 1, "config_switch $ENV{HOSTNAME}" );
}

