#!perl
use 5.10.0;
use strict;
use warnings FATAL => 'all';
use Data::Printer;
use File::ShareDir;
use Test::More;
use App::CELL;
use App::CELL::Log qw( log_debug log_info );

plan tests => 5;

my $status = App::CELL::Log::configure( 'CELLtest' );
log_info("-------------------------------------------------------- ");
log_info("---                    08-cell.t                     ---");
log_info("-------------------------------------------------------- ");

my $bool = App::CELL->meta( 'META_CELL_STATUS_BOOL' );
ok( ! defined($bool), "CELL should not think it is initialized" );

# first try without pointing to site config directory -- CELL will
# configure itself from the distro's ShareDir
$status = App::CELL->init('CELLtest'); 
ok( $status->ok, "CELL initialization from ShareDir ok" );

my $sharedir = File::ShareDir::dist_dir('App-CELL');
my $configdir = App::CELL->meta('CELL_SITECONF_DIR');
diag( "Distro ShareDir is $sharedir");
diag( "ConfigDir is $configdir");
is( $sharedir, $configdir, 
    "CELL_SITECONF_DIR meta param is properly set to the ShareDir");

# once configured, CELL will ignore the environment variable when
# App::CELL->init is called again
$ENV{'CELL_CONFIGDIR'} = $ENV{'PWD'} . "/config";
$status = App::CELL->init('CELLtest');
ok( $status->ok, "CELL initialization still OK" );

is( $sharedir, $configdir, 
    "CELL_SITECONF_DIR meta param is still set to the ShareDir");
