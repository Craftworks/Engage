package Engage::Log;

use Moose::Role;
with 'MooseX::LogDispatch';

requires 'env_value';

has 'debug' => (
    is  => 'rw',
    isa => 'Bool',
    default => 0,
);

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

no Moose::Role;

$Log::Dispatch::Config::CallerDepth = 1; 

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

    $self->debug( $self->env_value( 'DEBUG' ) ? 1 : 0 );

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
