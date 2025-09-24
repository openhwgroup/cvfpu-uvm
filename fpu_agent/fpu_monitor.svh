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
 *  Description   : Monitor of the CVFPU UVM testbench
 *  History       :
 */

class fpu_monitor extends uvm_monitor;

    `uvm_component_utils(fpu_monitor)

    // -------------------------------------------------------------------------
    // Fields for FPU monitor
    // -------------------------------------------------------------------------
    protected uvm_active_passive_enum is_active = UVM_PASSIVE;

    virtual fpu_if                   fpu_vif;

    int                              num_req_pkts;
    int                              num_resp_pkts;
  
    // -------------------------------------------------------------------------
    // Internal members for monitoring requests
    // -------------------------------------------------------------------------
    uvm_analysis_port #(fpu_req_t) ap_fpu_req;
    fpu_req_t                      m_req_packet;
    
    // -------------------------------------------------------------------------
    // Internal members for monitoring responses
    // -------------------------------------------------------------------------
    uvm_analysis_port #(fpu_rsp_t) ap_fpu_rsp;
    fpu_rsp_t                      m_rsp_packet;

    // -------------------------------------------------------------------------
    // Sequencer used to clean the inflight id list
    // -------------------------------------------------------------------------
    fpu_sequencer                  m_sequencer;

    // -------------------------------------------------------------------------
    // Events to handle reset
    // -------------------------------------------------------------------------
    event                          reset_asserted;
    event                          reset_deasserted;

    // -------------------------------------------------------------------------
    // Constructor
    // -------------------------------------------------------------------------
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction: new

    // -------------------------------------------------------------------------
    // Build phase
    // -------------------------------------------------------------------------
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        ap_fpu_req  = new("ap_fpu_req", this);
        ap_fpu_rsp = new("ap_fpu_rsp", this);

        num_req_pkts        = 0;
        num_resp_pkts       = 0;

        `uvm_info(get_full_name( ), "Build stage complete.", UVM_DEBUG)
    endfunction: build_phase

    // -------------------------------------------------------------------------
    // Pre-reset phase
    // -------------------------------------------------------------------------
    virtual task pre_reset_phase(uvm_phase phase);
        super.pre_reset_phase(phase);
        -> reset_asserted;
    endtask: pre_reset_phase

    // -------------------------------------------------------------------------
    // Reset phase
    // -------------------------------------------------------------------------
    virtual task reset_phase(uvm_phase phase);
        super.reset_phase(phase);
        num_req_pkts            = 0;
        num_resp_pkts           = 0;
    endtask: reset_phase


    // -------------------------------------------------------------------------
    // Post-reset phase
    // -------------------------------------------------------------------------
    virtual task post_reset_phase(uvm_phase phase);
        super.post_reset_phase(phase);
        -> reset_deasserted;
    endtask: post_reset_phase

    // -------------------------------------------------------------------------
    // Main phase
    // -------------------------------------------------------------------------
    virtual task main_phase(uvm_phase phase);
        `uvm_info("FPU MONITOR", "Entering Main Phase", UVM_HIGH);
        fork
            collect_reqs();
            collect_resps();
        join_none
        `uvm_info("FPU MONITOR", "Leaving Main Phase", UVM_HIGH);
    endtask: main_phase

    // -------------------------------------------------------------------------
    // Collect requests 
    // -------------------------------------------------------------------------
    virtual task collect_reqs();
        fpu_req_t req;

        forever begin
            @(posedge fpu_vif.clk_i);
            
            if (fpu_vif.fpu_valid_i && fpu_vif.fpu_ready_o) begin
                req.data = fpu_vif.fu_data_i;
                req.fmt  = fpu_vif.fpu_fmt_i;
                req.rm   = fpu_vif.fpu_rm_i;
                req.frm  = fpu_vif.fpu_frm_i;
                req.prec = fpu_vif.fpu_prec_i;
                
                print_fpu_req(req, "FPU_MONITOR_REQ", UVM_HIGH);
                m_req_packet = req;

                // Send object to the scoreboard
                ap_fpu_req.write(req);
                num_req_pkts++;
            end
        end
    endtask: collect_reqs
    
    // -------------------------------------------------------------------------
    // Collect responses
    // -------------------------------------------------------------------------
    task collect_resps();
        fpu_rsp_t rsp;

        forever begin
            @(posedge fpu_vif.clk_i);
            if (fpu_vif.fpu_valid_o) begin

                rsp.trans_id = fpu_vif.fpu_trans_id_o;
                rsp.result   = fpu_vif.result_o;
                rsp.exception = fpu_vif.fpu_exception_o;
            
                print_fpu_rsp(rsp, "FPU_MONITOR_RSP", UVM_HIGH);

                // Free corresponding entry
                if (is_active == UVM_ACTIVE ) m_sequencer.q_inflight_tid.delete(rsp.trans_id);

                // Send object to the scoreboard
                ap_fpu_rsp.write(rsp);
                num_resp_pkts++;
            end
        end
    endtask

    // -------------------------------------------------------------------------
    // Report phase
    // -------------------------------------------------------------------------
    virtual function void report_phase(uvm_phase phase);
        `uvm_info(get_type_name( ), $psprintf("REPORT: COLLECTED REQUEST TRANSACTIONS = %0d, COLLECTED RESPONSE TRANSACTIONS = %d",
                                                num_req_pkts, num_resp_pkts), UVM_HIGH)
    endfunction: report_phase

    // ----------------------------------------------------------------------
    // Set agent to active mode
    // ----------------------------------------------------------------------
    function void set_is_active();
        is_active = UVM_ACTIVE;
    endfunction: set_is_active

    // -------------------------------------------------------------------------
    // API to set the interface 
    // -------------------------------------------------------------------------
    function void set_fpu_vif (virtual fpu_if I);
        fpu_vif = I;
    endfunction

endclass: fpu_monitor
