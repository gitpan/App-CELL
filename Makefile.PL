use 5.014001;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;
use File::ShareDir::Install;

install_share 'config';

WriteMakefile(
    NAME             => 'App::CELL',
    AUTHOR           => q{Smithfarm <presnypreklad@gmail.com>},
    VERSION_FROM     => 'lib/App/CELL.pm',
    ABSTRACT_FROM    => 'lib/App/CELL.pm',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.014001,
    CONFIGURE_REQUIRES => {
        'File::ShareDir::Install' => 0,
    },
    BUILD_REQUIRES => {
        'Data::Printer'      => 0,
        'Log::Any::Test'     => 0,
    },
    PREREQ_PM => {
        'Date::Format'       => 0,
        'File::HomeDir'      => 0,
        'File::ShareDir'     => 0,
        'File::Next'         => 0,
        'File::Touch'        => 0,
        'Log::Any'           => 0,
        'Try::Tiny'          => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'CELL-*' },
);

package MY;
use File::ShareDir::Install qw(postamble);

