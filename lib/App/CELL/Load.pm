# ************************************************************************* 
# Copyright (c) 2014, SUSE LLC
# 
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# 1. Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
# 
# 2. Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
# 
# 3. Neither the name of SUSE LLC nor the names of its contributors may be
# used to endorse or promote products derived from this software without
# specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
# ************************************************************************* 

package App::CELL::Load;

use strict;
use warnings;
use 5.012;

use App::CELL::Config qw( $meta $core $site );
use App::CELL::Log qw( $log );
use App::CELL::Message;
use App::CELL::Status;
use App::CELL::Test qw( cmp_arrays );
use App::CELL::Util qw( stringify_args is_directory_viable );
use Data::Dumper;
use File::Next;
use File::ShareDir;

=head1 NAME

App::CELL::Load -- find and load message files and config files



=head1 VERSION

Version 0.170

=cut

our $VERSION = '0.170';



=head1 SYNOPSIS
 
    use App::CELL::Load;

    # Load App::CELL's internal messages and config params and then
    # attempt to load the application's messages and config params
    $status = App::CELL::Load::init();
    return $status if $status->not_ok;

    # attempt to determine the site configuration directory
    my $sitedir = App::CELL::Load::get_sitedir();

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



=head1 PACKAGE VARIABLES

This module provides the following package variables

=over 

=item C<$sharedir> - the full path of the sharedir

=item C<$sharedir_loaded> - whether it has been loaded or not

=item C<$sitedir> - the full path of the site configuration directory

=item C<$sitedir_loaded> - whether it has been loaded or not

=back

=cut

our $sharedir = '';
our $sharedir_loaded = 0;
our @sitedir = ();
our $sitedir_loaded = 0;


=head1 MODULES

=head2 init

Re-entrant initialization function.

On first call, initializes all three site configuration hashes by
performing the following actions:

=over

=item 1. load App::CELL's internal messages and meta, core, and site
params from the distro share directory determined using File::ShareDir
(i.e. the C<config/> directory of the distro, wherever it happens to be
installed)

=item 2. determine the "site dir" (site configuration directory) by first
looking for a 'sitedir' argument to the function and, failing that,
looking for a 'CELL_SITE
procedure described in ...WIP...

=item 3. if a viable site dir is found, load messages and meta, core, and
site params from it.

=back

Subsequent calls check package variables to determine status of previous
calls. For example, if no sharedir is found, a critical error is raised.
The application could theoretically attempt to fix this and try again. Or,
it might happen that the sharedir is loaded as expected, but the sitedir
is not found, in which case on the second call the initialization
routine would try again to find the sitedir.

Once a directory has been loaded, there is no way to "undo" it, and
L<App::CELL> will not look at that directory again.

Upon success the routine sets the following App::CELL params:

=over

=item C<CELL_META_SHAREDIR_LOADED> - meta param (boolean)

=item C<CELL_SHAREDIR_FULLPATH> - site param (scalar)

=item C<CELL_META_SITEDIR_LOADED> - meta param (boolean)

=item C<CELL_SITEDIR_FULLPATH> - site param (array ref)

=back

Optionally takes a PARAMHASH. The following arguments are recognized:

=over

=item C<appname> - name of the application

=item C<sitedir> - full path to the/a site dir

=back

E.g.: 

    my $status = App::CELL::Load::init( appname => 'FooBar', 
        sitedir => '/etc/FooBar' );

If no sitedir is provided (through either the argument list or the
environment), return status will be 'ok' provided the sharedir was found
and loaded; otherwise, an 'ERR' status is returned.

If a sitedir is provided, yet not successfully loaded, an 'ERR' status will
be returned.

=cut

