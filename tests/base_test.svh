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

    // Number of transactions in a sequence
    int                         num_txn;

    // --------------------------------------------------
    // Internal fields
    // -------------------------------------------------
    bit          all_done;      // set when scoreboard signals completion
    int unsigned clk_cnt_before_rst;  // Number of clock cycles before asserting async reset
    int unsigned nb_trans_before_rst; // Number of output transactions before asserting async reset

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

      env = fpu_env::type_id::create("env", this);

      if(!uvm_config_db#(virtual xrtl_clock_vif)::get(this, "", "clk_if", clk_vif)) begin
      `uvm_error("NOVIF", {"Unable to get vif from configuration database for: ",
                  get_full_name( ), ".vif"})
      end

      if(!uvm_config_db#(virtual fpu_if)::get(this, "", "fpu_vif", fpu_vif)) begin
        `uvm_error("NOVIF", {"Monitor virtual interface must be set for: ",
                    get_full_name( ), ".fpu_vif"})
      end

      if (!uvm_config_db #( virtual pulse_if)::get(this, "", "flush_driver", flush_vif )) begin
          `uvm_fatal("BUILD_PHASE", $psprintf("Unable to get flush_driver for %s from configuration database", get_name() ) );
      end

      base_sequence = fpu_base_sequence::type_id::create("seq");

      `uvm_info(get_full_name(), "Build phase complete", UVM_HIGH)
    endfunction: build_phase

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
    all_done = 0;
  endtask

  // -------------------------------------------------------------------------
  // Main phase
  // -------------------------------------------------------------------------
  virtual task main_phase(uvm_phase phase);

    num_txn = env.m_fpu_top_cfg.get_num_txn();

    // Compute the number of transactions after which a reset is asserted
    nb_trans_before_rst = $urandom_range(num_txn/4, num_txn/2);
    all_done = 0;

    super.main_phase( phase );

    phase.phase_done.set_drain_time(this, 1500);
    phase.raise_objection(this, "Test started");
    
    do begin
      fork
        // ---------------------------------------
        // MAIN THREAD
        // ---------------------------------------
        begin: MAIN_THREAD
          `uvm_info(get_full_name(), "Inside main thread", UVM_HIGH)
          base_sequence.set_num_txn(num_txn);
          base_sequence.start(env.m_fpu_agent.m_sequencer);
          // Block until all transactions are executed
          wait (env.m_fpu_sb.all_done == 1'b1);
          all_done = 1;
        end
        // ---------------------------------------
        // FLUSH THREAD
        // ---------------------------------------
        begin: FLUSH_THREAD
          `uvm_info(get_full_name(), "Inside flush thread", UVM_HIGH)
          if ( env.m_fpu_top_cfg.get_flush_on_the_fly() && env.m_flush_driver.get_pulse_cnt() < 1) begin
            // Block until a flush is detected
            @(env.m_flush_driver.pulse_fired);
          end else begin
            // Wait here until all transactions are executed
            wait (0);
          end
        end
        // ---------------------------------------
        // RESET THREAD
        // ---------------------------------------
        begin : RESET_THREAD
          `uvm_info(get_full_name(), "Inside reset thread", UVM_HIGH)
          if ( env.m_fpu_top_cfg.get_reset_on_the_fly() && !env.m_reset_driver.get_reset_on_the_fly_done()) begin
            // Wait until transaction threshold or clock timeout
            forever begin
              clk_vif.wait_n_clocks(1);
              clk_cnt_before_rst++;

              // Assert reset on the fly when condition is met
              if( (env.m_fpu_sb.get_req_counter() == nb_trans_before_rst) || (clk_cnt_before_rst == 10*num_txn) ) begin
                `uvm_info(get_full_name(), $sformatf("Asserting reset after %0d reqs / %0d clks",
                                env.m_fpu_sb.get_req_counter(),
                                clk_cnt_before_rst), UVM_HIGH)
                env.m_reset_driver.emit_assert_reset();
                all_done=1; // Break from while loop
                break; // Break from forever loop
              end
            end
          end else begin
            // Wait here until all transactions are executed
            wait (0);
          end
        end
      join_any
      disable fork;
      `uvm_info(get_full_name(), "Fork disabled", UVM_HIGH)
    end while (!all_done);

    phase.drop_objection(this, "Test finished");

    `uvm_info(get_full_name(), "Main phase complete", UVM_LOW)
  endtask
endclass: base_test