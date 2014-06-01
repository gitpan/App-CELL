package App::CELL::Util;

use strict;
use warnings;
use 5.012;

use Date::Format;
use App::CELL::Status;

=head1 NAME

App::CELL::Util - generalized, reuseable functions



=head1 VERSION

Version 0.153

=cut

our $VERSION = '0.153';



=head1 SYNOPSIS

    use App::CELL::Util qw( utc_timestamp is_directory_viable );

    # utc_timestamp
    print "UTC time is " . utc_timestamp() . "\n";

    # is_directory_viable
    my $status = is_directory_viable( $dir_foo );
    print "$dir_foo is a viable directory" if $status->ok;
    if ( $status->not_ok ) {
        my $problem = $status->payload;
        print "$dir_foo is not viable because $problem\n";
    }

=cut


=head1 EXPORTS

This module provides the following public functions:

=over 

=item C<utc_timestamp>

=item C<is_directory_viable>

=back

=cut 

use Exporter qw( import );
our @EXPORT_OK = qw( utc_timestamp is_directory_viable );


=head1 FUNCTIONS


=head2 utc_timestamp

=cut

sub utc_timestamp {
   return uc time2str("%Y-%m-%d %H:%M %Z", time, 'GMT');
}


=head2 is_directory_viable

Run viability checks on a directory. Takes: full path to directory. Returns
paramhash containing two keys: 'status' (true/false) and 'problem'
(description of problem).

=cut

sub is_directory_viable {

    my $confdir = shift;
    my $problem = '';

    CRIT_CHECK: {
        if ( not -e $confdir ) {
            $problem = "does not exist";
            last CRIT_CHECK;
        }
        if ( not -d $confdir ) {
            $problem = "exists but not a directory";
            last CRIT_CHECK;
        }
        if ( not -r $confdir or not -x $confdir ) {
            $problem = "directory exists but insufficient permissions";
            last CRIT_CHECK;
        }
    } # CRIT_CHECK

    if ( $problem ) {
        return App::CELL::Status->not_ok( $problem );
    }

    return App::CELL::Status->ok;
}

1;
# END OF App::CELL::Util.pm
