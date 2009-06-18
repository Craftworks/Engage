package Engage::FCGI;

use Moose;
use Sys::Hostname;
use Data::Dumper;
with 'Engage::Utils';
with 'Engage::Config';

has '+config_prefix' => (
    default => 'fcgi',
);

has 'app' => (
    is  => 'ro',
    isa => 'Str',
    required => 1,
);

has 'listen' => (
    is  => 'rw',
    isa => 'Str',
);

sub BUILD {
    my $self = shift;
    my $app  = $self->app;
    my $hostname = Sys::Hostname::hostname;

    die qq{Cannot find key "$app" in configuration}
        if ( !exists $self->config->{ $app } );

    my $found = 0;
    for my $config (@{ $self->config->{ $app } }) {
        my $regex = $config->{'host'} || '';
        if ( $hostname =~ /$regex/ ) {
            $found = 1;
            $self->config( $config );
            last;
        }
    }
    $found or die qq{Cannot find config for "$hostname"};

    if ( my $listen = delete $self->config->{'listen'} ) {
        $self->listen( $listen );
    }

    if ( my $env = delete $self->config->{'env'} ) {
        $ENV{$_} = $env->{$_} for ( keys %$env );
    }
}

no Moose;

__PACKAGE__->meta->make_immutable;

sub run {
    my $self = shift;

    my $class = sprintf '%s::%s', $self->app_name, $self->app;
    local $ENV{'CATALYST_ENGINE'} = 'FastCGI';
    Class::MOP::load_class( $class );
    $class->run(
        $self->listen,
        $self->config,
    );
}

1;

__END__
