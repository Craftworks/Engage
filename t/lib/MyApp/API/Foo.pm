package MyApp::API::Foo;
use Moose;
extends 'MyApp::API';
sub foo {}
__PACKAGE__->meta->make_immutable;
