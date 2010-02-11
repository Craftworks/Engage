package Engage::Helper;

use Moose;
use Moose::Util::TypeConstraints;
use MooseX::AttributeHelpers;
use Config;
use File::Spec;
use File::Path;
use FindBin;
use IO::File;
use POSIX;
use Path::Class;
use Template;
use namespace::clean -except => 'meta';
with 'Engage::Utils';
# Catalyst::Helper
use Data::Dumper;

subtype 'PackageName'
    => as 'Str'
    => where { /^[a-zA-Z_][\w:]+$/ && !/\b:\b|:{3,}/ }
    => message { 'Must be valid package name' };

has 'force' => (
    is  => 'ro',
    isa => 'Bool',
    default => 0,
);

has 'name' => (
    is  => 'ro',
    isa => 'PackageName',
    required => 1,
);

has 'app_dist' => (
    is  => 'ro',
    isa => 'Str',
    default => sub { my $dist = shift->name; $dist =~ s/\:\:/-/go; $dist },
);

has 'app_prefix' => (
    is  => 'ro',
    isa => 'Str',
    default => sub { $_[0]->class2prefix( $_[0]->name ) },
    lazy => 1,
);

has 'app_env' => (
    is  => 'ro',
    isa => 'Str',
    default => sub { $_[0]->class2env( $_[0]->name ) },
    lazy => 1,
);

has 'dir' => (
    is  => 'rw',
    isa => 'HashRef[Str]',
    metaclass => 'Collection::Hash',
    provides  => {
        'set' => 'set_dir',
        'get' => 'get_dir',
        'exists' => 'exists_dir',
    },
    lazy_build => 1,
);

has 'dirs' => (
    is  => 'rw',
    isa => 'ArrayRef[Str]',
    default => sub { [] },
    metaclass => 'Collection::Array',
    provides  => {
        'push' => 'push_dirs',
    },
);

has 'file' => (
    is  => 'rw',
    isa => 'HashRef[Str]',
    default => sub { +{} },
    metaclass => 'Collection::Hash',
    provides  => {
        'set' => 'set_file',
        'get' => 'get_file',
    },
    lazy => 1,
);

has 'author' => (
    is  => 'ro',
    isa => 'Str',
    default => sub {
        $ENV{'AUTHOR'} || eval { (getpwuid($<))[6] } || 'Engage developer';
    },
);

has 'perlpath' => (
    is  => 'ro',
    isa => 'Str',
    default => sub {
        -r '/usr/bin/env' ? '/usr/bin/env perl' : $Config{'perlpath'};
    },
);

has 'helper' => (
    is  => 'ro',
    isa => 'Str',
    default => 'App',
);

has 'renderer' => (
    is  => 'ro',
    isa => 'Template',
    default => sub { Template->new },
    lazy => 1,
);

has 'template' => (
    is  => 'ro',
    isa => 'HashRef[Str]',
    lazy_build => 1,
);

has 'vars' => (
    is  => 'rw',
    isa => 'HashRef',
    default => sub { +{} },
);

sub _build_dir {
    my $self = shift;

    my %dir = ( 'root' => $self->app_dist );
    for (qw/lib extlib script t conf template static/) {
        $dir{$_} = File::Spec->catdir( $dir{'root'}, $_ );
    }
    $dir{'app'}  = File::Spec->catdir( $dir{'lib'}, split '::', $self->name );
    for (qw/dod dao api srv wui/) {
        $dir{$_} = File::Spec->catdir( $dir{'app'}, uc );
    }

    return \%dir;
}

sub _build_template {
    my $self = shift;
    my $data = ref($self) . '::DATA';
    local $/;
    my @files = split /(?:\r?\n)?___\[(.+?)\]___\r?\n/m, <$data>;
    shift @files;
    return +{ @files };
}

sub BUILD {
    my ( $self, $args ) = @_;
    # base class only
    return if ref $self ne __PACKAGE__;
    my $class = $self->helper;
    $class = "Engage::Helper::$class";
    Class::MOP::load_class( $class );
    bless $self, $class;
    %$self = %{ $class->new( $args ) };
}

sub catdir {
    my $self = shift;
    my $key  = shift;

    if ( $self->exists_dir($key) ) {
        return File::Spec->catfile( $self->get_dir($key), @_ );
    }

    die qq/Undefined directory "$key", set path before catdir\n/;
}

sub mk_stuff {
    my $self = shift;
    $self->mk_dirs;
    $self->mk_files;
}

sub mk_dirs {
    my $self = shift;

    for my $dir (sort @{ $self->dirs }) {
        if ( -d $dir ) {
            print qq/    exists "$dir"\n/;
            next;
        }
        if ( File::Path::mkpath($dir) ) {
            print qq/   created "$dir"\n/;
        }
        else {
            die qq/Couldn't create "$dir", "$!"\n/;
        }
    }

    return 1;
}

sub mk_files {
    my $self = shift;

    # lazy build
    $self->app_dist;
    $self->app_prefix;
    $self->app_env;

    my $files = $self->file;
    for my $key ( sort { $files->{$a} cmp $files->{$b} } keys %$files ) {
        my $file = Path::Class::File->new( $files->{$key} );
        my $content = $self->render( $key );

        my $action = 'created';
        if ( -e $file && $file->slurp eq $content ) {
            $action = 'exists';
        }
        elsif ( -e $file && $self->force ) {
            $action = 'modified';
        }
        elsif ( -e $file && !$self->force ) {
            $file .= '.new';
        }

        $file->dir->mkpath;

        if ( $action =~ /created|modified/o && (my $fh = $file->openw) ) {
            binmode $fh;
            $fh->print( $content );
            $fh->close;
            chmod 0700, $file if ( $file =~ /\.pl$/o );
        }

        printf qq/%8s "%s"\n/, $action, $file;
    }

    return 1;
}

sub render {
    my ( $self, $file ) = @_;
    my $class = blessed $self;
    my $template = $self->template->{$file};
    die qq/Couldn't find template "$file" at $class, undefined or empty\n/
        unless defined $template and length $template;
    my $content;
    my $vars = +{ %$self, %{ $self->vars } };
    $self->renderer->process( \$template, $vars, \$content )
        or die qq/Couldn't process "$file", / . $self->renderer->error;
    return $content;
}

1;
