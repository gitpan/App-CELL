#!perl
use 5.10.0;
use strict;
use warnings FATAL => 'all';
use File::ShareDir;
use Test::More;
use App::CELL qw( $CELL );
use App::CELL::Log qw( $log );
use App::CELL::Test;

plan tests => 6;

my $status;
$log->init( ident => 'CELLtest' );
$log->info("------------------------------------------------------- ");
$log->info("---                   100-cell.t                    ---");
$log->info("------------------------------------------------------- ");

my $bool = $CELL->meta( 'META_CELL_STATUS_BOOL' );
ok( ! defined($bool), "CELL should not think it is initialized" );

# first try without pointing to site config directory -- CELL will
# configure itself from the distro's ShareDir
$status = $CELL->init( appname => 'CELLfoo'); 
ok( $status->ok, "CELL initialization from ShareDir ok" );

my $supp_lang = $CELL->config('CELL_SUPPORTED_LANGUAGES');
ok( App::CELL::Test::cmp_arrays( $supp_lang, [ 'en' ] ), 
    "CELL_SUPPORTED_LANGUAGES is set to just English" );

ok( App::CELL::Test::cmp_arrays( $supp_lang, 
    \@App::CELL::Message::supp_lang ), 
    "supp_lang package variable is set"); 

my $sharedir = $CELL->config('CELL_SHAREDIR_FULLPATH'); ok(
defined( $sharedir ), "CELL_SHAREDIR_FULLPATH is defined" );

is( $sharedir, File::ShareDir::dist_dir('App-CELL'),
    "CELL_SHAREDIR_FULLPATH is properly set to the ShareDir");
