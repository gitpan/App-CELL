#!perl

#
# t/004-debug.t
#
# The purpose of this unit test is to demonstrate how the unit tests can be
# used for debugging (not to test debugging)
#

use 5.012;
use strict;
use warnings FATAL => 'all';
use App::CELL::Config;
use App::CELL::Load;
use App::CELL::Log qw( $log );
use Test::More tests => 1;

#
# To activate debugging, uncomment the following
#
#use App::CELL::Test::LogToFile;
#$log->init( debug_mode => 1 );

my $status;
$log->init( ident => 'CELLtest' );
$log->info("---------------------------------------------------------");
$log->info("---                   004-debug.t                     ---");
$log->info("---------------------------------------------------------");

$status = App::CELL::Load::init();
is( $status->level, "WARN", "Load without sitedir results gives warning" );