sub init {
    my @ARGS = @_;

    my $return_status;

    # check for even number of arguments
    return App::CELL::Status->new( 
               level => 'err', 
               code => 'CELL_BAD_PARAMHASH' 
           ) if @ARGS % 2 != 0 ;

    my %ARGS = @ARGS;

    if ( @ARGS ) {
        $log->notice( "Entering App::CELL::Load::init version $VERSION ARGS: " . stringify_args( \%ARGS ) );
    } else {
        $log->notice( "Entering App::CELL::Load::init version $VERSION NO ARGS" );
    }

    # check for taint mode
    if ( ${^TAINT} != 0 ) {
        return App::CELL::Status->new( level => "FATAL",
            code => "Attempt to load while in taint mode (-T)" );
    }

    # look up sharedir
    if ( not $sharedir ) {
        my $tmp_sharedir = File::ShareDir::dist_dir('App-CELL');
        if ( ! is_directory_viable( $tmp_sharedir ) ) {
            return App::CELL::Status->new( 
                level => 'ERR', 
                code => 'CELL_SHAREDIR_NOT_VIABLE',
                args => [ $tmp_sharedir, $App::CELL::Util::not_viable_reason ],
            );
        } 
        $log->info( "Found viable CELL configuration directory " . 
            $tmp_sharedir . " in App::CELL distro" );
        $site->set( 'CELL_SHAREDIR_FULLPATH', $tmp_sharedir );
        $sharedir = $tmp_sharedir;
    }

    # walk sharedir
    if ( $sharedir and not $sharedir_loaded ) {
        my $status = message_files( $sharedir );
        my $load_status = _report_load_status( $sharedir, 'App:CELL distro sharedir', 'messages', $status );
        return $load_status if $load_status->not_ok;
        $status = meta_core_site_files( $sharedir );
        $load_status = _report_load_status( $sharedir, 'App:CELL distro sharedir', 'config params', $status );
        return $load_status if $load_status->not_ok;
        $site->set( 'CELL_SHAREDIR_LOADED', 1 );
        $sharedir_loaded = 1;
    }

    my $sitedir_expected = ( ( $ARGS{sitedir} or $ARGS{enviro} ) ? 1 : 0 );
    if ( $sitedir_expected ) {
        $log->debug( "We are expected to load a sitedir" );
    } else {
        $log->debug( "We are _not_ expected to load a sitedir" );
    }

    if ( @sitedir ) {
        $log->debug( "sitedir package variable contains ->" . 
                     join( ':', @sitedir ) . "<-" );
    } else {
        $log->debug( "sitedir package variable is empty" );
    }

    # look up sitedir
    my $sitedir_candidate;
    if ( $sitedir_expected ) {
        $sitedir_candidate = get_sitedir( %ARGS );
        if ( ! $sitedir_candidate ) {
            my $source = ( $ARGS{sitedir} ? "PARAMHASH" : "environment" );
            return App::CELL::Status->new (
                level => 'ERR',
                code => 'CELL_SITEDIR_NOT_FOUND',
                args => [ $sitedir_candidate, $source ],
            );
        }
    }

    # walk sitedir
    if ( $sitedir_expected and $sitedir_candidate ) {
        my $status = message_files( $sitedir_candidate );
        my $messages_loaded = _report_load_status( $sitedir_candidate, 'site dir', 'messages', $status );
        $status = meta_core_site_files( $sitedir_candidate );
        my $params_loaded = _report_load_status( $sitedir_candidate, 'sitedir', 'config params', $status );
        if ( $messages_loaded->ok or $params_loaded->ok ) {
            $meta->set( 'CELL_META_SITEDIR_LOADED', 
                        ( $meta->CELL_META_SITEDIR_LOADED + 1 ) );
            push @sitedir, $sitedir_candidate;
            $meta->set( 'CELL_META_SITEDIR_LIST', \@sitedir );
        }
    }

    # check that at least sharedir has really been loaded
    SANITY: {
        my $results = [];
        my $status = App::CELL::Message->new( code => 'CELL_LOAD_SANITY_MESSAGE' );
        my $msgobj;

        if ( $status->ok ) {
            $msgobj = $status->payload;
            push @$results, (
                $meta->CELL_LOAD_SANITY_META,
                $core->CELL_LOAD_SANITY_CORE,
                $site->CELL_LOAD_SANITY_SITE,
                $msgobj->text(),
                        );
            my $cmp_arrays_result = cmp_arrays( 
                $results, 
                [ 'Baz', 'Bar', 'Foo', 'This is a sanity testing message' ],
            );
            last SANITY if $cmp_arrays_result;
        }
        return App::CELL::Status->new(
            level => 'ERR',
            code => 'CELL_LOAD_FAILED_SANITY',
        );
    }
        
    $log->debug( "Leaving App::CELL::Load::init" );

    return App::CELL::Status->ok;
}


