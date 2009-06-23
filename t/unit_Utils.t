use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More tests => 12;

BEGIN { use_ok 'Engage::Utils' }

use MyApp::API::Foo;
use Cwd;

#=============================================================================
# appclass
#=============================================================================
is( MyApp::API::Foo->appclass, 'MyApp', 'appclass class method' );
is( MyApp::API::Foo->new->appclass, 'MyApp', 'appclass instance method' );

#=============================================================================
# appprefix
#=============================================================================
is( MyApp::API::Foo->appprefix, 'myapp_api_foo', 'appprefix class method' );
is( MyApp::API::Foo->new->appprefix, 'myapp_api_foo', 'appprefix instance method' );

#=============================================================================
# env_value
#=============================================================================
{
    local $ENV{'MYAPP_HOME'} = '/path/to/myapp';
    is( MyApp::API::Foo->env_value('home'), '/path/to/myapp', 'env_value myapp' );
}
{
    local $ENV{'ENGAGE_HOME'} = '/path/to/engage';
    is( MyApp::API::Foo->env_value('home'), '/path/to/engage', 'env_value engage' );
}
{
    is( MyApp::API::Foo->env_value('home'), undef, 'env_value undef' );
}

#=============================================================================
# home
#=============================================================================
{
    local $ENV{'MYAPP_HOME'} = '/path';
    is( MyApp::API::Foo->new->home, '/path', 'home from env' );
}
{
    require MyApp::API::Foo;
    is( MyApp::API::Foo->new->home, $FindBin::Bin, 'home from inc' );
}
{
    my $cwd = Cwd::cwd;
    chdir "$FindBin::Bin/lib" or die $!;
    is( MyApp::API::Foo->new->home, $FindBin::Bin, 'home from cwd' );
    chdir $cwd;
}

#=============================================================================
# path_to
#=============================================================================
is( MyApp::API::Foo->new->path_to('foo'),
    Path::Class::Dir->new("$FindBin::Bin/foo")->resolve, 'path_to' );

