package Engage::DOD::Role::Driver;

use Moose::Role;

requires 'create';
requires 'read';
requires 'update';
requires 'delete';

no Moose::Role;

1;
