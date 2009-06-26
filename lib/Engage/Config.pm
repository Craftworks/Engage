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

has 'loaded_files' => (
    is  => 'ro',
    isa => 'ArrayRef[Path::Class::File]',
    lazy_build => 1,
);

has 'loaded_config' => (
    is  => 'ro',
    isa => 'ArrayRef[HashRef]',
    lazy_build => 1,
);

has 'config_key' => (
    is  => 'ro',
    isa => 'Str',
    builder => '_build_config_key',
);

has 'config_switch' => (
    is  => 'ro',
    isa => 'Bool',
    default => 0,
);

no Moose::Role;

sub _build_config_key {
    my $self     = shift;
    my $class    = ref $self;
    my $appclass = $self->appclass;
    my ($key) = $class =~ /^$appclass\::(.+)/;
    $key;
}

sub _build_loaded_files {
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

sub _build_loaded_config {
    my $self = shift;
    Config::Any->load_files({
        files   => $self->loaded_files,
        use_ext => 1,
    });
}

sub _build_config {
    my $self = shift;

    return +{} unless @{ $self->loaded_config };

    my $config = {};
    _merge_hash($self, $config);
    _substitute($self, $config);

    $config = $config->{$self->config_key} || {};

    if ( $self->config_switch ) {
        _find_by_hostname($config);
    }

    return $config;
}

no namespace::clean;

sub _merge_hash {
    my $self   = shift;
    my $config = shift;

    my $msg = '%s and %s cannot merge in config file.';
    my $behavior = Hash::Merge::get_behavior;
    Hash::Merge::specify_behavior({
        SCALAR => {
            SCALAR => sub { $_[1] },
            ARRAY  => sub { confess sprintf $msg, 'SCALAR', 'ARRAY' },
            HASH   => sub { confess sprintf $msg, 'SCALAR', 'HASH'  },
        },
        ARRAY  => {
            SCALAR => sub { confess sprintf $msg, 'ARRAY', 'SCALAR' },
            ARRAY  => sub { $_[1] },
            HASH   => sub { confess sprintf $msg, 'ARRAY', 'HASH'   },
        },
        HASH   => {
            SCALAR => sub { confess sprintf $msg, 'HASH', 'SCALAR'  },
            ARRAY  => sub { confess sprintf $msg, 'HASH', 'ARRAY'   },
            HASH   => sub { Hash::Merge::_merge_hashes( $_[0], $_[1] ) },
        },
    }, 'ENGAGE_CONFIG' );
    for ( @{ $self->loaded_config } ) {
        %$config = %{ Hash::Merge::merge( $config, values %$_ ) };
    }
    Hash::Merge::set_behavior( $behavior );
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
    my $config = shift;

    require Sys::Hostname;
    my $hostname = $ENV{'HOSTNAME'} || Sys::Hostname::hostname();

    my $default  = delete $config->{'DEFAULT'} || {};
    for my $host_regex ( keys %$config ) {
        if ( $hostname =~ /$host_regex/ ) {
            %$config = %{ $config->{$host_regex} };
            return;
        }
    }

    confess qq{Cannot find config for "$hostname"} unless %$default;
    %$config = %$default;
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
