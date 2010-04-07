package Engage::DAO::Utils;

use strict;
use warnings;
use Carp;
use Scalar::Util 'blessed';
use namespace::clean;

sub join_tables {
    shift if ( blessed $_[0] || exists $::{"$_[0]\::"} );
    my ( $left, $right, $lkey, $rkey ) = @_;
    $rkey ||= $lkey;

    eval {
        my %right;
        for my $row (@$right) {
            $right{ $row->{$rkey} } = $row;
        }

        for my $row (@$left) {
            my $key = $row->{$lkey};
            if ( $right{ $key } ) {
                %$row = ( %{$right{ $key }}, %$row );
            }
        }
    };
    confess $@ unless !$@;

    return;
}

1;
