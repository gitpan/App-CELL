#!perl
use 5.10.0;
use strict;
use warnings FATAL => 'all';
use Data::Printer;
use Test::More;
use App::CELL;
use App::CELL::Log qw( log_debug log_info );

plan tests => 3;

my $status = App::CELL::Log::configure( 'CELLtest' );
log_info("-------------------------------------------------------- ");
log_info("---                    07-cell.t                     ---");
log_info("-------------------------------------------------------- ");

my $bool = App::CELL->meta( 'CELL_CONFIG_INITIALIZED' );
ok( ! $bool, "CELL should not think it is initialized" );

# first try without pointing to site config directory
$status = App::CELL->init;
ok( ! $status->ok, "CELL initialization _NOT_ ok" );

$ENV{'CELL_CONFIGDIR'} = $ENV{'PWD'} . "/config";
$status = App::CELL->init;
ok( $status->ok, "CELL initialization OK" );
