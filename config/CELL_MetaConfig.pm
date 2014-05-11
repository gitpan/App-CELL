#
# App::CELL internal meta configuration parameters
#
# This file is part of the App::CELL distro:
#    https://metacpan.org/pod/App::CELL

# Development takes place here:
#    https://sourceforge.net/projects/perl-cell/
#
# This file contains parameters that are internal to App::CELL. It is not
# meant to be edited by the user.
#

# boolean value whether App::CELL distro sharedir has been loaded
# (defaults to 1 since the param is initialized only when distro sharedir
# is loaded)
set('CELL_META_DISTRO_SHAREDIR_LOADED', 1);

# boolean value whether site config dir has been loaded
set('CELL_META_SITECONF_DIR_LOADED', 0);

# boolean value whether App::CELL has been initialized
set('CELL_META_INIT_STATUS_BOOL', 0);

# date and time when App::CELL was initialized
set('CELL_META_START_DATETIME', '');


