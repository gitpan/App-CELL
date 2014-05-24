#!perl
use strict;
use warnings;

use App::CELL;
use App::CELL::Log qw( $log );
use File::Spec;
use Log::Any::Adapter ('File', File::Spec->catfile ( 
            File::HomeDir::home(), 'tmp', 'CELLdemo.log',
        ) 
    );

print "App::CELL has not been initialized\n" if not App::CELL->meta('CELL_META_INIT_STATUS_BOOL');
App::CELL->init( appname => 'CELLdemo' );
print "App::CELL has been initialized\n" if App::CELL->meta('CELL_META_INIT_STATUS_BOOL');

print "App::CELL supports the following languages: ", @{ App::CELL->config( 'CELL_SUPPORTED_LANGUAGES' ) }, "\n";

print "CELL_CORE_UNIT_TESTING: ", App::CELL->config('CELL_CORE_UNIT_TESTING'), "\n";
App::CELL::Config::set_site( 'CELL_CORE_UNIT_TESTING', "foobar" );
print "CELL_CORE_UNIT_TESTING: ", App::CELL->config('CELL_CORE_UNIT_TESTING'), "\n";
