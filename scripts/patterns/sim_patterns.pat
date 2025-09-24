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
#  Creation Date : March, 2025
#  Description   : Patterns file for use with scanlogs.
#  History       :
## ###########################################################################
# Patterns file
#
# This file defines that patterns which are used to identify an error
# or a warning in a simulation log file.
#
# This file can be used as a base and can be customized depending of 
# user needs
#
# Some regular expression below are used for UVM log file
# 
# ###########################################################################
EOT,TEST COMPLETED
ERROR,UVM_ERROR.*\@
ERROR,UVM_FATAL.*\@
ERROR,Fatal:
ERROR,\* Error
ERROR,Error:
WARNING,UVM_WARNING.*\@
WARNING,Warning:
WARNING,Warning.*at
RESET,RESET DONE.*0 active
SEED,sv_seed ([0-9]+)
EOT,Note: \$finish
ERROR,Fatal error
ERROR,Unrecognized parameter name:
ERROR,Unexpected characters after parameter value:
ERROR,Quoted string not terminated by end of line
ERROR,Model qualifiers not yet implemented for
ERROR,Model qualifiers not allowed for
ERROR,Invalid include filespec:
ERROR,Instance qualifiers not yet implemented for
ERROR,Instance qualifiers not allowed with
