package Engage::Job::Worker;

use Moose;
use Data::Dumper;
use Time::HiRes;
use namespace::clean -except => 'meta';

with 'Engage::Utils';
with 'Engage::Config';
with 'Engage::Log';
with 'Engage::Class::Loader';

has '+config_prefix' => ( default => 'job' );

no Moose;

__PACKAGE__->add_loader('API');
__PACKAGE__->meta->make_immutable;

sub keep_exit_status_for { 0       }
sub max_retries          { 2       }
sub retry_delay          { 30      }
sub grab_for             { 60 * 60 }

sub grab_job {
    my $class = shift;
    my ( $client ) = @_;
    return $client->find_job_for_workers([ $class ]);
}

sub work_safely {
    my ( $class, $job ) = @_;

    my $client = $job->handle->client;
    $job->set_as_current;
    $client->start_scoreboard;

    # parameter info
    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Sortkeys = 1;
    my $t = Text::SimpleTable->new( [ 35, 'Parameter' ], [ 36, 'Value' ] );
    for my $key ( sort keys %{ $job->arg } ) {
        $t->row( $key, Data::Dumper::Dumper $job->arg->{$key} );
    }

    # work
    my $start = [ Time::HiRes::gettimeofday ];
    my $self = $class->new( $job->arg );
    $self->log->info("*** Working on $class ***");
    $self->log->info( "Worker Parameters are:\n" . $t->draw );
    my $res = eval { $self->work($job) };
    my $elapsed = sprintf '%.4f', Time::HiRes::tv_interval( $start );
    $self->log->info( sprintf 'Worker %s took %.4fs', $class, $elapsed );

    my $cjob = $client->current_job;
    if ($@) {
        $self->log->info("Work failed: $@");
        $cjob->failed($@);
    }
    if ( !$cjob->did_something ) {
        $cjob->failed('Job did not explicitly complete, fail, or get replaced');
    }

    $client->end_scoreboard;

    return $res;
}

1;
