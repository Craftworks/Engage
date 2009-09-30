package MyApp::API::Bar;

use Moose;

extends 'MyApp::API';

sub bar { 'bar' }

no Moose;

__PACKAGE__->meta->make_immutable;

1;
