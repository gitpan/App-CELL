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

package App::CELL::Status;

use strict;
use warnings;
use 5.012;

use App::CELL::Log qw( $log );
use App::CELL::Util qw( stringify_args );
use Scalar::Util qw( blessed );



=head1 NAME

App::CELL::Status - class for return value objects



=head1 VERSION

Version 0.180

=cut

our $VERSION = '0.180';



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

=item C<caller> - an array reference containing the three-item list
generated by the C<caller> function

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
anything other than "OK". Always returns a status object. If no level is
specified, the level will be 'ERR'. If no code is given, the code will be 

=cut

sub new {
    my ( $class, @ARGS ) = @_;
    my %ARGS = @ARGS;
    my $self;

    # default to ERR level
    if ( not grep { $ARGS{level} eq $_ } $log->permitted_levels ) {
        $ARGS{level} = 'ERR';
    }

    # if caller array not given, create it
    if ( not $ARGS{caller} ) {
        $ARGS{caller} = [ caller ];
    }

    $ARGS{args} = [] if not defined( $ARGS{args} );
    $ARGS{called_from_status} = 1;

    if ( $ARGS{code} ) {
        # App::CELL::Message->new returns a status object
        my $status = $class->SUPER::new( %ARGS );
        if ( $status->ok ) {
            my $parent = $status->payload;
            $ARGS{msgobj} = $parent;
            $ARGS{code} = $parent->code;
            $ARGS{text} = $parent->text;
        } else {
            $ARGS{code} = $status->code;
            if ( $ARGS{args} ) {
               $ARGS{text} = $status->text . stringify_args( $ARGS{args} );
            } else {
               $ARGS{text} = $status->text;
            }
        }
    }

    # bless into objecthood
    $self = bless \%ARGS, 'App::CELL::Status';

    # Log the message
    $log->status_obj( $self ) if ( $ARGS{level} ne 'OK' and $ARGS{level} ne 'NOT_OK' );

    # return the created object
    return $self;
}


=head2 dump

Dump an existing status object. Takes: PARAMHASH. Parameter 'to' determines
destination, which can be 'string' (default), 'log' or 'fd'.

    # dump object to string
    my $dump_str = $status->dump();
       $dump_str = $status->dump( to => 'string' );
    
    # dump object to log
    $status->dump( to => 'log' );

    # dump object to file descriptor
    $status->dump( fd => STDOUT );
    $status->dump( to => 'fd', fd => STDOUT );

Always returns a true value.

=cut

sub dump {
    my ( $self, %ARGS ) = shift;
    if ( not %ARGS ) {
        $log->status_obj( $self );
    } else {
        if ( exists $ARGS{fd} ) {
            $log->debug( "Future dump-to-fd code goes here" );
        } else {
            $log->debug( "Doing nothing" );
        }
    }

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

    my ( $self, $payload ) = @_;
    my $ARGS = {};

    if ( blessed $self ) 
    { # instance method
        return 1 if ( $self->level eq 'OK' );
        return 0;

    } 
    $ARGS->{level} = 'OK';
    $ARGS->{payload} = $payload if $payload;
    $ARGS->{caller} = [ caller ];
    return bless $ARGS, __PACKAGE__;
}


=head2 not_ok

Similar method to 'ok', except it handles 'NOT_OK' status. 

When called as an instance method, returns a true value if the status level
is anything other than 'OK'. Otherwise false.

When called as a class method, returns a 'NOT_OK' status object.
Optionally, a payload can be supplied as an argument.

=cut

sub not_ok {

    my ( $self, $payload ) = @_;
    my $ARGS = {};

    if ( blessed $self ) 
    { # instance method
        return 1 if $self->{level} ne 'OK';
        return 0;
    } 
    $ARGS->{level} = 'NOT_OK';
    $ARGS->{payload} = $payload if $payload;
    $ARGS->{caller} = [ caller ];
    return bless $ARGS, __PACKAGE__;
}


=head2 level

Accessor method, returns level of status object in ALL-CAPS. All status
objects must have a level attribute.

=cut

sub level { return $_[0]->{level}; }


=head2 code

Accesor method, returns code of status object, or "C<< <NONE> >>" if none
present.

=cut

sub code { return $_[0]->{code} || "<NONE>"; }
    

=head2 text

Accessor method, returns text of status object, or the code if no text
present. If neither code nor text are present, returns "C<< <NONE> >>"

=cut

sub text {
    return $_[0]->{text} if $_[0]->{text};
    return $_[0]->code;
}


=head2 caller

Accessor method. Returns array reference containing output of C<caller>
function associated with this status object, or C<[]> if not present.

=cut

sub caller { return $_[0]->{caller} || []; }


=head2 payload

When called with no arguments, acts like an accessor method.
When called with a scalar argument, either adds that as the payload or
changes the payload to that.

Logs a warning if an existing payload is changed.

Returns the (new) payload or undef.

=cut

sub payload {
    my ( $self, $new_payload ) = @_;
    if ( defined $new_payload ) {
        $log->warn( "Changing payload of status object. Old payload was " . 
                    "->$self->{payload}<-" ) if $self->{payload};
        $self->{payload} = $new_payload;
    }
    return $self->{payload};
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
