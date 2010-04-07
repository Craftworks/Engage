use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More tests => 11;

BEGIN { use_ok 'Engage::Register' }

$ENV{'CONFIG_PATH'} = "$FindBin::Bin/conf";

my $class = 'Engage::Register';

#=============================================================================
# new
#=============================================================================
my $register = new_ok( 'Engage::Register' );
is( $class->instance, $class->new, 'same instance' );
is( $class->instance, $register, 'support both' );

#=============================================================================
# set
#=============================================================================
ok( $register->set('foo', 'bar'), 'set value' );

#=============================================================================
# get
#=============================================================================
ok( !$register->get('undef'), 'undefined' );
is( $register->get('foo') => 'bar', 'get value');

#=============================================================================
# other package
#=============================================================================
is( $Class1::Var => undef, 'before set' );
{
    package Class1;
    our $Var = Engage::Register->set('baz', 'baz');
}
is( $Class1::Var => 'baz', 'after set' );
{
    package Class2;
    our $Var = Engage::Register->get('baz');
}
is( $Class2::Var => 'baz', 'other package' );
is( $Class1::Var, $Class2::Var, 'same value' );

