#!perl
use strict;
use warnings;

use App::CELL 0.133 qw( $CELL $log );
use File::HomeDir;
use File::Spec;
use Log::Any::Adapter ('File', File::Spec->catfile ( 
            File::HomeDir::my_home(), 'tmp', 'CELLdemo.log',
        ) 
    );

print "App::CELL has not been initialized\n" if not $CELL->meta('CELL_META_INIT_STATUS_BOOL');
$CELL->init( appname => 'CELLdemo', debug_mode => 1 );
print "App::CELL has been initialized\n" if $CELL->meta('CELL_META_INIT_STATUS_BOOL');

print "App::CELL supports the following languages: ", @{ $CELL->config( 'CELL_SUPPORTED_LANGUAGES' ) }, "\n";

print "CELL_CORE_SAMPLE: ", $CELL->config('CELL_CORE_SAMPLE'), "\n";
App::CELL::Config::set_site( 'CELL_CORE_SAMPLE', "foobar" );
print "CELL_CORE_SAMPLE: ", $CELL->config('CELL_CORE_SAMPLE'), "\n";
$log->debug( "CELLtest.plx ending" );

__END__

=pod

=head1 NAME

demo.plx - demonstrate how App::CELL might be used

=cut
