package App::CELL::Log;

use 5.10.0;
use strict;
use warnings;

# IMPORTANT: this module must not depend on any other CELL modules
use File::Spec;



=head1 NAME

App::CELL::Log - the Logging part of CELL



=head1 VERSION

Version 0.110

=cut

our $VERSION = '0.110';



=head1 SYNOPSIS

    use App::CELL::Log qw( $log );

    # set up logging for application FooBar -- need only be done once
    $log->init( ident => 'FooBar' );  
    
    # log messages at different log levels
    $log->trace    ( "Trace-level message"     );
    $log->debug    ( "Debug-level message"     );
    $log->info     ( "Info-level message"      );
    $log->inform   ( "Info-level message"      );
    $log->ok       ( "Info-level message prefixed with 'OK: '");
    $log->not_ok   ( "Info-level message prefixed with 'NOT_OK: '");
    $log->warning  ( "Warning-level message"   );
    $log->warn     ( "Warning-level message"   );
    $log->error    ( "Error-level message"     );
    $log->critical ( "Critical-level message"  );
    $log->crit     ( "Critical-level message"  );
    $log->fatal    ( "Critical-level message"  );
    $log->alert    ( "Alert-level message"     );
    $log->emergency( "Emergency-level message" );

    # Log a status object (don't do this: it happens automatically when
    # status object is constructed)
    App::CELL::Log::status_obj( $status_obj );



=head1 INHERITANCE

This module inherits from L<Log::Any>

=cut

use parent qw( Log::Any );



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

our $ident = '';
our $show_caller = 1;
our $debug_mode = 0;
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
        if ( $ARGS{ident} eq $ident ) {
            $log->info( "Logging already configured" );
        } else {
            $ident = $ARGS{ident};
            $log_any_obj = Log::Any->get_logger(category => $ident);
        }
    } elsif ( not $ident ) {
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


=head2 ident

Accessor method.

=cut

sub ident {
    return $ident;
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

    return if not $debug_mode and ( $method_lc eq 'debug' or $method_lc eq 'trace' );
    
    $log->init( ident => $ident ) if not $log_any_obj;

    $log_any_obj->$method_lc( _assemble_log_message( "$level: $msg_text", $file, $line ) );

}


=head2 status_obj

Take a status object and log it.

=cut

sub status_obj {
    my $status_obj = shift;
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

    if ( File::Spec->file_name_is_absolute( $file ) ) {
       ( undef, undef, $file ) = File::Spec->splitpath( $file );
    }

    return "$message at $file line $line" if $show_caller and $file;

    return $message;
}

1;
