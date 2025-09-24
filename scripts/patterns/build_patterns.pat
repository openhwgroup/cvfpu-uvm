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
#
# ###########################################################################
# This file defines the patterns which are used for analyzing the log
# file produced when compiling a design for Questa.
# ###########################################################################

# Define patterns which indicate errors
ERROR_NUM,Errors: ([0-9]+)
ERROR,\* No rule to make target
ERROR,\*\* Error
ERROR,\*\*\* ERROR

# Define patterns which indicate warnings
WARNING,\* Warning

# Define patterns which indicate the build (vopt) has completed
EOT,Optimized design name is

# Define patterns for grouping error messages in a summary table
GROUP,(vopt-[0-9]+),QUESTA_ELABORATE
GROUP,(vcom-[0-9]+),QUESTA_COMPILE
GROUP,(vlog-[0-9]+),QUESTA_COMPILE
