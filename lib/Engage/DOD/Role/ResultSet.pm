package Engage::DOD::Role::ResultSet;

use Moose::Role;

requires 'rows';
requires 'next_array';
requires 'next_hash';
requires 'all_array';
requires 'all_hash';

no Moose::Role;

sub next {
    shift->next_hash( @_ );
}

sub all {
    shift->all_hash( @_ );
}

1;
