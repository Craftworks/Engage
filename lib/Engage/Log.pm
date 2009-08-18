package Engage::Log;

use Moose::Role;
use Data::Dump 'dump';
with 'MooseX::LogDispatch';

requires 'env_value';

has 'debug' => (
    is  => 'ro',
    isa => 'Bool',
    default => sub { shift->env_value( 'DEBUG' ) ? 1 : 0 },
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

$Log::Dispatch::Config::CallerDepth = 0;

Class::MOP::Class->create(
    'Log::Dispatch' => (
        methods => {
            'dump'  => sub {
                local $Log::Dispatch::Config::CallerDepth = 1;
                shift->log( level => 'debug',   message => dump @_ );
            },
            'print' => sub {
                local $Log::Dispatch::Config::CallerDepth = 1;
                shift->log( level => 'debug',   message => "@_" );
            },
            'warn'  => sub {
                local $Log::Dispatch::Config::CallerDepth = 1;
                shift->log( level => 'warning', message => "@_" );
            },
            'fatal' => sub {
                local $Log::Dispatch::Config::CallerDepth = 1;
                shift->log( level => 'alert',   message => "@_" );
            },
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
            format    => '%d{%Y-%m-%d %H:%M:%S} [%p] %m at %P line %L%n',
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
