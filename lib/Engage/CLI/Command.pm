package Engage::CLI::Command;

use Moose;
extends 'MooseX::App::Cmd::Command';
with 'Engage::Config';
with 'Engage::Log';
with 'Engage::Class::Loader';

has '+config_prefix' => (
    default => 'cli'
);

has '+class_for_loading' => (
    default => sub { [ 'API' ] },
);

no Moose;

__PACKAGE__->meta->make_immutable;

1;

__END__
