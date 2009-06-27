package Engage::Job::Client;

use MooseX::Singleton;
use TheSchwartz;

with 'Engage::Utils';
with 'Engage::Config';
with 'Engage::Log';

has '+config_prefix' => ( default => 'job' );
has '+config_key'    => ( default => 'Job' );
has '+config_switch' => ( default => 1     );

has 'job' => (
    is  => 'ro',
    isa => 'TheSchwartz',
    lazy_build => 1,
);

no Moose;

__PACKAGE__->meta->make_immutable;

sub _build_job {
    TheSchwartz->new( databases => shift->config->{'databases'} );
}

sub assign {
    my ( $self, $worker, @args ) = @_;
    my $appclass = $self->appclass;
    $self->job->insert( "$appclass\::Job::Worker::$worker", @args );
}

sub can_do    { shift->job->can_do    }
sub work_once { shift->job->work_once }

1;
