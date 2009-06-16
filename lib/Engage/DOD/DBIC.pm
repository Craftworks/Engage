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
        $self->connections->{$datasource} = $self->schema_class->connect(
            @{ $self->config->{'datasources'}{$datasource} }
        );
    }

    return $self->connections->{$datasource};
}

sub dbh {
    shift->schema(@_)->storage->dbh;
}

1;
