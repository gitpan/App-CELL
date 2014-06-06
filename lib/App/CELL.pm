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
use Scalar::Util qw( blessed );


=head1 NAME

App::CELL - Configuration, Error-handling, Localization, and Logging



=head1 VERSION

Version 0.159

=cut

our $VERSION = '0.159';



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

    # get a list of all supported languages
    my @supp_lang = $CELL->supported_languages;

    # determine if a language is supported
    print "sk supported" if $CELL->language_supported('sk');

    # get message object and text in default language
    my $fmsg = $CELL->msg('FOO_INFO_MSG');
    my $text = $fmsg->text;

    # get message object and text in default language
    # (message that takes arguments)
    $fmsg = $CELL->msg('BAR_ARGS_MSG', "arg1", "arg2");
    print $fmsg->text, "\n";

    # get text of message in a different language
    my $sk_text = $fmsg->lang('sk')->text;



=head1 DESCRIPTION

This is the top-level module of App::CELL, the Configuration,
Error-handling, Localization, and Logging framework for applications (or
scripts) written in Perl.

For details, read the POD in the L<App::CELL> distro. For an introduction,
read L<App::CELL::Guide>.



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

Get list of supported languages. Equivalent to:

    $site->CELL_SUPPORTED_LANGUAGES || [ 'en ]

=cut

sub supported_languages {
    return App::CELL::Message::supported_languages();
}


=head2 language_supported

Determine if a given language is supported.

=cut

sub language_supported {
    return App::CELL::Message::language_supported( $_[1] );
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

    my ( $class, @ARGS ) = @_;
    if ( @ARGS % 2 ) {
        return $CELL->status_err( code => "CELL_ODD_ARGS",
           args => [ '$CELL->load', stringify_args( \@ARGS ) ] );
    }
    my %ARGS = @ARGS;
    my $status; 

    #if ( $CELL->loaded eq 'BOTH' ) {
    #    $log->debug("Reentering App::CELL->load");
    #    return App::CELL::Status->new( level => 'WARN',
    #        code => 'CELL_ALREADY_INITIALIZED',
    #    );
    #}

    $CELL->{appname} = $ARGS{appname} if $ARGS{appname};
    $CELL->{appname} = __PACKAGE__ if not $CELL->{'appname'};

    # Presumably this is what the application wants; if not, it can be
    # overrided
    $log->ident( $CELL->{'appname'} );

    # we only get past this next call if at least the sharedir loads
    # successfully (sitedir is optional)
    $status = App::CELL::Load::init( %ARGS );
    return $status unless $status->ok;
    $log->info( "App::CELL has finished loading messages and site conf params" );

    $log->show_caller( $site->CELL_LOG_SHOW_CALLER );
    $log->debug_mode ( $site->CELL_DEBUG_MODE );

    # initialize package variables in Message.pm
    @App::CELL::Message::supp_lang = @{ $site->CELL_SUPPORTED_LANGUAGES };
    $App::CELL::Message::default_lang = $site->CELL_LANGUAGE || 'en';

    $meta->set( 'CELL_META_START_DATETIME', utc_timestamp() );
    $log->info( "**************** CELL started at " . 
                $meta->CELL_META_START_DATETIME     . " (UTC)" );

    return App::CELL::Status->ok;
}


=head2 Status constructors

The following "factory" makes a bunch of status constructor methods
(wrappers for App::CELL::Status->new )

=cut

BEGIN {
    foreach (@App::CELL::Log::permitted_levels) {
        no strict 'refs';
        my $level_uc = $_;
        my $level_lc = lc $_;
        *{"status_$level_lc"} = sub { 
            my ( $self, $code, @ARGS ) = @_;
            if ( @ARGS % 2 ) { # odd number of arguments
                @ARGS = ();
            }
            return App::CELL::Status->new(
                level => $level_uc,
                code => $code,
                @ARGS,
            );
        }
    }
}

=head3 status_crit

Constructor for 'CRIT' status objects

=head3 status_critical

Constructor for 'CRIT' status objects

=head3 status_debug

Constructor for 'DEBUG' status objects

=head3 status_emergency

Constructor for 'DEBUG' status objects

=head3 status_err

Constructor for 'ERR' status objects

=head3 status_error

Constructor for 'ERR' status objects

=head3 status_fatal

Constructor for 'FATAL' status objects

=head3 status_info

Constructor for 'INFO' status objects

=head3 status_inform

Constructor for 'INFORM' status objects

=head3 status_not_ok

Constructor for 'NOT_OK' status objects

=head3 status_notice

Constructor for 'NOTICE' status objects

=head3 status_ok

Constructor for 'OK' status objects

=head3 status_trace

Constructor for 'TRACE' status objects

=head3 status_warn

Constructor for 'WARN' status objects

=head3 status_warning

Constructor for 'WARNING' status objects


=head2 msg 

Construct a message object (wrapper for App::CELL::Message::new)

=cut

sub msg { 
    my ( $self, $code, @ARGS ) = @_;
    my $status = App::CELL::Message->new( code => $code, args => [ @ARGS ] );
    return if $status->not_ok; # will return undef in scalar mode
    my $msgobj = $status->payload;
    return $msgobj if blessed $msgobj;
    return;
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
