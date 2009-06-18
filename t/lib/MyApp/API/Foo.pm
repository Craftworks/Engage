package MyApp::API::Foo;
use Moose;
extends 'MyApp::API';
with 'Engage::Utils';
sub foo {}
__PACKAGE__->meta->make_immutable;
