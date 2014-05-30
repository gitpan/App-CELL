#!perl -T
use 5.10.0;
use strict;
use warnings FATAL => 'all';
use App::CELL::Log qw( $log );
use App::CELL::Status;
use App::CELL::Test qw( cmp_arrays );
use File::Spec;
use Test::More;

plan tests => 10;

my $status;
$log->init( ident => 'CELLtest' );
$log->info("-------------------------------------------------------- ");
$log->info("---                   003-test.t                     ---");
$log->info("-------------------------------------------------------- ");

$status = App::CELL::Test::mktmpdir();
ok( $status->ok, "mktmpdir status OK" );
my $tmpdir = $status->payload;
ok( -d $tmpdir, "Test directory is present" );

$status = App::CELL::Test::touch_files( $tmpdir, 'foo', 'bar', 'baz' );
is( $status, 3, "touch_files returned right number" );

$status = App::CELL::Test::cleartmpdir();
ok( $status->ok, "cleartmpdir status OK" );
ok( ! -e $tmpdir, "Test directory really gone" );

$status = -d $tmpdir;
ok( ! $status, "Test directory is really gone" );

my $booltrue = cmp_arrays( [ 0, 1, 2 ], [ 0, 1, 2 ] );
ok( $booltrue, "cmp_arrays works on identical array refs" );

my $boolfalse = cmp_arrays( [ 0, 1, 2 ], [ 'foo', 'bar', 'baz' ] );
ok( ! $boolfalse, "cmp_arrays works on different array refs" );

$booltrue = cmp_arrays( [], [] );
ok( $booltrue, "cmp_arrays works on two empty array refs" );

$boolfalse = cmp_arrays( [], [ 'foo' ] );
ok( ! $boolfalse, "cmp_arrays works on empty and non-empty array refs" );
