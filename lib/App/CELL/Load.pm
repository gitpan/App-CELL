package App::CELL::Load;

use 5.10.0;
use strict;
use warnings;

use App::CELL::Config;
use App::CELL::Log qw( log_debug log_info );
use App::CELL::Message;
use App::CELL::Status;
use App::CELL::Util qw( is_directory_viable );
use Data::Printer;
use File::Next;
use File::ShareDir;

=head1 NAME

App::CELL::Load -- find and load message files and config files



=head1 VERSION

Version 0.088

=cut

our $VERSION = '0.088';



=head1 SYNOPSIS
 
    use App::CELL::Load;

    # Load App::CELL's internal messages and config params and then
    # attempt to load the application's messages and config params
    $status = App::CELL::Load::init();
    return $status if $status->not_ok;

    # attempt to determine the site configuration directory
    my $siteconfdir = App::CELL::Load::get_siteconfdir();

    # get a reference to a list of configuration files (full paths) of a
    # given type under a given directory
    my $metafiles = App::CELL::Load::find_files( '/etc/CELL', 'meta' );
   
    # load messages from all message file in a given directory and all its
    # subdirectories
    $status = message_files( '/etc/CELL' );

    # load meta, core, and site params from all meta, core, and site
    # configuration files in a given directory and all its subdirectories
    $status = meta_core_site_files( '/etc/CELL' );



=head1 DESCRIPTION

The purpose of the App::CELL::Load module is to provide message and config
file finding and loading functionality to the App::CELL::Message and
App::CELL::Config modules.



=head2 init

Re-entrant initialization function.

On first call, initializes all three site configuration hashes by
performing the following actions:

=over

=item 1. load App::CELL's internal messages and meta, core, and site
params from the distro share directory determined using File::ShareDir

=item 2. look for a site configuration directory by consulting (a) the
environment, (b) C<~/.cell/CELL.conf>, (c) C</etc/sysconfig/perl-CELL>,
(d) C</etc/CELL>. Error exit on fail.

=item 3. load messages and meta, core, and site params from the 
site configuration directory.

=back

Subsequent calls check state variables to determine status of previous
calls. For example, it might happen that the first call only loads the
App::CELL configuration, but not the site configuration, etc.

Sets the following App::CELL site params:

=over

=item C<CELL_META_DISTRO_SHAREDIR_LOADED> - meta param

=item C<CELL_DISTRO_SHAREDIR_FULLPATH> - site param

=item C<CELL_META_SITECONF_DIR_LOADED> - meta param

=item C<CELL_META_SITECONF_DIR_FULLPATH> - site param

=back

Takes: nothing; returns: status object. To be called like this:

    my $status = App::CELL::Load::init();

Return status is ok provided at least the distro sharedir was found and
loaded.

=cut

sub init {

    log_debug( "Entering App::CELL::Load::init" );

    # re-entrant function
    use feature "state";
    state $sharedir = '';
    state $sharedir_loaded = 0;
    state $siteconfdir = '';
    state $siteconfdir_loaded = 0;

    if ( not $sharedir ) {
        my $tmp_sharedir = File::ShareDir::dist_dir('App-CELL');
        my $status = is_directory_viable( $tmp_sharedir );
        if ( $status->not_ok ) {
            return App::CELL::Status->new( level => 'CRIT', 
                code => 'App::CELL distro sharedir ->%s<- is not viable for reason ->%s<-',
                args => [ $tmp_sharedir, $status->payload ],
            );
        } 
        log_info( "Found viable CELL configuration directory " . 
            $tmp_sharedir . " in App::CELL distro" );
        App::CELL::Config::set_site( 'CELL_DISTRO_SHAREDIR_FULLPATH', $tmp_sharedir );
        $sharedir = $tmp_sharedir;
    }

    if ( $sharedir and not $sharedir_loaded ) {
        my $status = message_files( $sharedir );
        _report_load_status( $sharedir, 'App:CELL distro sharedir', 'messages', $status );
        $status = meta_core_site_files( $sharedir );
        _report_load_status( $sharedir, 'App:CELL distro sharedir', 'config params', $status );
        App::CELL::Config::set_meta( 'CELL_META_DISTRO_SHAREDIR_LOADED', 1 );
        $sharedir_loaded = 1;
    }

    if ( not $siteconfdir ) {
        my $tmp_siteconf = get_siteconfdir();
        if ( $tmp_siteconf ) {
            App::CELL::Config::set_site( 'CELL_SITECONF_DIR_FULLPATH', $tmp_siteconf );
            $siteconfdir = $tmp_siteconf;
        } else {
            App::CELL::Status->new (
                level => 'WARN',
                code => 'CELL_SITECONF_DIR_MISSING',
            );
        }
    }

    if ( $siteconfdir and not $siteconfdir_loaded ) {
        my $status = message_files( $siteconfdir );
        _report_load_status( $siteconfdir, 'site conf dir', 'messages', $status );
        $status = meta_core_site_files( $siteconfdir );
        _report_load_status( $siteconfdir, 'site conf dir', 'config params', $status );
        App::CELL::Config::set_meta( 'CELL_META_SITECONF_DIR_LOADED', 1 );
        $siteconfdir_loaded = 1;
    }

    log_debug( "Leaving App::CELL::Load::init" );

    return App::CELL::Status->ok;
}


