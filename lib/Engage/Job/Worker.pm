package Engage::Job::Worker;

use Moose;
extends 'TheSchwartz::Worker';
with 'Engage::Utils';
with 'Engage::Config';
with 'Engage::Log';
with 'Engage::Class::Loader';

no Moose;

__PACKAGE__->add_loader('API');
__PACKAGE__->meta->make_immutable;

1;
