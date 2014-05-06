#!perl
use 5.10.0;
use strict;
use warnings FATAL => 'all';
use App::CELL::Config;
use App::CELL::Log qw( log_debug log_info );
use Test::More;

plan tests => 1;

my $configdir = $ENV{'CELL_CONFIGDIR'} = $ENV{'PWD'} . "/config";
diag( "CELL_CONFIGDIR environment variable set to $configdir" );
is( App::CELL::Config::get_siteconfdir, $configdir, 
    "get_siteconfdir sees and understands the environment variable we just set" );

