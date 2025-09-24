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
 *  Description   : Pseudo-random test where format and operation are fixed to 
 *                  a random value, remaining fields are fully random
 *  History       :
 */


class fpu_fmt_single_op_test extends base_test;

    `uvm_component_utils(fpu_fmt_single_op_test)

    fpu_fmt_single_op_seq  m_seq;
  
    // -------------------------------------------------------------------------
    // Constructor
    // -------------------------------------------------------------------------
    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction: new

    // -------------------------------------------------------------------------
    // Pre Main Phase
    // -------------------------------------------------------------------------
    virtual task pre_main_phase(uvm_phase phase);

      ariane_pkg::fu_op operation;
      logic [1:0]       fmt;

	    std::randomize(operation) with { operation inside {FADD, FSUB, FMUL, FDIV, FSQRT, FMADD, FMSUB, FCMP, FMIN_MAX, FSGNJ, FCLASS, FCVT_I2F, FCVT_F2F, FNMADD, FNMSUB, FMV_X2F, FMV_F2X} ; }; // Remove FCVT_F2I until bug is fixed
      
      fmt = $urandom_range(1); // Generate random format FP32/FP64

      // Create new sequence
      m_seq = fpu_fmt_single_op_seq::type_id::create("seq");

      m_seq.set_op(operation);
      m_seq.set_fmt(fmt);
      
      if(!$cast(base_sequence, m_seq)) `uvm_fatal("CAST FAILED", "cannot cast base seqence");

      super.pre_main_phase(phase);

    endtask: pre_main_phase
  
endclass: fpu_fmt_single_op_test
