package Engage::Helper;

use strict;
use warnings;
use base 'Class::Accessor::Fast';
use Config;
use File::Spec;
use File::Path;
use FindBin;
use IO::File;
use POSIX 'strftime';
use Template;
use Catalyst::Utils;
use Catalyst::Exception;

my %cache;

=head1 NAME

Engage::Helper - Bootstrap a Engage application

=head1 SYNOPSIS

  engage.pl <myappname>

=cut

=head1 DESCRIPTION

This module is used by B<catalyst.pl> to create a set of scripts for a
new catalyst application. The scripts each contain documentation and
will output help on how to use them if called incorrectly or in some
cases, with no arguments.

It also provides some useful methods for a Helper module to call when
creating a component. See L</METHODS>.

=head1 SCRIPTS

=head2 _create.pl

Used to create new components for a catalyst application at the
development stage.

=head2 _server.pl

The catalyst test server, starts an HTTPD which outputs debugging to
the terminal.

=head2 _test.pl

A script for running tests from the command-line.

=head2 _cgi.pl

Run your application as a CGI.

=head2 _fastcgi.pl

Run the application as a fastcgi app. Either by hand, or call this
from FastCgiServer in your http server config.

=head1 HELPERS

The L</_create.pl> script creates application components using Helper
modules. The Catalyst team provides a good number of Helper modules
for you to use. You can also add your own.

Helpers are classes that provide two methods.

    * mk_compclass - creates the Component class
    * mk_comptest  - creates the Component test

So when you call C<scripts/myapp_create.pl view MyView TT>, create
will try to execute Catalyst::Helper::View::TT->mk_compclass and
Catalyst::Helper::View::TT->mk_comptest.

See L<Catalyst::Helper::View::TT> and
L<Catalyst::Helper::Model::DBIC::Schema> for examples.

All helper classes should be under one of the following namespaces.

    Catalyst::Helper::Model::
    Catalyst::Helper::View::
    Catalyst::Helper::Controller::

=head2 COMMON HELPERS

=over

=item *

L<Catalyst::Helper::Model::DBIC::Schema> - DBIx::Class models

=item *

L<Catalyst::Helper::View::TT> - Template Toolkit view

=item *

L<Catalyst::Helper::Model::LDAP>

=item *

L<Catalyst::Helper::Model::Adaptor> - wrap any class into a Catalyst model

=back

=head3 NOTE

The helpers will read author name from /etc/passwd by default. + To override, please export the AUTHOR variable.

=head1 METHODS

=head2 mk_compclass

This method in your Helper module is called with C<$helper>
which is a L<Engage::Helper> object, and whichever other arguments
the user added to the command-line. You can use the $helper to call methods
described below.

If the Helper module does not contain a C<mk_compclass> method, it
will fall back to calling L</render_file>, with an argument of
C<compclass>.

=head2 mk_comptest

This method in your Helper module is called with C<$helper>
which is a L<Engage::Helper> object, and whichever other arguments
the user added to the command-line. You can use the $helper to call methods
described below.

If the Helper module does not contain a C<mk_compclass> method, it
will fall back to calling L</render_file>, with an argument of
C<comptest>.

=head2 mk_stuff

This method is called if the user does not supply any of the usual
component types C<view>, C<controller>, C<model>. It is passed the
C<$helper> object (an instance of L<Engage::Helper>), and any other
arguments the user typed.

There is no fallback for this method.

=head1 INTERNAL METHODS

These are the methods that the Helper classes can call on the
<$helper> object passed to them.

=head2 render_file ($file, $path, $vars)

Render and create a file from a template in DATA using Template
Toolkit. $file is the relevent chunk of the __DATA__ section, $path is
the path to the file and $vars is the hashref as expected by
L<Template Toolkit|Template>.

=head2 get_file ($class, $file)

Fetch file contents from the DATA section. This is used internally by
L</render_file>.  $class is the name of the class to get the DATA
section from.  __PACKAGE__ or ( caller(0) )[0] might be sensible
values for this.

=head2 mk_app

Create the main application skeleton. This is called by L<catalyst.pl>.

=head2 mk_component ($app)

This method is called by L<create.pl> to make new components
for your application.

=head3 mk_dir ($path)

Surprisingly, this function makes a directory.

=head2 mk_file ($file, $content)

Writes content to a file. Called by L</render_file>.

=head2 next_test ($test_name)

Calculates the name of the next numbered test file and returns it.
Don't give the number or the .t suffix for the test name.

=head1 NOTE

The helpers will read author name from /etc/passwd by default.
To override, please export the AUTHOR variable.

=head1 SEE ALSO

L<Catalyst::Manual>, L<Catalyst::Test>, L<Catalyst::Request>,
L<Catalyst::Response>, L<Catalyst>

=head1 AUTHORS

Craftworks, C<< <craftwork at cpan org> >>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=begin pod_to_ignore

=cut

sub get_file {
    my ( $self, $class, $file ) = @_;
    unless ( $cache{$class} ) {
        local $/;
        $cache{$class} = eval "package $class; <DATA>";
    }
    my $data = $cache{$class};
    my @files = split /^__(.+)__\r?\n/m, $data;
    shift @files;
    while (@files) {
        my ( $name, $content ) = splice @files, 0, 2;
        return $content if $name eq $file;
    }
    return 0;
}

