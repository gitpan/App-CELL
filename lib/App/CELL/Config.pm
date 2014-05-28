package App::CELL::Config;

use strict;
use warnings;
use 5.010;

use App::CELL::Log qw( $log );
use App::CELL::Status;

=head1 NAME

App::CELL::Config -- load, store, and dispense meta parameters, core
parameters, and site parameters



=head1 VERSION

Version 0.142

=cut

our $VERSION = '0.142';



=head1 SYNOPSIS
 
    use App::CELL::Config qw( $meta $core $site );

    # get a parameter value (returns value or undef)
    my $value;
    $value = $meta->MY_PARAM;
    $value = $core->MY_PARAM;
    $value = $site->MY_PARAM;

    # set a meta parameter
    $meta->set( 'MY_PARAM', 42 );

    # set an as-yet undefined core/site parameter
    $core->set( 'MY_PARAM', 42 );
    $site->set( 'MY_PARAM', 42 );



=head1 DESCRIPTION

The purpose of the L<App::CELL::Config> module is to maintain and provide
access to three package variables, C<$meta>, C<$core>, and C<$site>, which
are actually singleton objects, containing configuration parameters loaded
by L<App::CELL::Load> from files in the distro sharedir and the site
configuration directory, if any.

For details, read L<App::CELL::Guilde>.



=head1 EXPORTS

This module exports three scalars: the 'singleton' objects C<$meta>,
C<$core>, and C<$site>.

=cut

use Exporter qw( import );
our @EXPORT_OK = qw( $meta $core $site );

our $meta = bless { CELL_CONFTYPE => 'meta' }, __PACKAGE__;
our $core = bless { CELL_CONFTYPE => 'core' }, __PACKAGE__;
our $site = bless { CELL_CONFTYPE => 'site' }, __PACKAGE__;



=head1 AUTOLOAD ROUTINE

The C<AUTOLOAD> routine handles calls that look like this:
   $meta->MY_PARAM
   $core->MY_PARAM
   $site->MY_PARAM

=cut

our $AUTOLOAD;
sub AUTOLOAD {
    my $self = shift;
    ( my $param ) = $AUTOLOAD =~ m/.*::(.*)$/;
    my ( $throwaway, $file, $line ) = caller;
    $log->fatal( "Bad call to Config.pm \$$param at $file line $line!" ) if not ref $self;
    if ( $self->{'CELL_CONFTYPE'} eq 'meta' ) {
        return $meta->{$param}->{Value} if exists $meta->{$param};
    } elsif ( $self->{'CELL_CONFTYPE'} eq 'core' ) {
        return $core->{$param}->{Value} if exists $core->{$param};
    } else {
        return $site->{$param}->{Value} if defined $site->{$param};
    }
    return $core->{$param}->{Value} if defined $core->{$param};
    return;
}


=head2 set_meta

By definition, meta parameters are mutable. Use this function to set or
change them. Takes two arguments: parameter name and new value. If the
parameter didn't exist before, it will be created. Returns 'ok' status
object.

TO_DO: check value to make sure it's a scalar.

=cut

sub set_meta {
    my ( $param, $value ) = @_;
    if ( exists $meta->{$param} ) {
        App::CELL::Status->new(
            level => 'NOTICE',
            code => 'CELL_OVERWRITE_META_PARAM',
            args => [ $param, $value ],
            caller => [ caller ],
        );
    } else {
        $log->info( "Setting meta parameter $param for the first time" );
    }
    $meta->{$param} = {
           'File' => '<INTERNAL>',
           'Line' => 0,
           'Value' => $value,
    };
    return App::CELL::Status->ok;
}


=head2 set_core

Sets core parameter, provided it doesn't already exist. Wrapper.

=cut

sub set_core {
    my ( $param, $value ) = @_;
    return _set_core_site( 'core', $param, $value );
}


=head2 set_site

Sets site parameter, provided it doesn't already exist. Wrapper.

=cut

sub set_site {
    my ( $param, $value ) = @_;
    return _set_core_site( 'site', $param, $value );
}


=head3 _set_core_site

Core and site parameters are immutable. This function can be used to set
them, provided they don't already exist. Takes three arguments: param type,
param name and new value. If the parameter didn't exist before, it will be
created.  Returns 'ok' status object on success, or error object on
failure.

=cut

sub _set_core_site {
    no strict 'refs';   # valid throughout the subroutine
    my ( $type, $param, $value ) = @_;
    #if ( $type eq "core" and exists $core->{$param} ) {
    if ( exists $$type->{$param} ) {
        return App::CELL::Status->new( level => 'ERR', 
            code => 'CELL_CORE_PARAM_EXISTS_IMMUTABLE',
            args => [ $param ],
        );
    } else {
        $log->info( "Setting $type parameter $param" );
        $$type->{$param} = {
           'File' => '<INTERNAL>',
           'Line' => 0,
           'Value' => $value,
        };
        return App::CELL::Status->ok;
    }
}

# END OF App::CELL::Config MODULE
1;
