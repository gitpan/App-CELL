#!perl -T
use 5.10.0;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Data::Printer;

plan tests => 19;

BEGIN {
    use_ok( 'Carp' );
    use_ok( 'Exporter', qw( import ) );
    use_ok( 'Scalar::Util', qw( blessed ) );

    use_ok( 'Date::Format' );
    use_ok( 'Config::General' );
    use_ok( 'File::HomeDir' );
    use_ok( 'File::ShareDir' );
    use_ok( 'File::Next' );
    use_ok( 'File::Spec' );
    use_ok( 'File::Touch' );
    use_ok( 'Log::Fast' );

    use_ok( 'App::CELL' );
    use_ok( 'App::CELL::Config' );
    use_ok( 'App::CELL::Status' );
    use_ok( 'App::CELL::Load' );
    use_ok( 'App::CELL::Log', qw( log_debug log_info ) );
    use_ok( 'App::CELL::Message' );
    use_ok( 'App::CELL::Util', qw( timestamp ) );
    use_ok( 'App::CELL::Test' );
}

#p( %INC );
#diag( "Testing Carp $Carp::VERSION, Perl $], $^X" );
#diag( "Testing Config::Simple $Config::Simple::VERSION, Perl $], $^X" );
#diag( "Testing CELL $App::CELL::VERSION, Perl $], $^X" );
#diag( "Testing App::CELL::Config $App::CELL::Config::VERSION, Perl $], $^X" );