sub mk_app {
    my ( $self, $name ) = @_;

    # Needs to be here for PAR
    require Catalyst;

    if ( $name =~ /[^\w:]/ || $name =~ /^\d/ || $name =~ /\b:\b|:{3,}/) {
        warn "Error: Invalid application name.\n";
        return 0;
    }
    $self->{name            } = $name;
    $self->{dir             } = $name;
    $self->{dir             } =~ s/\:\:/-/g;
    $self->{script          } = File::Spec->catdir( $self->{dir}, 'script' );
    $self->{appprefix       } = Catalyst::Utils::appprefix($name);
    $self->{appenv          } = Catalyst::Utils::class2env($name);
    $self->{startperl       } = -r '/usr/bin/env'
                                ? '#!/usr/bin/env perl'
                                : "#!$Config{perlpath} -w";
    $self->{scriptgen       } = $Catalyst::Devel::CATALYST_SCRIPT_GEN || 4;
    $self->{catalyst_version} = $Catalyst::VERSION;
    $self->{author          } = $self->{author} = $ENV{'AUTHOR'}
      || eval { @{ [ getpwuid($<) ] }[6] }
      || 'Engage developer';

    my $gen_scripts  = ( $self->{makefile} ) ? 0 : 1;
    my $gen_makefile = ( $self->{scripts} )  ? 0 : 1;
    my $gen_app = ( $self->{scripts} || $self->{makefile} ) ? 0 : 1;

    if ($gen_app) {
        $self->_mk_dirs;
        $self->_mk_config;
        $self->_mk_appclass;
        $self->_mk_rootclass;
        $self->_mk_class_fcgi;
        $self->_mk_class_cli;
        $self->_mk_class_cli_command;
        $self->_mk_class_job;
        $self->_mk_class_dod;
        $self->_mk_class_dao;
        $self->_mk_class_api;
        $self->_mk_readme;
        $self->_mk_changes;
        $self->_mk_apptest;
#       $self->_mk_images;
#       $self->_mk_favicon;
    }
    if ($gen_makefile) {
        $self->_mk_makefile;
    }
    if ($gen_scripts) {
#       $self->_mk_cgi;
#       $self->_mk_fastcgi;
        $self->_mk_server;
#       $self->_mk_test;
        $self->_mk_create;
        $self->_mk_fcgi;
        $self->_mk_cli;
        $self->_mk_job;
        $self->_mk_information;
    }
    return $self->{dir};
}

