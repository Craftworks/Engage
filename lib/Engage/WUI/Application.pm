package Engage::WUI::Application;

use Moose;
use Catalyst::Runtime 5.80;
use Catalyst;
use Time::HiRes;
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

after 'finalize_error' => sub {
    my $c = shift;
    $c->forward('/error/handle_exception');
};

no Moose;

__PACKAGE__->add_loader('API');
__PACKAGE__->meta->make_immutable;

1;
