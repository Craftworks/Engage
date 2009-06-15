use strict;
use warnings;
use Test::More tests => 6;
use FindBin;

BEGIN { use_ok 'Engage::Config' }

{
    package MyApp;
    use Moose;
    with 'Engage::Config';
    has '+config_path' => (
        default => "$FindBin::Bin/conf/"
    );
    has '+config_prefix' => (
        default => 'dod'
    );

    package Engage::API::Email;
    use Moose;
    with 'Engage::Config';
    has '+config_path' => (
        default => "$FindBin::Bin/conf/"
    );
    has '+config_prefix' => (
        default => 'api'
    );
}

Engage::API::Email->new;

#=============================================================================
# new
#=============================================================================
ok( MyApp->new, 'new' );

#=============================================================================
# loaded_config
#=============================================================================
is_deeply( MyApp->new( config_prefix => 'dod' )->loaded_config, [
    "$FindBin::Bin/conf/dod.dbic.yml",
    "$FindBin::Bin/conf/dod.general.yml",
    "$FindBin::Bin/conf/dod.general-local.yml",
], 'loaded config include local' );

#=============================================================================
# config_suffix
#=============================================================================
is_deeply( MyApp->new( config_suffix => 'product' )->loaded_config, [
    "$FindBin::Bin/conf/dod.dbic.yml",
    "$FindBin::Bin/conf/dod.general.yml",
], 'loaded config exclude local' );

#=============================================================================
# merge
#=============================================================================
{
    my $config = Engage::API::Email->new( config_suffix => 'product' )->config;
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
    my $config = Engage::API::Email->new( config_suffix => 'staging' )->config;
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

