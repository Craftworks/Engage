package Engage::API;

use Moose;
with 'Engage::Config';
with 'Engage::Log';
with 'Engage::Class::Loader';

has '+config_prefix' => (
    default => 'api',
);

has '+class_for_loading' => (
    default => sub { [ 'DAO' ] },
);

no Moose;

__PACKAGE__->meta->make_immutable;

1;
