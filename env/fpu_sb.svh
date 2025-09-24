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
 *  Description   : Scoreboard of CVFPU UVM testbench
 *  History       :
 */


class fpu_sb extends uvm_scoreboard;

    `uvm_component_utils(fpu_sb)

    // -----------------------------------------------------------------------
    // Analysis Ports
    // -----------------------------------------------------------------------
    // Receives the request sent to the DUV
    uvm_tlm_analysis_fifo #(fpu_req_t) af_fpu_req;
    
    // Receives the response sent by the DUV
    uvm_tlm_analysis_fifo #(fpu_rsp_t) af_fpu_rsp;

    fpu_req_t q_fpu_req[ logic [CVA6Cfg.TRANS_ID_BITS-1:0] ];
    fpu_rsp_t q_fpu_rsp[ logic [CVA6Cfg.TRANS_ID_BITS-1:0] ];

    // -------------------------------------------------------------------------
    // Events to handle reset
    // -------------------------------------------------------------------------
    event reset_asserted;
    event reset_deasserted;

    int req_cnt;  // Request  counter
    int rsp_cnt; // Response counter

    virtual pulse_if flush_vif;
    pulse_gen_driver flush_driver;

    // -----------------------------------------------------------------------
    // Reference model handle
    // -----------------------------------------------------------------------
    fpu_refmodel m_ref_model;

    // -----------------------------------------------------------------------
    // Sequencer handle
    // -----------------------------------------------------------------------
    fpu_sequencer m_sequencer;

    // -------------------------------------------------------------------------
    // Constructor
    // -------------------------------------------------------------------------
    function new(string name, uvm_component parent);
      super.new(name, parent);
      
      af_fpu_req = new("af_fpu_req", this);
      af_fpu_rsp = new("af_fpu_rsp", this);
    endfunction: new

    // -------------------------------------------------------------------------
    // Build phase
    // -------------------------------------------------------------------------
    function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      m_ref_model = new;

      `uvm_info("SCOREBOARD", "Build stage complete.", UVM_MEDIUM)
    endfunction: build_phase

    // -------------------------------------------------------------------------
    // Pre-reset phase
    // -------------------------------------------------------------------------
    virtual task pre_reset_phase(uvm_phase phase);
        super.pre_reset_phase(phase);
        -> reset_asserted;
    endtask: pre_reset_phase

    // ------------------------------------------------------------------------
    // Reset phase
    // ------------------------------------------------------------------------
    task reset_phase(uvm_phase phase );
      super.reset_phase(phase);
      
      q_fpu_req.delete();
      q_fpu_rsp.delete();
      m_sequencer.q_inflight_tid.delete();

      req_cnt = 0;

      `uvm_info("SCOREBOARD", "Reset stage complete.", UVM_MEDIUM)
    endtask: reset_phase

    // ------------------------------------------------------------------------
    // Post reset phase
    // ------------------------------------------------------------------------
    virtual task post_reset_phase(uvm_phase phase);
      -> reset_deasserted;
      `uvm_info("SCOREBOARD", "Post Reset stage complete.", UVM_MEDIUM)
    endtask : post_reset_phase


    // -------------------------------------------------------------------------
    // Run phase
    // -------------------------------------------------------------------------
    virtual task main_phase(uvm_phase phase);
      super.main_phase(phase);
      fork
        collect_fpu_req();
        collect_fpu_resp();
        flush_env();
      join_none
    endtask: main_phase

    // -------------------------------------------------------------------------
    // Flushes environment
    // -------------------------------------------------------------------------
    virtual task flush_env();
      forever begin
        @(posedge flush_vif.m_pulse_out);
        `uvm_info("FPU SB", "Flush asserted", UVM_LOW);
        @(negedge flush_vif.m_pulse_out);
        `uvm_info("FPU SB", "Flush de-asserted", UVM_LOW);

        // Empty all lists
        q_fpu_req.delete();
        q_fpu_rsp.delete();
        m_sequencer.q_inflight_tid.delete();
      end
    endtask 

    // -------------------------------------------------------------------------
    // Collect request sent to the DUV
    // -------------------------------------------------------------------------
    virtual task collect_fpu_req();
      fpu_req_t req;
      
      forever begin
        af_fpu_req.get(req);

        print_fpu_req(req, "FPU_SB_REQ", UVM_LOW);

        // Insert request in req queue
        q_fpu_req[req.data.trans_id] = req;

        // Increment counter
        req_cnt++;
      end
    endtask
    
    // -------------------------------------------------------------------------
    // Collect response sent by the DUV and compare it with result computed by 
    // reference model 
    // -------------------------------------------------------------------------
    virtual task collect_fpu_resp();
      fpu_rsp_t 			         rsp;
      fpu_req_t 			         req;
      logic [CVA6Cfg.FLen-1:0] exp_result;
	    fpnew_pkg::status_t      exp_flags;

      forever begin
        af_fpu_rsp.get(rsp);

        print_fpu_rsp(rsp, "FPU_SB_RSP", UVM_LOW);

        if (q_fpu_req.exists(rsp.trans_id)) begin
          req = q_fpu_req[rsp.trans_id];

          // Compute expected response -> Either special flag, or number
          m_ref_model.compute_expected(req);
		  
          exp_result = m_ref_model.m_expected_result;
          exp_flags  = m_ref_model.m_flags;
		  	  
          // Compare results
          if (exp_result != rsp.result) begin
            `uvm_error("FPU_SB_ERR", $sformatf("C_RST (%0h) != FPU_RST (%0h)", exp_result , rsp.result));
          end else if (exp_flags != rsp.exception.cause) begin
            `uvm_error("FPU_SB_ERR", $sformatf("C_FLAGS (%0h) != FPU_FLAGS (%0h)", exp_flags, rsp.exception.cause));
          end
          // Verification is done, free entry
          q_fpu_req.delete(rsp.trans_id);
        end else begin
          `uvm_error("FPU_SB_ERR", $sformatf("TID = %0h. No corresponding request", rsp.trans_id));
        end
      end
    endtask: collect_fpu_resp

    // ------------------------------------------
    // API to get request counter
    // ------------------------------------------
    function int get_req_counter();
      return req_cnt;
    endfunction 

endclass: fpu_sb
