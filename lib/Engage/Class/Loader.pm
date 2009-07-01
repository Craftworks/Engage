package Engage::Class::Loader;

use Moose::Role;

requires 'appclass';

has 'loaded_instances' => (
    is  => 'ro',
    isa => 'HashRef[Object]',
    default => sub { {} },
);

sub add_loader {
    my $self = shift;
    my @class_for_loading = @_;

    for my $class (@class_for_loading) {
        (my $method = lc $class) =~ s/::/_/go;

        $self->meta->add_method($method, sub {
            my $self = shift;
            my $comp = shift;

            my $app       = $self->appclass;
            my $module    = "$app\::$class\::$comp";
            my $instances = $self->loaded_instances;

            if ( !Class::MOP::is_class_loaded($module) ) {
                Class::MOP::load_class($module);
            }

            if ( !defined $instances->{$module} ) {
                $instances->{$module} = $module->new(@_);
            }

            return $instances->{$module};
        });

        $self->meta->add_method("new_$method", sub {
            my $self = shift;
            my $comp = shift;

            my $app       = $self->appclass;
            my $module    = "$app\::$class\::$comp";

            if ( !Class::MOP::is_class_loaded($module) ) {
                Class::MOP::load_class($module);
            }

            return $module->new(@_);
        });
    }
};

no Moose::Role;

1;

__END__

=head1 NAME

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 add_loader(@class_for_loading)

add method to caller class

=head1 AUTHOR

Craftworks, C<< <craftwork at cpan org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Craftworks, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
