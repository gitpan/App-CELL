#-------------------------------------------------------------#
# CELL_Config.pm
#
# App::CELL's own core configuration parameters. This file
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

# CELL_DEBUG_MODE
#        debug mode means that calls to $log->trace and $log->debug
#        won't be suppressed - off by default
set('CELL_DEBUG_MODE', 0);

# CELL_SHAREDIR_FULLPATH
#        full path of App::CELL distro sharedir
#        overrided by site param when sharedir is loaded
set('CELL_SHAREDIR_FULLPATH', '');

# CELL_SITEDIR_FULLPATH
#        full path of siteconf dir
#        overrided by site param when siteconf dir is loaded
set('CELL_SITEDIR_FULLPATH', '');

# CELL_SUPPORTED_LANGUAGES
#        reference to a list of supported language tags
#        (i.e. languages for which we have _all_ messages
#        translated)
set( 'CELL_SUPPORTED_LANGUAGES', [ 'en' ] );

# CELL_LANGUAGE
#        the language that messages will be displayed in by default,
#        when no language is specified by other means
set('CELL_LANGUAGE', 'en');

# CELL_CORE_UNIT_TESTING
#        used only for App::CELL unit tests
set('CELL_CORE_UNIT_TESTING', [ 'nothing special' ] );

# CELL_LOAD_SANITY_CORE
#        used by App::CELL::Load::init sanity check
set('CELL_LOAD_SANITY_CORE', 'Bar');

# CELL_CORE_SAMPLE
#        sample core variable (for demo purposes)
set('CELL_CORE_SAMPLE', 'layers of sediments' );

# CELL_LOG_SHOW_CALLER
#        determine whether App::CELL::Log appends file and line number of
#        caller to log messages
set( 'CELL_LOG_SHOW_CALLER', 1 );

#-------------------------------------------------------------#
#           DO NOT EDIT ANYTHING BELOW THIS LINE              #
#-------------------------------------------------------------#
use strict;
use warnings;
1;
