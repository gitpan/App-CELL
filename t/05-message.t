#!perl
use 5.10.0;
use strict;
use warnings FATAL => 'all';
use Data::Printer;
use File::ShareDir;
use App::CELL::Log qw( log_debug log_info );
use App::CELL::Message;
use Test::More;

plan tests => 5;

my $status = App::CELL::Log::configure( 'CELLtest' );
log_info("-------------------------------------------------------- ");
log_info("---             05-message.t PRE-INIT                ---");
log_info("-------------------------------------------------------- ");

# This will pull in message configuration from the distro's ShareDir
App::CELL::Message::init();

# provided we are on a system without a pre-existing CELL configuration,
# we can assume that the call to App::CELL::Message::init() already set
# the CELL configuration directory to the distro's ShareDir
my $sharedir = File::ShareDir::dist_dir('App-CELL');
my $configdir = App::CELL::Config::get_siteconfdir();
diag("ShareDir is $sharedir");
diag("ConfigDir is $configdir");
is( $sharedir, $configdir,
    "get_siteconfdir properly defaults to the distro's ShareDir" );

my $message = App::CELL::Message->new();
is( $message->code, '<NO_CODE>', "code defaults to correct value" );
#diag( "Text of " . $message->code . " message is ->" . $message->text . "<-" );

$message = App::CELL::Message->new( code => 'UNGHGHASDF!*' );
is( $message->code, 'UNGHGHASDF!*', "Pre-init unknown message codes are passed through" );
#diag( "Text of " . $message->code . " message is ->" . $message->text . "<-" );

$message = App::CELL::Message->new( 
            code => "Pre-init message w/arg ->%s<-",
            args => [ "CONTENT" ],
                             );
is( $message->text, "Pre-init message w/arg ->CONTENT<-", "Pre-init unknown message codes can contain arguments" );
log_debug( $message->text );
#diag( "Text of " . $message->code . " message is ->" . $message->text . "<-" );

$status = App::CELL::Message::init;
ok( $status->ok, "App::CELL::Message::init OK" );
