package Engage::Job::Daemon;

use Moose;
use Sys::Hostname;
use Module::Pluggable::Object;
use Parallel::Prefork;
use Text::SimpleTable;
use namespace::clean -except => 'meta';

with 'Engage::Utils';
with 'Engage::Config';
with 'Engage::Log';
with 'Engage::Job';

has '+config_prefix' => ( default => 'job' ); 
has '+config_key'    => ( default => 'Job' );
has '+config_switch' => ( default => 1     );

has 'proc_manager' => (
    is  => 'ro',
    isa => 'Parallel::Prefork',
    lazy_build => 1,
);

has 'worker_classes' => (
    is  => 'ro',
    isa => 'ArrayRef[Str]',
    builder => '_build_worker_classes',
);

no Moose;

__PACKAGE__->meta->make_immutable;

sub _build_worker_classes {
    my $self = shift;
    my $appclass = $self->appclass;
    my $locator= Module::Pluggable::Object->new(
        search_path => "$appclass\::Job::Worker",
    );
    Class::MOP::load_class($_) for $locator->plugins;
    [ $locator->plugins ];
}

sub _build_proc_manager {
    my $self = shift;
    Parallel::Prefork->new({
        max_workers  => $self->config->{'max_workers'} || 4,
        fork_delay   => 1,
        trap_signals => {
            TERM => 'TERM',
            HUP  => 'TERM',
        },
    });
}

sub BUILD {
    my $self = shift;
    if ( $self->debug ) {
        my $t = Text::SimpleTable->new($self->term_width - 6);
        $t->row($_) for @{$self->worker_classes};
        $self->log->debug( "Loaded workers:\n" . $t->draw . "\n" )
            if @{ $self->worker_classes };
    }
}

sub run {
    my $self = shift;
    my $pm = $self->proc_manager;

    $self->log->debug("Start daemon $$") if $self->debug;
    (my $appprefix = $self->appprefix) =~ s/_/-/;
    $0 = "$appprefix-pm";
    $self->job->can_do; # check database connection

    while ( $pm->signal_received ne 'TERM' ) {

        # spawn child
        $pm->start and next;
        $self->log->debug("Spawn child $$") if $self->debug;
        $0 = $appprefix;

        # init worker
        $self->job->can_do($_) for (@{ $self->worker_classes });

        # works
        my $works_before_exit = $self->config->{'max_work_per_child'} || 10;
        $SIG{'TERM'} = sub { $works_before_exit = 0 };
        while ( 0 < $works_before_exit ) {
            sleep 1 and next unless $self->job->work_once;
            $self->log->debug("Worked child $$") if $self->debug;
            --$works_before_exit;
        }

        # finish
        $self->log->debug("Finish child $$") if $self->debug;
        $pm->finish;
    }

    $pm->wait_all_children;
    die q{something's wrong};
}

1;

=head1 NAME

Engage::Job - Engage JobQueue

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 run

Run job queue process.

=head1 AUTHOR

Craftworks, C<< <craftwork at cpan org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Craftworks, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

