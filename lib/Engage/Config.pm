package Engage::Config;

use Moose::Role;
use MooseX::Types::Path::Class;
use FindBin;
use Config::Any;
use Hash::Merge;
use Data::Visitor::Callback;
use Scalar::Alias;
use namespace::clean -except => 'meta';

requires 'appclass';

has 'config' => (
    is  => 'rw',
    isa => 'HashRef',
    builder => '_build_config',
);

has 'config_path' => (
    is  => 'rw',
    isa => 'Path::Class::Dir',
    coerce => 1,
    default  => sub { $ENV{'CONFIG_PATH'} || "$FindBin::Bin/../conf" },
);

has 'loaded_config' => (
    is  => 'ro',
    isa => 'ArrayRef[Path::Class::File]',
    lazy_build => 1,
);

has 'config_prefix' => (
    is  => 'ro',
    isa => 'Str',
    required => 1,
);

has 'config_suffix' => (
    is  => 'ro',
    isa => 'Str',
    default => sub { $ENV{'CONFIG_LOCAL_SUFFIX'} || 'local' },
);

has 'config_switch' => (
    is  => 'ro',
    isa => 'Bool',
    default => 0,
);

no Moose::Role;

sub _build_loaded_config {
    my $self   = shift;
    my $prefix = $self->config_prefix;
    my $suffix = $self->config_suffix;
    my $pregex = qr/^($prefix\.(.+)\.(.{1,4}))$/;
    my $sregex = qr/-$suffix\.(.{1,4})$/;
    my %extens = map { $_ => 1 } @{ Config::Any->extensions };

    my @files;
    $self->config_path->recurse('callback' => sub {
        my $file = shift;
        return if ( $file->is_dir );
        return if !( my ($base, $name, $ext) = $file->basename =~ $pregex );
        return if ( !$extens{$ext} );
        push @files, $file if ( $name !~ /-/o || $base =~ $sregex );
    });

    return [ sort {
        $a =~ $sregex cmp $b =~ $sregex || $a cmp $b || $a <=> $b
    } @files ];
}

sub _build_config {
    my $self = shift;

    my $config = Config::Any->load_files({
        files   => $self->loaded_config,
        use_ext => 1,
    });
    return +{} if !@$config;

    my %config = _merge_hash($config);

    _substitute($self, \%config);

    my $class = ref $self;
    (my $abbr = substr ($class, length $self->appclass)) =~ s/^:://o;
    my $class_config = $config{$abbr} || {};

    if ( $self->config_switch ) {
        _find_by_hostname($class_config);
    }

    return $class_config;
}

no namespace::clean;

sub _merge_hash {
    my $config = shift;
    my %config;
    my $behavior = Hash::Merge::get_behavior;
    Hash::Merge::specify_behavior({
        SCALAR => {
            SCALAR => sub { $_[1] },
            ARRAY  => sub { Carp::croak 'SCALAR and ARRAY cannot merge in config file.' },
            HASH   => sub { Carp::croak 'SCALAR and HASH cannot merge in config file.' },
        },
        ARRAY  => {
            SCALAR => sub { Carp::croak 'ARRAY and SCALAR cannot merge in config file.' },
            ARRAY  => sub { $_[1] },
            HASH   => sub { Carp::croak 'ARRAY and HASH cannot merge in config file.' },
        },
        HASH   => {
            SCALAR => sub { Carp::croak 'HASH and SCALAR cannot merge in config file.' },
            ARRAY  => sub { Carp::croak 'HASH and ARRAY cannot merge in config file.' },
            HASH   => sub { Hash::Merge::_merge_hashes( $_[0], $_[1] ) },
        },
    }, 'ENGAGE_CONFIG' );
    %config = %{ Hash::Merge::merge( \%config, values %$_ ) } for (@$config);
    Hash::Merge::set_behavior( $behavior );
    return %config;
}

sub _substitute {
    my ( $self, $config ) = @_;
    Data::Visitor::Callback->new(
        plain_value => sub {
            return unless ( defined && length );
            s{__(\w+?)(?:\((.+?)\))?__}{
                my $value = $self->$1( $2 ? split /,/, $2 : () );
                defined $value ? $value : '';
            }egx;
        }
    )->visit($config);
}

sub _find_by_hostname {
    my alias $config = shift;

    require Sys::Hostname;
    my $hostname = $ENV{'HOSTNAME'} || Sys::Hostname::hostname();

    my $default  = delete $config->{'DEFAULT'} || {};
    for my $host_regex ( keys %$config ) {
        if ( $hostname =~ qr/$host_regex/ ) {
            $config = $config->{$host_regex};
            return;
        }
    }

    confess qq{Cannot find config for "$hostname"} unless %$default;
    $config = $default;
}

use namespace::clean;

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
