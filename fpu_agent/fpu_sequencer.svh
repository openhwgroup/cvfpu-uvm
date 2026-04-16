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
 *  Description   : Sequencer of the CVFPU UVM testbench
 *  History       :
 */

`uvm_analysis_imp_decl(_flush)

class fpu_sequencer extends uvm_sequencer #(fpu_txn, fpu_txn);

  uvm_analysis_imp_flush #(bit, fpu_sequencer) flush_export;

  // -------------------------------------------------------
  // List of in-flight transactions' IDs
  // -------------------------------------------------------
  bit [CVA6Cfg.TRANS_ID_BITS-1:0] q_inflight_tid[ bit [CVA6Cfg.TRANS_ID_BITS-1:0] ];
  
  `uvm_sequencer_utils(fpu_sequencer)
  
  // -------------------------------------------------------------------------
  // Constructor
  // -------------------------------------------------------------------------
  function new(string name = "fpu_sequencer", uvm_component parent);
      super.new(name, parent);
      
  endfunction: new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    flush_export = new("flush_export", this);
  endfunction
  
  // -------------------------------------------------------------------------
  // Called automatically when monitor writes to ap_flush
  // -------------------------------------------------------------------------
  virtual function void write_flush(bit t);
    // Stop any running sequences
    stop_sequences();

  endfunction
endclass: fpu_sequencer
