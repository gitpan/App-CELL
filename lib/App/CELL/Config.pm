package App::CELL::Config;

use strict;
use warnings;
use 5.10.0;

use App::CELL::Load;
use App::CELL::Log qw( $log );
use App::CELL::Status;

=head1 NAME

App::CELL::Config -- load, store, and dispense meta parameters, core
parameters, and site parameters



=head1 VERSION

Version 0.121

=cut

our $VERSION = '0.121';



=head1 SYNOPSIS
 
    use App::CELL::Config;

    # get a parameter value (returns value or undef)
    my $value = App::CELL::Config::get_param( 'meta', 'MY_PARAM' );
    my $value = App::CELL::Config::get_param( 'core', 'MY_PARAM' );
    my $value = App::CELL::Config::get_param( 'site', 'MY_PARAM' );

    # set a meta parameter
    App::CELL::Config::set_meta( 'MY_PARAM', 42 );


=head1 DESCRIPTION

The purpose of the C<App::CELL::Config> module is to maintain and provide
access to three package variables, C<$meta>, C<$core>, and C<$site>,
which are references to hashes holding the names, values, and other
information related to the configuration parameters loaded from files in
the App::CELL distro sharedir and the site configuration directory, if any.
These values are loaded by the C<App::CELL::Load> module.


=head1 PACKAGE VARIABLES

=head2 C<$meta>

Holds parameter values loaded from files with names of the format
C<[...]_MetaConfig.pm>. These "meta parameters" are by definition
changeable.

=cut

our $meta = {};


=head2 C<$core>

Holds parameter values loaded from files whose names match
C<[...]_Config.pm>. Sometimes referred to as "core parameters", these are
intended to be set by the application programmer to provide default values
for site parameters.

=cut

our $core = {};


=head2 C<$site>

Holds parameter values loaded from files of the format
C<[...]_SiteConfig.pm> -- referred to as "site parameters".
These are intended to be set by the site administrator.

=cut

our $site = {};



=head1 HOW PARAMETERS ARE INITIALIZED

Like message templates, the meta, core, and site parameters are initialized
by C<require>-ing files in the configuration directory. As described above,
files in this directory are processed according to their filenames. 

The actual directory path is determined by consulting the C<CELL_CONFIGDIR>
environment variable, the file C<.cell/CELL.conf> in the user's C<HOME>
directory, or the file C</etc/sysconfig/perl-CELL>, in that order --
whichever is found first, "wins".

CELL's configuration parameters are modelled after those of Request
Tracker. Configuration files are special Perl modules that are loaded at
run-time.  The modules should be in the C<CELL> package and should consist
of a series of calls to the C<set> function (which is provided by C<CELL>
and will not collide with your application's function of the same name).

CELL configuration files are straightforward and simple to create and
maintain, while still managing to provide power and flexibility. For
details, see the C<CELL_MetaConfig.pm> module in the CELL distribution.



=head1 PUBLIC FUNCTIONS AND METHODS


=head2 config

The C<config> method provides clients access to site
configuration parameters. A simple logic is applied: if the parameter is
defined in 'site', we're done: that is the value. If the parameter is not
defined in 'site', check 'core' and use that value, if available.

If neither 'site' nor 'core' has a definition for the parameter, undef is
returned.

=cut

sub config {
    my $param = shift;
    my $value = get_param( 'site', $param );
    return $value if defined( $value );
    $value = get_param( 'core', $param );
    return $value if defined( $value );
    return; # returns undef in scalar context
}


=head2 get_param

Basic function providing access to values of site configuration parameters
(i.e. the values stored in the C<%meta>, C<%core>, and C<%site> module
variables). Takes two arguments: type ('meta', 'core', or 'site') and
parameter name. Returns parameter value on success, undef on failure (i.e.
when parameter is not defined).

    my $value = App::CELL::Config::get_param( 'meta', 'META_MY_PARAM' );

=cut

sub get_param {
    no strict 'refs';   # valid throughout get_param
    my ( $type, $param ) = @_;

    # sanity
    if ( not defined($$type) or not ref($$type) ) {
        return; # returns undef in scalar context
    }

    # logic
    if ( exists $$type->{$param} ) {
        $log->debug( "get_param: $type param $param value ->" .  $$type->{$param}->{'Value'} . "<-" );
        return $$type->{$param}->{'Value'};
    }

    return; # returns undef in scalar context
}


=head2 set_meta

By definition, meta parameters are mutable. Use this function to set or
change them. Takes two arguments: parameter name and new value. If the
parameter didn't exist before, it will be created. Returns 'ok' status
object.

TO_DO: check value to make sure it's a scalar.

=cut

sub set_meta {
    my ( $param, $value ) = @_;
    if ( exists $meta->{$param} ) {
        App::CELL::Status->new(
            level => 'NOTICE',
            code => 'CELL_OVERWRITE_META_PARAM',
            args => [ $param, $value ],
            caller => [ caller ],
        );
    } else {
        $log->info( "Setting meta parameter $param for the first time" );
    }
    $meta->{$param} = {
           'File' => '<INTERNAL>',
           'Line' => 0,
           'Value' => $value,
    };
    return App::CELL::Status->ok;
}


=head2 set_core

Sets core parameter, provided it doesn't already exist. Wrapper.

=cut

sub set_core {
    my ( $param, $value ) = @_;
    return _set_core_site( 'core', $param, $value );
}


=head2 set_site

Sets site parameter, provided it doesn't already exist. Wrapper.

=cut

sub set_site {
    my ( $param, $value ) = @_;
    return _set_core_site( 'site', $param, $value );
}


=head3 _set_core_site

Core and site parameters are immutable. This function can be used to set
them, provided they don't already exist. Takes three arguments: param type,
param name and new value. If the parameter didn't exist before, it will be
created.  Returns 'ok' status object on success, or error object on
failure.

=cut

sub _set_core_site {
    no strict 'refs';   # valid throughout the subroutine
    my ( $type, $param, $value ) = @_;
    #if ( $type eq "core" and exists $core->{$param} ) {
    if ( exists $$type->{$param} ) {
        return App::CELL::Status->new( level => 'ERR', 
            code => 'CELL_CORE_PARAM_EXISTS_IMMUTABLE',
            args => [ $param ],
        );
    } else {
        $log->info( "Setting $type parameter $param" );
        $$type->{$param} = {
           'File' => '<INTERNAL>',
           'Line' => 0,
           'Value' => $value,
        };
        return App::CELL::Status->ok;
    }
}

# END OF App::CELL::Config MODULE
1;
