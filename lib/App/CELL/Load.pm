package App::CELL::Load;

use 5.10.0;
use strict;
use warnings;

use App::CELL::Log qw( log_debug log_info );
use Data::Printer;
use File::Next;

=head1 NAME

App::CELL::Load -- find and load configuration files



=head1 VERSION

Version 0.076

=cut

our $VERSION = '0.076';



=head1 SYNOPSIS
 
    use App::CELL::Load;

    # get a reference to a list of configuration files (full paths) of a
    # given type under the given directory
    my $metafiles = App::CELL::Load::find_files( '/etc/CELL', 'meta' );
   
    # load messages from message file (full path)
    my $count = App::CELL::Load::parse_message_file( File => $msgfile,
                                                     Dest => $msghashref );

    # load config params from configuration file (full path)
    $count = App::CELL::Load::parse_config_file( File => $file,
                                                 Dest => ${ $type } );


=head1 DESCRIPTION

The purpose of the App::CELL::Load module is to provide configuration file
finding and loading functionality to the App::CELL::Config and App::CELL::Message
modules.


=head2 find_files

Takes two arguments: full directory path and config file type.

Always returns an array reference. On "failure", the array reference will
be empty.

How it works: first, the function checks a state variable to see if the
"work" of walking the configuration directory has already been done.  If
so, then the function simply returns the corresponding array reference from
its cache (the state hash C<%resultlist>). If this is the first invocation
for this directory, the function walks the directory (and all its
subdirectories) to find files matching one of the four regular expressions
corresponding to the four types of configuration files('meta', 'core',
'site', 'message'). For each matching file, the full path is pushed onto
the corresponding array in the cache.

Note that only CELL_MAX_CONFIG_FILES will be loaded.
=cut

# regular expressions for each file type
our $typeregex = {
       'meta'    => qr/^.+_MetaConfig.pm$/a ,
       'core'    => qr/^.+_Config.pm$/a     ,
       'site'    => qr/^.+_SiteConfig.pm$/a ,
       'message' => qr/^.+_Message(_[^_]+){0,1}.conf$/a ,
};

# MAX_FILES puts a limit on how many files we will look at in our directory
# tree walk
our $CELL_MAX_CONFIG_FILES = 1000;

sub find_files {
    my ( $type, $dirpath ) = @_;

    # re-entrant function
    use feature "state";
    state $resultcache = {};

    # If $dirpath key exists in %resultcache, we are re-entering.
    # In other words, $dirpath has already been walked and all the 
    # filepaths are already in the array stored within %resultcache
    if ( exists ${ $resultcache }{ $dirpath } ) {
        log_debug( "Re-entering find_files for $dirpath (type '$type')" );
        return ${ $resultcache }{ $dirpath }{ $type };
    } else { # create it
        ${ $resultcache }{ $dirpath } = {  
              'meta' => [],
              'core' => [],
              'site' => [],
              'message' => [],
        };
        log_debug( "Preparing to walk $dirpath" );
    }

    # walk the directory (do we need some error checking here?)
    log_debug( "find_files: directory path is $dirpath" );
    my $iter = File::Next::files( $dirpath );

    # while we are walking, go ahead and populate the result cache for _all
    # four_ types (even though we were asked for just one type)
    my $walk_counter = 0;
    while ( defined ( my $file = $iter->() ) ) {
        $walk_counter += 1;
        if ( $walk_counter > $CELL_MAX_CONFIG_FILES ) {
            App::CELL::Status->new ( level => 'ERROR', code =>
                "Maximum number of configuration file candidates " .
                "($App::CELL::Load::CELL_MAX_CONFIG_FILES) " .
                "exceeded in $dirpath" );
            last; # stop looping if there are so many files
        }
        if ( not -r $file ) {
            App::CELL::Status->new ( level => 'WARN', code => 
                "find_files passed over ->$file<- (not readable)" );
            next; # jump to next file
        }
        my $counter = 0;
        foreach my $type ( 'meta', 'core', 'site', 'message' ) {
            if ( $file =~ /${ $App::CELL::Load::typeregex }{ $type }/ ) { 
                push @{ ${ $resultcache }{ $dirpath}{ $type } }, $file;
                $counter += 1;
            }
        }
        if ( not $counter ) {
            App::CELL::Status->new ( level => 'WARN', code => 
                "find_files passed over ->$file<- (unknown"
                . " file type)" );
        }
    }
    return ${ $resultcache }{ $dirpath }{ $type };
}


