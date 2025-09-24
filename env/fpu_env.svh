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
 *  Description   : environment class of the CVFPU UVM testbench
 *  History       :
 */

class fpu_env extends uvm_env;

    `uvm_component_utils(fpu_env);

    fpu_agent                    m_fpu_agent;
    clock_driver_c               m_clock_driver;
    clock_config_c               m_clock_cfg;
    watchdog_c                   m_watchdog;
    fpu_sb                       m_fpu_sb;

    pulse_gen_driver             m_flush_driver;
    pulse_gen_cfg                m_flush_cfg;

    fpu_top_cfg                  m_fpu_top_cfg;

    reset_driver_c #(1'b1,50,0)  m_reset_driver;
        
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
        
        m_fpu_agent = fpu_agent::type_id::create("fpu_agent", this);
        m_fpu_agent.set_is_active();

        m_fpu_sb = fpu_sb::type_id::create("fpu_sb", this);

        m_clock_driver = clock_driver_c::type_id::create("clock_driver", this );
        m_clock_cfg    = clock_config_c::type_id::create("clock_cfg", this );
        m_clock_driver.m_clk_cfg = m_clock_cfg;
        
        m_reset_driver = reset_driver_c#( 1'b1,50,0 )::type_id::create("reset_driver", this );
        m_watchdog     = watchdog_c::type_id::create("watchdog",this);

        m_flush_driver = pulse_gen_driver::type_id::create("flush_driver", this );
        m_flush_cfg    = pulse_gen_cfg::type_id::create("flush_cfg", this );

        m_fpu_top_cfg  = fpu_top_cfg::type_id::create("fpu_top_cfg", this );

        `uvm_info(get_full_name(), "Build phase complete", UVM_DEBUG)
    endfunction: build_phase
    
    // -------------------------------------------------------------------------
    // Connect phase
    // -------------------------------------------------------------------------
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        m_fpu_agent.m_monitor.ap_fpu_req.connect(m_fpu_sb.af_fpu_req.analysis_export );
        m_fpu_agent.m_monitor.ap_fpu_rsp.connect(m_fpu_sb.af_fpu_rsp.analysis_export );

        m_flush_driver.m_pulse_cfg = m_flush_cfg;
        m_fpu_sb.m_sequencer = m_fpu_agent.m_sequencer;
        `uvm_info(get_full_name( ), "Connect phase complete.", UVM_DEBUG)
    endfunction: connect_phase

    // -------------------------------------------------------------------------
    // End of elaboration phase
    // -------------------------------------------------------------------------
    virtual function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        // Configure clock with a frequency = 1 GHz    
        if (!m_clock_cfg.randomize() with {m_starting_signal_level == 0; m_clock_frequency == 1000; m_duty_cycle == 50;}) begin
            `uvm_error("End of elaboration", "Randomization failed");
        end     
        
        `uvm_info(get_full_name( ), "End of elaboration phase complete.", UVM_DEBUG)
    endfunction: end_of_elaboration_phase

endclass : fpu_env

