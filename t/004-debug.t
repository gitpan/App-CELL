#!perl
use 5.10.0;
use strict;
use warnings FATAL => 'all';
use App::CELL::Config;
use App::CELL::Load;
use App::CELL::Log qw( log_info );
use Data::Printer;
use Test::More;

plan tests => 2;

my $status = App::CELL::Log::configure( 'CELLtest' );
log_info("---------------------------------------------------------");
log_info("---                   004-debug.t                     ---");
log_info("---------------------------------------------------------");

$status = App::CELL::Load::init();
ok( $status->ok, "Loaded App::CELL configuration from distro share dir" );

#p( $App::CELL::Config::core );
my $debugbool = App::CELL::Config::get_param( 'core', 'CELL_DEBUG_MODE' );
is( $debugbool, 0, "Debugging is turned off by default" );
