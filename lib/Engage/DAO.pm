package Engage::DAO;

use Moose;
use Engage::Exception;
with 'Engage::Utils';
with 'Engage::Config';
with 'Engage::Log';
with 'Engage::Class::Loader';

has '+config_prefix' => (
    default => 'dao',
);

has 'data_class' => (
    is  => 'ro',
    isa => 'Str',
    default => sub {
        my $self = shift;
        my $app  = $self->appclass;
        substr ref $self, length "$app\::DAO::";
    },
);

has 'data_name' => (
    is  => 'ro',
    isa => 'Str',
    default => sub {
        my $self = shift;
        my $name = $self->data_class;
        $name = lc $name if ( $name =~ /^[A-Z]+$/ );
        $name =~ s/([A-Z])/_\L$1\E/go;
        $name =~ s/^_//o;
        $name;
    },
    lazy => 1,
);

__PACKAGE__->add_loader('DOD');
__PACKAGE__->meta->make_immutable;

no Moose;

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
