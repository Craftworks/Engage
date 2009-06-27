package MyApp::Job::Client;

use Moose;

extends 'Engage::Job::Client';

no Moose;

__PACKAGE__->meta->make_immutable;

1;
