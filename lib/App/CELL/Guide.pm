package App::CELL::Guide;

use 5.10.0;
use strict;
use warnings;



=head1 NAME

App::CELL::Guide - Introduction to App::CELL (POD-only module)



=head1 VERSION

Version 0.110

=cut

our $VERSION = '0.110';



=head1 SYNOPSIS

   $ perldoc App::CELL::Guide



=head1 INTRODUCTION

L<App::CELL> is the Configuration, Error-handling, Localization, and
Logging (CELL) framework for applications written in Perl. In the
L</APPROACH> section, this Guide describes the CELL approach to each of
these four areas, separately. Then, in the </RATIONALE> section,
it presents the author's reasons for bundling them together.



=head1 HISTORY

CELL was written by Smithfarm in 2013 and 2014, initially as part of the
Dochazka project [[ link to SourceForge ]]. Due to its generic nature, it
was spun off into a separate project.



=head1 APPROACH

This section presents CELL's approach to each of its four principal
functions: L</Configuration>, L</Error handling>, L<Localization>, and
L<Logging>.


=head2 Configuration

CELL provides the application developer and site administrator with a
straightforward and powerful way to define configuration parameters as
needed by the application. 

Configuration parameters are placed in specially-named files within a
directory referred to by CELL as the "site configuration directory", or
"sitedir". CELL recognizes three types of configuration parameters (and,
hence, three types of configuration files). These three types are called
C<meta>, C<core>, and C<site> parameters, respectively.

The first category, C<meta>, consists of "mutable" parameters -- i.e.
parameters that can be changed by the application program. These are
similar to global/package variables.

C<core> and C<site> are the second and third categories, or "namespaces".
These are used for storing immutable values. Though the values themselves
are read-only, a given parameter FOOBAR can be "changed" by defining its
default value in C<core> and then setting the FOOBAR C<site> parameter to a
different value. In such a case, the C<site> FOOBAR will take precedence
over its C<core> counterpart. 

Since the configuration files themselves are Perl modules, Perl is
leveraged to parse them. Values can be any legal scalar value, so
references to arrays, hashes, or subroutines can be used, as well as simple
numbers and strings. For details, see L</SITE CONFIGURATION DIRECTORY>,
L<App::CELL::Config> and L<App::CELL::Load>.

CELL's configuration logic is inspired by Request Tracker.


=head2 Error handling

To facilitate error handling and make the application's source code easier
to read and understand, or at least mitigate its impenetrability, CELL
provides the L<App::CELL::Status> module, which enables functions in the
application to return status objects if desired.

Status objects have the following principal attributes: C<level>, C<code>,
C<args>, and C<payload>, which are given by the programmer when the status
object is constructed, as well as attributes like C<text>, C<lang>, and
C<caller>, which are derived by CELL. In addition to the attributes,
C<Status.pm> also provides some useful methods for processing status
objects.

In order to signify an error, subroutine C<foo_dis> could for example do
this:

    return $CELL->status(
        level => 'ERR',
        code => 'Gidget displacement %s out of range',
        args => [ $displacement ],
    );

Upon success, C<foo_dis> could return an 'OK' status with the gidgit
displacement value in the payload: 

    return $CELL->ok( $displacement );

The calling function could check the return value like this:

    my $status = foo_dis();
    return $status if $status->not_ok;
    my $displacement = $status->payload;
    
For details, see L<App::CELL::Status> and L<App::CELL::Message>.

CELL's error-handling logic is inspired by brian d foy's article "Return
error objects instead of throwing exceptions"

    L<http://www.effectiveperlprogramming.com/2011/10/return-error-objects-instead-of-throwing-exceptions/>


=head2 Localization

This CELL component, called "Localization", gives the programmer a way to
encapsulate a "message" (in its simplest form, a string) within a message
object and then use that object in various ways.

So, provided the necessary message files have been loaded, the programmer
could do this:

    my $message = $CELL->message( code => 'FOOBAR' );
    print $message->text, '\n'; # message FOOBAR in the default language
    print $message->text( lang => 'de' ) # same message, in German

Messages are loaded when CELL is initialized, from files in the site
configuration directory. Each file contains messages in a particular
language. For example, the file C<Dochazka_Message_en.conf> contains
messages relating to the Dochazka application, in the English language. To
provide the same messages in German, the file would be copied to
C<Dochazka_Message_de.conf> and translated.

Since message objects are used by L<App::CELL::Status>, it is natural for
the programmer to put error messages, warnings, etc. in message files and
refer to them by their codes.

C<App::CELL::Message> could also be extended to provide methods for
encrypting messages and/or converting them into various target formats
(JSON, HTML, Morse code, etc.).

For details, see </MESSAGE CONFIGURATION> and <App::CELL::Message>.


=head2 Logging

For logging, CELL uses L<Log::Any> and optionally extends it by adding
the caller's filename and line number to each message logged. 

Message and status objects have 'log' methods, of course, and by default
all statuses (except 'OK') are logged upon creation.

