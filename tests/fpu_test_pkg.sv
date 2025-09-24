/*
 *  Copyright (c) 2025 CEA*
 *  *Commissariat a l'Energie Atomique et aux Energies Alternatives (CEA)
 *
 *  SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
 *
 *  Licensed under the Solderpad Hardware License v 2.1 (the “License”); you
 *  may not use this file except in compliance with the License, or, at your
 *  option, the Apache License version 2.0. You may obtain a copy of the
 *  License at
 *
 *  https://solderpad.org/licenses/SHL-2.1/
 *
 *  Unless required by applicable law or agreed to in writing, any work
 *  distributed under the License is distributed on an “AS IS” BASIS, WITHOUT
 *  WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
 *  License for the specific language governing permissions and limitations
 *  under the License.
 */
/*
 *  Authors       : Ihsane TAHIR
 *  Creation Date : March, 2025
 *  Description   : Package that includes all test classes of CVFPU UVM testbench
 *  History       :
 */


package fpu_test_pkg;
  import ariane_pkg::*;
  import uvm_pkg::*;
  import fpu_agent_pkg::*;
  import fpu_env_pkg::*;
  import fpu_common_pkg::*;
  
  `include "uvm_macros.svh"

  // Include definition of tests
  `include "base_test.svh"
  `include "fpu_single_op_test.svh"
  `include "fpu_unit_test.svh"
  `include "fpu_op_group_test.svh"
  `include "fpu_random_test.svh"
  `include "bug_f2i_test.svh"
  `include "fpu_fmt_single_op_test.svh"
  `include "fpu_fmt_op_group_test.svh"
  `include "fpu_fmt_random_test.svh"

endpackage: fpu_test_pkg

