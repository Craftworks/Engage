package Engage::Exception;

# XXX: See bottom of file for Exception implementation

package Engage::Exception::Base;

use Moose;
use Carp;
use namespace::clean -except => 'meta';

=head1 NAME

Engage::Exception - Engage Exception Class

=head1 SYNOPSIS

   Engage::Exception->throw( qq/Fatal exception/ );

See also L<Engage>.

=head1 DESCRIPTION

This is the Engage Exception class.

=head1 METHODS

=head2 throw( $message )

=head2 throw( message => $message )

=head2 throw( error => $error )

Throws a fatal exception.

=cut

has message => (
    is      => 'ro',
    isa     => 'Str',
    default => sub { $! || '' },
);

use overload
    q{""}    => \&as_string,
    fallback => 1;

sub as_string {
    my ($self) = @_;
    return $self->message;
}

around BUILDARGS => sub {
    my ($next, $class, @args) = @_;
    if (@args == 1 && !ref $args[0]) {
        @args = (message => $args[0]);
    }

    my $args = $class->$next(@args);
    $args->{message} ||= $args->{error}
        if exists $args->{error};

    return $args;
};

sub throw {
    my $class = shift;
    my $error = $class->new(@_);
    local $Carp::CarpLevel = 1;
    croak $error;
}

sub rethrow {
    my ($self) = @_;
    croak $self;
}

=head2 meta

Provided by Moose

=head1 AUTHORS

Engage Contributors, see Engage.pm

=head1 COPYRIGHT

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

Engage::Exception::Base->meta->make_immutable;

package Engage::Exception;

use Moose;
use namespace::clean -except => 'meta';

use vars qw[$ENGAGE_EXCEPTION_CLASS];

BEGIN {
    extends($ENGAGE_EXCEPTION_CLASS || 'Engage::Exception::Base');
}

__PACKAGE__->meta->make_immutable;

1;