Here's how to set up (and do) logging in the application:

    use App::CELL::Log qw( $log );
    $log->init( ident => 'AppFoo' );
    $log->debug( "Three lines into AppFoo" );

L<App::CELL::Log> provides its own singleton, but since all method calls
are passed to L<Log::Any>, anyway, the L<App::CELL::Log> singleton behaves
just like its L<Log::Any> counterpart. This is useful, e.g., for testing
log messages:

    use Log::Any::Test;
    $log->contains_only_ok( "Three lines into AppFoo" );

To actually see your log messages, you have to do something like this:

    use Log::Any::Adapter ('File', $ENV{'HOME'} . '/tmp/CELLtest.log');



=head1 SITE CONFIGURATION DIRECTORY

=head2 Two directories

The site configuration directory, or "sitedir", is where all the
application's configuration information (C<core>, C<site>, and C<meta>
parameters; C<message> codes and texts) is stored.

CELL itself has an analogous configuration directory, called the
"sharedir", where it's own internal configuration defaults are stored.
CELL's core parameters can be overridden by the application's site params.

During initialization, CELL recursively walks first the sharedir, and then
the sitedir, looking through those directories and all their
subdirectories for meta, core, site, and message configuration files.

The sharedir is part of the App::CELL distro and CELL's initialization
routine finds it via a call to the C<dist_dir> routine in the
L<File::ShareDir> module.

=head2 How CELL finds it

The sitedir must be created and populated with configuration files by the
site administrator. CELL's initialization routine finds it by looking in
three places:

=over

=item C<sitedir> parameter -- the initialization route, C<< $CELL->init >>,
takes a C<sitedir> parameter containing the full path to the sitedir. For
portability, the path should be constructed using L<File::Spec> (e.g. the
C<catfile> method) or similar.

=item C<enviro> parameter -- if no valid C<sitedir> paramter is given,
C<init> looks for a parameter called C<enviro> containing the name of an
environment variable containing the sitedir path.

=item C<CELL_SITEDIR> environment variable -- if no viable sitedir can be
found by consulting the function call parameters, C<init> looks in this
literal environment variable

=back

For examples of how to call the C<init> routine, see C<App::CELL>.

=head2 How to populate it

Once it finds a valid site configuration directory tree, CELL walks it,
looking for files matching one four regular expressions:

=over

=item C<^.+_MetaConfig.pm$> (meta)

=item C<^.+_Config.pm$> (core)

=item C<^.+_SiteConfig.pm$> (site)

=item C<^.+_Message(_[^_]+){0,1}.conf$> (message)

=back

Files with names that don't match any of the above regexes are ignored.

For the syntax of these files see CELL's own configuration files in the
sharedir (C<config/> in the distro). All four types of configuration file
are represented there, with comments.


=head1 MESSAGE CONFIGURATION

=for comment
Old verbiage -- revisit.

=head2 Introduction

To an application programmer, localization may seem like a daunting
proposition. All strings the application displays to users must be replaced
by variable names. Then you have to figure out where to put all the
strings, translate them into multiple languages, write a library (or find
an existing one) to display the right string in the right language at the
right time and place. What is more, the application must be configurable,
so the language can be changed by the user or the site administrator.

All of this is a lot of work, particularly for already existing,
non-localized applications, but even for new applications designed from the
start to be localizable.

App::CELL's objective is to provide a simple, straightforward way
to write and maintain localizable applications in Perl. Notice the key word
"localizable" -- the application may not, and most likely will not, be
localized in the initial stages of development, but that is the time when
localization-related design decisions need to be made. App::CELL tries to
take some of the guesswork out of those decisions.

Later, when it really is time for the application to be translated
into one or more additional languages, this becomes a relatively simple
matter of translating a bunch of text strings that are grouped together in
one or more configuration files with syntax so trivial that no technical
expertise is needed to work with them. (Often, the person translating the
application is not herself technically inclined.)

=head2 Localization with App::CELL

All strings that may potentially need be localized (even if we don't have
them translated into other languages yet) are placed in message files under
the site configuration directory. In order to be found and parsed by
App::CELL, message files must meet some basic conditions:

=over

=item 1. file name format: C<AppName_Message_lang.conf>

=item 2. file location: anywhere under the site configuration directory

=item 3. file contents: must be parsable

=back

=head3 Format of message file names

At initialization time, App::CELL walks the site configuration directory
tree looking for filenames that meet certain regular expressions. The
regular expression for message files is:

    ^.+_Message(_[^_]+){0,1}.conf$

In less-precise human terms, this means that the initialization routine
looks for filenames consisting of at least three, but possibly four,
components:

=over

=item 1. the application name (this can be anything)

=item 2. followed by C<_Message>

=item 3. optionally followed by C<_languagetag> where "languagetag" is a
language tag (see L</..link..> for details)

=item 4. ending in C<.conf>

=back

Examples:

    CELL_Message.conf
    CELL_Message_en.conf
    CELL_Message_cs-CZ.conf
    DifferentApplication_Message.conf


=head3 Location of message files

