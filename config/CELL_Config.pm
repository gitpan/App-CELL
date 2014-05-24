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
#        language tag determining localization behavior 
#        default
set('CELL_LANGUAGE', 'en');

# CELL_CORE_UNIT_TESTING
#        used only for App::CELL unit tests
set('CELL_CORE_UNIT_TESTING', [ 'nothing special' ] );

# CELL_LOG_SHOW_CALLER
#        determine whether App::CELL::Log appends file and line number of
#        caller to log messages
set( 'CELL_LOG_SHOW_CALLER', 1 );

1;
