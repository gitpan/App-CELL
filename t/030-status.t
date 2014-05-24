#!perl -T
use 5.10.0;
use strict;
use warnings FATAL => 'all';
use Data::Printer;
use App::CELL::Log qw( $log );
use App::CELL::Status;
use App::CELL::Test;
use Test::More;

plan tests => 20;

my $status;
$log->init( ident => 'CELLtest' );
$log->info("------------------------------------------------- ");
$log->info("---               030-status.t                ---");
$log->info("------------------------------------------------- ");

$status = App::CELL::Status->ok;
ok( $status->ok, "OK status is OK" );

$status = App::CELL::Status->not_ok;
ok( ! $status->ok, "NOT_OK status is not OK" );
ok( $status->not_ok, "NOT_OK status is not_ok" );

$status = App::CELL::Status->new( level => 'OK' );
ok( $status->ok, "OK status via new is OK" );
ok( ! $status->not_ok, "OK status via new is not not OK" );

$status = App::CELL::Status->new( level => 'NOT_OK' );
ok( ! $status->ok, "NOT_OK status via new is not OK" );
ok( $status->not_ok, "NOT_OK status via new is not OK" );

$status = App::CELL::Status->new( level => 'DEBUG' );
ok( $status->not_ok, "DEBUG status is not OK" );

$status = App::CELL::Status->new( level => 'INFO' );
ok( $status->not_ok, "INFO status is not OK" );

$status = App::CELL::Status->new( level => 'NOTICE' );
ok( $status->not_ok, "NOTICE status is not OK" );

$status = App::CELL::Status->new( level => 'WARN' );
ok( $status->not_ok, "WARN status is not OK" );

$status = App::CELL::Status->new( level => 'ERR' );
ok( $status->not_ok, "ERR status is not OK" );

$status = App::CELL::Status->new( level => 'CRIT' );
ok( $status->not_ok, "CRIT status is not OK" );

$status = App::CELL::Status->new( level => 'OK',
    payload => [ 0, 'foo' ] );
ok( $status->ok, "OK status object with payload is OK" );
ok( App::CELL::Test::cmp_arrays( [ 0, 'foo' ], $status->payload ), "Payload is retrievable" );

$status = App::CELL::Status->new( 
            level => 'NOTICE',
            code => "Pre-init notice w/arg ->%s<-",
            args => [ "CONTENT" ],
                             );
ok( ! $status->ok, "Our pre-init status is not OK" );
ok( $status->not_ok, "Our pre-init status is not_ok" );
is( $status->msgobj->text, "Pre-init notice w/arg ->CONTENT<-", "Access message object through the status object" );

$status = App::CELL::Status->new(
              level => 'CRIT',
              code => "This is just a test. Don't worry; be happy.",
              payload => "FOOBARBAZ",
          );
is( $status->payload, "FOOBARBAZ", "Payload accessor function returns the right value" );
is( $status->level, "CRIT", "Level accessor function returns the right value" );
