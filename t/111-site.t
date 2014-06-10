#!perl
use 5.012;
use strict;
use warnings FATAL => 'all';
use App::CELL qw( $CELL $log $meta $core $site );
use App::CELL::Test qw( mktmpdir cleartmpdir populate_file );
#use App::CELL::Test::LogToFile;
#use Data::Dumper;
use File::Spec;
use Scalar::Util qw( blessed );
use Test::More tests => 7;

my $status;
delete $ENV{CELL_DEBUG_MODE};
$log->init( ident => 'CELLtest', debug_mode => 1 );
$log->info("------------------------------------------------------- ");
$log->info("---                   111-site.t                    ---");
$log->info("------------------------------------------------------- ");

is( $CELL->loaded, 0, "\$CELL->loaded is zero before anything is loaded" );
ok( ! defined( $meta->CELL_META_SITEDIR_LOADED ), "Meta param undefined before load");
my $sitedir = 'NON-EXISTENT-FOO-BAR-DIRECTORY';
ok( ! -e $sitedir, "Non-existent foo bar directory does not exist" );
$status = $CELL->load( sitedir => $sitedir );
is( $CELL->loaded, "SHARE", "\$CELL->loaded is SHARE after unsuccessful call to \$CELL->load" );
ok( $status->not_ok, "CELL initialization with non-existent sitedir NOT ok" );
is( $status->level, "ERR", "Status is ERR" );
is( $status->code, "CELL_SITEDIR_NOT_FOUND", "Status code is CELL_SITEDIR_NOT_FOUND" );
