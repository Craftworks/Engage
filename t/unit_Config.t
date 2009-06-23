use strict;
use warnings;
use Test::More tests => 7;
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
    my $local = {
        'sender' => {
            'mailer' =>  'SMTP',
            'mailer_args' => { 
                'Host' => 'product.example.com',
                'Hello' => 'smtp_host',
            },
        },
    };
    is_deeply( $config, {
        %$local,
        'global' => {
            'API::Email' => $local,
        },
    }, 'merge product' );
}
{
    my $config = MyApp::API::Email->new( config_suffix => 'staging' )->config;
    delete $config->{'global'};
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
    my $config = $class->new( config_prefix => 'test' )->config->{'global'};
    is_deeply( $config->{'substitute'}, {
        'env_value' => 'env_foo',
        'path_to' => "$home/somewhere",
        'home' => "$home",
    }, 'substitute' );
}

