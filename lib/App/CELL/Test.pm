package App::CELL::Test;

use strict;
use warnings;
use 5.010;

use App::CELL::Log qw( $log );
use File::Spec;

=head1 NAME

App::CELL::Test - functions for unit testing 


=head1 VERSION

Version 0.142

=cut

our $VERSION = '0.142';



=head1 SYNOPSIS

    use App::CELL::Test;

    App::CELL::Test::cleartmpdir();
    my $tmpdir = App::CELL::Test::mktmpdir();
    App::CELL::Test::touch_files( $tmpdir, 'foo', 'bar', 'baz' );
    my $booltrue = App::CELL::Test::cmp_arrays(
        [ 0, 1, 2 ], [ 0, 1, 2 ]
    );
    my $boolfalse = App::CELL::Test::cmp_arrays(
        [ 0, 1, 2 ], [ 'foo', 'bar', 'baz' ]
    );


=head1 DESCRIPTION

The C<App::CELL::Test> module provides a number of special-purpose functions for
use in CELL's test suite. 



=head1 EXPORTS

This module provides the following exports:

=over 

=item C<cmp_arrays> - cmp_arrays routine

=back

=cut 

use Exporter qw( import );
our @EXPORT_OK = qw( cmp_arrays );



=head1 PACKAGE VARIABLES

=cut

our $app_cell_test_dir_name = 'App-CELLtest';
our $app_cell_test_dir_full = '';



=head1 FUNCTIONS


=head2 mktmpdir

Creates the App::CELL testing directory in the system temporary directory
(e.g. C</tmp>) and returns the path to this directory or "undef" on
failure.

=cut

sub mktmpdir {

    use Try::Tiny;

    $app_cell_test_dir_full = File::Spec->catfile( 
                                  File::Spec->tmpdir, 
                                  $app_cell_test_dir_name,
                              );
    try { 
        mkdir $app_cell_test_dir_full; 
    }
    catch {
        my $errmsg = $_ || '';
        $errmsg =~ s/\n//g;
        $errmsg =~ s/\012/ -- /g;
        $errmsg = "Attempting to create $app_cell_test_dir_full . . . failure: $errmsg";
        $log->debug( $errmsg );
        print STDERR $errmsg, "\n";
        return; # returns undef in scalar context
    };

    $log->debug( "Attempting to create $app_cell_test_dir_full . . . success" );

    return $app_cell_test_dir_full;
}


=head2 cleartmpdir

Wipes (rm -rf) the App::CELL testing directory, if it exists. Returns:

=over

=item C<true> App::CELL testing directory successfully wiped or not there in the first
place

=item C<false> directory still there even after C<rm -rf> attempt

=back

=cut

sub cleartmpdir {
    require ExtUtils::Command;
    return 1 if not -e $app_cell_test_dir_full;
    local $ARGV[0] = $app_cell_test_dir_full;
    ExtUtils::Command::rm_rf();
    return 1 if not -e $app_cell_test_dir_full;
    return 0;
}


=head2 touch_files

"Touch" some files. Takes: directory path and list of files to "touch" in
that directory. Returns number of files successfully touched.

=cut

sub touch_files {

    use Try::Tiny;

    my ( $dirspec, @file_list ) = @_;
    my $count = @file_list;
    try {
        use File::Touch;
        File::Touch::touch( 
            map { File::Spec->catfile( $dirspec, $_ ); }
            @file_list 
        );
    }
    catch {
        my $errmsg = $_;
        $errmsg =~ s/\n//g;
        $errmsg =~ s/\012/ -- /g;
        $errmsg = "Attempting to 'touch' $count files in $dirspec . . . failure: $errmsg";
        $log->debug( $errmsg );
        print STDERR $errmsg, "\n";
        return 0;
    };
    $log->debug( "Attempting to 'touch' $count files in $dirspec . . .  success" );
    return $count;
}


=head2 cmp_arrays

Compare two arrays of unique elements, order doesn't matter. 
Takes: two array references
Returns: true (they have the same elements) or false (they differ).

=cut

sub cmp_arrays {
    my ( $ref1, $ref2 ) = @_;
        
    $log->debug( "cmp_arrays: we were asked to compare two arrays:");
    $log->debug( "ARRAY #1: " . join( ',', @$ref1 ) );
    $log->debug( "ARRAY #2: " . join( ',', @$ref2 ) );

    # convert them into hashes
    my ( %ref1, %ref2 );
    map { $ref1{ $_ } = ''; } @$ref1;
    map { $ref2{ $_ } = ''; } @$ref2;

    # make a copy of ref1
    my %ref1_copy = %ref1;

    # for each element of ref1, if it matches an element in ref2, delete
    # the element from _BOTH_ 
    foreach ( keys( %ref1_copy ) ) {
        if ( exists( $ref2{ $_ } ) ) {
            delete $ref1{ $_ };
            delete $ref2{ $_ };
        }
    }

    # if the two arrays are the same, the number of keys in both hashes should
    # be zero
    $log->debug( "cmp_arrays: after comparison, hash #1 has " . keys( %ref1 )
    . " elements and hash #2 has " . keys ( %ref2 ) . " elements" );
    if ( keys( %ref1 ) == 0 and keys( %ref2 ) == 0 ) {
        return 1;
    } else {
        return 0;
    }
}

1;
