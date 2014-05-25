package App::CELL;

use strict;
use warnings;
use 5.10.0;

use Carp;
use App::CELL::Config;
use App::CELL::Status;
use App::CELL::Log qw( $log );
use App::CELL::Util qw( utc_timestamp );


=head1 NAME

App::CELL - Configuration, Error-handling, Localization, and Logging



=head1 VERSION

Version 0.115

=cut

our $VERSION = '0.115';



=head1 SYNOPSIS

   use App::CELL;
   use App::CELL::Log qw( $log );

   # initialization (set up logging, load config params and messages from
   # configuration directory) of an application called FooBar
   App::CELL->init( ident => 'FooBar' );

   # log messages (see L<App::CELL::Log> for details)
   $log->debug( "Debug-level log message" );
   $log->info( "Info-level log message" );

   # process status objects returned by function Foo::fn
   my $status = Foo::fn( ... );
   return $status unless $status->ok;

   # set the value of a meta parameter META_MY_PARAM to 42
   App::CELL->set_meta( 'META_MY_PARAM', 42 );

   # get the value of a meta parameter
   my $value = App::CELL->meta( 'META_MY_PARAM' );

   # get the value of a site configuration parameter
   $value = App::CELL->config( 'MY_PARAM' );

   # note: site configuration parameters are read-only: to change
   # them, edit the core and site configuration files and run your
   # application again.
   # 
   # For details, see the CELL Guide (in C<doc/>)
   


=head1 DESCRIPTION

This is the top-level module of App::CELL, the Configuration,
Error-handling, Localization, and Logging framework for
applications written in Perl.

App::CELL is released under the GNU Affero General Public License Version 3
in the hopes that it will be useful, but with no warrany of any kind. For
details, see the C<LICENSE> file in the top-level distro directory.

This module provides a number of public methods. For the sake of
uniformity, no functions are exported: the methods are designed to be
called using "arrow" notation, i.e.:

    App::CELL->method_name( args );

Some of the methods are "constructors" in the sense that they return
objects. 

=over 

=item C<init> - initialize App::CELL

=item C<set_meta> - set a meta parameter to an arbitrary value

=item C<meta> - get value of a meta parameter

=item C<config> - get value of a site parameter

=back

Each of these methods is described in somewhat more detail in the
L</METHODS> section, which contains links to the actual functions for those
methods that are merely wrappers.



=head1 PACKAGE VARIABLES

=cut

our $initialized = 0;



=head1 METHODS


=head2 init

This method needs to be called at least once, preferably before calling any
of the other methods. It performs all necessary initialization tasks. It is
designed to be re-entrant, which means you can call it more than once. 

The first time the function is called, it performs the following
tasks:

=over 

=item - configure logging

App::CELL uses C<Log::Any> to log its activities. WIP

=item - load message templates

CELL message templates are a special type of meta parameter that is loaded
from files whose names look like C<[...]_Message_en.pm>, where C<en> can be
any language tag (actually, any string, but you should stick to real
language tags at all if possible). See the CELL Guide for more information
on using CELL for localization.

=item - load meta parameters

Meta parameters are a replacement for global variables. They are
programatically changeable and their defaults are loaded from configuration
files with names of the format C<[...]_Meta.pm>. See C<App::CELL::Config> for
more information.

=item - load core and site parameters

Core and site configuration parameters are strictly read-only, and are
stored in any number of files whose names have the format
C<[...]_Config.pm> and C<[...]_SiteConfig.pm>. These two types of
parameters are designed to work together, with core parameters providing
defaults and site parameters providing site-specific overrides. See
the CELL Guide for more information on using CELL for configuration.

=back

Optionally takes arguments as a PARAMHASH. The following params are
recognized:

=over

=item C<appname> - name of the application (used to set the C<Log::Any>
logger category and also in the site directory search (see
C<App::CELL::Load>)

=item C<sitedir> - full path to the site directory (when C<App::CELL::Load>
conducts its site dir search, it will look here first)

=back

Returns an C<App::CELL::Status> object with level either "OK"
(on success) or "CRIT" (on failure). On success, it also sets the
C<CELL_META_INIT_STATUS_BOOL> and C<CELL_META_START_DATETIME> meta
parameters.

=cut

sub init {

    my ( $class, %Args ) = @_;

    my $status;

    if ( $initialized ) {
        $log->debug("Reentering App::CELL->init");
        App::CELL::Status->new( level => 'INFO',
            code => 'CELL_ALREADY_INITIALIZED',
        );
        return App::CELL::Status->ok;
    }

    # determine the application name
    my $appname;
    if ( $Args{appname} ) {
        $appname = $Args{appname} ;
    } else {
        $appname = 'CELLtest';
    }

    # determine debugging mode
    my $debug_mode;
    if ( $Args{debug} ) {
        $debug_mode = 1;
    } else {
        $debug_mode = 0;
    }

    # set logger category
    $log->init( ident => $appname, debug_mode => $debug_mode );

    # load site configuration parameters
    $status = App::CELL::Load::init( %Args );
    return $status unless $status->ok;
    $log->info( "App::CELL has finished loading messages and site conf params" );

    # set $App::CELL::Log::show_caller
    App::CELL::Log->init( show_caller => App::CELL::Config::config( 'CELL_LOG_SHOW_CALLER' ) );

    # initialize package variables in Message.pm
    @App::CELL::Message::supp_lang = 
        @{ App::CELL::Config::config( 'CELL_SUPPORTED_LANGUAGES' ) };
    $App::CELL::Message::language_tag = 
        App::CELL::Config::config( 'CELL_LANGUAGE' ) || 'en';

    $initialized = 1;
    App::CELL::Config::set_meta( 'CELL_META_INIT_STATUS_BOOL', $initialized );
    App::CELL::Config::set_meta( 'CELL_META_START_DATETIME', utc_timestamp() );
    $log->info( "**************** CELL started at "
                    . App::CELL->meta( 'CELL_META_START_DATETIME' )
                    . " (UTC)" );

    return App::CELL::Status->ok;
}


=head2 set_meta

Set a meta parameter. Wrapper for App::CELL::Config::set_meta. Takes two
arguments: string containing name of meta parameter, and value (scalar,
arrayref, or hashref) to assign to the parameter. Returns a status object.

=cut

sub set_meta {
    shift();  # throw away the class
    if ( @_ ) {
        return App::CELL::Config::set_meta( @_ );
    } else {
        return App::CELL::Status->new( level => 'ERR',
                   code => 'CELL_ERR_BAD_ARGUMENT' );
    }
}


=head2 meta

Get value of a meta parameter. Wrapper for App::CELL::MetaConfig::get_param.
Takes one argument: string containing name of meta parameter. Returns value
of meta parameter if the parameter exists, otherwise undef.

=cut

sub meta {
    # use $_[1] because $_[0] is the class name
    return if not $_[1]; # returns undef in scalar context
    App::CELL::Config::get_param( 'meta', $_[1] );
}


=head2 config

The C<config> method provides clients access to site
configuration parameters. A simple logic is applied: if the parameter is
defined in 'site', we're done: that is the value. If the parameter is not
defined in 'site', check 'core' and use that value, if available.

If neither 'site' nor 'core' has a definition for the parameter, undef is
returned.

=cut

sub config {
    # use $_[1] because $_[0] is the class name
    return if not $_[1]; # returns undef in scalar context
    return App::CELL::Config::config( $_[1] );
}

# END OF CELL MODULE
1;
