package App::CELL;

use strict;
use warnings;
use 5.012;

use Carp;
use App::CELL::Config qw( $meta $core $site );
use App::CELL::Load;
use App::CELL::Log qw( $log );
use App::CELL::Status;
use App::CELL::Util qw( utc_timestamp );


=head1 NAME

App::CELL - Configuration, Error-handling, Localization, and Logging



=head1 VERSION

Version 0.146

=cut

our $VERSION = '0.146';



=head1 SYNOPSIS

    # imagine you have a script/app called 'foo' . . . 

    use Log::Any::Adapter ( 'File', "/var/tmp/foo.log" );
    use App::CELL qw( $CELL $log $meta $site );

    # load config params and messages from sitedir
    my $status = $CELL->load( appname => 'foo', 
                              sitedir => '/etc/foo' );
    return $status unless $status->ok;

    # write to the log
    $log->notice("Configuration loaded from /etc/foo");

    # get value of site configuration parameter FOO_PARAM
    my $val = $site->FOO_PARAM;

    # get text of message in default language
    my $txt = $CELL->msg('FOO_INFO_MSG')->text;

    # get text of message in a different language
    $txt = $CELL->msg('FOO_INFO_MSG')->lang('sk')->text;



=head1 DESCRIPTION

This is the top-level module of App::CELL, the Configuration,
Error-handling, Localization, and Logging framework for
applications (or scripts) written in Perl.

For details, see the documentation below and in L<App::CELL::Guide>.



=head1 EXPORTS

This module provides the following exports:

=over 

=item C<$CELL> - App::CELL singleton object

=item C<$log> - App::CELL::Log singleton object

=item C<$meta> - App::CELL::Config singleton object

=item C<$core> - App::CELL::Config singleton object

=item C<$site> - App::CELL::Config singleton object

=back

=cut 

use Exporter qw( import );
our @EXPORT_OK = qw( $CELL $log $meta $core $site );

our $CELL = bless { 
        appname  => __PACKAGE__,
        enviro   => '',
    }, __PACKAGE__;

# ($log is imported from App::CELL::Log)
# ($meta, $core, and $site are imported from App::CELL::Config)



=head1 METHODS


=head2 appname

Get the C<appname> attribute, i.e. the name of the application or script
that is using L<App::CELL> for its configuration, error handling, etc.

=cut

sub appname { return $CELL->{appname}; }


=head2 enviro

Get the C<enviro> attribute, i.e. the name of the environment variable
containing the sitedir

=cut

sub enviro { return $CELL->{enviro}; }


=head2 loaded

Get the current load status, which can be any of the following:
    0        nothing loaded yet
    'SHARE'  sharedir loaded
    'BOTH'   sharedir _and_ sitedir loaded

=cut

sub loaded {
    return 'SHARE' if $App::CELL::Load::sharedir_loaded and not
                      $App::CELL::Load::sitedir_loaded;
    return 'BOTH'  if $App::CELL::Load::sharedir_loaded and
                      $App::CELL::Load::sitedir_loaded;
    return 0;
}


=head2 sharedir

Get the C<sharedir> attribute, i.e. the full path of the site configuration
directory (available only after sharedir has been successfully loaded)

=cut

sub sharedir { 
    return '' if not $App::CELL::Load::sharedir_loaded;
    return $App::CELL::Load::sharedir;
}


=head2 sitedir

Get the C<sitedir> attribute, i.e. the full path of the site configuration
directory (available only after sitedir has been successfully loaded)

=cut

sub sitedir { 
    return '' if not $App::CELL::Load::sitedir_loaded;
    return $App::CELL::Load::sitedir;
}


=head2 supported_languages

Get $supported_languages array ref from L<App::CELL::Message>

=cut

sub supported_languages {
    return \@App::CELL::Message::supp_lang || [];
}


=head2 load

Attempt to load messages and configuration parameters from the sharedir
and, possibly, the sitedir as well.

Takes: a PARAMHASH that should include C<appname> and at least one of 
C<enviro> or C<sitedir> (if both are given, C<enviro> takes precedence with
C<sitedir> as a fallback).

Returns: an C<App::CELL::Status> object, which could be any of the
following: 
    OK    success
    WARN  previous call already succeeded, nothing to do 
    ERR   failure

On success, it also sets the C<CELL_META_START_DATETIME> meta parameter.

=cut

sub load {

    my ( $class, %Args ) = @_;
    my $status;

    if ( $CELL->loaded eq 'BOTH' ) {
        $log->debug("Reentering App::CELL->load");
        return App::CELL::Status->new( level => 'WARN',
            code => 'CELL_ALREADY_INITIALIZED',
        );
    }

    $CELL->{'appname'} = __PACKAGE__ if not $CELL->{'appname'};

    # $log->init is fully re-entrant, and nothing is actually logged until
    # the application does something with Log::Any::Adapter, so this will 
    # probably be convenient, or at least do no harm
    $log->ident( $CELL->{'appname'} );

    # we only get past this next call if at least the sharedir loads
    # successfully (sitedir is optional)
    $status = App::CELL::Load::init( %Args );
    return $status unless $status->ok;
    $log->info( "App::CELL has finished loading messages and site conf params" );

    $log->show_caller( $site->CELL_LOG_SHOW_CALLER );
    $log->debug_mode ( $site->CELL_DEBUG_MODE );

    # initialize package variables in Message.pm
    @App::CELL::Message::supp_lang = @{ $site->CELL_SUPPORTED_LANGUAGES };
    $App::CELL::Message::language_tag = $site->CELL_LANGUAGE || 'en';

    App::CELL::Config::set_meta( 'CELL_META_START_DATETIME', utc_timestamp() );
    $log->info( "**************** CELL started at " . 
                $meta->CELL_META_START_DATETIME     . " (UTC)" );

    return App::CELL::Status->ok;
}


=head2 set_meta

Set a meta parameter. Wrapper for App::CELL::Config::set_meta. Takes two
arguments: string containing name of meta parameter, and value (scalar,
arrayref, or hashref) to assign to the parameter. Returns a status object.

=cut

sub set_meta {
    shift();  # throw away the class/object
    if ( @_ ) {
        return App::CELL::Config::set_meta( @_ );
    } else {
        return App::CELL::Status->new( level => 'ERR',
                   code => 'CELL_ERR_BAD_ARGUMENT' );
    }
}


=head2 msg 

Construct a message object (wrapper for App::CELL::Message::new)

=cut

sub msg { 
    my ( $self, $code ) = @_;
    my $status = App::CELL::Message->new( code => $code );
    return if $status->not_ok; # will return undef in scalar mode
    return $status->payload;
}



=head1 COPYRIGHT AND LICENSE

App::CELL is Copyright (C) 2014, SUSE LLC

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

Author: Nathan Cutler L<mailto:presnypreklad@gmail.com>

    If the above link doesn't work for any reason, the full text of the license
    can also be found in the "LICENSE" file, located in the top-level directory 
    of the App::CELL distro (i.e. in the same directory where this README file 
    is located)

=cut

# END OF CELL MODULE
1;