sub _report_load_status {
    my ( $dir_path, $dir_desc, $what, $status ) = @_;
    my $quantitems = ${ $status->payload }{quantitems} || 0; 
    my $quantfiles = ${ $status->payload }{quantfiles} || 0;
    if ( $quantitems == 0 and $quantfiles == 0 ) {
        App::CELL::Status->new(
            level => 'WARN',
            code => 'Walked %s ->%s<- for %s, but none were loaded',
            args => [ $dir_desc, $dir_path, $what ],
            caller => [ caller ],
        );
    } else {
        App::CELL::Status->new (
            level => 'NOTICE',
            code => "Imported ->%s<- %s from %s files in %s %s",
            args => [ $quantitems, $what, $quantfiles, $dir_desc, $dir_path ],
            caller => [ caller ],
        );
    }
}

=head2 message_files

Loads message files from the given directory. Takes: full path to
configuration directory. Returns: result hash containing 'quantfiles'
(total number of files processed) and 'count' (total number of
messages loaded).

=cut

sub message_files {

    my $confdir = $_[0];
    my %reshash;
    $reshash{quantfiles} = 0;
    $reshash{quantitems} = 0;

    my $file_list = find_files( 'message', $confdir );
    foreach my $file ( @$file_list ) {
        $reshash{quantfiles} += 1;
        $reshash{quantitems} += parse_message_file( 
            File => $file,
            Dest => $App::CELL::Message::mesg,
        );
    }

    return App::CELL::Status->new(
        level => 'OK',
        payload => \%reshash,
    );
}


=head2 meta_core_site_files

Loads meta, core, and site config files from the given directory. Takes:
full path to configuration directory. Returns: result hash containing
'quantfiles' (total number of files processed) and 'count' (total number of
configuration parameters loaded).

=cut

sub meta_core_site_files {

    my $confdir = $_[0];
    my %reshash;
    $reshash{quantfiles} = 0;
    $reshash{quantitems} = 0;

    foreach my $type ( 'meta', 'core', 'site' ) {
        no strict 'refs';
        my $fulltype = 'App::CELL::Config::' . $type;
        log_debug( "\$fulltype is $fulltype");
        my $file_list = find_files( $type, $confdir );
        foreach my $file ( @$file_list ) {
            $reshash{quantfiles} += 1;
            $reshash{quantitems} += parse_config_file( 
                File => $file,
                Dest => $$fulltype,
            );
        }
    }

    return App::CELL::Status->new(
        level => 'OK',
        payload => \%reshash,
    );
}


=head2 get_siteconfdir

Look in various places (in a pre-defined order) for the site
configuration directory. Stop as soon as we come up with a viable
candidate. On success, returns a string containing an absolute
directory path. On failure, returns undef.

=cut

