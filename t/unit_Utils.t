use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More tests => 10;
use Cwd;

BEGIN { use_ok 'Engage::Utils' }

{
    package MyApp;
    use Moose;
    with 'Engage::Utils';
    package MyApp::Foo;
    use Moose;
    with 'Engage::Utils';
}

#=============================================================================
# env_value
#=============================================================================
{
    local $ENV{'MYAPP_HOME'} = '/path/to/myapp';
    is( MyApp->env_value('home'), '/path/to/myapp', 'env_value myapp' );
}
{
    local $ENV{'ENGAGE_HOME'} = '/path/to/engage';
    is( MyApp->env_value('home'), '/path/to/engage', 'env_value engage' );
}
{
    is( MyApp->env_value('home'), undef, 'env_value undef' );
}

#=============================================================================
# home
#=============================================================================
{
    local $ENV{'MYAPP_HOME'} = '/path';
    is( MyApp->new->home, '/path', 'home from env' );
}
{
    require MyApp::API::Foo;
    is( MyApp::API::Foo->new->home, $FindBin::Bin, 'home from inc' );
}
{
    my $cwd = Cwd::cwd;
    chdir "$FindBin::Bin/lib" or die $!;
    is( MyApp->new->home, $FindBin::Bin, 'home from cwd' );
    chdir $cwd;
}

#=============================================================================
# app_name
#=============================================================================
is( MyApp->new->app_name, 'MyApp', 'app_name short' );
is( MyApp::Foo->new->app_name, 'MyApp', 'app_name long' );

#=============================================================================
# path_to
#=============================================================================
is( MyApp::API::Foo->new->path_to('foo'), "$FindBin::Bin/foo", 'path_to' );

