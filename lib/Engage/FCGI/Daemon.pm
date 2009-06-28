package Engage::FCGI::Daemon;

use Moose;

with 'Engage::Utils';
with 'Engage::Config';

has '+config_prefix' => ( default => 'fcgi' );
has '+config_switch' => ( default => 1      );

has 'site' => (
    is  => 'ro',
    isa => 'Str',
    required => 1,
);

has 'listen' => (
    is  => 'rw',
    isa => 'Str',
);

no Moose;

__PACKAGE__->meta->make_immutable;

sub BUILD {
    my $self = shift;

    $self->config( $self->config->{ $self->site } );

    if ( my $listen = delete $self->config->{'listen'} ) {
        $self->listen( $listen );
    }

    if ( my $env = delete $self->config->{'env'} ) {
        $ENV{$_} = $env->{$_} for keys %$env;
    }
}

sub run {
    my $self = shift;

    my $class = sprintf '%s::WUI::%s', $self->appclass, $self->site;
    local $ENV{'CATALYST_ENGINE'} = 'FastCGI';
    Class::MOP::load_class( $class );
    $class->run(
        $self->listen,
        $self->config,
    );
}

1;

__END__

=head1 NAME

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 run

Run FastCGI

=head1 AUTHOR

Craftworks, C<< <craftwork at cpan org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Craftworks, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
