package Engage::FCGI;

use Moose;
use Sys::Hostname;
with 'Engage::Utils';
with 'Engage::Config';

has '+config_prefix' => (
    default => 'fcgi',
);

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
    my $site = $self->site;
    my $hostname = Sys::Hostname::hostname;

    confess qq{Cannot find key "$site" in configuration}
        if ( !exists $self->config->{ $site } );

    my $found = 0;
    for my $config (@{ $self->config->{ $site } }) {
        my $regex = $config->{'host'} || '';
        if ( $hostname =~ /$regex/ ) {
            $found = 1;
            $self->config( $config );
            last;
        }
    }
    $found or confess qq{Cannot find config for "$hostname"};

    if ( my $listen = delete $self->config->{'listen'} ) {
        $self->listen( $listen );
    }

    if ( my $env = delete $self->config->{'env'} ) {
        $ENV{$_} = $env->{$_} for ( keys %$env );
    }
}

sub run {
    my $self = shift;

    my $class = sprintf '%s::WUI::%s', $self->app_name, $self->site;
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
