#
#  Copyright (c) 2025 CEA*
#  *Commissariat a l'Energie Atomique et aux Energies Alternatives (CEA)
#
#  SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
#
#  Licensed under the Solderpad Hardware License v 2.1 (the “License”); you
#  may not use this file except in compliance with the License, or, at your
#  option, the Apache License version 2.0. You may obtain a copy of the
#  License at
#
#  https://solderpad.org/licenses/SHL-2.1/
#
#  Unless required by applicable law or agreed to in writing, any work
#  distributed under the License is distributed on an “AS IS” BASIS, WITHOUT
#  WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#  License for the specific language governing permissions and limitations
#  under the License.
#
#
#  Authors       : Ihsane TAHIR
#  Creation Date : March, 2025
#  Description   : 
#  History       :
#

#!/bin/csh -f
set sourced=($_) ### THIS LINE MUST BE THE FIRST COMMAND LINE AFTER THE SHEBANG

set C_TOP = "\e[1;32m" # Green
set C_RST = "\e[1;0m"  # Default
set C_MSG = "\e[1;34m" # Blue

setenv PROJECT_DIR    ${cwd}

echo $C_TOP">>>>>> Initializing Platform <<<<<<"$C_RST

############################################################
# Update all git submodules
############################################################
echo $C_MSG"Update all git submodules" $C_RST
git submodule init
git submodule sync
git submodule update --init --recursive

################################################
# Add the local path to the perl libraries
# that are local to our repository.
################################################
if ( $?PERL5LIB ) then
   setenv PERL5LIB "${PERL5LIB}:${PROJECT_DIR}/scripts/perl5"
else
   setenv PERL5LIB "${PROJECT_DIR}/scripts/perl5"
endif

################################################
# TOOLS
################################################
# Questasim
setenv PATH ${QUESTA_PATH}/bin:$PATH

#SCANLOGS
setenv SCRIPTS $PROJECT_DIR/scripts
setenv PATH ${SCRIPTS}:$PATH

setenv TARGET_CFG    cv64a60ax
setenv CVA6_REPO_DIR ${PROJECT_DIR}/modules/cva6
setenv CORE_V_VERIF  ${PROJECT_DIR}/modules/core-v-verif
setenv DV_UTILS_DIR  ${CORE_V_VERIF}/lib/cv_dv_utils
setenv SCRIPTS_DIR   ${DV_UTILS_DIR}/python/sim_cmd

echo $C_TOP">>>>>> Initialization Done <<<<<<"$C_RST
