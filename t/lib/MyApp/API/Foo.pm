package MyApp::API::Foo;

use Moose;

extends 'MyApp::API';

sub foo { 'foo' }

no Moose;

__PACKAGE__->meta->make_immutable;

1;
