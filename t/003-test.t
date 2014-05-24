#!perl -T
use 5.10.0;
use strict;
use warnings FATAL => 'all';
use App::CELL::Log qw( $log );
use App::CELL::Status;
use App::CELL::Test;
use File::Spec;
use Test::More;

plan tests => 9;

my $status;
$log->init( ident => 'CELLtest' );
$log->info("-------------------------------------------------------- ");
$log->info("---                   003-test.t                     ---");
$log->info("-------------------------------------------------------- ");

$status = App::CELL::Test::cleartmpdir();
ok( $status, "Test directory is not present" );

my $tmpdir = App::CELL::Test::mktmpdir();
$status = -d $tmpdir;
ok( $status, "Test directory is present" );

$status = App::CELL::Test::touch_files( $tmpdir, 'foo', 'bar', 'baz' );
is( $status, 3, "touch_files returned right number" );

$status = App::CELL::Test::cleartmpdir();
ok( $status, "Test directory wiped" );

$status = -d $tmpdir;
ok( ! $status, "Test directory is really gone" );

my $booltrue = App::CELL::Test::cmp_arrays(
    [ 0, 1, 2 ], [ 0, 1, 2 ]
);
ok( $booltrue, "cmp_arrays works on identical array refs" );

my $boolfalse = App::CELL::Test::cmp_arrays(
    [ 0, 1, 2 ], [ 'foo', 'bar', 'baz' ]
);
ok( ! $boolfalse, "cmp_arrays works on different array refs" );

$booltrue = App::CELL::Test::cmp_arrays( [], [] );
ok( $booltrue, "cmp_arrays works on two empty array refs" );

$boolfalse = App::CELL::Test::cmp_arrays( [], [ 'foo' ] );
ok( ! $boolfalse, "cmp_arrays works on empty and non-empty array refs" );
