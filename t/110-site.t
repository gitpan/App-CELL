#!perl
use 5.012;
use strict;
use warnings FATAL => 'all';
use App::CELL qw( $CELL $log $meta $core $site );
use App::CELL::Test qw( mktmpdir cleartmpdir populate_file );
#use App::CELL::Test::LogToFile;
#use Data::Dumper;
use File::Spec;
use Scalar::Util qw( blessed );
use Test::More tests => 15;

my $status;
delete $ENV{CELL_DEBUG_MODE};
$log->init( ident => 'CELLtest', debug_mode => 1 );
$log->info("------------------------------------------------------- ");
$log->info("---                   110-site.t                    ---");
$log->info("------------------------------------------------------- ");

$status = mktmpdir();
ok( $status->ok, "Temporary directory created" );
my $sitedir = $status->payload;
ok( -d $sitedir, "tmpdir is a directory" );
ok( -W $sitedir, "tmpdir is writable by us" );

my $full_path = File::Spec->catfile( $sitedir, 'CELL_Message_en.conf' );
my $stuff = <<'EOS';
# some messages in English
TEST_MESSAGE
This is a test message.

FOO_BAR
Message that says foo bar.

BAR_ARGS_MSG
This %s message takes %s arguments.

EOS
#diag( "Now populating $full_path" );
populate_file( $full_path, $stuff );

$full_path = File::Spec->catfile( $sitedir, 'CELL_Message_cz.conf' );
$stuff = <<'EOS';
# some messages in Czech
TEST_MESSAGE
Tato zpráva slouží k testování.

FOO_BAR
Zpráva, která zní foo bar.

BAR_ARGS_MSG
Tato %s zpráva bere %s argumenty.

EOS
#diag( "Now populating $full_path" );
populate_file( $full_path, $stuff );

$full_path = File::Spec->catfile( $sitedir, 'CELL_SiteConfig.pm' );
$stuff = <<'EOS';
# set supported languages
set( 'CELL_SUPPORTED_LANGUAGES', [ 'en', 'cz' ] );

1;
EOS
#diag( "Now populating $full_path" );
populate_file( $full_path, $stuff );

$status = $CELL->load( sitedir => $sitedir );
ok( $status->ok, "CELL initialization with sitedir OK" );
is_deeply( $CELL->supported_languages, [ 'en', 'cz' ], 
    "CELL now supports two languages instead of just one" );
ok( $CELL->language_supported( 'en' ), "English is supported" );
ok( $CELL->language_supported( 'cz' ), "Czech is supported" );
ok( ! $CELL->language_supported( 'fr' ), "French is not supported" );
is( $site->CELL_LANGUAGE, 'en', "Site language default is English" );
my $msgobj = $CELL->msg('TEST_MESSAGE');
ok( blessed($msgobj), "Message object is blessed" );
is( $msgobj->text, 'This is a test message.', 
    "Test message has the right text" );
$msgobj = $CELL->msg( 'NON_EXISTENT_MESSAGE' );
ok( blessed($msgobj), "Message object with undefined code is blessed" );
is( $msgobj->text, 'NON_EXISTENT_MESSAGE', 
    "Non-existent message text the same as non-existent message code" );

$msgobj = $CELL->msg( 'BAR_ARGS_MSG', "FooBar", 2 );
is( $msgobj->text, 'This FooBar message takes 2 arguments.' );

$status = $msgobj->lang('cz');
my $cesky_text = $status->payload->text;
is( $cesky_text, "Tato FooBar zpráva bere 2 argumenty." );

1;
