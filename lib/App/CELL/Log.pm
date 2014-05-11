package App::CELL::Log;

use 5.10.0;
use strict;
use warnings;

# IMPORTANT: this module must not depend on any other CELL modules
use File::Spec;
use Log::Any qw( $log );



=head1 NAME

App::CELL::Log - the Logging part of CELL



=head1 VERSION

Version 0.088

=cut

our $VERSION = '0.088';



=head1 SYNOPSIS

    use App::CELL::Log qw( log_debug log_info );

    # configure logging for application FooBar -- need only be done once
    my $status = App::CELL::Log::configure('FooBar');  
    return $status unless $status->ok;

    # Info and debug messages are created by calling log_info and
    # log_debug, respectively
    log_info  ( "Info-level message"  );
    log_debug ( "Debug-level message" );

    # Arbitrary log message (use sparingly -- see App::CELL::Status
    # for a way to trigger higher-level log messages
    App::CELL::Log::arbitrary( 'WARN', "Be warned!" );

    # Log a status object (don't do this: it happens automatically when
    # status object is constructed)
    App::CELL::Log::status_obj( $status_obj );



=head1 EXPORTS

This module exports the following functions:

=over 

=item C<log_debug>

=item C<log_info>

=back

=cut 

use Exporter qw( import );
our @EXPORT_OK = qw( log_debug log_info );



=head1 PACKAGE VARIABLES

=over

=item C<$ident> - the name of our application

=item C<$log_level> - value linked to the C<CELL_DEBUG_MODE> site param;
must be a level recognized by C<Log::Fast>

=item C<@permitted_levels> - list of permissible log levels

=back 

=cut

our $ident;
our $log_level = 'INFO';
our @permitted_levels =
       ( 'OK', 'NOT_OK', 'DEBUG', 'INFO', 'NOTICE', 'WARN', 'ERR', 'CRIT' );



=head1 DESCRIPTION

The C<App::CELL::Log> module provides for "log-only messages" (see
Localization section of the top-level README for a discussion of the
different types of CELL messages).



=head1 FUNCTIONS


=head2 configure

Configures logging the way we like it. Takes one argument: the 'ident'
(identifier) string, which will probably be the application name. If not
given, defaults to 'CELL'. Returns status object.

TO DO: get ident and default log-level from site configuration, if
available.
TO DO: if we've already completed CELL server initialization, return
without doing anything

Returns: true on success, false on failure

=cut

sub configure {
    my $local_ident = shift || 'CELLtest';

    # re-entrant function: run only if (a) we haven't been initialized
    # at all yet, or (b) we were initialized under a different ident
    # string
    if ( $ident and ( $local_ident eq $ident ) ) {
        $log->info( "Logging already configured" );
        return 1;
    }
    # first invocation or change of ident
    $log = Log::Any->get_logger(category => $local_ident);
    $ident = $local_ident;

    return 1;
}


=head2 log_debug

Exportable function. Takes a string and writes it to syslog with log
level "DEBUG". Always returns true.

=cut

sub log_debug {
    my $msg_text = shift;
    $log->debug( _assemble_log_message( $msg_text, caller ) );
    return 1;
}


=head2 log_info

Exportable function. Takes a string and writes it to syslog with log
level "INFO". Always returns true.

=cut

sub log_info {
    my $msg_text = shift;
    $log->info( _assemble_log_message( $msg_text, caller ) );
    return 1;
}


=head2 arbitrary

Write an arbitrary message to any log level. Takes two string arguments:
log level and message to write.

=cut

sub arbitrary {
    my ( $level, $msg_text ) = @_;
    $level = uc $level;
    if ( not $msg_text ) { $msg_text = '<NONE>'; }
    if ( not grep { $level eq $_ } @permitted_levels )
    {
        my ( $pkg, $file, $line ) = caller;
        $msg_text .= " <- detected attempt to to log this message at"
        . " unknown level $level in $pkg ($file) line $line";
        $level = 'WARN';
    }
    ( $level, $msg_text ) = _sanitize_level( $level, $msg_text );
    $log->$level( $msg_text );
    return 1;
}


=head2 status_obj

Take a status object and log it.

=cut

sub status_obj {
    my $status_obj = shift;
    my $level = $status_obj->{level};
    my $msg_text = $status_obj->text;
    my $pkg = undef;
    my $file = $status_obj->{filename};
    my $line = $status_obj->{line};

    ( $level, $msg_text ) = _sanitize_level( $level, $msg_text );

    $log->$level( 
        _assemble_log_message( $msg_text, $pkg, $file, $line ) );
}

sub _sanitize_level {
    my ( $level, $msg_text ) = @_;
    if ( $level eq 'OK' ) {
        $level = 'INFO';
        $msg_text = "OK: " . $msg_text;
    } elsif ( $level eq 'NOT_OK' ) {
        $level = 'INFO';
        $msg_text = "NOT_OK: " . $msg_text;
    } elsif ( $level eq 'CRIT' ) {
        $level = 'ERR';
        $msg_text = "CRITICAL: " . $msg_text;
    }
    return ( lc $level, $msg_text );
}

sub _assemble_log_message {
    my ( $message, $package, $filename, $line ) = @_;

    if ( File::Spec->file_name_is_absolute( $filename ) ) {
       ( undef, undef, $filename ) = File::Spec->splitpath( $filename );
    }
    return "$message at $filename line $line";
}

1;
