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
 *  Description   : Driver of the CVFPU UVM testbench
 *  History       :
 */

class fpu_driver extends uvm_driver #(fpu_txn);
  
    `uvm_component_utils(fpu_driver)

    // ------------------------------------------------------------------------
    // Local variable
    // ------------------------------------------------------------------------
    protected string name ;

    // ------------------------------------------------------------------------
    // Virtual interface
    // -----------------------------------------------------------------------
    virtual fpu_if fpu_vif;

    // -------------------------------------------------------------------------
    // Constructor
    // -------------------------------------------------------------------------
    function new(string name, uvm_component parent = null);
        super.new(name, parent);
        this.name = name;
    endfunction: new

    // -------------------------------------------------------------------------
    // Build phase
    // -------------------------------------------------------------------------
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
    endfunction: build_phase
    
    // -------------------------------------------------------------------------
    // Reset phase
    // -------------------------------------------------------------------------
    virtual task reset_phase(uvm_phase phase);
        super.reset_phase(phase);
        fpu_vif.fpu_valid_i         <= 1'b0;
        fpu_vif.fu_data_i.fu        <= FPU;
        fpu_vif.fu_data_i.operation <= FADD;
        fpu_vif.fu_data_i.operand_a <= '0;
        fpu_vif.fu_data_i.operand_b <= '0;
        fpu_vif.fu_data_i.imm       <= '0;
        fpu_vif.fu_data_i.trans_id  <= '0;
        fpu_vif.fpu_fmt_i           <= '0;
        fpu_vif.fpu_frm_i           <= '0;
        fpu_vif.fpu_rm_i            <= '0;
        fpu_vif.fpu_prec_i          <= '0;

        `uvm_info(this.name, "Reset stage complete.", UVM_LOW)

    endtask: reset_phase
  
    // -------------------------------------------------------------------------
    // Main phase
    // -------------------------------------------------------------------------
    virtual task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            get_and_drive();
        join_none
        
    endtask: main_phase

    // -------------------------------------------------------------------------
    // Get and drive task
    // -------------------------------------------------------------------------
    virtual task get_and_drive();

        forever begin
            // Get item from the sequencer (blocks until item is available)
            seq_item_port.get_next_item(req);
            
            send_req(req);
            // Indicate to the sequencer that the sequence is done
            seq_item_port.item_done();
        end
    endtask: get_and_drive

    // -------------------------------------------------------------------------
    // Send request task
    // -------------------------------------------------------------------------
    virtual task send_req(fpu_txn req);

        if (req.m_delay > 0) begin
            fpu_vif.wait_n_clocks(req.m_delay); 
        end

        fpu_vif.fpu_valid_i         <= 1'b1;
        fpu_vif.fu_data_i.operation <= req.m_operation;
        fpu_vif.fu_data_i.operand_a <= req.m_operand_a;
        fpu_vif.fu_data_i.operand_b <= req.m_operand_b;
        fpu_vif.fu_data_i.imm       <= req.m_imm;
        fpu_vif.fu_data_i.trans_id  <= req.m_trans_id;
        fpu_vif.fpu_fmt_i           <= req.m_fmt;
        fpu_vif.fpu_frm_i           <= req.m_frm;
        fpu_vif.fpu_rm_i            <= req.m_rm;
        fpu_vif.fpu_prec_i          <= req.m_prec;

        // Wait for the request to be consumed
        do @(posedge fpu_vif.clk_i); while (!fpu_vif.fpu_ready_o);

        fpu_vif.fpu_valid_i         <= 1'b0;

    endtask: send_req

    // -------------------------------------------------------------------------
    // API to set the interface 
    // -------------------------------------------------------------------------
    function void set_fpu_vif (virtual fpu_if I);
        fpu_vif = I;
    endfunction

    
endclass: fpu_driver