=head2 parse_message_file

This function is where message files are parsed. It takes a PARAMHASH
consisting of:

=over

=item C<File> - filename (full path)

=item C<Dest> - hash reference (where to store the message templates).

=back

Returns: number of stanzas successfully parsed and loaded

=cut

sub parse_message_file {
    my %ARGS = ( 
                    'File' => undef,
                    'Dest' => undef,
                    @_,
               );

    sub _process_stanza {

        # get arguments
        my ( $file, $lang, $stanza, $destref ) = @_;

        # put first token on first line into $code
        my ( $code ) = $stanza->[0] =~ m/^\s*(\S+)/a;
        if ( not $code ) {
            log_info( "ERROR: Could not process stanza ->"
                . join( " ", @$stanza ) . "<- in $file" );
            return 0;
        }
        log_debug( "process_stanza: CODE ->$code<- LANG ->$lang<-");

        # The rest of the lines are the message template
        my $text = '';
        foreach ( @$stanza[1 .. $#{ $stanza }] ) {
            chomp;
            $text = $text . " " . $_;
        }
        $text =~ s/^\s+//g;
        log_debug( "process_stanza: TEXT ->$text<-" );
        if ( $code and $lang and $text ) {
            # we have a candidate, but we don't want to overwrite
            # an existing entry with the same $code-$lang pair
            if ( exists $destref->{ $code }->{ $lang } ) {
                log_info( "ERROR: not loading code-lang pair ->$code"
                    . "/$lang<- with text ->$text<- because this "
                    . "would overwrite existing pair with text ->"
                    . $destref->{ $code }->{ $lang }->{ 'Text' } . "<-" );
            } else {
                $destref->{ $code }->{ $lang } = {
                                     'Text' => $text,
                                     'File' => $file,
                                                 }; 
                return 1;
            }
        }
        return 0;
    }

    # determine language from file name
    my ( $lang ) = $ARGS{'File'} =~ m/_Message_([^_]+).conf$/a;
    if ( not $lang ) {
        log_info( "Could not determine language from filename "
            . "$ARGS{'File'} -- reverting to default language "
            . "->en<-" );
        $lang = 'en';
    }

    # open the file for reading
    open( my $fh, "<", $ARGS{'File'} )
                         or die "cannot open < $ARGS{'File'}: $!";

    my @stanza = ();
    my $index = 0;
    my $count = 0;
    while ( <$fh> ) {
        chomp( $_ );
        #log_debug( "Read line =>$_<= from $ARGS{'File'}" );
        if ( $_ ) { 
            if ( ! /^\s*#/ ) {
                s/^\s*//g;
                s/\s*$//g;
                $stanza[ $index++ ] = $_; 
            }
        } else {
            $count += _process_stanza( $ARGS{'File'}, $lang, \@stanza, 
                                       $ARGS{'Dest'} ) if @stanza;
            @stanza = ();
            $index = 0;
        }
    }
    # There might be one stanza left at the end
    $count += _process_stanza( $ARGS{'File'}, $lang, \@stanza, 
                               $ARGS{'Dest'} ) if @stanza;

    close $fh;

    #log_info( "Parsed and loaded $count configuration stanzas "
    #          . "from $ARGS{'File'}" );
    #p( %{ $ARGS{'Dest'} } );
    
    return $count;
};


=head2 parse_config_file

Parses a configuration file and adds the parameters found to the hashref
provided. If a parameter already exists in the hashref, a warning is
generated, the existing parameter is not overwritten, and processing
continues. 

This function doesn't care what type of configuration parameters
are in the file, except that they must be scalar values. Since the
configuration files are actually Perl modules, the value can even be
a reference (to an array, a hash, or a subroutine, or any other complex
data structure).

The technique used in the C<eval>, derived from Request Tracker, can be
described as follows: a local typeglob "set" is defined, containing a
reference to an anonymous subroutine. Subsequently, a config file (Perl
module) consisting of calls to this "set" subroutine is C<require>d.

Note: If even one call to C<set> fails to compile, the entire file will be
rejected and no configuration parameters from that file will be loaded.

The C<parse_config_file> function takes a PARAMHASH consisting of:

=over

=item C<File> - filename (full path)

=item C<Dest> - hash reference (where to store the config params).

=back

Returns: number of configuration parameters parsed/loaded

(IMPORTANT NOTE: If even one call to C<set> fails to compile, the entire
file will be rejected and no configuration parameters from that file will
be loaded.)

=cut

sub parse_config_file {
    my %ARGS = ( 
                    'File' => undef,
                    'Dest' => undef,
                    @_,
               );

    # This is so we can use the C<$self> variable (in the C<eval>
    # statement, below) to reach the C<_conf_from_config> functions from
    # the configuration file.
    my $self = {};
    bless $self;

    my $count = 0;
    log_info( "Loading =>$ARGS{'File'}<=" );
    if (not defined $ARGS{'Dest'}) {
        log_info("Something strange happened");
    }
    eval {
        local *set = sub($$) {
            my ( $param, $value ) = @_;
            my ( undef, $file, $line ) = caller;
            $count += $self->_conf_from_config(
                'Dest'  => $ARGS{'Dest'},
                'Param' => $param,
                'Value' => $value,
                'File'  => $file,
                'Line'  => $line,
            );
        };
        require $ARGS{'File'};
    };
    if ( $@ ) {
        $@ =~ s/\o{12}/ -- /ag;
        log_debug( $@ );
        App::CELL::Status->new( level => 'ERR',
                                      code => 'SITECONF_LOAD_FAIL',
                                      args => [ $ARGS{'File'}, $@ ], );
        log_debug( "The count is $count" );
        return $count;
    }
    #log_info( "Successfully loaded $count configuration parameters "
    #          . "from $ARGS{'File'}" );

    return $count;
}


=head2 _conf_from_config

This function takes a target hashref (which points to one of the 'meta',
'core', or 'site' package hashes in C<App::CELL::Config>), a config parameter
(i.e. a string), config value, config file name, and line number.

Let's imagine that the configuration parameter is "FOO_BAR". The function
first checks if a key named "FOO_BAR" already exists in the package hash
(which is passed into the function as C<%ARGS{'Dest'}>). If there isn't
one, it creates that key. If there is one, it leaves it untouched and
triggers a warning.

Although the arguments are passed to the function in the form of a
PARAMHASH, the function converts them into ordinary private variables.
This was necessary to avoid extreme notational ugliness.

=cut

sub _conf_from_config {
    my $self = shift;
    # convert PARAMHASH into private variables
    my ( undef,  $desthash,   # $ARGS{'Dest'}
         undef,  $param   ,   # $ARGS{'Param'}
         undef,  $value   ,   # $ARGS{'Value'}
         undef,  $file    ,   # $ARGS{'File'}
         undef,  $line    ,   # $ARGS{'Line'}
       ) = @_;

    if ( keys( %{ $desthash->{ $param } } ) ) 
    {
        App::CELL::Log::arbitrary( 'WARN', "ignoring duplicate definition of config "
                  . "parameter $param in line $line of config file $file" );
        return 0;
    } else {
        $desthash->{ $param } = {
                                    'Value' => $value,
                                    'File'  => $file,
                                    'Line'  => $line,
                                }; 
        return 1;
    } 
}

1;
