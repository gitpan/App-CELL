#!perl
use 5.012;
use strict;
use warnings FATAL => 'all';
use Test::More;
use App::CELL qw( $log $meta );

#
# To activate debugging, uncomment the following line
#
use Log::Any::Adapter ('File', $ENV{'HOME'} . '/tmp/CELLtest.log');

plan tests => 1;

$log->info("************************************ 111-test.t");
App::CELL::Config::set_meta('MY_PARAM', 42);
is( $meta->MY_PARAM, 42, 'MY_PARAM is 42' );
