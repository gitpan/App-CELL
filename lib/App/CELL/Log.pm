package App::CELL::Log;

use strict;
use warnings;
use 5.010;

# IMPORTANT: this module must not depend on any other CELL modules
use File::Spec;
use Log::Any;



=head1 NAME

App::CELL::Log - the Logging part of CELL



=head1 VERSION

Version 0.141

=cut

our $VERSION = '0.141';



=head1 SYNOPSIS

    use App::CELL::Log qw( $log );

    # set up logging for application FooBar -- need only be done once
    $log->init( ident => 'FooBar' );  

    # do not suppess 'trace' and 'debug' messages
    $log->init( debug_mode => 1 );     

    # do not append filename and line number of caller
    $log->init( show_caller => 0 );

    # log messages at different log levels
    my $level = 'warn'  # can be any of the levels provided by Log::Any
    $log->$level ( "Foobar log message" );

    # the following App::CELL-specific levels are supported as well
    $log->ok       ( "Info-level message prefixed with 'OK: '");
    $log->not_ok   ( "Info-level message prefixed with 'NOT_OK: '");

    # by default, the caller's filename and line number are appended
    # to suppress this for an individual log message:
    $log->debug    ( "Debug-level message", suppress_caller => 1 );

    # Log a status object (happens automatically when object is
    # constructed)
    $log->status_obj( $status_obj );

    # Log a message object
    $log->message_obj( $message_obj );



=head1 EXPORTS

This module provides the following exports:

=over 

=item C<$log> - App::CELL::Log singleton

=back

=cut 

use Exporter qw( import );
our @EXPORT_OK = qw( $log );



=head1 PACKAGE VARIABLES

=over

=item C<$ident> - the name of our application

=item C<$show_caller> - boolean value, determines if caller information is
displayed in log messages

=item C<$debug_mode> - boolean value, determines if we display debug
messages

=item C<$log> - App::CELL::Log singleton object

=item C<$log_any_obj> - Log::Any singleton object

=item C<@permitted_levels> - list of permissible log levels

=back 

=cut

our $debug_mode = 0;
our $ident = 'CELLtest';
our $show_caller = 1;
our $log = bless {}, __PACKAGE__;
our $log_any_obj;
our @permitted_levels = qw( OK NOT_OK TRACE DEBUG INFO INFORM NOTICE
        WARN WARNING ERR ERROR CRIT CRITICAL FATAL EMERGENCY );
our $AUTOLOAD;



=head1 DESCRIPTION

App::CELL's logs using L<Log::Any>. This C<App::CELL::Log> module exists
to: (1) provide documentation, (2) store the logging category (C<$ident>),
(3) store the L<Log::Any> log object, (4) provide convenience functions for
logging 'OK' and 'NOT_OK' statuses.



=head1 METHODS


=head2 debug_mode

Set the $debug_mode package variable

=cut

sub debug_mode { $debug_mode = $_[1]; }


=head2 ident

Set the $ident package variable and the Log::Any category

=cut

sub ident {
    my $self = shift;
    $ident = shift;
    $log_any_obj = Log::Any->get_logger(category => $ident);
}


=head2 show_caller

Set the $show_caller package variable

=cut

sub show_caller { $show_caller = $_[1]; }


=head2 init

Initializes (or reconfigures) the logger. Although in most cases folks will
want to call this in order to set C<ident>, it is not required for logging
to work. See L<App::CELL::Guide> for instructions on how to log with 
L<App::CELL>.

Takes PARAMHASH as argument. Recognized parameters: 

=over

=item C<ident> -- (i.e., category) string, e.g. 'FooBar' for
the FooBar application, or 'CELLtest' if none given

=item C<show_caller> -- sets the C<$show_caller> package variable (see
above)

=item C<debug_mode> -- sets the C<$debug_mode> package variable (see above)

=back

Always returns 1.

=cut

