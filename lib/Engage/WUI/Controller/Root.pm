package Engage::WUI::Controller::Root;

=head1 NAME

Engage::WUI::Base::Controller::Root - Base Root Controller for Engage

=head1 SYNOPSIS

=head1 DESCRIPTION

[enter your description here]

=cut

use Moose;

BEGIN { extends 'Catalyst::Controller' }

no Moose;

__PACKAGE__->meta->make_immutable;

=head1 METHODS

=head2 begin

=cut

sub begin :Private {
    my ( $self, $c ) = @_;
}

=head2 prepare

This is the C<prepare> method that initializes the request.  Any matching 
action will go through this, so it is an application-wide automatically 
executed action. For more information, see L<Catalyst::DispatchType::Chained>

=cut

sub prepare :Chained('/') PathPart('') CaptureArgs(0) {
    my ( $self, $c ) = @_;
}

=head2 default

This is the "not found" action, any request that can't be handled falls to this
 
=cut

sub default :Private {
    my ( $self, $c ) = @_;
    $c->forward('/error/not_found');
}

=head2 index

This is the "/" action, dispatched to based on the C<Args(0)>.

=cut

sub index :Chained('prepare') PathPart('') Args(0) {
    my ( $self, $c ) = @_;
}

=head2 end

Attempt to render a view, if needed.  To modify the default view, set the
C<default_view> key in the configuration.

=cut

sub end :Private {
    my ( $self, $c ) = @_;
    $c->log->debug(sprintf 'Status %d %s', $c->res->status, HTTP::Status::status_message( $c->res->status ) );
    return 1 if $c->res->status =~ /^3\d\d$/o;
    return 1 if $c->res->body;
    $c->forward('render');
}

=head2 render

=cut

sub render :ActionClass('RenderView') {}

1;

=head1 AUTHOR

Craftworks, C<< <craftwork at cpan org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Craftworks, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
