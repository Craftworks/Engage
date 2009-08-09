package Engage::WUI::Base::Application;

use Moose;
use Catalyst::Runtime 5.80;
use Catalyst;
use Time::HiRes;
extends 'Catalyst';

our $StartedOn;

BEGIN {
    $StartedOn = Time::HiRes::time;
}

after setup_finalize => sub {
    my $c = shift;
    $c->log->info(sprintf 'Setup took %0.6fs', Time::HiRes::time - $StartedOn );
    $c->log->_flush if $c->log->can('_flush');
};

override finalize => sub {
    my $c = shift;
    $c->forward('/error/handle_exception') if @{ $c->error };
    $c->next::method( @_ );
};

no Moose;

__PACKAGE__->meta->make_immutable;

1;
