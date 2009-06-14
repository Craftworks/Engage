use strict;
use warnings;
use Test::More tests => 5;
use FindBin;

BEGIN { use_ok 'Engage::Config' }

{
    package MyApp;
    use Moose;
    with 'Engage::Config';
    has '+config_path' => (
        default => "$FindBin::Bin/conf/"
    );
}

is_deeply( MyApp->new( config_prefix => 'dod' )->loaded_config, [
    "$FindBin::Bin/conf/dod.dbic.yml",
    "$FindBin::Bin/conf/dod.general.yml",
    "$FindBin::Bin/conf/dod.general-local.yml",
], 'loaded config include local' );

is_deeply( MyApp->new( config_prefix => 'dod', config_suffix => 'product' )->loaded_config, [
    "$FindBin::Bin/conf/dod.dbic.yml",
    "$FindBin::Bin/conf/dod.general.yml",
], 'loaded config exclude local' );

is_deeply( MyApp->new( config_prefix => 'api', config_suffix => 'product' )->config, {
    'API::Email' => {
        'sender' => {
            'mailer' =>  'SMTP',
            'mailer_args' => { 
                'Host' => 'product.example.com',
                'Hello' => 'smtp_host',
            },
        },
    },
}, 'merge product' );

is_deeply( MyApp->new( config_prefix => 'api', config_suffix => 'staging' )->config, {
    'API::Email' => {
        'sender' => {
            'mailer' =>  'SMTP',
            'mailer_args' => { 
                'Host' => 'staging.example.com',
                'Hello' => 'smtp_host',
            },
        },
    },
}, 'merge staging' );

