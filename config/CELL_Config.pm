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

# CELL_CORE_SAMPLE
#        sample core variable (for demo purposes)
set('CELL_CORE_SAMPLE', 'layers of sediments' );

# CELL_LOG_SHOW_CALLER
#        determine whether App::CELL::Log appends file and line number of
#        caller to log messages
set( 'CELL_LOG_SHOW_CALLER', 1 );

use strict;
use warnings;

1;
