package Engage::DAO;

use Moose;
with 'Engage::Config';
with 'Engage::Log';
with 'Engage::Class::Loader';

has '+config_prefix' => (
    default => 'dao',
);

has '+class_for_loading' => (
    default => sub { [ 'DOD' ] },
);

no Moose;

__PACKAGE__->meta->make_immutable;

1;
