#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Engage' );
}

diag( "Testing Engage $Engage::VERSION, Perl $], $^X" );
