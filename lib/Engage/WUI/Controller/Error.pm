package Engage::WUI::Controller::Error;

use Moose;
use HTTP::Status;

BEGIN { extends 'Catalyst::Controller' }

sub handle_exception :Private {
    my ( $self, $c ) = @_;
}

sub not_found :Private {
    my ( $self, $c ) = @_;
    $c->res->body( HTTP::Status::status_message( RC_NOT_FOUND ) );
    $c->res->status( RC_NOT_FOUND );
    $c->detach;
}

__PACKAGE__->meta->make_immutable;

1;

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
