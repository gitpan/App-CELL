package App::CELL::Message;

use strict;
use warnings;
use 5.012;

use App::CELL::Config;
use App::CELL::Log qw( $log );
use Data::Dumper;
use Try::Tiny;


=head1 NAME

App::CELL::Message - handle messages the user might see



=head1 VERSION

Version 0.153

=cut

our $VERSION = '0.153';



=head1 SYNOPSIS

    use App::CELL::Message;

    # server messages: pass message code only, message text
    # will be localized to the site default language, if 
    # assertainable, or, failing that, in English
    my $message = App::CELL::Message->new( code => 'FOOBAR' )
    # and then we pass $message as an argument to 
    # App::CELL::Status->new

    # client messages: pass message code and session id,
    # message text will be localized according to the user's language
    # preference setting
    my $message = App::CELL::Message->new( code => 'BARBAZ',
                                          session => $s_obj );
    $msg_to_display = $message->App::CELL::Message->text;

    # a message may call for one or more arguments. If so,
    # include an 'args' hash element in the call to 'new':
    args => [ 'FOO', 'BAR' ]
    # they will be included in the message text via a call to 
    # sprintf



=head1 EXPORTS AND PUBLIC METHODS

This module provides the following public functions and methods:

=over 

=item C<new> - construct a C<App::CELL::Message> object

=item C<text> - get text of an existing object

=item C<max_size> - get maximum size of a given message code

=back

=cut 



=head1 DESCRIPTION

An App::CELL::Message object is a reference to a hash containing some or
all of the following keys (attributes):

=over 

=item C<code> - message code (see below)

=item C<text> - message text

=item C<error> - error (if any) related to this message

=item C<language> - message language (e.g., English)

=item C<max_size> - maximum number of characters this message is
guaranteed not to exceed (and will be truncated to fit into)

=item C<truncated> - boolean value: text has been truncated or not

=back

The information in the hash is sourced from two places: the
C<$mesg> hashref in this module (see L</CONSTANTS>) and the SQL
database. The former is reserved for "system critical" messages, while
the latter contains messages that users will come into contact with on
a daily basis. System messages are English-only; only user messages
are localizable.



=head1 PACKAGE VARIABLES


=head2 C<$mesg>

The C<App::CELL::Message> module stores messages in a package variable, C<$mesg>
(which is a hashref).

=cut 

our $mesg;



=head1 FUNCTIONS AND METHODS


=head2 supported_languages

Get reference to list of supported languages.

=cut

sub supported_languages {
    my $supp_lang = $App::CELL::Config::site->CELL_SUPPORTED_LANGUAGES || [ 'en' ];
    return $supp_lang;
}


=head2 language_supported

Determine if a given language is supported.

=cut

sub language_supported {
    my ( $lang ) = @_;
    return 1 if grep( /$lang/, @{ supported_languages() } );
    return 0;
}


=head2 new
  
Construct a message object. Takes a message code and, optionally, a
reference to an array of arguments. Returns a status object. If the status
is ok, then the message object will be in the payload. See L</SYNOPSIS>.

=cut

sub new {

    my ( $class, %ARGS ) = @_; 
    my $stringified_args = _stringify_args( \%ARGS );
    my $my_caller;

    if ( $ARGS{called_from_status} ) {
        $my_caller = $ARGS{caller};
    } else {
        $my_caller = [ caller ];
    }
   
    if ( not exists( $ARGS{'code'} ) ) {
        return App::CELL::Status->new( level => 'ERR', 
            code => 'CELL_MESSAGE_NO_CODE', 
            args => [ $stringified_args ],
            caller => $my_caller,
        );
    }
    if ( not $ARGS{'code'} ) {
        return App::CELL::Status->new( level => 'ERR', 
            code => 'CELL_MESSAGE_CODE_UNDEFINED',
            args => [ $stringified_args ],
            caller => $my_caller,
        );
    }

    # This next line is important: it may happen that the developer wants
    # to quickly code some messages/statuses without formally assigning
    # codes in the site configuration. In these cases, the $mesg lookup
    # will fail. Instead of throwing an error, we just generate a message
    # text from the value of 'code'.
    my $text = $mesg->
               { $ARGS{code} }->
               { $ARGS{lang} || $App::CELL::Config::site->CELL_LANGUAGE || 'en' }->
               { 'Text' } 
               || $ARGS{code};

    # strip out anything that resembles a newline
    $text =~ s/\n//g;
    $text =~ s/\012/ -- /g;

    # insert the arguments into the message text -- needs to be in an eval
    # block because we have no control over what crap the application
    # programmer might send us
    try { 
        local $SIG{__WARN__} = sub {
            die;
        };
        $ARGS{text} = sprintf( $text, @{ $ARGS{args} || [] } ); 
    }
    catch {
        my $errmsg = $_;
        $errmsg =~ s/\012/ -- /g;
        return App::CELL::Status->new( level => 'ERR',
            code => 'CELL_MESSAGE_ARGUMENT_MISMATCH',
            args => [ $ARGS{code}, $errmsg ],
            caller => $my_caller,
        );
        #my $buffer = $mesg->{ 'CELL_MESSAGE_ARGUMENT_MISMATCH' }->{ 'en' }->{ 'Text' };
        #if ( $buffer ) {
        #    $buffer = sprintf( $buffer, $ARGS{code}, $errmsg );
        #} else {
        #    $buffer = "CELL_MESSAGE_ARGUMENT_MISMATCH on " . $ARGS{code} .
        #              " (sprintf said ->$errmsg<-)";
        #}
        #$log->err( $buffer );
    };

    $log->debug( "Creating message object ->" . $ARGS{code} .  "<-", caller => $my_caller);

    # bless into objecthood
    my $self = bless \%ARGS, 'App::CELL::Message';

    # return ok status with created object in payload
    return App::CELL::Status->new( level => 'OK',
        payload => $self,
    );
}


=head2 lang

Clones the message into another language.

=cut

sub lang {
    my ( $self, $lang ) = @_;
    my $fully_blessed = _stringify_args( $self );
    return $fully_blessed =~ m/\{(.*)\}/
}

=head3 _stringify_args

Convert args into a string for error reporting

=cut

sub _stringify_args {
    local $Data::Dumper::Indent = 0;
    local $Data::Dumper::Terse = 1;
    my $args = shift;
    my $args_as_string;
    if ( %$args ) {
        $args_as_string = Dumper( $args );
    } else {
        $args_as_string = '';
    }
    return $args_as_string;
}


=head2 stringify

Generate a string representation of a message object using Data::Dumper.

=cut

sub stringify {
    local $Data::Dumper::Terse = 1;
    my $self = shift;
    my %u_self = %$self;
    return Dumper( \%u_self );
}

=head2 code

Accessor method for the 'code' attribute.

=cut

sub code {
    my $self = shift;
    return if not $self->{code}; # returns undef in scalar context
    return $self->{code};
}


=head2 args

Accessor method for the 'args' attribute.

=cut

sub args {
    my $self = $_[0];
    return [] if not $self->{args};
    return $self->{args};
}


=head2 text
 
Accessor method for the 'text' attribute. Returns content of 'text'
attribute, or "<NO_TEXT>" if it can't find any content.

=cut

sub text {
    my $self = $_[0];
    return "<NO_TEXT>" if not $self->{text};
    return $self->{text};
}

1;
