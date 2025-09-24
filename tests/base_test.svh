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
 *  Description   : Base test of the CVFPU UVM testbench
 *  History       :
 */

class base_test extends uvm_test;
    `uvm_component_utils(base_test)
  
    fpu_env                     env;

    // -------------------------------------------------------------------------
    // Virtual interfaces
    // -------------------------------------------------------------------------
    virtual xrtl_clock_vif      clk_vif;
    virtual fpu_if              fpu_vif;
    virtual pulse_if            flush_vif;

    // --------------------------------------------------
    // This sequence needs to be overwritten in the test 
    // -------------------------------------------------
    fpu_base_sequence           base_sequence; 

    int unsigned                clk_cnt_before_rst;
    int unsigned                nb_trans_before_rst;

    // Number of transactions in a sequence
    int                         num_txn;

    // -------------------------------------------------------------------------
    // Constructor
    // -------------------------------------------------------------------------
    function new(string name, uvm_component parent);
      super.new(name, parent);

      if (!$value$plusargs("NB_TXNS=%d", num_txn )) begin
        num_txn = 10000;
      end // if
      
      `uvm_info( get_full_name(), $sformatf("NUM_TXN=%0d", num_txn), UVM_HIGH );      
    endfunction: new

    // -------------------------------------------------------------------------
    // Build phase
    // -------------------------------------------------------------------------
    function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      env = fpu_env::type_id::create("env", this);

      if(!uvm_config_db#(virtual xrtl_clock_vif)::get(this, "", "clk_if", clk_vif)) begin
      `uvm_error("NOVIF", {"Unable to get vif from configuration database for: ",
                  get_full_name( ), ".vif"})
      end

      if(!uvm_config_db#(virtual fpu_if)::get(this, "", "fpu_vif", fpu_vif)) begin
        `uvm_error("NOVIF", {"Monitor virtual interface must be set for: ",
                    get_full_name( ), ".fpu_vif"})
      end

      if(!uvm_config_db #( virtual pulse_if)::get(null, "", "flush_driver", flush_vif ))  begin
        `uvm_error("NOVIF", {"Unable to get vif from configuration database for: ",
                    get_full_name( ), ".vif"})
      end

      base_sequence = fpu_base_sequence::type_id::create("seq");

      `uvm_info(get_full_name(), "Build phase complete", UVM_HIGH)
    endfunction: build_phase

    // -------------------------------------------------------------------------
    // Connect phase
    // -------------------------------------------------------------------------
    function void connect_phase(uvm_phase phase);
      `uvm_info(get_full_name( ), "Connect phase complete.", UVM_LOW)

      env.m_fpu_sb.flush_vif    = flush_vif;
      env.m_fpu_sb.flush_driver = env.m_flush_driver;
    endfunction: connect_phase 

  // -------------------------------------------------------------------------
  // End of elaboration phase
  // -------------------------------------------------------------------------
  virtual function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);

    `uvm_info(get_full_name(), "Entering end of elaboration", UVM_LOW)

    // Generate top configuration: reset on the fly/flush on the fly flags
    if( !env.m_fpu_top_cfg.randomize()) begin
      `uvm_error("End of elaboration", "Randomization of config failed");
    end

    `uvm_info("TOP CFG", $sformatf("%s", env.m_fpu_top_cfg.convert2string()), UVM_DEBUG)
  
    // Configure pulse generator to generate a pulse for flush signal
    env.m_flush_cfg.set_pulse_enable( env.m_fpu_top_cfg.get_flush_on_the_fly() ); // Enable flush based on configuration
    env.m_flush_cfg.set_pulse_clock_based(1);   // Synchronous pulse
    env.m_flush_cfg.set_pulse_width(1);         // Pulse of 1 clk cycle with
    env.m_flush_cfg.set_pulse_period($urandom_range(65000, 30000)); // Generate pulse every rand x clk cycles
    env.m_flush_cfg.set_pulse_phase_shift(0);   // Phase shift
    env.m_flush_cfg.set_pulse_num(1);           // Number of flush pulses

    // Configure the number of resets to be generated
    if (env.m_fpu_top_cfg.get_reset_on_the_fly()) env.m_reset_driver.set_num_reset( $urandom_range(10, 5));
  endfunction

  // -------------------------------------------------------------------------
  // Reset phase
  // -------------------------------------------------------------------------
  virtual task reset_phase( uvm_phase phase );
    clk_cnt_before_rst = 0;
  endtask

  // -------------------------------------------------------------------------
  // Main phase
  // -------------------------------------------------------------------------
  virtual task main_phase(uvm_phase phase);
    super.main_phase( phase );

    phase.phase_done.set_drain_time(this, 1500);

    fork
      // --------------------------------------------------------------
      // start the base sequence here 
      // This base sequence needs to be overwritten in the test class 
      // ---------------------------------------------------------------
      base_sequence.start(env.m_fpu_agent.m_sequencer);
    join_none
    
    // Compute the number of transactions after which a reset is asserted
    nb_trans_before_rst = $urandom_range(num_txn/2, num_txn/4);

    if (env.m_fpu_top_cfg.get_reset_on_the_fly()) begin
      fork
        phase.raise_objection(this, "Start reset asertion");
        forever begin
          clk_vif.wait_n_clocks(1);
          clk_cnt_before_rst++;

          // Assert reset on the fly when condition is met
          if( (env.m_fpu_sb.get_req_counter() == nb_trans_before_rst) || (clk_cnt_before_rst == 10*num_txn) ) begin	
            phase.drop_objection(this, "Assert reset");
            
            // env.m_fpu_agent.m_sequencer.stop_sequences();
            env.m_reset_driver.emit_assert_reset();
          end

          // Break from loop when reset is done
          if(env.m_reset_driver.get_reset_on_the_fly_done() == 1) begin
            `uvm_info("RESET ON THE FLY END", $sformatf("%0d(d), %0d(d)",env.m_fpu_sb.get_req_counter(), nb_trans_before_rst ), UVM_DEBUG); 
            phase.drop_objection(this, "Finish reset assertion");
            break;
          end
        end
      join_none
    end

    phase.raise_objection(this, "Starting sequences");
    clk_vif.wait_n_clocks(100000);
    phase.drop_objection(this, "Completed sequences");

    `uvm_info(get_full_name(), "Main phase complete", UVM_LOW)
  endtask
  

endclass: base_test
