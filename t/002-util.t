#!perl -T
use 5.10.0;
use strict;
use warnings FATAL => 'all';
use App::CELL::Log qw( $log );
use App::CELL::Status;
#use App::CELL::Test::LogToFile;
use App::CELL::Util qw( utc_timestamp is_directory_viable );
use File::Spec;
use Test::More;

plan tests => 4;

my $status;
$log->init( ident => 'CELLtest' );
$log->info("-------------------------------------------------------- ");
$log->info("---                   002-util.t                     ---");
$log->info("-------------------------------------------------------- ");

# test that App::CELL::Util::timestamp returns something that looks
# like a timestamp
my $timestamp_regex = qr/^\d{4,4}-\d{2,2}-\d{1,2} \d{2,2}:\d{2,2}/a;
my $timestamp = utc_timestamp();
ok( $timestamp =~ $timestamp_regex, "App::CELL::Util::timestamp" );
#diag( "Timestamp: " . $timestamp );

# App::CELL::Util::is_directory_viable with a viable directory
my $test_dir = File::Spec->catfile (
                   File::Spec->rootdir(),
               );
#diag( "Testing directory $test_dir" );
$status = is_directory_viable( $test_dir );
ok( $status->ok, "Root directory is viable" );

# App::CELL::Util::is_directory_viable with a non-viable directory
$test_dir = "###foobarbazblat342###";
#diag( "Testing directory $test_dir" );
$status = is_directory_viable( $test_dir );
#diag( $status->payload ) if $status->payload;
ok( $status->not_ok, "Invalid directory is not viable" );
is( $status->payload, "does not exist", "Invalid directory is not viable for the right reason" );
