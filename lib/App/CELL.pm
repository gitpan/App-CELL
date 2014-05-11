package App::CELL;

use 5.10.0;
use strict;
use warnings;

use Carp;
use App::CELL::Config;
use App::CELL::Status qw( is_error );
use App::CELL::Log;
use App::CELL::Util qw( utc_timestamp );


=head1 NAME

App::CELL - Configuration, Error-handling, Localization, and Logging



=head1 VERSION

Version 0.088

=cut

our $VERSION = '0.088';



=head1 SYNOPSIS

   use App::CELL;

   # initialization (set up logging, load config params and messages from
   # configuration directory) of an application called FooBar
   App::CELL->init('FooBar');

   # write arbitrary, non-localized strings to syslog
   App::CELL->log_debug( "DEBUG level message" );
   App::CELL->log_info( "INFO level message" );

   # process status objects returned by invoked function
   my $status = Function::invocation( ... );
   return $status unless $status->ok;

   # set the value of a meta parameter META_MY_PARAM to 42
   App::CELL->set_meta( 'META_MY_PARAM', 42 );

   # get the value of a meta parameter
   my $value = App::CELL->meta( 'META_MY_PARAM' );

   # get the value of a site configuration parameter
   $value = App::CELL->config( 'MY_PARAM' );

   # note: site configuration parameters are read-only: to change
   # them, edit the core and site configuration files.
   # 
   # For details, see the CELL Guide (in C<doc/>)
   


=head1 DESCRIPTION

This is the top-level module of App::CELL, the Configuration,
Error-handling, Localization, and Logging framework for Perl
applications running under Unix-like systems such as SUSE Linux
Enterprise.

Configuration, error-handling, localization, and logging may seem like
diverse topics. In the author's experience, however, applications written
for "users" (however that term may be defined) frequently need to:

=over

=item 1. be configurable by the user or site administrator

=item 2. handle errors robustly, without hangs and crashes

=item 3. potentially display messages in various languages

=item 4. log various types of messages to syslog

=back

Since these basic functions seem to work well together, CELL is designed to
provide them in an integrated, well-documented, straightforward, and
reusable package.

For details, see the CELL Guide (in C<doc/>)


=head1 HISTORY

CELL was written by Smithfarm in late 2013 and early 2014, initially as
part of the Dochazka project [[ link to SourceForge ]]. Due to its generic
nature, it was spun off into a separate project.



=head1 COMPONENTS


=head2 C<lib/App/CELL.pm>

This top-level module is all the application programmer needs to gain
access to the CELL's key functions.

See L</SYNOPSIS> for code snippets, and L</METHODS> for
details.


=head2 C<lib/App/CELL/Config.pm>

This module provides CELL's Configuration functionality.


=head2 C<lib/App/CELL/Load.pm>

C<Load.pm> encapsulates all the complexity of loading messages and
config params from files in two directories: (1) the App::CELL distro
sharedir containing App::CELL's own configuration, and (2) the site
configuration directory, if present.


=head2 C<lib/App/CELL/Log.pm>

Logging is simple in Perl, thanks to CPAN modules like C<Log::Fast>, but
CELL tries to make it even simpler.


=head2 C<lib/App/CELL/Message.pm>

Localization is on the wish-list of many software projects. With App::CELL,
I can easily design and write my application to be localizable from the
very beginning, without having to invest much effort.


=head2 C<lib/App/CELL/Status.pm>

C<Status.pm> provides CELL's Error-handling functionality. Since status
objects inherit from message objects, the application programmer can
instruct CELL to generate localized status messages (errors, warnings,
notices) if she wishes.



=head1 HOW TO USE THIS MODULE

This module, C<lib/App/CELL.pm>, provides a number of public methods. For the
sake of uniformity, no functions are exported: the methods are designed to
be called using "arrow" notation, i.e.:

    App::CELL->method_name( args );

Some of the methods are "constructors" in the sense that they return
objects. 

=over 

=item C<init> - initialize App::CELL

=item C<log_debug> - send DEBUG-level message to syslog

=item C<log_info> - send INFO-level message to syslog

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

CELL uses the syslog facility to log its activities, and provides logging
methods to enable the application to do the same. It is recommended that
syslog be configured to send CELL-related log messages to a separate file,
e.g. C</var/log/[APP]>.

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

=item - load message templates

CELL message templates are a special type of meta parameter that is loaded
from files whose names look like C<[...]_Message_en.pm>, where C<en> can be
any language tag (actually, any string, but you should stick to real
language tags at all if possible). See the CELL Guide for more information
on using CELL for localization.

=back

Takes one argument: string to be used as identifier (C<ident>) for syslog.
This string, usually the application name, will be pre-pended to all
messages and can be used to configure syslog to put all log messages
related to your application in a separate file within C</var/log>, or
elsewhere. Returns an C<App::CELL::Status> object with level either "OK"
(on success) or "CRIT" (on failure).

On success, it also sets the C<CELL_META_INIT_STATUS_BOOL> and
C<CELL_META_START_DATETIME> meta parameters.

=cut

sub init {

    my ( $class, $app_name ) = $_;

    my $status;

    App::CELL->log_debug("Reentering App::CELL->init") if $initialized;
    return App::CELL::Status->ok if $initialized; # nothing to do

    # open and configure syslog connection
    App::CELL::Log::configure( $app_name );

    # load site configuration parameters
    $status = App::CELL::Load::init();
    return $status unless $status->ok;
    App::CELL->log_info( "App::CELL has finished loading messages and site conf params" );

    App::CELL::Config::set_meta( 'CELL_META_INIT_STATUS_BOOL', 1 );
    App::CELL::Config::set_meta( 'CELL_META_START_DATETIME', utc_timestamp() );
    App::CELL->log_info( "**************** CELL started at "
                    . App::CELL->meta( 'CELL_META_START_DATETIME' )
                    . " (UTC)" );

    $initialized = 1;
    return App::CELL::Status->ok;
}


=head2 log_debug

Send a DEBUG-level message to syslog. Takes a string. Returns nothing.

=cut

sub log_debug {
    # use $_[1] because $_[0] is the class name
    App::CELL::Log::arbitrary( 'debug', $_[1] || "<NO_MESSAGE>" );
}


=head2 log_info

Send an INFO-level message to syslog. Takes a string. Returns nothing.

=cut

sub log_info {
    # use $_[1] because $_[0] is the class name
    App::CELL::Log::arbitrary( 'info', $_[1] || "<NO_MESSAGE>" );
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
