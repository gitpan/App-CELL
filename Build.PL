#!/usr/bin/perl
use 5.012000; # CPAN Testers
use strict;
use warnings FATAL => 'all';
use Module::Build 0.37;

my $build = Module::Build->new(
    module_name        => 'App::CELL',
    dist_author        => q{Smithfarm <presnypreklad@gmail.com>},
    dist_version_from  => 'lib/App/CELL.pm',
    license            => 'GPL_3',
    create_license     => 1,
    share_dir          => { 
        dist => [ 'config' ], 
    },
    configure_requires => {
        'Module::Build'      => 0.37,
    },
    build_requires     => { 
        'Data::Dumper'       => 0,
        'Log::Any::Test'     => 0 
    },
    requires           => {
        'Date::Format'       => 0,
        'File::HomeDir'      => 0,
        'File::ShareDir'     => 0,
        'File::Next'         => 0,
        'File::Touch'        => 0,
        'Log::Any'           => 0,
        'perl'               => 5.012000,
        'Try::Tiny'          => 0,
    },
    meta_merge => {
        resources => {
            repository => 'https://sourceforge.net/projects/perl-cell/',
        }
    },
);

$build->create_build_script;
