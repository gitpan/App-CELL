# ************************************************************************* 
# Copyright (c) 2014, SUSE LLC
# 
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# 1. Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
# 
# 2. Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
# 
# 3. Neither the name of SUSE LLC nor the names of its contributors may be
# used to endorse or promote products derived from this software without
# specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
# ************************************************************************* 

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