sub get_siteconfdir {

    # re-entrant function
    #use feature "state";
    #state $siteconfdir = '';
    #return $siteconfdir if $siteconfdir;

    # first invocation
    my $siteconfdir;
    my ( $candidate, $log_message, $status );
    GET_CANDIDATE_DIR: {
        # look in the environment 
        if ( $candidate = $ENV{ 'CELL_CONFIGDIR' } ) {
            $log_message = "Found viable CELL configuration directory"
                           . " in environment (CELL_CONFIGDIR)";
            $status = is_directory_viable( $candidate );
            last GET_CANDIDATE_DIR if $status->ok;
        } else {
            log_info( "looking at environment but no indication of "
                      . " App::CELL site configuration directory there" );
        }
    
        # look in the home directory
        my $cellconf = File::Spec->catfile ( 
                                    File::HomeDir::home(), 
                                    '.cell',
                                    'CELL.conf' 
                                           );
        if ( $candidate = _read_siteconfdir_from_file( $cellconf ) ) {
            $log_message = "Found viable CELL configuration directory"
                           . " in ~/.cell/CELL.conf";
            $status = is_directory_viable( $candidate );
            last GET_CANDIDATE_DIR if $status->ok;
        }

        # look in /etc/sysconfig/perl-CELL
        $cellconf = File::Spec->catfile ( 
                                    File::Spec->rootdir(),
                                    'etc',
                                    'sysconfig',
                                    'perl-CELL'
                                        );
        if ( $candidate = _read_siteconfdir_from_file( $cellconf ) ) {
            $log_message = "Found viable CELL configuration directory"
                           . " in /etc/sysconfig/perl-CELL";
            $status = is_directory_viable( $candidate );
            last GET_CANDIDATE_DIR if $status->ok;
        }

        # fall back to /etc/CELL
        $candidate = File::Spec->catfile (
                                    File::Spec->rootdir(),
                                    'etc',
                                    'CELL',
                                         );
        $log_message = "Found viable CELL configuration directory"
                        . " /etc/CELL";
        $status = is_directory_viable( $candidate );
        last GET_CANDIDATE_DIR if $status->ok;
        log_info( "looking at /etc/CELL but it is not viable" );

        # FAIL
        return; # returns undef in scalar context
    }

    # SUCCEED
    log_info( $log_message );
    $siteconfdir = $candidate;
    return $siteconfdir;
}


=head3 _read_siteconfdir_from_file

Takes the full path of what might be a configuration file containing
SITECONF_PATH setting. Returns that setting (which is a possible site conf
directory) on success, undef on failure.

=cut

