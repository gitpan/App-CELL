package App::CELL::Status;

use strict;
use warnings;
use 5.010;

use App::CELL::Log qw( $log );
use Scalar::Util qw( blessed );



=head1 NAME

App::CELL::Status - class for return value objects



=head1 VERSION

Version 0.143

=cut

our $VERSION = '0.143';



=head1 SYNOPSIS

    use App::CELL::Status;

    # simplest usage
    my $status = App::CELL::Status->ok;
    print "ok" if ( $status->ok );
    $status = App::CELL::Status->not_ok;
    print "NOT ok" if ( $status->not_ok );

    # as a return value: in the caller
    my $status = $XYZ( ... );
    return $status if not $status->ok;  # handle failure
    my $payload = $status->payload;     # handle success

    # just to log something more serious than DEBUG or INFO (see
    # App::CELL::Log for how to log those)
    App::CELL::Status->new( 'WARN', 'Watch out!' );
    App::CELL::Status->new( 'NOTICE', 'Look at this!' );



=head1 INHERITANCE

This module inherits from C<App::CELL::Message>

=cut

use parent qw( App::CELL::Message );



=head1 DESCRIPTION

An App::CELL::Status object is a reference to a hash containing some or
all of the following keys (attributes):

=over 

=item C<level> - the status level (see L</new>, below)

=item C<message> - message explaining the status

=item C<fullpath> - full path to file where the status occurred

=item C<filename> - alternatively, the name of the file where the status occurred

=item C<line> - line number where the status occurred

=back

The typical use cases for this object are:

=over

=item As a return value from a function call

=item To trigger a higher-severity log message

=back

All calls to C<< App::CELL::Status->new >> with a status other than OK
trigger a log message.



=head1 PUBLIC METHODS

This module provides the following public methods:



=head2 new
 
Construct a status object and trigger a log message if the level is
anything other than "OK". Returns the object.

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

=cut

sub new {
    my $class = shift;
    my $self;
    my %ARGS = (
                    # only level is mandatory
                    level    => '<NO_LEVEL>',
                    code     => '<NO_CODE>',
                    @_,
               ); 

    # 'OK' and 'NOT_OK' status objects have an optional payload, but
    # nothing else
    if ( $ARGS{level} ne 'OK' and $ARGS{level} ne 'NOT_OK' )
    {
        # default to ERR level
        if ( not grep { $ARGS{level} eq $_ } @App::CELL::Log::permitted_levels ) {
            $ARGS{level} = 'ERR';
        }

        # if caller array not given, create it
        if ( not exists $ARGS{caller} ) {
            $ARGS{caller} = [ caller ];
        }

        $ARGS{args} = [] if not defined( $ARGS{args} );
        $ARGS{called_from_status} = 1;

        # App::CELL::Message->new returns a status object
        my $status = $class->SUPER::new( %ARGS );
        if ( $status->ok ) {
            my $parent = $status->payload();
            $ARGS{msgobj} = $parent;
            $ARGS{code} = $parent->code;
            $ARGS{text} = $parent->text;
        } else {
            $ARGS{code} = $status->code;
            $ARGS{text} = $status->text;
        }
    }

    # bless into objecthood
    $self = bless \%ARGS, 'App::CELL::Status';

    # Log the message
    $self->log if ( $ARGS{level} ne 'OK' and $ARGS{level} ne 'NOT_OK' );

    # return the created object
    return $self;
}


=head2 log

Write an existing status object to syslog. Takes the object, and logs
it. Always returns true, because we don't want the program to croak just
because syslog is down.

=cut

sub log {
    my $self = shift;
    $log->status_obj( $self );
#    return 1 if $self->{level} eq 'OK'; # don't log 'OK'
#
#    my $level = lc $self->level || 'info';
#    {
#        no strict 'refs';
#        $log->$level( $self->text, caller => [ $self->caller ] );
#    }
#
    return 1;
}


=head2 ok

If the first argument is blessed, assume we're being called as an
instance method: return true if status is OK, false otherwise.

Otherwise, assume we're being called as a class method: return a 
new OK status object with optional payload (optional parameter to the
method call, must be a scalar).

=cut

sub ok {

    my ( $class, $self );

    if ( blessed $_[0] ) {

        # instance method
        $self = $_[0];

        # if it's not an error, it will have status level OK
        return 1 if ( $self->level eq 'OK' );
        # otherwise
        return 0;

    } else { # class method

        # check for payload
        if ( $_[1] ) {
            return App::CELL::Status->new(
                level => 'OK',
                payload => $_[1],
            );
        } else {
            return App::CELL::Status->new( level => 'OK' );
        }
    }
}


=head2 not_ok

If the first argument is blessed, assume we're being called as an
instance method: return true if status is OK, false otherwise.

Otherwise, assume we're being called as a class method: return a 
new non-OK status object with optional payload (optional parameter to the
method call, must be a scalar).

=cut

sub not_ok {

    my ( $arg0, $arg1 ) = @_;

    if ( blessed $arg0 ) 
    { 
        # instance method
        return 1 if ( $arg0->level ne 'OK' );
        return 0;
    } 

    # class method

    # check for payload
    if ( $arg1 ) {
        return App::CELL::Status->new(
            level => 'NOT_OK',
            payload => $_[1],
        );
    }

    # no payload
    return App::CELL::Status->new( level => 'NOT_OK' );
}


=head2 notice

Boolean function, returns true if status object has level 'NOTICE', false
otherwise.

=cut

sub notice {

    my ( $arg0, $arg1 ) = @_;

    if ( blessed $arg0 )
    {
        # instance method - OK
        return 1 if ( $arg0->level eq 'NOTICE' );
    } 
    return 0;
}


=head2 warn

Boolean function, returns true if status object has level 'WARN', false
otherwise.

=cut

sub warn {

    my ( $arg0, $arg1 ) = @_;

    if ( blessed $arg0 )
    {
        # instance method - OK
        return 1 if ( $arg0->level eq 'WARN' );
    } 
    return 0;
}


=head2 err

Boolean function, returns true if status object has level 'ERR', false
otherwise.

=cut

sub err {

    my ( $arg0, $arg1 ) = @_;

    if ( blessed $arg0 )
    {
        # instance method - OK
        return 1 if ( $arg0->level eq 'ERR' );
    } 
    return 0;
}


=head2 level

Accessor method.

=cut

sub level {
    my $self = shift;

    return $self->{level} if exists $self->{level};
    return "<NO_LEVEL>";
}


=head2 text

Accessor method.

=cut

sub text {
    my $self = shift;
    return $self->{text} || $self->msgobj->text() || "<NO_TEXT>";
}


=head2 caller

Accessor method.

=cut

sub caller {
    my $self = shift;
    return @{ $self->{caller} };
}


=head2 payload

When called with no arguments, acts like an accessor method.
When called with a scalar argument, either adds that as the payload or
changes the payload to that.

Generates a warning if an existing payload is changed.

Returns the (new) payload or undef.

=cut

sub payload {
    my $self = $_[0];
    my $new_payload = $_[1];

    if ( defined( $new_payload ) ) {
        $self->{payload} = $new_payload;
    }
    return $self->{payload} if exists $self->{payload};
    return; # returns undef in scalar context
}


=head2 msgobj

Accessor method (returns the parent message object)

=cut

sub msgobj {
    my $self = $_[0];

    return $self->{msgobj} if exists $self->{msgobj};
    return; # returns undef in scalar context
}

1;
