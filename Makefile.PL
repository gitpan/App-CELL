use 5.10.0;
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
    MIN_PERL_VERSION => 5.10.0,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        #'ABC'              => 1.6,
        #'Foo::Bar::Module' => 5.0401,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'CELL-*' },
);

package MY;
use File::ShareDir::Install qw(postamble);