sub mk_component {
    my $self = shift;
    my $app  = shift;
    $self->{app} = $app;
    $self->{author} = $self->{author} = $ENV{'AUTHOR'}
      || eval { @{ [ getpwuid($<) ] }[6] }
      || 'A clever guy';
    $self->{base} ||= File::Spec->catdir( $FindBin::Bin, '..' );
    if ( $_[0] =~ /^(?:dod|dao|api)$/i ) {
        my $type   = uc shift;
        my $name   = shift || "Missing name for DOD/DAO/API";
        my $helper = shift;
        my @args   = @_;
        $self->{long_type} = $type;
        my $appdir = File::Spec->catdir( split /\:\:/, $app );
        my $test_path =
          File::Spec->catdir( $FindBin::Bin, '..', 'lib', $appdir, $type );
        $self->{type}  = $type;
        $self->{name}  = $name;
        $self->{class} = "$app\::$type\::$name";

        # Class
        my $path =
          File::Spec->catdir( $FindBin::Bin, '..', 'lib', $appdir, $type );
        my $file = $name;
        if ( $name =~ /\:/ ) {
            my @path = split /\:\:/, $name;
            $file = pop @path;
            $path = File::Spec->catdir( $path, @path );
        }
        $self->mk_dir($path);
        $file = File::Spec->catfile( $path, "$file.pm" );
        $self->{file} = $file;

        # Test
        $self->{test_dir} = File::Spec->catdir( $FindBin::Bin, '..', 't' );
        $self->{test}     = $self->next_test;

        # Helper
        if ($helper) {
            my $comp  = $self->{long_type};
            my $class = "Engage::Helper::$comp\::$helper";
            eval "require $class";

            if ($@) {
                Catalyst::Exception->throw(
                    message => qq/Couldn't load helper "$class", "$@"/ );
            }

            if ( $class->can('mk_compclass') ) {
                return 1 unless $class->mk_compclass( $self, @args );
            }
            else { return 1 unless $self->_mk_compclass }

            if ( $class->can('mk_comptest') ) {
                $class->mk_comptest( $self, @args );
            }
            else { $self->_mk_comptest }
        }
        # Fallback
        else {
            return 1 unless $self->_mk_compclass;
            $self->_mk_comptest;
        }
    }
    elsif ( $_[0] !~ /^(?:model|view|controller)$/i ) {
        my $helper = shift;
        my @args   = @_;
        my $class  = "Engage::Helper::$helper";
        eval "require $class";

        if ($@) {
            $class =~ s/^Engage/Catalyst/;
            eval "require $class";
        }

        if ($@) {
            Catalyst::Exception->throw(
                message => qq/Couldn't load helper "$class", "$@"/ );
        }

        if ( $class->can('mk_stuff') ) {
            return 1 unless $class->mk_stuff( $self, @args );
        }
    }
    else {
        my $type   = shift;
        my $site   = shift;
        my $name   = shift || "Missing name for model/view/controller";
        my $helper = shift;
        my @args   = @_;
       return 0 if $name =~ /[^\w\:]/;
        $site              = ucfirst $site;
        $type              = lc $type;
        $self->{long_type} = ucfirst $type;
        $type              = 'M' if $type =~ /model/i;
        $type              = 'V' if $type =~ /view/i;
        $type              = 'C' if $type =~ /controller/i;
        my $appdir = File::Spec->catdir( split /\:\:/, $app );
        my $test_path =
          File::Spec->catdir( $FindBin::Bin, '..', 'lib', $appdir, 'WUI', $site, 'C' );
        $type = $self->{long_type} unless -d $test_path;
        $self->{type}  = $type;
        $self->{site}  = $site;
        $self->{name}  = $name;
        $self->{class} = "$app\::WUI::$site\::$type\::$name";

        # Class
        my $path =
          File::Spec->catdir( $FindBin::Bin, '..', 'lib', $appdir, 'WUI', $site, $type );
        my $file = $name;
        if ( $name =~ /\:/ ) {
            my @path = split /\:\:/, $name;
            $file = pop @path;
            $path = File::Spec->catdir( $path, @path );
        }
        $self->mk_dir($path);
        $file = File::Spec->catfile( $path, "$file.pm" );
        $self->{file} = $file;

        # Test
        $self->{test_dir} = File::Spec->catdir( $FindBin::Bin, '..', 't' );
        $self->{test}     = $self->next_test;

        # Helper
        if ($helper) {
            my $comp  = $self->{long_type};
            my $class = "Engage::Helper::$comp\::$helper";
            eval "require $class";

            if ($@) {
                Catalyst::Exception->throw(
                    message => qq/Couldn't load helper "$class", "$@"/ );
            }

            if ( $class->can('mk_compclass') ) {
                return 1 unless $class->mk_compclass( $self, @args );
            }
            else { return 1 unless $self->_mk_compclass }

            if ( $class->can('mk_comptest') ) {
                $class->mk_comptest( $self, @args );
            }
            else { $self->_mk_comptest }
        }

        # Fallback
        else {
            return 1 unless $self->_mk_compclass;
            $self->_mk_comptest;
        }
    }
    return 1;
}

sub mk_dir {
    my ( $self, $dir ) = @_;
    if ( -d $dir ) {
        print qq/ exists "$dir"\n/;
        return 0;
    }
    if ( mkpath [$dir] ) {
        print qq/created "$dir"\n/;
        return 1;
    }

    Catalyst::Exception->throw( message => qq/Couldn't create "$dir", "$!"/ );
}

sub mk_file {
    my ( $self, $file, $content ) = @_;
    if ( -e $file ) {
        print qq/ exists "$file"\n/;
        return 0
          unless ( $self->{'.newfiles'}
            || $self->{scripts}
            || $self->{makefile} );
        if ( $self->{'.newfiles'} ) {
            if ( my $f = IO::File->new("< $file") ) {
                my $oldcontent = join( '', (<$f>) );
                return 0 if $content eq $oldcontent;
            }
            $file .= '.new';
        }
    }
    if ( my $f = IO::File->new("> $file") ) {
        binmode $f;
        print $f $content;
        print qq/created "$file"\n/;
        return 1;
    }

    Catalyst::Exception->throw( message => qq/Couldn't create "$file", "$!"/ );
}

sub next_test {
    my ( $self, $tname ) = @_;
    if ($tname) { $tname = "$tname.t" }
    else {
        my $name   = $self->{name};
        my $prefix = $name;
        $prefix =~ s/::/-/g;
        $prefix         = $prefix;
        $tname          = $prefix . '.t';
        $self->{prefix} = $prefix;
        $prefix         = lc $prefix;
        $prefix =~ s/-/\//g;
        $self->{uri} = "/$prefix";
    }
    my $dir  = $self->{test_dir};
    my $site = $self->{site} || '';
    my $type = lc $self->{type};
    $site .= '_' if $site;
    $self->mk_dir($dir);
    return File::Spec->catfile( $dir, "$type\_${site}$tname" );
}

sub render_file {
    my ( $self, $file, $path, $vars ) = @_;
    $vars ||= {};
    my $t = Template->new;
    my $template = $self->get_file( ( caller(0) )[0], $file );
    return 0 unless $template;
    my $output;
    $t->process( \$template, { %{$self}, %$vars }, \$output )
      || Catalyst::Exception->throw(
        message => qq/Couldn't process "$file", / . $t->error() );
    $self->mk_file( $path, $output );
}

sub _mk_information {
    my $self = shift;
    print qq/Change to application directory and Run "perl Makefile.PL" to make sure your install is complete\n/;
}

sub _mk_dirs {
    my $self = shift;
    $self->mk_dir( $self->{dir} );
    $self->mk_dir( $self->{script} );
    $self->{lib} = File::Spec->catdir( $self->{dir}, 'lib' );
    $self->mk_dir( $self->{lib} );
    $self->{conf} = File::Spec->catdir( $self->{dir}, 'conf' );
    $self->mk_dir( $self->{conf} );
    $self->{template} = File::Spec->catdir( $self->{dir}, 'template' );
    $self->mk_dir( $self->{template} );
    $self->{template_p} = File::Spec->catdir( $self->{template}, 'Service', 'p' );
    $self->mk_dir( $self->{template_p} );
    $self->{template_m} = File::Spec->catdir( $self->{template}, 'Service', 'm' );
    $self->mk_dir( $self->{template_m} );
    $self->{static} = File::Spec->catdir( $self->{dir}, 'static' );
    $self->mk_dir( $self->{static} );
    $self->{image} = File::Spec->catdir( $self->{static}, 'image' );
    $self->mk_dir( $self->{image} );
    $self->{css} = File::Spec->catdir( $self->{static}, 'css' );
    $self->mk_dir( $self->{css} );
    $self->{js} = File::Spec->catdir( $self->{static}, 'js' );
    $self->mk_dir( $self->{js} );
#   $self->{daemon} = File::Spec->catdir( $self->{dir}, 'daemon' );
#   $self->mk_dir( $self->{daemon} );
#   $self->{fcgi_service} = File::Spec->catdir( $self->{daemon}, 'fcgi_service' );
#   $self->mk_dir( $self->{fcgi_service} );
#   $self->mk_dir( File::Spec->catdir( $self->{fcgi_service}, 'log' ) );
#   $self->{fcgi_admin} = File::Spec->catdir( $self->{daemon}, 'fcgi_admin' );
#   $self->mk_dir( $self->{fcgi_admin} );
#   $self->mk_dir( File::Spec->catdir( $self->{fcgi_admin}, 'log' ) );
    $self->{t} = File::Spec->catdir( $self->{dir}, 't' );
    $self->mk_dir( $self->{t} );

    $self->{class} = File::Spec->catdir( split( /\:\:/, $self->{name} ) );
    $self->{mod} = File::Spec->catdir( $self->{lib}, $self->{class} );

    $self->{wui} = File::Spec->catdir( $self->{mod}, 'WUI' );

    $self->{catalyst} = File::Spec->catdir( $self->{wui}, 'Service' );
    $self->mk_dir( $self->{catalyst} );

    if ( $self->{short} ) {
        $self->{m} = File::Spec->catdir( $self->{catalyst}, 'M' );
        $self->mk_dir( $self->{m} );
        $self->{v} = File::Spec->catdir( $self->{catalyst}, 'V' );
        $self->mk_dir( $self->{v} );
        $self->{c} = File::Spec->catdir( $self->{catalyst}, 'C' );
        $self->mk_dir( $self->{c} );
    }
    else {
        $self->{m} = File::Spec->catdir( $self->{catalyst}, 'Model' );
        $self->mk_dir( $self->{m} );
        $self->{v} = File::Spec->catdir( $self->{catalyst}, 'View' );
        $self->mk_dir( $self->{v} );
        $self->{c} = File::Spec->catdir( $self->{catalyst}, 'Controller' );
        $self->mk_dir( $self->{c} );
    }

    $self->{dod} = File::Spec->catdir( $self->{mod}, 'DOD' );
    $self->mk_dir( $self->{dod} );
    $self->{dao} = File::Spec->catdir( $self->{mod}, 'DAO' );
    $self->mk_dir( $self->{dao} );
    $self->{api} = File::Spec->catdir( $self->{mod}, 'API' );
    $self->mk_dir( $self->{api} );
    $self->{job} = File::Spec->catdir( $self->{mod}, 'Job' );
    $self->mk_dir( $self->{job} );
    $self->{cli} = File::Spec->catdir( $self->{mod}, 'CLI' );
    $self->mk_dir( $self->{cli} );
    $self->{command} = File::Spec->catdir( $self->{cli}, 'Command' );
    $self->mk_dir( $self->{command} );

    my $name = $self->{name};
    $self->{rootname} =
      $self->{short} ? "$name\::WUI::Service::C::Root" : "$name\::WUI::Service::Controller::Root";
    $self->{base} = File::Spec->rel2abs( $self->{dir} );
}

sub _mk_makefile {
    my $self = shift;
    $self->{path} = File::Spec->catfile( 'lib', split( '::', $self->{name} ) );
    $self->{path} .= '.pm';
    my $dir = $self->{dir};
    $self->render_file( 'makefile', "$dir\/Makefile.PL" );

    if ( $self->{makefile} ) {

        # deprecate the old Build.PL file when regenerating Makefile.PL
        $self->_deprecate_file(
            File::Spec->catdir( $self->{dir}, 'Build.PL' ) );
    }
}

sub _mk_config {
    my $self      = shift;
    my $dir       = $self->{conf};
    my $appprefix = $self->{appprefix};
    $self->render_file( 'config',
        File::Spec->catfile( $dir, "fcgi.$appprefix.yml" ) );
}

sub _mk_appclass {
    my $self = shift;
    my $appsite = $self->{appsite} = 'Service';
    my $name = $self->{name};
    my $mod = File::Spec->catdir( $self->{wui}, $appsite );
    $self->render_file( 'appclass', "$mod.pm" );
}

sub _mk_rootclass {
    my $self = shift;
    $self->render_file( 'rootclass',
        File::Spec->catfile( $self->{c}, "Root.pm" ) );
}

sub _mk_class_fcgi {
    my $self = shift;
    $self->render_file( 'class_fcgi',
        File::Spec->catfile( $self->{mod}, "FCGI.pm" ) );
}

sub _mk_class_dod {
    my $self = shift;
    my $dod  = $self->{dod};
    $self->render_file( 'class_dod', "$dod.pm" );
}

sub _mk_class_dao {
    my $self = shift;
    my $dao  = $self->{dao};
    $self->render_file( 'class_dao', "$dao.pm" );
}

sub _mk_class_api {
    my $self = shift;
    my $api  = $self->{api};
    $self->render_file( 'class_api', "$api.pm" );
}

sub _mk_class_cli {
    my $self = shift;
    my $cli  = $self->{cli};
    $self->render_file( 'class_cli', "$cli.pm" );
}

sub _mk_class_cli_command {
    my $self = shift;
    my $command  = $self->{command};
    $self->render_file( 'class_cli_command', "$command.pm" );
}

sub _mk_class_job {
    my $self = shift;
    my $job  = $self->{job};
    $self->render_file( 'class_job', "$job.pm" );
}

sub _mk_readme {
    my $self = shift;
    my $dir  = $self->{dir};
    $self->render_file( 'readme', "$dir\/README" );
}

sub _mk_changes {
    my $self = shift;
    my $dir  = $self->{dir};
    my $time = strftime('%Y-%m-%d %H:%M:%S', localtime time);
    $self->render_file( 'changes', "$dir\/Changes", { time => $time } );
}

sub _mk_apptest {
    my $self = shift;
    my $t    = $self->{t};
    $self->render_file( 'apptest',         "$t\/01app.t" );
    $self->render_file( 'podtest',         "$t\/02pod.t" );
    $self->render_file( 'podcoveragetest', "$t\/03podcoverage.t" );
}

sub _mk_cgi {
    my $self      = shift;
    my $script    = $self->{script};
    my $appprefix = $self->{appprefix};
    $self->render_file( 'cgi', "$script\/$appprefix\_cgi.pl" );
    chmod 0700, "$script/$appprefix\_cgi.pl";
}

sub _mk_fastcgi {
    my $self      = shift;
    my $script    = $self->{script};
    my $appprefix = $self->{appprefix};
    $self->render_file( 'fastcgi', "$script\/$appprefix\_fastcgi.pl" );
    chmod 0700, "$script/$appprefix\_fastcgi.pl";
}

sub _mk_server {
    my $self      = shift;
    my $script    = $self->{script};
    my $appprefix = $self->{appprefix};
    $self->render_file( 'server', "$script\/$appprefix\_server.pl" );
    chmod 0700, "$script/$appprefix\_server.pl";
}

sub _mk_fcgi {
    my $self      = shift;
    my $script    = $self->{script};
    my $appprefix = $self->{appprefix};
    $self->render_file( 'fcgi', "$script\/$appprefix\_fcgi.pl" );
    chmod 0700, "$script/$appprefix\_fcgi.pl";
}

sub _mk_cli {
    my $self      = shift;
    my $script    = $self->{script};
    my $appprefix = $self->{appprefix};
    $self->render_file( 'cli', "$script\/$appprefix\_cli.pl" );
    chmod 0700, "$script/$appprefix\_cli.pl";
}

sub _mk_job {
    my $self      = shift;
    my $script    = $self->{script};
    my $appprefix = $self->{appprefix};
    $self->render_file( 'job', "$script\/$appprefix\_job.pl" );
    chmod 0700, "$script/$appprefix\_job.pl";
}

sub _mk_test {
    my $self      = shift;
    my $script    = $self->{script};
    my $appprefix = $self->{appprefix};
    $self->render_file( 'test', "$script/$appprefix\_test.pl" );
    chmod 0700, "$script/$appprefix\_test.pl";
}

sub _mk_create {
    my $self      = shift;
    my $script    = $self->{script};
    my $appprefix = $self->{appprefix};
    $self->render_file( 'create', "$script\/$appprefix\_create.pl" );
    chmod 0700, "$script/$appprefix\_create.pl";
}

sub _mk_compclass {
    my $self = shift;
    my $file = $self->{file};
    $self->{framework} = $self->{type} =~ /DOD|DAO|API/ ? 'Engage' : 'Catalyst';
    $self->{is_engage} = $self->{framework} eq 'Engage';
    return $self->render_file( 'compclass', "$file" );
}

sub _mk_comptest {
    my $self = shift;
    my $test = $self->{test};
    $self->render_file( 'comptest', "$test" );
}

1;
__DATA__
__appclass__
package [% name %]::WUI::[% appsite %];

use strict;
use warnings;

use Catalyst::Runtime 5.80;

# Set flags and add plugins for the application
#
#         -Debug: activates the debug mode for very useful log messages
#   ConfigLoader: will load the configuration from a Config::General file in the
#                 application's home directory
# Static::Simple: will serve static files from the application's root
#                 directory

use parent qw/Catalyst/;
use Catalyst qw/-Debug
                ConfigLoader
                Static::Simple/;
our $VERSION = '0.01';

# Configure the application.
#
# Note that settings in [% appprefix %].conf (or other external
# configuration file that you set up manually) take precedence
# over this when using ConfigLoader. Thus configuration
# details given here can function as a default configuration,
# with an external configuration file acting as an override for
# local deployment.

__PACKAGE__->config( name => '[% name %]::WUI::[% appsite %]' );

# Start the application
__PACKAGE__->setup();


=head1 NAME

[% name %] - Catalyst based application

=head1 SYNOPSIS

    script/[% appprefix %]_server.pl

=head1 DESCRIPTION

[enter your description here]

=head1 SEE ALSO

L<[% rootname %]>, L<Catalyst>

=head1 AUTHOR

[% author %]

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
__rootclass__
package [% rootname %];

use strict;
use warnings;
use parent 'Catalyst::Controller';

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config->{namespace} = '';

=head1 NAME

[% rootname %] - Root Controller for [% name %]

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=cut

=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    # Hello World
    $c->response->body( $c->welcome_message );
}

sub default :Path {
    my ( $self, $c ) = @_;
    $c->response->body( 'Page not found' );
    $c->response->status(404);
}

=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') {}

=head1 AUTHOR

[% author %]

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
__class_fcgi__
package [% name %]::FCGI;

use Moose;
extends 'Engage::FCGI';

__PACKAGE__->meta->make_immutable;

1;
__class_dod__
package [% name %]::DOD;

use Moose;
extends 'Engage::DOD';

__PACKAGE__->meta->make_immutable;

1;
__class_dao__
package [% name %]::DAO;

use Moose;
extends 'Engage::DAO';

__PACKAGE__->meta->make_immutable;

1;
__class_api__
package [% name %]::API;

use Moose;
extends 'Engage::API';

__PACKAGE__->meta->make_immutable;

1;
__class_cli__
package [% name %]::CLI;

use Moose;
extends 'Engage::CLI';

__PACKAGE__->meta->make_immutable;

1;
__class_cli_command__
package [% name %]::CLI::Command;

use Moose;
extends 'Engage::CLI::Command';

__PACKAGE__->meta->make_immutable;

1;
__class_job__
package [% name %]::Job;

use Moose;
extends 'Engage::Job';

__PACKAGE__->meta->make_immutable;

1;
__makefile__
[% startperl %]
# IMPORTANT: if you delete this file your app will not work as
# expected.  You have been warned.
use inc::Module::Install;

name '[% dir %]';
all_from '[% path %]';

requires 'Moose';
requires 'MooseX::Types::Path::Class';
requires 'MooseX::LogDispatch';
requires 'MooseX::App::Cmd';
requires 'Catalyst::Runtime' => '[% catalyst_version %]';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'Catalyst::Plugin::Static::Simple';
requires 'Catalyst::Action::RenderView';
requires 'FCGI';
requires 'FCGI::ProcManager';
requires 'parent';
requires 'Config::General'; # This should reflect the config file format you've chosen
                 # See Catalyst::Plugin::ConfigLoader for supported formats
catalyst;

install_script glob('script/*.pl');
auto_install;
WriteAll;
__config__
FCGI:
  Service:
    -
      host: ^product\d{3}
      listen: '/tmp/.s.fcgi.service'
      nproc: 5
      pidfile: pid
      keep_stderr: 1
      env:
        [% appenv %]_DEBUG: 0
        DBIC_TRACE: 1
    -
      listen: '/tmp/.s.fcgi.service'
      nproc: 1
      pidfile: pid
      keep_stderr: 1
      env:
        [% appenv %]_DEBUG: 1
        DBIC_TRACE: 1

__readme__
Run script/[% appprefix %]_server.pl to test the application.
__changes__
This file documents the revision history for Perl extension [% name %].

0.01  [% time %]
        - initial revision, generated by Engage
__apptest__
[% startperl %]
use strict;
use warnings;
use Test::More tests => 2;

BEGIN { use_ok 'Catalyst::Test', '[% name %]' }

ok( request('/')->is_success, 'Request should succeed' );
__podtest__
[% startperl %]
use strict;
use warnings;
use Test::More;

eval "use Test::Pod 1.14";
plan skip_all => 'Test::Pod 1.14 required' if $@;
plan skip_all => 'set TEST_POD to enable this test' unless $ENV{TEST_POD};

all_pod_files_ok();
__podcoveragetest__
[% startperl %]
use strict;
use warnings;
use Test::More;

eval "use Test::Pod::Coverage 1.04";
plan skip_all => 'Test::Pod::Coverage 1.04 required' if $@;
plan skip_all => 'set TEST_POD to enable this test' unless $ENV{TEST_POD};

all_pod_coverage_ok();
__cgi__
[% startperl %]

BEGIN { $ENV{CATALYST_ENGINE} ||= 'CGI' }

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use [% name %];

[% name %]->run;

1;

=head1 NAME

[% appprefix %]_cgi.pl - Catalyst CGI

=head1 SYNOPSIS

See L<Catalyst::Manual>

=head1 DESCRIPTION

Run a Catalyst application as a cgi script.

=head1 AUTHORS

Catalyst Contributors, see Catalyst.pm

=head1 COPYRIGHT


This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
__fastcgi__
[% startperl %]

BEGIN { $ENV{CATALYST_ENGINE} ||= 'FastCGI' }

use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;
use FindBin;
use lib "$FindBin::Bin/../lib";
use [% name %];

my $help = 0;
my ( $listen, $nproc, $pidfile, $manager, $detach, $keep_stderr );

GetOptions(
    'help|?'      => \$help,
    'listen|l=s'  => \$listen,
    'nproc|n=i'   => \$nproc,
    'pidfile|p=s' => \$pidfile,
    'manager|M=s' => \$manager,
    'daemon|d'    => \$detach,
    'keeperr|e'   => \$keep_stderr,
);

pod2usage(1) if $help;

[% name %]->run(
    $listen,
    {   nproc   => $nproc,
        pidfile => $pidfile,
        manager => $manager,
        detach  => $detach,
        keep_stderr => $keep_stderr,
    }
);

1;

=head1 NAME

[% appprefix %]_fastcgi.pl - Catalyst FastCGI

=head1 SYNOPSIS

[% appprefix %]_fastcgi.pl [options]

 Options:
   -? -help      display this help and exits
   -l -listen    Socket path to listen on
                 (defaults to standard input)
                 can be HOST:PORT, :PORT or a
                 filesystem path
   -n -nproc     specify number of processes to keep
                 to serve requests (defaults to 1,
                 requires -listen)
   -p -pidfile   specify filename for pid file
                 (requires -listen)
   -d -daemon    daemonize (requires -listen)
   -M -manager   specify alternate process manager
                 (FCGI::ProcManager sub-class)
                 or empty string to disable
   -e -keeperr   send error messages to STDOUT, not
                 to the webserver

=head1 DESCRIPTION

Run a Catalyst application as fastcgi.

=head1 AUTHORS

Catalyst Contributors, see Catalyst.pm

=head1 COPYRIGHT

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
__server__
[% startperl %]

BEGIN {
    $ENV{CATALYST_ENGINE} ||= 'HTTP';
    $ENV{CATALYST_SCRIPT_GEN} = [% scriptgen %];
    require Catalyst::Engine::HTTP;
}

use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;
use FindBin;
use lib "$FindBin::Bin/../lib";

my $debug             = 0;
my $fork              = 0;
my $help              = 0;
my $host              = undef;
my $port              = $ENV{[% appenv %]_PORT} || $ENV{CATALYST_PORT} || 3000;
my $keepalive         = 0;
my $restart           = $ENV{[% appenv %]_RELOAD} || $ENV{CATALYST_RELOAD} || 0;
my $background        = 0;
my $pidfile           = undef;
my $site              = 'Service';

my $check_interval;
my $file_regex;
my $watch_directory;
my $follow_symlinks;

my @argv = @ARGV;

GetOptions(
    'debug|d'             => \$debug,
    'fork|f'              => \$fork,
    'help|?'              => \$help,
    'host=s'              => \$host,
    'port|p=s'            => \$port,
    'keepalive|k'         => \$keepalive,
    'restart|r'           => \$restart,
    'restartdelay|rd=s'   => \$check_interval,
    'restartregex|rr=s'   => \$file_regex,
    'restartdirectory=s@' => \$watch_directory,
    'followsymlinks'      => \$follow_symlinks,
    'background'          => \$background,
    'pidfile=s'           => \$pidfile,
    'site|s=s'            => \$site
);

pod2usage(1) if $help;

if ( $debug ) {
    $ENV{CATALYST_DEBUG} = 1;
}

# If we load this here, then in the case of a restarter, it does not
# need to be reloaded for each restart.
require Catalyst;

# If this isn't done, then the Catalyst::Devel tests for the restarter
# fail.
$| = 1 if $ENV{HARNESS_ACTIVE};

my $runner = sub {
    my $class = "[% name %]::WUI::$site";
    # This is require instead of use so that the above environment
    # variables can be set at runtime.
    eval "require $class";

    $class->run(
        $port, $host,
        {
            argv       => \@argv,
            'fork'     => $fork,
            keepalive  => $keepalive,
            background => $background,
            pidfile    => $pidfile,
        }
    );
};

if ( $restart ) {
    die "Cannot run in the background and also watch for changed files.\n"
        if $background;

    require Catalyst::Restarter;

    my $subclass = Catalyst::Restarter->pick_subclass;

    my %args;
    $args{follow_symlinks} = 1
        if $follow_symlinks;
    $args{directories} = $watch_directory
        if defined $watch_directory;
    $args{sleep_interval} = $check_interval
        if defined $check_interval;
    $args{filter} = qr/$file_regex/
        if defined $file_regex;

    my $restarter = $subclass->new(
        %args,
        start_sub => $runner,
        argv      => \@argv,
    );

    $restarter->run_and_watch;
}
else {
    $runner->();
}

1;

=head1 NAME

[% appprefix %]_server.pl - Catalyst Testserver

=head1 SYNOPSIS

[% appprefix %]_server.pl [options]

 Options:
   -d -debug          force debug mode
   -f -fork           handle each request in a new process
                      (defaults to false)
   -? -help           display this help and exits
      -host           host (defaults to all)
   -p -port           port (defaults to 3000)
   -k -keepalive      enable keep-alive connections
   -r -restart        restart when files get modified
                      (defaults to false)
   -rd -restartdelay  delay between file checks
                      (ignored if you have Linux::Inotify2 installed)
   -rr -restartregex  regex match files that trigger
                      a restart when modified
                      (defaults to '\.yml$|\.yaml$|\.conf|\.pm$')
   -restartdirectory  the directory to search for
                      modified files, can be set mulitple times
                      (defaults to '[SCRIPT_DIR]/..')
   -follow_symlinks   follow symlinks in search directories
                      (defaults to false. this is a no-op on Win32)
   -background        run the process in the background
   -pidfile           specify filename for pid file

 See also:
   perldoc Catalyst::Manual
   perldoc Catalyst::Manual::Intro

=head1 DESCRIPTION

Run a Catalyst Testserver for this application.

=head1 AUTHORS

Catalyst Contributors, see Catalyst.pm

=head1 COPYRIGHT

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
__fcgi__
[% startperl %]

use FindBin;
use lib "$FindBin::Bin/../lib";
use [% name %]::FCGI;

[% name %]::FCGI->new( site => shift )->run;

__cli__
[% startperl %]

use FindBin;
use lib "$FindBin::Bin/../lib";
use [% name %]::CLI -run;

__job__
[% startperl %]

use FindBin;
use lib "$FindBin::Bin/../lib";
use [% name %]::Job;

[% name %]::Job->new->run;

__test__
[% startperl %]

use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Catalyst::Test '[% name %]';

my $help = 0;

GetOptions( 'help|?' => \$help );

pod2usage(1) if ( $help || !$ARGV[0] );

print request($ARGV[0])->content . "\n";

1;

=head1 NAME

[% appprefix %]_test.pl - Catalyst Test

=head1 SYNOPSIS

[% appprefix %]_test.pl [options] uri

 Options:
   -help    display this help and exits

 Examples:
   [% appprefix %]_test.pl http://localhost/some_action
   [% appprefix %]_test.pl /some_action

 See also:
   perldoc Catalyst::Manual
   perldoc Catalyst::Manual::Intro

=head1 DESCRIPTION

Run a Catalyst action from the command line.

=head1 AUTHORS

Catalyst Contributors, see Catalyst.pm

=head1 COPYRIGHT

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
__create__
[% startperl %]

use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;
eval "use Engage::Helper;";

if ($@) {
  die <<END;
To use the Catalyst development tools including catalyst.pl and the
generated script/myapp_create.pl you need Catalyst::Helper, which is
part of the Catalyst-Devel distribution. Please install this via a
vendor package or by running one of -

  perl -MCPAN -e 'install Catalyst::Devel'
  perl -MCPANPLUS -e 'install Catalyst::Devel'
END
}

my $force = 0;
my $mech  = 0;
my $help  = 0;

GetOptions(
    'nonew|force'    => \$force,
    'mech|mechanize' => \$mech,
    'help|?'         => \$help
 );

pod2usage(1) if ( $help || !$ARGV[0] );

my $helper = Engage::Helper->new( { '.newfiles' => !$force, mech => $mech } );

pod2usage(1) unless $helper->mk_component( '[% name %]', @ARGV );

1;

=head1 NAME

[% appprefix %]_create.pl - Create a new Catalyst Component

=head1 SYNOPSIS

[% appprefix %]_create.pl [options] [site] model|view|controller name [helper] [options]

 Options:
   -force        don't create a .new file where a file to be created exists
   -mechanize    use Test::WWW::Mechanize::Catalyst for tests if available
   -help         display this help and exits

 Examples:
   [% appprefix %]_create.pl controller Site My::Controller
   [% appprefix %]_create.pl -mechanize controller Site My::Controller
   [% appprefix %]_create.pl view Site My::View
   [% appprefix %]_create.pl view Site MyView TT
   [% appprefix %]_create.pl view Site TT TT
   [% appprefix %]_create.pl model Site My::Model
   [% appprefix %]_create.pl model Site SomeDB DBIC::Schema MyApp::Schema\
   create=dynamic dbi:SQLite:/tmp/my.db
   [% appprefix %]_create.pl model Site AnotherDB DBIC::Schema MyApp::Schema\
   create=static dbi:Pg:dbname=foo root 4321

 See also:
   perldoc Catalyst::Manual
   perldoc Catalyst::Manual::Intro

=head1 DESCRIPTION

Create a new Catalyst Component.

Existing component files are not overwritten.  If any of the component files
to be created already exist the file will be written with a '.new' suffix.
This behavior can be suppressed with the C<-force> option.

=head1 AUTHORS

Catalyst Contributors, see Catalyst.pm

=head1 COPYRIGHT

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
__compclass__
package [% class %];
[% IF is_engage %]
use Moose;
extends 'Engage::[% type %]';
[% ELSE %]
use strict;
use warnings;
use parent 'Catalyst::[% long_type %]';
[% END %]
=head1 NAME

[% class %] - [% framework %] [% long_type %]

=head1 DESCRIPTION

[% framework %] [% long_type %].

=head1 METHODS

=cut
[% IF long_type == 'Controller' %]
=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body('Matched [% class %] in [%name%].');
}
[% ELSIF is_engage %]
no Moose;

__PACKAGE__->meta->make_immutable;
[% END %]
=head1 AUTHOR

[%author%]

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
__comptest__
use strict;
use warnings;
[% IF long_type == 'Controller' %][% IF mech %]use Test::More;

eval "use Test::WWW::Mechanize::Catalyst '[% app %]'";
plan $@
    ? ( skip_all => 'Test::WWW::Mechanize::Catalyst required' )
    : ( tests => 2 );

ok( my $mech = Test::WWW::Mechanize::Catalyst->new, 'Created mech object' );

$mech->get_ok( 'http://localhost[% uri %]' );
[% ELSE %]use Test::More tests => 3;

BEGIN { use_ok 'Catalyst::Test', '[% app %]::WUI::[% site %]' }
BEGIN { use_ok '[% class %]' }

ok( request('[% uri %]')->is_success, 'Request should succeed' );
[% END %]
[% ELSE %]use Test::More tests => 1;

BEGIN { use_ok '[% class %]' }
[% END %]
