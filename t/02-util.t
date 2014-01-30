#!perl -T
use 5.10.0;
use strict;
use warnings FATAL => 'all';
use App::CELL::Log qw( log_info );
use App::CELL::Util qw( timestamp );
use Test::More;

plan tests => 1;

my $status = App::CELL::Log::configure( 'CELLtest' );
log_info("-------------------------------------------------------- ");
log_info("---                   02-util.t                      ---");
log_info("-------------------------------------------------------- ");
# test that App::CELL::Util::timestamp returns something that looks
# like a timestamp
my $timestamp_regex = qr/\d{4,4}-[A-Z]{3,3}-\d{1,2} \d{2,2}:\d{2,2}/a;
ok( timestamp() =~ $timestamp_regex, "App::CELL::Util::timestamp" );
diag( "Timestamp: " . timestamp() );
