package Engage::Register;

use MooseX::Singleton;
use MooseX::AttributeHelpers;
use namespace::clean -except => 'meta';

has '_instances' => (
    is  => 'rw',
    isa => 'HashRef',
    default   => sub { +{} },
    metaclass => 'Collection::Hash',
    provides  => {
        'get' => 'get',
        'set' => 'set',
    },
);

around 'get' => sub {
    my ( $next, $self, @args ) = @_;
    unless ( blessed $self ) {
        $self = $self->instance;
    }
    $self->$next(@args);
};

around 'set' => sub {
    my ( $next, $self, @args ) = @_;
    unless ( blessed $self ) {
        $self = $self->instance;
    }
    $self->$next(@args);
};

__PACKAGE__->meta->make_immutable;

1;
