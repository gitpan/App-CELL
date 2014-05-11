#!perl
use 5.10.0;
use strict;
use warnings FATAL => 'all';
use Data::Printer;
use File::ShareDir;
use App::CELL::Load;
use App::CELL::Log qw( log_debug log_info );
use App::CELL::Message;
use Test::More;

plan tests => 3;

my $status = App::CELL::Log::configure( 'CELLtest' );
log_info("----------------------------------------------- ");
log_info("---             005-message.t               ---");
log_info("----------------------------------------------- ");

my $message = App::CELL::Message->new();
is( $message->code, 'CELL_MESSAGE_NO_CODE', "code defaults to correct value" );
#diag( $message->stringify );

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
