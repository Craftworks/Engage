package Engage::DOD::DBIC;

use Moose;
use Carp;
extends 'Engage::DOD';
use Data::Dumper;

has 'schema_class' => (
    is  => 'ro',
    isa => 'Str',
    required => 1,
    default  => sub {
        shift->config->{'schema_class'};
    },
    lazy => 1,
);

has 'connections' => (
    is  => 'ro',
    isa => 'HashRef[DBIx::Class::Schema]',
    default => sub { {} },
    lazy => 1,
);

__PACKAGE__->meta->make_immutable;

no Moose;

sub BUILD {
    my $self = shift;
    Class::MOP::load_class($self->schema_class);
}

sub schema {
    my ( $self, $datasource ) = @_;

    croak qq{Unknown datasource "$datasource"}
        if ( !exists $self->config->{'datasources'}{$datasource} );

    if ( !exists $self->connections->{$datasource} ) {
        my $schema = $self->schema_class->connect(
            @{ $self->config->{'datasources'}{$datasource} }
        );
        $schema->storage->debug( 1 );
        $schema->storage->debugfh( $self->log );
        $self->connections->{$datasource} = $schema;
    }

    return $self->connections->{$datasource};
}

sub dbh {
    shift->schema(@_)->storage->dbh;
}

1;

=head1 NAME

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 schema

=head2 dbh

=head1 AUTHOR

Craftworks, C<< <craftwork at cpan org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Craftworks, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
