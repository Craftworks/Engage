package Engage::Utils;

use Moose::Role;
use MooseX::Types::Path::Class;
use Digest::MD5;
use Time::HiRes;
use Cwd;

has 'home' => (
    is  => 'ro',
    isa => 'Path::Class::Dir',
    builder => '_build_home',
    coerce => 1,
);

has 'term_width' => (
    is  => 'ro',
    isa => 'Int',
    lazy_build => 1,
);

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

        $home = $home->absolute->cleanup->resolve;
        $home = $home->parent while $home =~ /b?lib$/o;
    }

    return $home;
}

sub _build_term_width {
    my $self = shift;

    my $width = eval '
        use Term::Size::Any;
        (Term::Size::Any::chars())[0];
    ';

    if ($@) {
        $width = $ENV{'COLUMNS'}
            if exists $ENV{'COLUMNS'}
            && $ENV{'COLUMNS'} =~ /^\d+$/;
    }

    $width = 80 unless ( $width && 80 <= $width );
    $width;
}

sub appclass {
    my $self  = shift;
    my $class = ref $self || $self;
    if ( $class =~ /^(.+?)::(?:DOD|DAO|API|CLI|WUI|SRV|Job|FCGI)(?:::)?.*$/o ) {
        return $1;
    }
}

sub class2prefix {
    my $class = ( (@_ == 1) ? (blessed $_[0] || $_[0]) : $_[1] ) || '';
    $class =~ s/::/_/go;
    return lc $class;
}

sub class2env {
    my $class = ( (@_ == 1) ? (blessed $_[0] || $_[0]) : $_[1] ) || '';
    $class =~ s/::/_/go;
    return uc $class;
}

sub env_value {
    my ( $self, $key ) = @_;
    $key = uc $key;

    for my $prefix ( uc $self->appclass, 'ENGAGE' ) {
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
        return $path->resolve;
    }
    else {
        return Path::Class::File->new( $self->home, @path );
    }
}

sub random_token {
    Digest::MD5::md5_hex( Time::HiRes::time . rand );
}

no Moose::Role;

1;

__END__

=head1 NAME

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 appprefix

    MyApp::Foo becomes myapp_foo

=head2 appclass

return application class

=head2 env_value($class, $key)

Checks for and returns an environment value. For instance, if $key is
'home', then this method will check for and return the first value it finds,
looking at $ENV{MYAPP_HOME} and $ENV{ENGAGE_HOME}.

=head2 path_to(@path)

Merges C<@path> with C<< home() >> and returns a
L<Path::Class::Dir> object. Note you can usually use this object as
a filename, but sometimes you will have to explicitly stringify it
yourself by calling the C<<->stringify>> method.

For example:

    $self->path_to( 'db', 'sqlite.db' );

=head1 AUTHOR

Craftworks, C<< <craftwork at cpan org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Craftworks, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
