#!perl

#
# t/070-config.t
#
# Run Config.pm through its paces
#

use 5.10.0;
use strict;
use warnings FATAL => 'all';
use App::CELL::Config qw( $meta $core $site );
use App::CELL::Load;
use App::CELL::Log qw( $log );
use App::CELL::Test;
use Test::More;

#
# To activate debugging, uncomment the following line
#
#use Log::Any::Adapter ('File', $ENV{'HOME'} . '/tmp/CELLtest.log');

plan tests => 25;

my $status;
$log->init( ident => 'CELLtest', debug_mode => 1 );
$log->info("-------------------------------------------------------");
$log->info("---                  070-config.t                   ---");
$log->info("-------------------------------------------------------");

#
# META
#

$status = $meta->CELL_META_TEST_PARAM_BLOOEY;
ok( ! defined($status), "Still no blooey" );

$status = App::CELL::Config::set_meta( 'CELL_META_TEST_PARAM_BLOOEY', 'Blooey' );
ok( $status->ok, "Blooey create succeeded" );

# 'exists' returns undef on failure
$status = exists $App::CELL::Config::meta->{ 'CELL_META_TEST_PARAM_BLOOEY' };
ok( defined( $status ), "Blooey exists after its creation" );

$status = $meta->CELL_META_TEST_PARAM_BLOOEY;
is( $status, "Blooey", "Blooey has the right value via get_param" );

$status = App::CELL::Load::init( appname => 'CELLtest' );
ok( $status->ok, "CELLtest load OK" );

# 'exists' returns undef on failure
$status = $meta->CELL_META_UNIT_TESTING;
ok( defined( $status ), "Meta unit testing param exists" );

my $value = $App::CELL::Config::meta->{ 'CELL_META_UNIT_TESTING' }->{'Value'};
is( ref( $value ), "ARRAY", "Meta unit testing param is an array reference" );

my $expected_value = [ 1, 2, 3, 'a', 'b', 'c' ];
$status = App::CELL::Test::cmp_arrays( $expected_value, $value );
ok( $status, "Meta unit testing param, obtained by cheating, has expected value" );

my $result = $meta->CELL_META_UNIT_TESTING;
$status = App::CELL::Test::cmp_arrays( $result, $expected_value );
ok( $status, "Meta unit testing param, obtained via get_param, has expected value" );

$status = App::CELL::Config::set_meta( 'CELL_META_UNIT_TESTING', "different foo" );
ok( $status->ok, "set_meta says OK" );

$result = undef;
$result = $meta->CELL_META_UNIT_TESTING;
is( $result, "different foo", "set_meta really changed the value" );
# (should also test that this triggers a log message !)

#
# CORE
#

# 'exists' returns undef on failure
$status = exists $App::CELL::Config::core->{ 'CELL_CORE_UNIT_TESTING' };
ok( defined( $status ), "Core unit testing param exists" );

$value = $App::CELL::Config::core->{ 'CELL_CORE_UNIT_TESTING' }->{'Value'};
is( ref( $value ), "ARRAY", "Core unit testing param is an array reference" );

$expected_value = [ 'nothing special' ];
$status = App::CELL::Test::cmp_arrays( $expected_value, $value );
ok( $status, "Core unit testing param, obtained by cheating, has expected value" );

$result = $core->CELL_CORE_UNIT_TESTING;
$status = App::CELL::Test::cmp_arrays( $result, $expected_value );
ok( $status, "Core unit testing param, obtained via get_param, has expected value" );

$status = App::CELL::Config::set_core( 'CELL_CORE_UNIT_TESTING', "different bar" );
ok( $status->err, "Attempt to set existing core param triggered ERR" );

my $new_result = $core->CELL_CORE_UNIT_TESTING;
isnt( $new_result, "different bar", "set_core did not change the value" );
is( $new_result, $result, "the value stayed the same" );

#
# SITE
#

# 'exists' returns undef on failure
$status = exists $App::CELL::Config::site->{ 'CELL_SITE_UNIT_TESTING' };
ok( defined( $status ), "Site unit testing param exists" );

$value = $App::CELL::Config::site->{ 'CELL_SITE_UNIT_TESTING' }->{'Value'};
is( ref( $value ), "ARRAY", "Site unit testing param is an array reference" );

$expected_value = [ 'Om mane padme hum' ];
$status = App::CELL::Test::cmp_arrays( $expected_value, $value );
ok( $status, "Site unit testing param, obtained by cheating, has expected value" );

$result = $site->CELL_SITE_UNIT_TESTING;
$status = App::CELL::Test::cmp_arrays( $result, $expected_value );
ok( $status, "Site unit testing param, obtained via get_param, has expected value" );

$status = App::CELL::Config::set_site( 'CELL_SITE_UNIT_TESTING', "different baz" );
ok( $status->err, "Attempt to set existing site param triggered ERR" );

$new_result = $site->CELL_SITE_UNIT_TESTING;
isnt( $new_result, "different baz", "set_site did not change the value" );
is( $new_result, $result, "the value stayed the same" );

