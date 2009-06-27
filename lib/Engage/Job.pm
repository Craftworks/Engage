package Engage::Job;

use Moose::Role;

requires 'appclass';

has 'job' => (
    is  => 'ro',
    isa => 'Engage::Job::Client',
    default => sub {
        my $self = shift;
        my $appclass = $self->appclass;
        my $class = "$appclass\::Job::Client";
        Class::MOP::load_class( $class );
        $class->instance;
    },
    lazy => 1,
);

no Moose::Role;

1;
