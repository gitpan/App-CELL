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

package App::CELL::Guide;

use strict;
use warnings;
use 5.012;



=head1 NAME

App::CELL::Guide - Introduction to App::CELL (POD-only module)



=head1 VERSION

Version 0.170

=cut

our $VERSION = '0.170';



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



=head1 GENERAL APPROACH

This section presents CELL's approach to each of its four principal
functions: L</Configuration>, L</Error handling>, L<Localization>, and
L<Logging>.


=head2 Approach to configuration

CELL provides the application developer and site administrator with a
straightforward and powerful way to define configuration parameters as
needed by the application. If you are familiar with Request Tracker, you
will know that there is a directory (C</opt/...> by default) which contains
two files, called C<RT_Config.pm> and C<RT_SiteConfig.pm> -- as their names
would indicate, they are actually Perl modules. The former is provided by
the upstream developers and contains all of RT's configuration parameters
and their "factory default" settings. The content of the latter is entirely
up to the RT site administrator and contains only those parameters that
need to be different from the defaults. Parameter settings in
C<RT_SiteConfig.pm>, then, override the defaults set in C<RT_Config.pm>.

L<App::CELL> provides this same functionality in a drop-in Perl module,
with some subtle differences. While RT uses a syntax like this:

   set( 'MY_PARAM', ...arguments...);

where C<...arguments...> is a list of scalar values (as with any Perl
subroutine), L<App::CELL> uses a slightly different format:

   set( 'MY_PARAM', $scalar );

where C<$scalar> can be any scalar value, i.e. including references. 

(Another difference is that L<App::CELL> provides both immutable site
parameters _and_ mutable C<meta> configuration parameters, whereas RT's
meta parameters are only used by RT itself.) For more information on
configuration, see L</Configuration in depth>.


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

    return $CELL->status_err( code => 'Gidget displacement %s out of range',
        args => [ $displacement ],
    );

(Instead of having the error text in the C<code>, it could be placed in a
message file in the sitedir with a code like DISP_OUT_OF_RANGE.) 

On success, C<foo_dis> could return an 'OK' status with the gidget
displacement value in the payload: 

    return $CELL->status_ok( payload => $displacement );

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

For details, see </Localization in depth> and <App::CELL::Message>.


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




=head1 DETAILED SPECIFICATIONS

=head2 Configuration in depth

=head3 Three types of parameters

CELL recognizes three types of configuration parameters: C<meta>, C<core>,
and C<site>. These parameters and their values are loaded from files
prepared and placed in the sitedir in advance.

=head3 Meta parameters

Meta parameters are by definition mutable: the application can change a
meta parameter's value any number of times, and L<App::CELL> will not care.
Initial C<meta> param settings are placed in a file entitled
C<$str_MetaConfig.pm> (where C<$str> is a string free of underscore
characters) in the sitedir. For example, if the application name is FooApp, its
initial C<meta> parameter settings could be contained in a file called
C<FooApp_MetaConfig.pm>. At initialization time, L<App::CELL> looks in
the sitedir for files matching this description, and attempts to load them.
(See L</How configuration files are named>.)

=head3 Core parameters

As in Request Tracker, C<core> paramters have immutable values and are
intended to be used as "factory defaults", set by the developer, that the
site administrator can override by setting site parameters. If the
application is called FooApp, its core configuration settings could be
contained in a file called C<FooApp_Config.pm> located in the sitedir. 
(See L</How configuration files are named> for details.)

=head3 Site parameters

Site parameters are kept separate from core parameters, but are closely
related to them. As far as the application is concerned, there are only
site parameters. How this works is best explained by two examples.

Let C<FOO> be an application that uses L<App::CELL>.

In the first example, core param C<FOO> is set to "Bar" and site param
C<FOO> is I<not> set at all. When the application calls C<< $site->FOO >>
the core parameter value "Bar" is returned.

In the second example, the core param C<FOO> is set to "Bar" and site
param C<FOO> is also set, but to a different value: "Whizzo". In this
scenario, when the application calls C<< $site->FOO >> the site parameter
("Whizzo") value is returned. 

This setup allows the site administrator to customize the application.

Site parameters are set in a file called C<$str_SiteConfig.pm>, where
C<$str> could be the appname.

=head3 Conclusion

How these three types of parameters are defined and used is up to the
application. As far as L<App::CELL> is concerned, they are all optional.

L<App::CELL> itself has its own internal meta, core, and site parameters,
but these are located elsewhere -- in the so-called "sharedir", a directory
that is internal to the L<App::CELL> distro/package. 

All these internal parameters start with C<CELL_> and are stored in the
same namespaces as the application's parameters. That means the application
programmer should avoid using parameters starting with C<CELL_>.

=head2 How configuration is stored

=head3 sitedir

Configuration parameters are placed in specially-named files within a
directory referred to by L<App::CELL> as the "site configuration
directory", or "sitedir". This directory is not a part of the L<App::CELL>
distribution and L<App::CELL> does not create it. Instead, the application
is expected to provide the full path to this directory to CELL's
initialization route, either via an argument to the function call or with
the help of an environment variable. CELL's initialization routine calls
L<App::CELL::Load::init> to do the actual work of walking the directory.

This "sitedir" (site configuration directory) is assumed to be the place
(or a place) where the application can store its configuration information
in the form of C<core>, C<site>, and C<meta> parameters. For
L</LOCALIZATION> purposes, C<message> codes and their corresponding texts
(in one or more languages) can be stored here as well, if desired.

=head3 sharedir