sub _report_load_status {
    my ( $dir_path, $dir_desc, $what, $status ) = @_;
    my $quantitems = ${ $status->payload }{quantitems} || 0; 
    my $quantfiles = ${ $status->payload }{quantfiles} || 0;
    if ( $quantitems == 0 ) {
        return App::CELL::Status->new(
            level => 'WARN',
            code => 'CELL_DIR_WALKED_NOTHING_FOUND',
            args => [ $dir_desc, $dir_path, $quantfiles, $what ],
            caller => [ caller ],
        );
    } else {
        # trigger a log message: note that we can't use an OK status here
        # because log messages for those are suppressed
        App::CELL::Status->new (
            level => 'NOTICE',
            code => 'CELL_DIR_WALKED_ITEMS_LOADED',
            args => [ $quantitems, $what, $quantfiles, $dir_desc, $dir_path ],
            caller => [ caller ],
        );
        return App::CELL::Status->ok;
    }
}

=head2 message_files

Loads message files from the given directory. Takes: full path to
configuration directory. Returns: result hash containing 'quantfiles'
(total number of files processed) and 'count' (total number of
messages loaded).

=cut

sub message_files {

    my $confdir = shift;
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

    my $confdir = shift;
    my %reshash;
    $reshash{quantfiles} = 0;
    $reshash{quantitems} = 0;

    foreach my $type ( 'meta', 'core', 'site' ) {
        my $fulltype = 'App::CELL::Config::' . $type;
        #$log->debug( "\$fulltype is $fulltype");
        my $file_list = find_files( $type, $confdir );
        foreach my $file ( @$file_list ) {
            no strict 'refs';
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


=head2 get_sitedir

Look in various places (in a pre-defined order) for the site
configuration directory. Stop as soon as we come up with a viable
candidate. On success, returns a string containing an absolute
directory path. On failure, returns undef.

=cut

sub get_sitedir {

    my %paramhash = @_;

    my ( $sitedir, $log_message, $status );
    GET_CANDIDATE_DIR: {

        # look in paramhash for sitedir
        $log->debug( "SITEDIR SEARCH, ROUND 1:" );
        if ( $sitedir = $paramhash{sitedir} ) {
            $log_message = "Viable site directory passed in argument PARAMHASH";
            last GET_CANDIDATE_DIR if is_directory_viable( $sitedir );
            $log->err( "Invalid sitedir ->" . $sitedir .  "<- " . 
                       "(" . $App::CELL::Util::not_viable_reason .  ") " .
                       "passed to App::CELL->init" );
            return; # returns undef in scalar context
        }
        $log->info( "looked at function arguments but they do not contain a literal site dir path" );

        # look in paramhash for name of environment variable
        $log->debug( "SITEDIR SEARCH, ROUND 2:" );
        if ( $paramhash{enviro} ) 
        {
            if ( $sitedir = $ENV{ $paramhash{enviro} } ) {
                $log_message = "Found viable sitedir in " . $paramhash{enviro}
                               . " environment variable";
                last GET_CANDIDATE_DIR if is_directory_viable( $sitedir );
            }
        }
        else 
        {
            if ( $sitedir = $ENV{ 'CELL_SITEDIR' } ) {
                $log_message = "Found viable sitedir in CELL_SITEDIR"
                               . " environment variable";
                last GET_CANDIDATE_DIR if is_directory_viable( $sitedir );
            }
        }
    
        # FAIL
        $log->info( "looked in the environment, but no viable sitedir there, either" );
        return; # returns undef in scalar context
    }

    # SUCCEED
    $log->notice( $log_message );
    return $sitedir;
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

Note that there is a ceiling on the number of files that will be considered
while walking the directory tree. This ceiling is defined in the package
variable C<$max_files> (see below).

=cut

# regular expressions for each file type
our $typeregex = {
       'meta'    => qr/^.+_MetaConfig.pm$/ ,
       'core'    => qr/^.+_Config.pm$/     ,
       'site'    => qr/^.+_SiteConfig.pm$/ ,
       'message' => qr/^.+_Message(_[^_]+){0,1}.conf$/ ,
};

# C<$max_files> puts a limit on how many files we will look at in our directory
# tree walk
our $max_files = 1000;

sub find_files {
    my ( $type, $dirpath ) = @_;

    # re-entrant function
    use feature "state";
    state $resultcache = {};

    # If $dirpath key exists in %resultcache, we are re-entering.
    # In other words, $dirpath has already been walked and all the 
    # filepaths are already in the array stored within %resultcache
    if ( exists ${ $resultcache }{ $dirpath } ) {
        $log->debug( "Re-entering find_files for $dirpath (type '$type')" );
        return ${ $resultcache }{ $dirpath }{ $type };
    } else { # create it
        ${ $resultcache }{ $dirpath } = {  
              'meta' => [],
              'core' => [],
              'site' => [],
              'message' => [],
        };
    }

    # walk the directory (do we need some error checking here?)
    $log->debug( "Preparing to walk $dirpath" );
    my $iter = File::Next::files( $dirpath );

    # while we are walking, go ahead and populate the result cache for _all
    # four_ types (even though we were asked for just one type)
    my $walk_counter = 0;
    ITER_LOOP: while ( defined ( my $file = $iter->() ) ) {
        $log->debug( "Now considering $file" );
        $walk_counter += 1;
        if ( $walk_counter > $max_files ) {
            App::CELL::Status->new ( 
                level => 'ERROR', 
                code => 'Maximum number of configuration file candidates ->%s<- exceeded in %s',
                args => [ $max_files, $dirpath ],
            );
            last ITER_LOOP; # stop looping if there are so many files
        }
        if ( not -r $file ) {
            App::CELL::Status->new ( 
                level => 'WARN', 
                code => 'Load operation passed over file ->%s<- (not readable)',
                args => [ $file ],
            );
            next ITER_LOOP; # jump to next file
        }
        my $counter = 0;
        foreach my $type ( 'meta', 'core', 'site', 'message' ) {
            if ( $file =~ /${ $typeregex }{ $type }/ ) { 
                push @{ ${ $resultcache }{ $dirpath}{ $type } }, $file;
                $counter += 1;
            }
        }
        if ( not $counter ) {
            App::CELL::Status->new ( 
                level => 'WARN', 
                code => 'Load operation passed over file %s (type not recognized)',
                args => [ $file ],
            );
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
    my @ARGS = @_;
    my %ARGS = ( 
                    'File' => undef,
                    'Dest' => undef,
                    @ARGS,
               );

    my $process_stanza_sub = sub {

        # get arguments
        my ( $file, $lang, $stanza, $destref ) = @_;

        # put first token on first line into $code
        my ( $code ) = $stanza->[0] =~ m/^\s*(\S+)/;
        if ( not $code ) {
            $log->info( "ERROR: Could not process stanza ->"
                . join( " ", @$stanza ) . "<- in $file" );
            return 0;
        }

        # The rest of the lines are the message template
        my $text = '';
        foreach ( @$stanza[1 .. $#{ $stanza }] ) {
            chomp;
            $text = $text . " " . $_;
        }
        $text =~ s/^\s+//g;
        $log->debug( "Parsed message CODE ->$code<- LANG ->$lang<- TEXT ->$text<-" );
        if ( $code and $lang and $text ) {
            # we have a candidate, but we don't want to overwrite
            # an existing entry with the same $code-$lang pair
            if ( exists $destref->{ $code }->{ $lang } ) {
                my $existing_text = $destref->{ $code }->{ $lang }->{ 'Text' };
                if ( $existing_text )
                { # it already has a text
                    $log->info( "ERROR: not loading code-lang pair ->$code"
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
    my ( $lang ) = $ARGS{'File'} =~ m/_Message_([^_]+).conf$/;
    if ( not $lang ) {
        $log->info( "Could not determine language from filename "
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
        #$log->debug( "Read line =>$_<= from $ARGS{'File'}" );
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

    #$log->info( "Parsed and loaded $count configuration stanzas "
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

    # This is so we can use the C<$self> variable (in the C<try>
    # statement, below) to reach the C<_conf_from_config> functions from
    # the configuration file.
    my $self = {};
    bless $self, 'App::CELL::Load';

    my $count = 0;
    
    # ideally this should be 'debug' for sharedir and 'info' for sitedir
    # but in this routine I have no easy way of telling one from the other
    $log->debug( "Loading =>$ARGS{'File'}<=" );
    if ( not ref( $ARGS{'Dest'} ) ) {
        $log->info("Something strange happened: " . ref( $ARGS{'Dest'} ));
    }

    {
        use Try::Tiny;
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
           $errmsg =~ s/\012/ -- /g;
           $log->err("CELL_CONFIG_LOAD_FAIL on file $ARGS{File} with error message: $errmsg");
           $log->debug( "The count is $count" );
           return $count;
        };
    }
    #$log->info( "Successfully loaded $count configuration parameters "
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
        $log->warn( "ignoring duplicate definition of config "
                  . "parameter $param in line $line of config file $file" );
        return 0;
    } else {
        $desthash->{ $param } = {
                                    'Value' => $value,
                                    'File'  => $file,
                                    'Line'  => $line,
                                }; 
        $log->debug( "Parsed parameter $param with value ->$value<- " .
                     "from $file, line $line", suppress_caller => 1 );
        return 1;
    } 
}

1;
