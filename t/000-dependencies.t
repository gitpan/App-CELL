#!perl -T
use 5.10.0;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Data::Printer;

plan tests => 25;

BEGIN {

    # CORE modules
    use_ok( 'Carp' );
    use_ok( 'English');
    use_ok( 'Exporter', qw( import ) );
    use_ok( 'ExtUtils::Command' );
    use_ok( 'File::Spec' );
    use_ok( 'Scalar::Util', qw( blessed ) );
    use_ok( 'Test::More' );

    # non-core (CPAN) modules
    use_ok( 'Config::General' );
    use_ok( 'Data::Printer' );
    use_ok( 'Date::Format' );
    use_ok( 'File::HomeDir' );
    use_ok( 'File::ShareDir' );
    use_ok( 'File::Next' );
    use_ok( 'File::Touch' );
    use_ok( 'Log::Any' );
    use_ok( 'Log::Any::Test' );
    use_ok( 'Try::Tiny' );

    # modules in this distro
    use_ok( 'App::CELL' );
    use_ok( 'App::CELL::Config' );
    use_ok( 'App::CELL::Status' );
    use_ok( 'App::CELL::Load' );
    use_ok( 'App::CELL::Log', qw( log_debug log_info ) );
    use_ok( 'App::CELL::Message' );
    use_ok( 'App::CELL::Util', qw( utc_timestamp is_directory_viable ) );
    use_ok( 'App::CELL::Test' );

}

#p( %INC );
#diag( "Testing Carp $Carp::VERSION, Perl $], $^X" );
#diag( "Testing Config::Simple $Config::Simple::VERSION, Perl $], $^X" );
#diag( "Testing CELL $App::CELL::VERSION, Perl $], $^X" );
#diag( "Testing App::CELL::Config $App::CELL::Config::VERSION, Perl $], $^X" );
