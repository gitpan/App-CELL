#!perl
use 5.10.0;
use strict;
use warnings FATAL => 'all';
use Data::Dumper;
use File::ShareDir;
use Test::More;
use App::CELL qw( $CELL $log );
use App::CELL::Test qw( cmp_arrays );

plan tests => 9;

my $status;
$log->init( ident => 'CELLtest' );
$log->info("------------------------------------------------------- ");
$log->info("---                   100-cell.t                    ---");
$log->info("------------------------------------------------------- ");

my $bool = $CELL->meta( 'META_CELL_STATUS_BOOL' );
ok( ! defined($bool), "Random config param not loaded yet" );
ok( ! $CELL->loaded, "CELL doesn't think it's loaded" );
ok( ! $log->{debug_mode}, "And we're not in debug mode" );

# first try without pointing to site config directory -- CELL will
# configure itself from the distro's ShareDir
$status = $CELL->load( appname => 'CELLfoo' ); 
ok( $status->ok, "CELL initialization from ShareDir ok" );
ok( $CELL->loaded eq 'SHARE', "$CELL->loaded says SHARE");

#diag( Dumper( $CELL->supported_languages ) );
ok( cmp_arrays( $CELL->supported_languages, [ 'en' ] ), 
    "CELL_SUPPORTED_LANGUAGES is set to just English" );

#diag( Dumper( \@App::CELL::Message::supp_lang ) );
ok( cmp_arrays( $CELL->supported_languages, \@App::CELL::Message::supp_lang ), 
    "supp_lang package variable is set to same value"); 

my $sharedir = $CELL->config('CELL_SHAREDIR_FULLPATH'); ok(
defined( $sharedir ), "CELL_SHAREDIR_FULLPATH is defined" );

is( $sharedir, File::ShareDir::dist_dir('App-CELL'),
    "CELL_SHAREDIR_FULLPATH is properly set to the ShareDir");
