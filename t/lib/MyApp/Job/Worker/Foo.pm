package MyApp::Job::Worker::Foo;

use Moose;
extends 'Engage::Job::Worker';

has 'msg' => ( is => 'ro' );
has 'now' => ( is => 'ro' );

no Moose;

__PACKAGE__->meta->make_immutable;

sub work {
    my ( $self, $job ) = @_;

    $self->log->debug('WORKIN');
    eval { $self->log->debug( $self->api('Foo')->foo ) };
    $self->log->debug($@);

    $job->failed("something's wrong");
}

1;
