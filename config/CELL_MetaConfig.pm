#-------------------------------------------------------------#
# CELL_MetaConfig.pm
#
# App::CELL's own site configuration parameters. This file
# is stored in the "distro sharedir" and is always loaded 
# before the files in the application sitedir.
#
# In addition to being used by App::CELL, the files in the
# distro sharedir (CELL_MetaConfig.pm, CELL_Config.pm, and
# CELL_SiteConfig.pm along with CELL_Message_en.conf,
# CELL_Message_cz.conf, etc.) can be used as models for 
# populating the application sitedir.
#
# See App::CELL::Guide for details.
#-------------------------------------------------------------#

# unique value used by App::CELL::Load::init routine sanity check
set('CELL_LOAD_SANITY_META', 'Baz');

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

#-------------------------------------------------------------#
#           DO NOT EDIT ANYTHING BELOW THIS LINE              #
#-------------------------------------------------------------#
use strict;
use warnings;
1;
