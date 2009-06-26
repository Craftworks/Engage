package Engage::API;

use Moose;
use Engage::Job::Client;
with 'Engage::Utils';
with 'Engage::Config';
with 'Engage::Log';
with 'Engage::Class::Loader';

has '+config_prefix' => ( default => 'api' );

has 'job' => (
    is  => 'ro',
    isa => 'Engage::Job::Client',
    default => sub { Engage::Job::Client->instance },
    lazy => 1,
);

no Moose;

__PACKAGE__->add_loader('DAO');
__PACKAGE__->meta->make_immutable;

1;

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
