package Engage::Log;

use Moose::Role;
with 'MooseX::LogDispatch';

$Log::Dispatch::Config::CallerDepth = 1; 

has 'log' => (
    is  => 'ro',
    isa => 'Log::Dispatch::Config',
    default => sub { shift->logger },
    lazy => 1,
);

has 'log_dispatch_conf' => (
    is  => 'ro',
    isa => 'HashRef',
    lazy_build => 1,
);

Class::MOP::Class->create(
    'Log::Dispatch' => (
        methods => {
            'print' => sub { shift->log( level => 'debug',   message => @_ ) },
            'warn'  => sub { shift->log( level => 'warning', message => @_ ) },
            'fatal' => sub { shift->log( level => 'alert',   message => @_ ) },
        },
    ),
);

sub _build_log_dispatch_conf {
    my $self = shift;
    if ( $self->can('config') && $self->config->{'Log::Dispatch'} ) {
        return $self->config->{'Log::Dispatch'};
    }
    else {
        return {
            class     => 'Log::Dispatch::Screen',
            min_level => 'debug',
            stderr    => 1,
            format    => '%d [%p] %m at %P line %L%n',
        }
    }
}

1;

__END__
