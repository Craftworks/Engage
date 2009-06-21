package Engage::Class::Loader;

use Moose::Role;
with 'Engage::Utils';

requires 'BUILD';

has 'class_for_loading' => (
    is  => 'ro',
    isa => 'ArrayRef[Str]',
    required => 1,
);

has 'loaded_instances' => (
    is  => 'ro',
    isa => 'HashRef[Object]',
    default => sub { {} },
);

before 'BUILD' => sub {
    my $self = shift;

    my $app = $self->app_name;
    for my $class (@{ $self->class_for_loading }) {
        (my $method = lc $class) =~ s/::/_/go;

        $self->meta->add_method($method, sub {
            my ( $self, $comp ) = @_;

            my $module = "$app\::$class\::$comp";
            my $instance = $self->loaded_instances->{$module};

            if ( !defined $instance ) {
                Class::MOP::load_class($module);
                $instance = $module->new;
            }

            return $instance;
        });
    }
};

no Moose::Role;

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
