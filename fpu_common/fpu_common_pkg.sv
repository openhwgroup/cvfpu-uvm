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
 *  Description   : Common package of the CVFPU UVM environment
 *  History       :
 */

package fpu_common_pkg;
    `include "uvm_macros.svh"
  
    import uvm_pkg::*;
    import ariane_pkg::*;

    localparam config_pkg::cva6_cfg_t CVA6Cfg = build_config_pkg::build_config(cva6_config_pkg::cva6_cfg);

    localparam int unsigned NCHUNKS = CVA6Cfg.XLEN/32;

    // Type definitions
    typedef struct packed {
        ariane_pkg::fu_t                  fu;           // Functional unit to use : FPU
        ariane_pkg::fu_op                 operation;    // Operation to perform
        logic [CVA6Cfg.XLEN-1:0]          operand_a;
        logic [CVA6Cfg.XLEN-1:0]          operand_b;
        logic [CVA6Cfg.XLEN-1:0]          imm;
        logic [CVA6Cfg.TRANS_ID_BITS-1:0] trans_id;        
    } fu_data_t;

    typedef struct packed {
        logic [CVA6Cfg.XLEN-1:0] cause;  // cause of exception
        logic [CVA6Cfg.XLEN-1:0] tval;  // additional information of causing exception (e.g.: instruction causing it),
        // address of LD/ST fault
        logic [CVA6Cfg.GPLEN-1:0] tval2;  // additional information when the causing exception in a guest exception
        logic [31:0] tinst;  // transformed instruction information
        logic gva;  // signals when a guest virtual address is written to tval
        logic valid;
    } exception_t;

    typedef struct packed {
    fu_data_t        data;
    logic      [1:0] fmt; // FP format
    logic      [2:0] rm;  // FP rounding mode
    logic      [2:0] frm; 
    logic      [6:0] prec; // FP precision - Unused
    } fpu_req_t;

    typedef struct packed {
    logic [CVA6Cfg.TRANS_ID_BITS-1:0] trans_id;
    logic [         CVA6Cfg.FLen-1:0] result;
    exception_t                       exception;
    } fpu_rsp_t;

    localparam int unsigned FP64_EXP_BITS = fpnew_pkg::exp_bits(fpnew_pkg::FP64);
    localparam int unsigned FP64_MAN_BITS = fpnew_pkg::man_bits(fpnew_pkg::FP64);

    localparam int unsigned FP32_EXP_BITS = fpnew_pkg::exp_bits(fpnew_pkg::FP32);
    localparam int unsigned FP32_MAN_BITS = fpnew_pkg::man_bits(fpnew_pkg::FP32);
    
    typedef struct packed {
        logic                     sign;
        logic [FP64_EXP_BITS-1:0] exponent;
        logic [FP64_MAN_BITS-1:0] mantissa;
    } fp_double_t;

    typedef struct packed {
        logic                     sign;
        logic [FP32_EXP_BITS-1:0] exponent;
        logic [FP32_MAN_BITS-1:0] mantissa;
    } fp_single_t;

    // print fpu req
    function void print_fpu_req(fpu_req_t R, string S, uvm_verbosity verbosity);
        `uvm_info(S, $sformatf("OP=%0s, OP_A=%0x(x), OP_B=%0x(x), IMM=%0x(x), TID=%0x(x), FMT=%0d(d), RM=%0x(x)", 
                                            R.data.operation,
                                            R.data.operand_a, 
                                            R.data.operand_b, 
                                            R.data.imm, 
                                            R.data.trans_id,
                                            R.fmt, 
                                            R.rm
                                ), verbosity);
    endfunction

    // print fpu rsp
    function void print_fpu_rsp(fpu_rsp_t R, string S, uvm_verbosity verbosity);
        `uvm_info(S, $sformatf("TID=%0x(x), RESULT=%0x(x), EXCEPTION=%0x(x)", 
                                    R.trans_id,
                                    R.result,
                                    R.exception.cause
                            ), verbosity);
    endfunction 


endpackage : fpu_common_pkg
