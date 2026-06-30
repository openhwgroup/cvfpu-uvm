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
    virtual pulse_if                 flush_vif;

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

    uvm_analysis_port #(fpu_obs_txn) ap_conv_obs;

    fpu_req_t m_pending_reqs [logic [CVA6Cfg.TRANS_ID_BITS-1:0]];


    // -------------------------------------------------------------------------
    // Analysis port for flush handling
    // -------------------------------------------------------------------------
    uvm_analysis_port #(bit)        ap_flush;

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
        ap_fpu_rsp  = new("ap_fpu_rsp", this);
        ap_flush    = new("ap_flush", this);
        ap_conv_obs = new("ap_conv_obs", this);

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
        forever begin
            fork
                collect_reqs();
                collect_resps();
                begin: FLUSH_THREAD
                    // Polling for a flush
                    @(posedge fpu_vif.clk_i iff flush_vif.m_pulse_out === 1'b1);
                    `uvm_info("FPU MONITOR", "Outside of fork: Flush detected", UVM_HIGH)
                end
                flush_detect();
            join_any
            disable fork;
            @(posedge fpu_vif.clk_i iff flush_vif.m_pulse_out === 1'b0);
        end
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

                m_pending_reqs[req.data.trans_id] = req;
            end
        end
    endtask: collect_reqs
    
    // -------------------------------------------------------------------------
    // Collect responses
    // -------------------------------------------------------------------------
    virtual task collect_resps();
        fpu_rsp_t rsp;
        fpu_obs_txn obs;

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

                if (m_pending_reqs.exists(rsp.trans_id)) begin
                    fpu_req_t paired_req;
                    paired_req = m_pending_reqs[rsp.trans_id];
                    m_pending_reqs.delete(rsp.trans_id);
                    // Sample for conversion coverage
                    // if (is_conv_op(ariane_pkg::fu_op'(paired_req.data.operation))) begin
                        obs = build_conv_obs_txn(paired_req, rsp);
                        ap_conv_obs.write(obs);
                    // end
                end else begin
                    `uvm_info("FPU_MONITOR",
                        $sformatf("Response trans_id=0x%0x has no matching pending request",
                                  rsp.trans_id),
                        UVM_HIGH)
                end
            end
        end
    endtask

    // -------------------------------------------------------------------------
    // Monitor flush signal
    // -------------------------------------------------------------------------
    virtual task flush_detect();
        @(posedge fpu_vif.clk_i iff flush_vif.m_pulse_out === 1'b1);
        `uvm_info("FPU MONITOR", "Flush detected", UVM_HIGH);

        // Notify sequencer and scoreboard of flush
        ap_flush.write(1'b1);
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

    function void set_flush_vif (virtual pulse_if I);
        flush_vif = I;
    endfunction

    // -------------------------------------------------------------------------
    // is_conv_op — returns 1 for operations handled by the conversion covergroup
    // -------------------------------------------------------------------------
    function automatic logic is_conv_op(ariane_pkg::fu_op op);
        return (op inside {FCVT_F2I, FCVT_I2F, FCVT_F2F});
    endfunction : is_conv_op

    // -------------------------------------------------------------------------
    // build_conv_obs_txn
    //   Pairs one accepted request with the corresponding DUT response and
    //   returns a populated fpu_obs_txn ready for the coverage subscriber.
    // -------------------------------------------------------------------------
    function automatic fpu_obs_txn build_conv_obs_txn(
        fpu_req_t req,
        fpu_rsp_t rsp
    );
        fpu_obs_txn obs;
        obs = fpu_obs_txn::type_id::create("conv_obs");

        obs.m_operation = ariane_pkg::fu_op'(req.data.operation);
        obs.m_fmt       = req.fmt;
        obs.m_rm        = req.rm;
        obs.m_imm       = req.data.imm;
        obs.m_operand_a = req.data.operand_a;
        obs.m_operand_b = req.data.operand_b;

        obs.result_o    = rsp.result;
        // FPnew status_t {NV[4], DZ[3], OF[2], UF[1], NX[0]} is forwarded
        // through CVA6's exception cause bus on the FPU response path.
        obs.status_o    = rsp.exception.cause[4:0];

        return obs;
    endfunction : build_conv_obs_txn

endclass: fpu_monitor
