#!perl
use 5.10.0;
use strict;
use warnings FATAL => 'all';
use Data::Printer;
use App::CELL::Log qw( log_debug log_info );
use App::CELL::Message;
use Test::More;

plan tests => 5;

my $status = App::CELL::Log::configure( 'CELLtest' );
log_info("-------------------------------------------------------- ");
log_info("---             04-message.t PRE-INIT                ---");
log_info("-------------------------------------------------------- ");

# Since we haven't run App::CELL::Config::init, this will just
# initialize a single, hard-coded message CELL_UNKNOWN_MESSAGE_CODE/en
App::CELL::Message::init();

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

my $configdir = $ENV{'CELL_CONFIGDIR'} = $ENV{'PWD'} . "/config";
diag( "CELL config directory is $configdir" );
is( App::CELL::Config::get_siteconfdir, $configdir, 
    "get_siteconfdir sees and understands the environment variable we just set" );

$status = App::CELL::Message::init;
ok( $status->ok, "App::CELL::Message::init OK" );
