package MyApp::Job::Daemon;

use Moose;
extends 'Engage::Job::Daemon';

no Moose;

__PACKAGE__->meta->make_immutable;

1;
