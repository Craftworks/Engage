package Engage::WUI::Controller::Error;

use Moose;
use HTTP::Status;

BEGIN { extends 'Catalyst::Controller' }

sub handle_exception :Private {
    my ( $self, $c ) = @_;
    if ( $c->engine->env->{'SEND_FATAL'} ) {
        $c->forward('send_fatal');
    }
}

sub handle_error :Private {
    my ( $self, $c ) = @_;
    $c->res->status(500);
    $c->stash->{'template'} = $c->config->{'http_error_template'};
}

sub not_found :Private {
    my ( $self, $c ) = @_;
    $c->res->body( HTTP::Status::status_message( RC_NOT_FOUND ) );
    $c->res->status( RC_NOT_FOUND );
    $c->detach;
}

sub send_fatal : Private {
    my ( $self, $c ) = @_;
    eval {
        $c->api('Email::Sender')->sendmail(
            'email' => $c->config->{'send_fatal'}{'email'},
            'to'    => $c->config->{'send_fatal'}{'to'},
            'vars'  => +{
                'error'  => [ map "$_", @{ $c->error } ],
                'params' => YAML::Syck::Dump($c->req->params),
                'env'    => $c->engine->env,
                'user'   => $c->user->obj,
            },
        );
    };
    $c->log->debug("$@") if $@;
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
