package Engage::Class::Loader;

use Moose::Role;
with 'Engage::Utils';

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

sub BUILD {
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

}

no Moose::Role;

1;

__END__
