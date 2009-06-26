package MyApp::API::Email;

use Moose;
extends 'MyApp::API';

no Moose;

__PACKAGE__->meta->make_immutable;

1;