As noted above, message files will be found as long as they are readable
and located anywhere under the base site configuration directory. For
details on how this base site configuration directory is searched for and
determined, see L</..link..>. 


=head3 How message files are parsed

Message files are parsed line-by-line. The parser routine is
C<parse_message_file> in the C<CELL::Load> module. Lines beginning with a
hash sign ('#') are ignored. The remaining lines are divided into
"stanzas", which must be separated by one or more blank lines.

Stanzas are interpreted as follows: the first line of the stanza should
contain a message code, which is simply a string. Any legal Perl scalar
value can be used, as long as it doesn't contain white space. CELL itself
uses ALL_CAPS strings starting with C<CELL_>.

The remaining lines of the stanza are assumed to be the message text. Two
caveats here:

=over

=item 1. In the configuration file, message text strings can be written on
multiple lines

=item 2. However, this is intended purely as a convenience for the
application programmer. When C<parse_message_file> encounters multiple
lines of text, it simply concatenated them together to form a single, long
string.

=back

For details, see the C<parse_message_file> function in C<App::CELL::Load>,
as well as App::CELL's own message file(s) in C<config/CELL> directory of
the App::CELL distro.

=head2 How the language is determined

Internally, each message text string is stored along with a language tag, which
defines which language the message text is written in. The language tag is
derived from the filename using a regular expression like this one:

    _Message_([^_]+).conf$

(The part in parentheses signifies the part between C<_Message_> and
C<.conf> -- this is stored in the C<language> attribute of the message
object.)

No sanity checks are conducted on the language tag. Whatever string
the regular expression produces becomes the language tag for all
messages in that file. If no language tag is found, CELL first looks for a
config parameter called C<CELL_DEFAULT_LANGUAGE> and, failing that, the
hard-coded fallback value is C<en>.

I'll repeat that, since it's important: CELL assumes that the message
file names contain the relevant language tag. If the message
file name is C<MyApp_Message_foo-bar.conf>, then CELL will tag all
messages in that file as being in the C<foo-bar> language. Message files
can also be named like this: C<MyApp_Message.conf>, i.e. without a language
tag. In this case, CELL will attempt to determine the default language from
a site configuration parameter (C<CELL_DEFAULT_LANGUAGE>). If this
parameter is not set, then CELL will give up and assume that all message
text strings are in English (language tag C<en> -- CELL's
author's native tongue).

=head2 Language tags in general

See the W3C's "Language tags in HTML and XML" white paper for a
detailed explanation of language tags:

    L<http://www.w3.org/International/articles/language-tags/>

And see here for list of all language tags:

    L<http://www.langtag.net/registries/lsr-language.txt>

Note that you should use hyphens, and not underscores, to separate
components within the language tag, i.e.:

    MyApp_Message_cs-CZ.conf   # correct
    MyApp_Message_cs_CZ.conf   # WRONG!!

Non-ASCII characters in config/message file names: may or may not work.
Better to avoid them.

=head2 Normal usage

In normal usage, the programmer adds messages to the respective
message files. After CELL initialization, these messages (or, more
precisely, message code-language pairs) will be available to the
programmer to use, either directly via CELL::Message->new or
indirectly as status codes.

If a message code has text strings in multiple languages, these language
variants can be obtained by specifying the C<Lang> parameter to
CELL::Message->new. If the C<Lang> parameter is not specified, CELL will
always try to use the default language (C<CELL_DEFAULT_LANGUAGE> or English if
that parameter has not been set).


=head1 COMPONENTS


=head2 L<App::CELL>

This top-level module exports a singleton, C<$CELL>, which is all the
application programmer needs to gain access to the CELL's key functions.


=head2 C<App::CELL::Config>

This module provides CELL's Configuration functionality.


=head2 C<App::CELL::Guide>

This guide.


=head2 C<App::CELL::Load>

This module hides all the complexity of loading messages and config params
from files in two directories: (1) the App::CELL distro sharedir containing
App::CELL's own configuration, and (2) the site configuration directory, if
present.


=head2 C<App::CELL::Log>

Logging is accomplished by using and extending L<Log::Any>.


=head2 C<App::CELL::Message>

Localization is on the wish-list of many software projects. With CELL,
the programmer can easily design and write my application to be localizable
from the very beginning, without having to invest much effort.


=head2 C<App::CELL::Status>

Provides CELL's error-handling functionality. Since status objects inherit
from message objects, the application programmer can instruct CELL to
generate localized status messages (errors, warnings, notices) if desired.


=head2 C<App::CELL::Test>

Some routines used by CELL's test suite.


=head2 C<App::CELL::Util>

Some generalized utility routines.



=head1 RATIONALE

In the author's experience, applications written for "users" (however that
term may be defined) frequently need to:

=over

=item 1. be configurable by the user or site administrator

=item 2. handle errors robustly, without hangs and crashes

=item 3. potentially display messages in various languages

=item 4. log various types of messages to syslog

=back

Since these basic functions seem to work well together, CELL is designed to
provide them in an integrated, well-documented, straightforward, and
reusable package.

=cut

1;

