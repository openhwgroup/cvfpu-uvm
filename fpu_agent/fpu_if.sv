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
 *  Description   : CVFPU interface
 *  History       :
 */

interface fpu_if (input bit clk_i, input bit rst_ni);
import fpu_common_pkg::*;

    // Request Port
    logic                                   fpu_valid_i;
    logic                                   fpu_ready_o;
    fu_data_t                               fu_data_i;
    logic       [                      1:0] fpu_fmt_i; // FP format
    logic       [                      2:0] fpu_rm_i;  // FP rounding mode
    logic       [                      2:0] fpu_frm_i; // For now unused
    logic       [                      6:0] fpu_prec_i; // FP precision
    
    // Response port
    logic                                   fpu_valid_o;
    logic       [CVA6Cfg.TRANS_ID_BITS-1:0] fpu_trans_id_o;
    logic       [         CVA6Cfg.FLen-1:0] result_o;
    exception_t                             fpu_exception_o;

  // ------------------------------------------------------------------------
  // Delay Task
  // ------------------------------------------------------------------------
  task wait_n_clocks( int N );          // pragma tbx xtf
    begin
      if( N > 0) begin
        @(posedge clk_i);
        repeat (N-1) @( posedge clk_i );
      end
    end
  endtask : wait_n_clocks
    
endinterface //fpu_if