sub _read_siteconfdir_from_file {
    my $candidate = shift;
    my ( $problem, $siteconfdir );
    log_debug( "_read_siteconfdir_from_file: checking out ->$candidate<-" ); 
    KONTROLA: {
        if ( not -e $candidate ) {
            $problem = "looking at ->$candidate<- but it doesn't exist";
            last KONTROLA;
        }
        if ( not -f $candidate ) {
            $problem = "looking at ->$candidate<- but it's not a file";
            last KONTROLA;
        }
        if ( -z $candidate ) {
            $problem = "looking at ->$candidate<- but it has zero size";
            last KONTROLA;
        }
        if ( not -r $candidate ) {
            $problem = "looking at ->$candidate<- but it's not readable";
            last KONTROLA;
        }

        # now we attempt to import configuration from the candidate
        #log_debug("Attempting to parse cellconf candidate ->$candidate<-" );
        my $conf = Config::General->new( $candidate );
        my %cellconf_hash = $conf->getall;
        #log_debug("Loaded " . keys(%cellconf_hash) . " hash elements" );
        if ( not $cellconf_hash{SITECONF_PATH} ) {
            $problem = "App::CELL found no SITECONF_PATH value in ->$candidate<-";
            last KONTROLA;
        }
        log_info("App::CELL found a SITECONF_PATH value ->" 
                 . $cellconf_hash{'SITECONF_PATH'} . "<- in ->$candidate<-");
        # Config::General doesn't strip quotes
        if ( $cellconf_hash{'SITECONF_PATH'} =~ m/'(?<value>[^']*)'/ ) {
            $cellconf_hash{'SITECONF_PATH'} = $+{'value'};
            log_info("Single quotes stripped from SITECONF_PATH value");
        }
        if ( $cellconf_hash{'SITECONF_PATH'} =~ m/"(?<value>[^"]*)"/ ) {
            $cellconf_hash{'SITECONF_PATH'} = $+{'value'};
            log_info("Double quotes stripped from SITECONF_PATH value");
        }
        log_info( $cellconf_hash{'SITECONF_PATH'} );
        if ( not File::Spec->file_name_is_absolute(
                             $cellconf_hash{'SITECONF_PATH'}) ) {
            $problem = "SITECONF_PATH value is not an absolute path";
            last KONTROLA;
        }
        if ( not -d $cellconf_hash{'SITECONF_PATH'} ) {
            $problem = "SITECONF_PATH value "
                       . $cellconf_hash{'SITECONF_PATH'}
                       . " is not a directory";
            last KONTROLA;
        }

        # we passed all the checks
        $siteconfdir = $cellconf_hash{'SITECONF_PATH'};
    } # KONTROLA

    if ( $problem ) {
        log_info( $problem );
        return; # returns undef in scalar context
    } else {
        App::CELL::Log::arbitrary( 'NOTICE', "SITECONF_PATH candidate is now ->$siteconfdir<-" );
        return $siteconfdir;
    }
}


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
    ITER_LOOP: while ( defined ( my $file = $iter->() ) ) {
        log_debug( "find_files now considering $file" );
        $walk_counter += 1;
        if ( $walk_counter > $CELL_MAX_CONFIG_FILES ) {
            App::CELL::Status->new ( level => 'ERROR', code =>
                "Maximum number of configuration file candidates " .
                "($App::CELL::Load::CELL_MAX_CONFIG_FILES) " .
                "exceeded in $dirpath" );
            last ITER_LOOP; # stop looping if there are so many files
        }
        if ( not -r $file ) {
            App::CELL::Status->new ( level => 'WARN', code => 
                "find_files passed over ->$file<- (not readable)" );
            next ITER_LOOP; # jump to next file
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
    #p( $resultcache );
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

    my $process_stanza_sub = sub {

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
                my $existing_text = $destref->{ $code }->{ $lang }->{ 'Text' };
                if ( $existing_text )
                { # it already has a text
                    log_info( "ERROR: not loading code-lang pair ->$code"
                        . "/$lang<- with text ->$text<- because this would"
                        . " overwrite existing pair with text ->$existing_text<-" );
                } 
                else
                { # it has no text
                    # assign this text to it
                    $destref->{ $code }->{ $lang } = {
                        'Text' => $text,
                        'File' => $file,
                    }; 
                    return 1;
                }
            } else {
                $destref->{ $code }->{ $lang } = {
                    'Text' => $text,
                    'File' => $file,
                }; 
                return 1;
            }
        }
        return 0;
    };

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
        $_ = '' if /^\s+$/;
        if ( $_ ) { 
            if ( ! /^\s*#/ ) {
                s/^\s*//g;
                s/\s*$//g;
                $stanza[ $index++ ] = $_; 
            }
        } else {
            $count += &$process_stanza_sub( $ARGS{'File'}, $lang, \@stanza, 
                          $ARGS{'Dest'} ) if @stanza;
            @stanza = ();
            $index = 0;
        }
    }
    # There might be one stanza left at the end
    $count += &$process_stanza_sub( $ARGS{'File'}, $lang, \@stanza, 
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

    use Try::Tiny;

    my %ARGS = ( 
                    'File' => undef,
                    'Dest' => undef,
                    @_,
               );

    # This is so we can use the C<$self> variable (in the C<eval>
    # statement, below) to reach the C<_conf_from_config> functions from
    # the configuration file.
    my $self = {};
    bless $self, 'App::CELL::Load';

    my $count = 0;
    log_info( "Loading =>$ARGS{'File'}<=" );
    if ( not ref( $ARGS{'Dest'} ) ) {
        log_info("Something strange happened: " . ref( $ARGS{'Dest'} ));
    }
    try {
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
    }
    catch {
       my $errmsg = $_;
       $errmsg =~ s/\o{12}/ -- /ag;
       log_debug( $errmsg );
       App::CELL::Status->new( level => 'ERR',
                                     code => 'CELL_CONFIG_LOAD_FAIL',
                                     args => [ $ARGS{'File'}, $errmsg ], );
       log_debug( "The count is $count" );
       return $count;
    };
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
