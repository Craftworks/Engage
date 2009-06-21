package Engage::Helper::Lighttpd;

=head1 NAME

Engage::Helper::Lighttpd - Helper for the lighttpd.conf

=head1 SYNOPSIS

  script/create.pl Lighttpd  [ HostRegex ] [ SocketPath ]

=head1 DESCRIPTION

Helper for the lighttpd.conf

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
has host => ( is => 'ro', isa => 'Str', required => 1 );
has socket => ( is => 'ro', isa => 'Str' );

sub mk_stuff {
    my ( $package, $helper, $host, $socket ) = @_;

    my $self = $package->new(
        helper => $helper,
        host   => $host   || 'localhost',
        socket => $socket || '/tmp/.s.fcgi.service',
    );

    $self->{conf} = File::Spec->catfile( $helper->{base}, 'conf', 'lighttpd.conf' );
    $helper->render_file( 'lighttpd_conf', $self->{conf}, $self );
}

1;

__DATA__

__lighttpd_conf__
server.modules += ( "mod_fastcgi" )
$HTTP["host"] =~ "[% host %]" {
    server.document-root = "[% base %]/static"
    # FAST CGI =========================
    $HTTP["url"] =~ "/[^/.]*(\?|$)" {
        fastcgi.server = (
            "" => ((
                "socket" => "[% socket %]",
                "check-local" => "disable",
            ))
        )
    }
}
