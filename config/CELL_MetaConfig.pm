#
# App::CELL internal meta configuration parameters
#
# This file is part of the App::CELL distro:
#    https://metacpan.org/pod/App::CELL
#
# Development takes place here:
#    https://sourceforge.net/projects/perl-cell/
#
# This file contains parameters that are internal to App::CELL. It can also
# serve as a model for setting up and populating the site configuration
# directory -- see App::CELL::Guide for more information.
#

use strict;
use warnings;

# unique value used by App::CELL::Load->init for sanity check
set('CELL_META_UNIQUE_VALUE', 'uniq');

# boolean value whether App::CELL distro sharedir has been loaded
# (defaults to 1 since the param is initialized only when distro sharedir
# is loaded)
set('CELL_META_SHAREDIR_LOADED', 1);

# boolean value whether site config dir has been loaded
set('CELL_META_SITEDIR_LOADED', 0);

# boolean value whether App::CELL has been initialized
set('CELL_META_INIT_STATUS_BOOL', 0);

# date and time when App::CELL was initialized
set('CELL_META_START_DATETIME', '');

# for unit testing
set( 'CELL_META_UNIT_TESTING', [ 1, 2, 3, 'a', 'b', 'c' ] );

1;
