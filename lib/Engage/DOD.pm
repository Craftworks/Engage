package Engage::DOD;

use Moose;
with 'Engage::Config';
with 'Engage::Log';

has '+config_prefix' => (
    default => 'dod',
);

no Moose;

__PACKAGE__->meta->make_immutable;

1;
