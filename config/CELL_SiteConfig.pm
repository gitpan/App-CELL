#-------------------------------------------------------------#
# CELL_SiteConfig.pm
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

# CELL_SITE_UNIT_TESTING
#        used only for App::CELL unit tests
set('CELL_SITE_UNIT_TESTING', [ 'Om mane padme hum' ] );

# CELL_LOAD_SANITY_SITE
#        used by App::CELL::Load::init sanity check
set('CELL_LOAD_SANITY_SITE', 'Foo');

#-------------------------------------------------------------#
#           DO NOT EDIT ANYTHING BELOW THIS LINE              #
#-------------------------------------------------------------#
use strict;
use warnings;
1;
