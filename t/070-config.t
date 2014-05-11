#!perl
use 5.10.0;
use strict;
use warnings FATAL => 'all';
use Data::Printer;
use App::CELL::Load;
use App::CELL::Log qw( log_debug log_info );
use App::CELL::Test;
use App::CELL::Util;
use File::Spec;
use Test::More;

plan tests => 4;

my $status = App::CELL::Log::configure( 'CELLtest' );
log_info("--------------------------------------------------------- ");
log_info("---                   070-config.t                    ---");
log_info("--------------------------------------------------------- ");

$status = App::CELL::Test::cleartmpdir();
ok( $status, "Temp directory not present" );
my $configdir = App::CELL::Test::mktmpdir();
my $siteconfigfile = File::Spec->catfile( $configdir, "siteconfig.conf" );
open(my $fh, '>', $siteconfigfile ) or die "Could not open file: $!";
my $stuff = <<EOS;
# This is a test
SITECONF_PATH="$configdir";
EOS
print $fh $stuff;
close $fh;
#diag( "Test siteconfigfile is $siteconfigfile" );
is( App::CELL::Load::_read_siteconfdir_from_file($siteconfigfile), $configdir, "_import_cellconf" );

ok( App::CELL::Util::is_directory_viable($configdir), "Configuration directory is viable" );

$status = App::CELL::Load::init;
ok( $status->ok, "App::CELL::Load::init OK" );

