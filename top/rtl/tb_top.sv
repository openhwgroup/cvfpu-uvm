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
 *  Description   : Top module of the CVFPU UVM testbench
 *  History       :
 */


module top;


    timeunit 1ns;
    timeprecision 1ps;

    // -----------------------------------------------------------------
    // Import/Include
    // -----------------------------------------------------------------
    `include "uvm_macros.svh"

    import uvm_pkg::*;
    import fpu_common_pkg::*;
    import fpu_test_pkg::*;
    // -----------------------------------------------------------------
    // Clock/Reset signals
    // -----------------------------------------------------------------
    bit   reset;
    bit   post_shutdown_phase;
    logic clk;
    logic rst_n;

   // -----------------------------------------------------------------
   // Interfaces
   // ----------------------------------------------------------------- 
    xrtl_clock_vif clock_if( .clock(clk));

    xrtl_reset_vif #(1'b1,50,0) reset_if (.clk(clk),
                                           .reset(reset),
                                           .reset_n(rst_n), 
                                           .post_shutdown_phase(post_shutdown_phase));
    
    fpu_if   fpu_vif   (.clk_i( clk ), .rst_ni( rst_n ) );
    pulse_if flush_vif (.clk  ( clk ), .rstn  ( rst_n ) );

   // -----------------------------------------------------------------
   // DUT: CVFPU wrapper for CVA6
   // -----------------------------------------------------------------
    fpu_wrap # (
        .CVA6Cfg   ( CVA6Cfg   ),
        .fu_data_t ( fu_data_t ),
        .exception_t (exception_t)
    ) dut (
        .clk_i           ( clk                    ),
        .rst_ni          ( rst_n                  ),
        .flush_i         ( flush_vif.m_pulse_out  ),
        .fpu_valid_i     ( fpu_vif.fpu_valid_i    ),
        .fpu_ready_o     ( fpu_vif.fpu_ready_o    ),
        .fu_data_i       ( fpu_vif.fu_data_i      ),
        .fpu_fmt_i       ( fpu_vif.fpu_fmt_i      ),
        .fpu_rm_i        ( fpu_vif.fpu_rm_i       ),
        .fpu_frm_i       ( fpu_vif.fpu_frm_i      ),
        .fpu_prec_i      ( fpu_vif.fpu_prec_i     ),
        .fpu_trans_id_o  ( fpu_vif.fpu_trans_id_o ),
        .result_o        ( fpu_vif.result_o       ),
        .fpu_valid_o     ( fpu_vif.fpu_valid_o    ),
        .fpu_exception_o ( fpu_vif.fpu_exception_o )
    );

    initial begin
        uvm_config_db#(virtual fpu_if)::set(uvm_root::get( ) , "*" , "fpu_vif", fpu_vif);
        uvm_config_db#(virtual pulse_if)::set(uvm_root::get(), "*", "flush_driver", flush_vif );
        uvm_config_db#(virtual xrtl_clock_vif)::set(uvm_root::get( ) , "*" , "clk_if", clock_if);

        uvm_config_db #(virtual xrtl_clock_vif)::set(uvm_root::get() , "*" , "clock_driver" , clock_if);
        uvm_config_db #( virtual xrtl_reset_vif #( 1'b1,50,0) )::set(uvm_root::get(), "*", "reset_driver", reset_if );
        run_test();
    end

endmodule