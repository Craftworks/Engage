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
    $worker = "$appclass\::Job::Worker::$worker";
    my $handle = $self->job->insert( $worker, @args );
    $self->log->info("Job assign to $worker") if $self->debug;
    return $handle;
}

sub can_do    { shift->job->can_do(@_)    }
sub work_once { shift->job->work_once(@_) }

1;
