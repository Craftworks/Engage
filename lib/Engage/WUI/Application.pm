package Engage::WUI::Application;

use Moose;
use Catalyst::Runtime 5.80;
use Catalyst;
use Time::HiRes;
use HTTP::Status;
extends 'Catalyst';
with 'Engage::Utils';
with 'Engage::Class::Loader';

our $StartedOn;

BEGIN {
    $StartedOn = Time::HiRes::time;
}

after 'setup_finalize' => sub {
    my $c = shift;
    $c->log->info(sprintf 'Setup took %0.6fs', Time::HiRes::time - $StartedOn );
    $c->log->_flush if $c->log->can('_flush');
};

around 'finalize_error' => sub {
    my ( $next, $self, @args ) = @_;
    my $c = $self;
    $c->forward('/error/handle_exception');
    if ( not $c->engine->env->{'NO_STACK_TRACE'} ) {
        $self->$next(@args);
    }
    $c->log->debug(sprintf 'Status %d %s',
        $c->res->status, HTTP::Status::status_message($c->res->status));
};

no Moose;

__PACKAGE__->add_loader('API');
__PACKAGE__->meta->make_immutable;

1;
