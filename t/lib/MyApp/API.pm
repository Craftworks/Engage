package MyApp::API;

use Moose;
extends 'Engage::API';
with 'Engage::Job';

no Moose;

__PACKAGE__->meta->make_immutable;

1;
