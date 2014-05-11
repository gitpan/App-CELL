#!perl -T
use 5.10.0;
use strict;
use warnings FATAL => 'all';

use Data::Printer;
use Log::Any::Test;
our $log = Log::Any->get_logger(category => 'CELLtest');
use App::CELL::Log qw( log_debug log_info );
use Test::More tests => 10;

# This test must come before any calls to log_debug / log_info
my $bool = App::CELL::Log::configure( 'CELLtest' );
diag("Problem with syslog") if not $bool;
ok( $bool, "Configure logging" );

log_info("-------------------------------------------------------- ");
log_info("---                   001-log.t                      ---");
log_info("-------------------------------------------------------- ");
$log->clear();
log_debug( "Testing: DEBUG log message" );
$log->contains_only_ok( "DEBUG log message", 'log_debug works');
log_info( "Testing: INFO log message" ); 
$log->contains_only_ok( "INFO log message", 'log_info works');
App::CELL::Log::arbitrary( "NOTICE", "Testing: NOTICE log message" );
$log->contains_only_ok( "NOTICE log message", 'arbitrary NOTICE works' );
App::CELL::Log::arbitrary( "WARN", "Testing: WARN log message" );
$log->contains_only_ok( "WARN log message", 'arbitrary WARN works' );
App::CELL::Log::arbitrary( "ERR", "Testing: ERR log message" ); 
$log->contains_only_ok( "ERR log message", 'arbitrary ERR works' );
App::CELL::Log::arbitrary( "CRIT", "Testing: CRIT log message" );
$log->contains_only_ok( "CRIT log message", 'arbitrary CRIT works' );
App::CELL::Log::arbitrary( "OK", "Testing: OK log message" ); 
$log->contains_only_ok( "OK log message", 'arbitrary OK works' );
App::CELL::Log::arbitrary( "NOT_OK", "Testing: NOT_OK log message" );
$log->contains_only_ok( "NOT_OK log message", 'arbitrary NOT_OK works' );
App::CELL::Log::arbitrary( "FUNKY", "Testing: FUNKY log message" ); 
$log->contains_only_ok( "FUNKY log message", 'arbitrary FUNKY works' );
