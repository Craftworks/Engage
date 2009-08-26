package Engage::DOD;

use Moose;
with 'Engage::Utils';
with 'Engage::Config';
with 'Engage::Log';

has '+config_prefix' => (
    default => 'dod',
);

has 'result_class' => (
    is  => 'ro',
    isa => 'Str',
    default => sub {
        my $self = shift;
        my $rs = sprintf '%s::ResultSet', ref $self;
        if ( !Class::MOP::is_class_loaded($rs) ) {
            Class::MOP::load_class($rs);
        }
        $rs;
    },
);

no Moose;

__PACKAGE__->meta->make_immutable;

1;

=head1 NAME

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Craftworks, C<< <craftwork at cpan org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Craftworks, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
