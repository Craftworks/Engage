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

=head1 NAME

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Craftworks, C<< <craftwork at cpan org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Craftworks, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