CELL itself has an analogous configuration directory, called the
"sharedir", where it's own internal configuration defaults are stored.
CELL's own core parameters can be overridden by the application's site
params, and in some cases this can even be desirable. For example, the
parameter C<CELL_DEBUG_MODE> can be overridden in the site configuration to
tell CELL to include debug-level messages in the log.

During initialization, CELL walks first the sharedir, and then
the sitedir, looking through those directories and all their
subdirectories for meta, core, site, and message configuration files.

The sharedir is part of the App::CELL distro and CELL's initialization
routine finds it via a call to the C<dist_dir> routine in the
L<File::ShareDir> module.

=head2 How the sitedir is found

The sitedir must be created and populated with configuration files by the
application programmer. Typically, this directory would form part of the
application distro and the site administrator would be expected to make a
site configuration file for parameters that she or he needs or wishes to
set. CELL's initialization routine, C<< $CELL->load >>, looks for the
sitedir using the following simple algorithm:

=over

=item C<sitedir> parameter -- a C<sitedir> parameter containing the
full path to the sitedir can be passed. For portability, the path should be
constructed using L<File::Spec> (e.g. the C<catfile> method) or similar.

=item C<enviro> parameter -- if no valid C<sitedir> parameter is given,
C<< $CELL->load >> looks for a parameter called C<enviro> containing the
name of an environment variable containing the sitedir path.

=item C<CELL_SITEDIR> environment variable -- if no viable sitedir can be
found by consulting the function call parameters, C<load> falls back to 
this hardcoded environment variable.

=back

If the algorithm completes without finding a sitedir, C<< $CELL->load >>
returns a "WARN" status. The application can check for this and call
C<load> again (any number of times). However, once a sitedir has been
identified, it cannot be changed except by terminating the application and
running it again.

For examples of how to call the C<load> routine, see L<App::CELL/SYNOPSIS>.

=head2 How configuration files are named

Once it finds a valid site configuration directory tree, CELL walks it,
looking for files matching one four regular expressions:

=over

=item C<^.+_MetaConfig.pm$> (meta)

=item C<^.+_Config.pm$> (core)

=item C<^.+_SiteConfig.pm$> (site)

=item C<^.+_Message(_[^_]+){0,1}.conf$> (message)

=back

Files with names that don't match any of the above regexes are ignored.
If multiple files match a given regex, all of them will be parsed (loaded).

The syntax of these files is very simple and can be easily deduced by
examining CELL's own configuration files in the sharedir (C<config/> in the
distro). All four types of configuration file are represented there, with
comments.

The configuration files are themselves Perl modules, and Perl is leveraged
to parse them. Values can be any legal scalar value, so references to
arrays, hashes, or subroutines can be used, as well as simple numbers and
strings. For details, see L</SITE CONFIGURATION DIRECTORY>,
L<App::CELL::Config> and L<App::CELL::Load>.

Message file parsing is done by a parsing routine that resides in
L<App::CELL::Load>. For details on the syntax and how the parser works, see
L<LOCALIZATION>.


=head2 Error handling in depth

=head3 STATUS OBJECTS

The most frequent case will be a status code of "OK" with no message (shown
here with optional "payload", which is whatever the function is supposed to
return on success:

    # all green
    return App::CELL::Status->new( level => 'OK',
                                  payload => $my_return_value,
                                );

To ensure this is as simple as possible in cases when no return value
(other than the simple fact of an OK status) is needed, we provide a
special constructor method:

    # all green
    return App::CELL::Status->ok;

In most other cases, we will want the status message to be linked to the
filename and line number where the C<new> method was called. If so, we call
the method like this:

    # relative to me
    App::CELL::Status->new( level => 'ERR', 
                           code => 'CODE1',
                           args => [ 'foo', 'bar' ],
                         );

It is also possible to report the caller's filename and line number:

    # relative to my caller
    App::CELL::Status->new( level => 'ERR', 
                           code => 'CODE1',
                           args => [ 'foo', 'bar' ],
                           caller => [ caller ],
                         );

It is also possible to pass a message object in lieu of C<code> and
C<msg_args> (this could be useful if we already have an appropriate message
on hand):

    # with pre-existing message object
    App::CELL::Status->new( level => 'ERR', 
                           msg_obj => $my_msg;
                         );

Permitted levels are listed in the C<@permitted_levels> package
variable in C<App::CELL::Log>.


=head2 Localization in depth

=head3 Introduction

To an application programmer, localization may seem like a daunting
proposition, and All strings the application displays to users must be replaced
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
variants can be obtained by specifying the C<lang> parameter to
CELL::Message->new. If the C<lang> parameter is not specified, CELL will
always try to use the default language (C<CELL_DEF_LANG> or English if
that parameter has not been set).



=head1 CAVEATS


=head2 Internal parameters

L<App::CELL> stores its own parameters (mostly meta and core, but also one
site param) in a separate directory, but when loaded they end up in the
same namespaces as the application's meta, core, and site parameters.
The names of these internal parameters are always prefixed with C<CELL_>.

Therefore, the application programmer should avoid using parameters
starting with C<CELL_>.


=head2 Mutable and immutable parameters

It is important to realize that, although core parameters can be overriden
by site parameters, internally the values of both are immutable. Although
it is possible to change them by cheating, the 'set' method of C<$core> and
C<$site> will refuse to change the value of an existing core/site parameter.

Therefore, use C<$meta> to store mutable values.


=head2 Taint mode

Since it imports configuration data at runtime from files supplied by the
user, L<App::CELL> should not be run under taint mode. The C<< load >>
routine checks this and will refuse to do anything if running with C<-T>.

To recapitulate: don't run L<App::CELL> in taint mode.


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

