package Engage::Helper::Daemontools::FCGI;

=head1 NAME

Engage::Helper::Daemontools::FCGI- Helper for daemontools run scripts

=head1 SYNOPSIS

  script/create.pl Daemontools::FCGI [ SiteName ] [ UserName ]

=head1 DESCRIPTION

Helper for the daemontools run scripts;

=head2 Arguments:

C<SiteName> is the site name for the Catalyst class
default value is C<'Service'>.

C<UserName> is the user name of fastcgi process. It is used by setuidgid.
default value is C<'root'>.

=head1 METHODS

=head2 mk_stuff

This is called by L<Catalyst::Helper> with the commandline args to generate the
files.

=head1 SEE ALSO

L<Catalyst::Helper>, L<Catalyst>,

=head1 AUTHOR

Craftworks, C<< <craftwork at cpan org> >>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

use Moose;

has helper => ( is => 'ro', isa => 'Engage::Helper', required => 1 );
has site   => ( is => 'ro', isa => 'Str' );
has user   => ( is => 'ro', isa => 'Str' );

sub mk_stuff {
    my ( $package, $helper, $site, $user ) = @_;

    my $self = $package->new(
        helper => $helper,
        site   => $site || 'Service',
        user   => $user || 'root',
    );

    $self->_parse_args;
    $self->_mk_files;
}

sub _parse_args {
    my $self = shift;
    my $helper = $self->{helper};

    $self->{daemon}       = lc "fcgi_" . $self->{site};
    $self->{script}       = File::Spec->catfile( $helper->{base}, 'script' );
    $self->{appprefix}    = Catalyst::Utils::appprefix( $helper->{app} );
    $self->{run_dir}      = File::Spec->catfile( $helper->{base}, 'daemon', $self->{daemon});
    $self->{run_file}     = File::Spec->catfile( $self->{run_dir}, 'run' );
    $self->{log_run_dir}  = File::Spec->catfile( $self->{run_dir}, 'log' );
    $self->{log_run_file} = File::Spec->catfile( $self->{log_run_dir}, 'run' );

}

sub _mk_files {
    my $self = shift;
    my $helper = $self->{helper};

    $helper->mk_dir($self->{run_dir});
    $helper->render_file( 'run', $self->{run_file}, $self );
    chmod 0755, $self->{run_file};

    $helper->mk_dir($self->{log_run_dir});
    $helper->render_file( 'log_run', $self->{log_run_file}, $self );
    chmod 0755, $self->{log_run_file};
}

1;

__DATA__

__run__
#!/bin/sh
if [ "$(id -u)" = "0" ]; then
    setuidgid='setuidgid [% user %]'
fi
exec 2>&1
PATH='/usr/bin:/usr/local/bin:[% script %]' \
$setuidgid \
[% appprefix %]_fcgi.pl [% site %]
__log_run__
#!/bin/sh
exec env - PATH='/usr/bin:/usr/local/bin' \
multilog s16777216 n4 \
./main \

