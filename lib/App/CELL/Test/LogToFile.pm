package App::CELL::Test::LogToFile;

use strict;
use warnings;
use 5.010;
use Test::More;

BEGIN {
   use File::Temp;
   my $tf;
   use Log::Any::Adapter ('File', $tf = File::Temp->new->filename );
   diag( "Logging to $tf" );
}

1;

__END__

=pod 

=head1 NAME

App::CELL::Test::LogToFile - really activate logging (for use within unit
tests)


=head1 VERSION

Version 0.159

=cut

our $VERSION = '0.159';



=head1 SYNOPSIS

    use App::CELL::Test::LogToFile;



=head1 DESCRIPTION

The C<App::CELL::Test::LogToFile> module provides an easy way to activate
log-to-temporary-file for a given unit test. Just 'use' and be happy. It
would probably work outside of unit tests, too, if it weren't for the call
to C<diag>.

=cut
