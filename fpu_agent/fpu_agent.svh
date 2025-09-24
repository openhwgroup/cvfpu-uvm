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
 *  Description   : Agent of the CVFPU UVM testbench
 *  History       :
 */

class fpu_agent extends uvm_agent;

    // -------------------------------------------------------------------------
    // UVM Utils
    // -------------------------------------------------------------------------
    `uvm_component_utils_begin(fpu_agent)
        `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_ALL_ON)
    `uvm_component_utils_end

    // -------------------------------------------------------------------------
    // Fields of the CVFPU agent
    // -------------------------------------------------------------------------
    protected uvm_active_passive_enum is_active = UVM_PASSIVE;

    fpu_sequencer m_sequencer;
    fpu_driver    m_driver;
    fpu_monitor   m_monitor;

    virtual fpu_if fpu_vif;
    
    // -------------------------------------------------------------------------
    // Constructor
    // -------------------------------------------------------------------------
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    // ----------------------------------------------------------------------
    // Build Phase
    // ----------------------------------------------------------------------
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        m_monitor = fpu_monitor::type_id::create("monitor", this);
        if(is_active == UVM_ACTIVE) begin
            m_sequencer = fpu_sequencer::type_id::create("sequencer", this);
            m_driver    = fpu_driver::type_id::create("driver", this);
            m_monitor.set_is_active();
        end

        if (!uvm_config_db #( virtual fpu_if)::get(this, "", "fpu_vif", fpu_vif )) begin
            `uvm_fatal("BUILD_PHASE", $psprintf("Unable to get fpu_vif_config for %s from configuration database", get_name() ) );
        end

        `uvm_info(get_full_name( ), "Build stage complete.", UVM_LOW)
    endfunction: build_phase
    
    // ----------------------------------------------------------------------
    // Connect phase
    // ----------------------------------------------------------------------
    function void connect_phase(uvm_phase phase);
        if(is_active == UVM_ACTIVE) begin
            m_driver.seq_item_port.connect(m_sequencer.seq_item_export);
            m_driver.set_fpu_vif(fpu_vif);
            m_monitor.m_sequencer = m_sequencer; 
        end
        m_monitor.set_fpu_vif(fpu_vif);
        `uvm_info(get_full_name( ), "Connect stage complete.", UVM_LOW)
    endfunction: connect_phase

    // ----------------------------------------------------------------------
    // Reset phase
    // ----------------------------------------------------------------------
    virtual task reset_phase( uvm_phase phase );
        if ( is_active == UVM_ACTIVE ) begin
            m_sequencer.stop_sequences();
            `uvm_info( "STOPPED SEQUENCES", "STOPPED SEQUENCES", UVM_LOW );
        end // if
    endtask: reset_phase

    // ----------------------------------------------------------------------
    // Set agent to active mode
    // ----------------------------------------------------------------------
    function void set_is_active();
        is_active = UVM_ACTIVE;
    endfunction: set_is_active
  
endclass: fpu_agent
