package Engage::Utils;

use Moose::Role;
use MooseX::Types::Path::Class;
use Cwd;

has 'home' => (
    is  => 'ro',
    isa => 'Path::Class::Dir',
    builder => '_build_home',
    coerce => 1,
);

has 'app_name' => (
    is  => 'ro',
    isa => 'Str',
    builder => '_build_app_name',
);

sub _build_app_name {
    my $pkg = ref shift;
    return index($pkg, ':') != -1
            ?  substr $pkg, 0, index($pkg, ':')
            : $pkg;
}

sub _build_home {
    my $self = shift;

    my $home;

    if ( my $env = $self->env_value('HOME') ) {
        $home = $env;
    }
    else {
        my $class = ref $self;
        (my $file = "$class.pm") =~ s{::}{/}go;

        if ( my $inc_entry = $INC{$file} ) {
            (my $path = $inc_entry ) =~ s/$file$//;
            $home = Path::Class::Dir->new($path);
        }
        else {
            $home = Path::Class::Dir->new(Cwd::cwd);
        }

        $home = $home->absolute->cleanup;
        $home = $home->parent while $home =~ /b?lib$/o;
    }

    return $home;
}

sub env_value {
    my ( $self, $key ) = @_;

    my $class = blessed $self ? ref $self : $self;
    $class =~ s/::/_/g;
    $class = uc $class;
    $key   = uc $key;

    for my $prefix ( $class, 'ENGAGE' ) {
        if ( defined( my $value = $ENV{"${prefix}_${key}"} ) ) {
            return $value;
        }
    }
    return;
}

sub path_to {
    my ( $self, @path ) = @_;
    my $path = Path::Class::Dir->new( $self->home, @path );
    if ( -d $path ) {
        return $path;
    }
    else {
        return Path::Class::File->new( $self->home, @path );
    }
}

no Moose::Role;

1;

__END__