sub init {
    my ( $self, %ARGS ) = @_;

    # process 'ident'
    if ( defined( $ARGS{ident} ) ) {
        if ( $ARGS{ident} eq $ident and $ident ne 'CELLtest' ) {
            $log->info( "Logging already configured" );
        } else {
            $ident = $ARGS{ident};
            $log_any_obj = Log::Any->get_logger(category => $ident);
        }
    } else {
        $ident = 'CELLtest';
        $log_any_obj = Log::Any->get_logger(category => $ident);
    }    

    # process 'debug_mode' argument and possibly override it with
    # CELL_DEBUG_MODE environment variable
    if ( exists( $ARGS{debug_mode} ) ) {
        $debug_mode = 1 if $ARGS{debug_mode};
        $debug_mode = 0 if not $ARGS{debug_mode};
    }
    if ( exists( $ENV{ 'CELL_DEBUG_MODE' } ) ) {
        $debug_mode = 1 if $ENV{ 'CELL_DEBUG_MODE' };
        $debug_mode = 0 if not $ENV{ 'CELL_DEBUG_MODE' };
    }
    
    # process 'show_caller'
    if ( exists( $ARGS{show_caller} ) ) {
        $show_caller = 1 if $ARGS{show_caller};
        $show_caller = 0 if not $ARGS{show_caller};
    }

    return 1;
}


=head2 AUTOLOAD

Call Log::Any methods after some pre-processing

=cut

sub AUTOLOAD {
    
    my $class = shift;
    my $method = $AUTOLOAD;
    $method =~ s/.*:://;

    # if method is not in permitted_levels, pass through to Log::Any
    # directly
    if ( not grep { $_ =~ /$method/i } @permitted_levels ) {
        return $log_any_obj->$method( @_ );
    }

    # we are logging a message: pass through to Log::Any after
    # pre-processing
    my ( $msg_text, %ARGS ) = @_;
    my ( $file, $line );
    my $level;
    my $method_uc = uc $method;
    if ( $method_uc eq 'OK' or $method_uc eq 'NOT_OK' ) {
        $level = $method_uc;
        $method_uc = 'INFO';
        $method = 'info';
    } else {
        $level = $method_uc;
    }
    my $method_lc = lc $method;

    # determine what caller info will be displayed, if any
    my $throwaway;
    if ( %ARGS ) {
        if ( $ARGS{caller} ) {
            ( $throwaway, $file, $line ) = @{ $ARGS{caller} };
        } elsif ( $ARGS{suppress_caller} ) {
            ( $file, $line ) = ( '', '' );
        } else {
            ( $throwaway, $file, $line ) = caller;
        }
    } else {
        ( $throwaway, $file, $line ) = caller;
    }

    $log->init( ident => $ident ) if not $log_any_obj;
    die "No Log::Any object!" if not $log_any_obj;
    return if not $debug_mode and ( $method_lc eq 'debug' or $method_lc eq 'trace' );
    $log_any_obj->$method_lc( _assemble_log_message( "$level: $msg_text", $file, $line ) );
}


=head2 status_obj

Take a status object and log it.

=cut

sub status_obj {
    my ( $self, $status_obj ) = @_;
    $log->init( ident => $ident ) if not $log_any_obj;
    my $level = $status_obj->{level};
    my $msg_text = $status_obj->text;
    my $pkg = undef;
    my $file = $status_obj->{filename};
    my $line = $status_obj->{line};

    ( $level, $msg_text ) = _sanitize_level( $level, $msg_text );

    $log->$level( 
        _assemble_log_message( $msg_text, $file, $line ) );
}


=head2 message_obj

Take a message object and log it.

=cut

sub message_obj {
    my ( $self, $message_obj ) = @_;
    $log->init( ident => $ident ) if not $log_any_obj;
    my $level = $message_obj->level;
    my $msg_text = $message_obj->text;
}


sub _sanitize_level {
    my ( $level, $msg_text ) = @_;
    if ( $level eq 'OK' ) {
        $level = 'INFO';
        $msg_text = "OK: " . $msg_text;
    } elsif ( $level eq 'NOT_OK' ) {
        $level = 'INFO';
        $msg_text = "NOT_OK: " . $msg_text;
    }
    return ( lc $level, $msg_text );
}

sub _assemble_log_message {
    my ( $message, $file, $line ) = @_;

    if ( $file and File::Spec->file_name_is_absolute( $file ) ) {
       ( undef, undef, $file ) = File::Spec->splitpath( $file );
    }

    return "$message at $file line $line" if $show_caller and $file;

    return $message;
}

1;
