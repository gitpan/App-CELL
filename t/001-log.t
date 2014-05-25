#!perl
use 5.10.0;
use strict;
use warnings FATAL => 'all';

use Log::Any::Test;
use App::CELL::Log qw( $log );
use App::CELL::Load;
use Test::More tests => 18;

# Initialize the logger
$log->init( ident => 'CELLtest', debug_mode => 1 );

# This is cheating, but we need the Log::Any object so we can call the
# testing methods
our $log_any_obj = Log::Any->get_logger(category => 'CELLtest');

$log->info("-------------------------------------------------------- ");
$log->info("---                   001-log.t                      ---");
$log->info("-------------------------------------------------------- ");
$log->clear();
$log->trace                   ( "TRACE log message" );
$log->contains_only_ok( "TRACE log message", 'trace works');
$log->debug                   ( "DEBUG log message" );
$log->contains_only_ok( "DEBUG log message", 'debug works');
$log->info                    ( "INFO log message" ); 
$log->contains_only_ok( "INFO log message", 'info works');
$log->notice                  ( "NOTICE log message" );
$log->contains_only_ok( "NOTICE log message", 'notice works' );
$log->warn                    ( "WARN log message" );
$log->contains_only_ok( "WARN log message", 'warn works' );
$log->err                     ( "ERR log message" ); 
$log->contains_only_ok( "ERR log message", 'err works' );
$log->crit                    ( "CRIT log message" );
$log->contains_only_ok( "CRIT log message", 'crit works' );
$log->alert                   ( "ALERT log message" );
$log->contains_only_ok( "ALERT log message", 'alert works' );
$log->emergency               ( "EMERGENCY log message" );
$log->contains_only_ok( "EMERGENCY log message", 'emergency works' );
$log->ok                      ( "OK log message" ); 
$log->contains_only_ok( "OK log message", 'ok works' );
$log->not_ok                  ( "NOT_OK log message" ); 
$log->contains_only_ok( "NOT_OK log message", 'not_ok works' );

my $status = App::CELL::Load::init( appname => 'CELLtest' );
ok( $status->ok, "Messages from sharedir loaded" );

$log->clear();
$status = App::CELL::Status->new( level => 'NOTICE', 
              code => 'CELL_TEST_MESSAGE' );
$log->contains_ok( 'DEBUG: Creating message object' );
$log->contains_only_ok( "NOTICE: This is a test message", "NOTICE test message ok" );

$log->init( debug_mode => 0 );
$log->trace("foo");
$log->empty_ok("No trace when debug_mode off");
$log->debug("bar");
$log->empty_ok("No debug when debug_mode off");
$log->info("baz");
$log->contains_only_ok( "baz", "INFO messages log even if debug_mode is off" );

$log->init( debug_mode => 1 );
$log->debug("bar");
$log->contains_only_ok( "bar", "debug_mode back on" );