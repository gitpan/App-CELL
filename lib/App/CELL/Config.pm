package App::CELL::Config;

use strict;
use warnings;
use 5.010;

use App::CELL::Log qw( $log );
use App::CELL::Status;
#use Data::Dumper;
use Scalar::Util qw( blessed );

=head1 NAME

App::CELL::Config -- load, store, and dispense meta parameters, core
parameters, and site parameters



=head1 VERSION

Version 0.150

=cut

our $VERSION = '0.150';



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
    die "Bad call to Config.pm \$$param at $file line $line!" if not blessed $self;
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


=head2 set

Use this function to set new params (meta/core/site) or change existing
ones (meta only). Takes two arguments: parameter name and new value. 
Returns a status object.

=cut

sub set {
    my ( $self, $param, $value ) = @_;
    return App::CELL::Status->not_ok if not blessed $self;
    my %ARGS = (
                    level => 'OK',
                    caller => [ caller ],
               );
    if ( $self->{'CELL_CONFTYPE'} eq 'meta' ) {
        if ( exists $meta->{$param} ) {
            %ARGS = (   
                        %ARGS,
                        code => 'CELL_OVERWRITE_META_PARAM',
                        args => [ $param, $value ],
                    );
            $log->debug( "Overwriting \$meta->$param with ->$value<-" );
        } else {
            $log->info( "Setting new \$meta->$param to ->$value<-" );
        }
        $meta->{$param} = {
                               'File' => (caller)[1],
                               'Line' => (caller)[2],
                               'Value' => $value,
                          };
        #$log->debug( Dumper $meta );
    } elsif ( $self->{'CELL_CONFTYPE'} eq 'core' ) {
        if ( exists $core->{$param} ) {
            %ARGS = (
                        %ARGS,
                        level => 'ERR',
                        code => 'CELL_PARAM_EXISTS_IMMUTABLE',
                        args => [ 'Core', $param ],
                    );
        } else {
            $core->{$param} = {
                                   'File' => (caller)[1],
                                   'Line' => (caller)[2],
                                   'Value' => $value,
                              };
        }
    } elsif ( $self->{'CELL_CONFTYPE'} eq 'site' ) {
        if ( exists $site->{$param} ) {
            %ARGS = (
                        %ARGS,
                        level => 'ERR',
                        code => 'CELL_PARAM_EXISTS_IMMUTABLE',
                        args => [ 'Site', $param ],
                    );
        } else {
            $site->{$param} = {
                                   'File' => (caller)[1],
                                   'Line' => (caller)[2],
                                   'Value' => $value,
                              };
        }
    }
    return App::CELL::Status->new( %ARGS );
}

# END OF App::CELL::Config MODULE
1;
