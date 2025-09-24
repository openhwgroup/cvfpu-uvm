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
 *  Description   : Package of the CVFPU UVM environment
 *  History       :
 */

package fpu_env_pkg;

  `include "uvm_macros.svh"
  
  import ariane_pkg::*;
  import uvm_pkg::*;
  import fpu_common_pkg::*;
  import fpu_refmodel_pkg::*;
  import fpu_agent_pkg::*;
  import clock_driver_pkg::*;
  import reset_driver_pkg::*;
  import watchdog_pkg::*;
  import pulse_gen_pkg::*;

  `include "fpu_sb.svh"
  `include "fpu_top_cfg.svh"
  `include "fpu_env.svh"

endpackage : fpu_env_pkg
