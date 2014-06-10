#!/usr/bin/perl
use 5.012000; # CPAN Testers
use strict;
use warnings FATAL => 'all';
use Module::Build 0.37;

my $build = Module::Build->new(
    module_name        => 'App::CELL',
    dist_author        => q{Smithfarm <presnypreklad@gmail.com>},
    dist_version_from  => 'lib/App/CELL.pm',
    license            => 'bsd',
    create_license     => 0,
    create_readme      => 1,
    share_dir          => { 
        dist => [ 'config' ], 
    },
    configure_requires => {
        'Module::Build'      => 0.37,
        'Software::License'  => 0,
    },
    build_requires     => { 
        'Log::Any::Adapter'  => 0,
        'Log::Any::Test'     => 0,
    },
    requires           => {
        'perl'               => 5.012,
        'Date::Format'       => 0,
        'File::HomeDir'      => 0,
        'File::ShareDir'     => 0,
        'File::Next'         => 0,
        'File::Touch'        => 0,
        'Log::Any'           => 0,
        'Try::Tiny'          => 0,
    },
    meta_merge => {
        resources => {
            homepage => 'https://sourceforge.net/projects/perl-cell/',
            repository => 'https://sourceforge.net/p/perl-cell/code/',
        }
    },
    add_to_cleanup     => [ 'App-CELL-*' ],
);

$build->create_build_script;
