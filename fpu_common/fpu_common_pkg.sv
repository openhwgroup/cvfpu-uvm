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
    import fpnew_pkg::*;

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
    localparam int unsigned EMIN_FP32 = 1 - fpnew_pkg::bias(fpnew_pkg::FP32) + fpnew_pkg::bias(fpnew_pkg::FP64);
    localparam int unsigned EMAX_FP32 = fpnew_pkg::bias(fpnew_pkg::FP32) + fpnew_pkg::bias(fpnew_pkg::FP64);
    localparam int unsigned EMAX_FP64 = 2*fpnew_pkg::bias(fpnew_pkg::FP64);
    
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

    typedef enum logic [2:0] { 
        INF,
        ZERO,
        SNAN,
        QNAN,
        SUBNORMAL,
        NORMAL
    } fp_op_type_e;
    
    // print fpu req
    function void print_fpu_req(fpu_req_t R, string S, uvm_verbosity verbosity);
        `uvm_info(S, $sformatf("OP=%0s, OP_A=%0x(x), OP_B=%0x(x), IMM=%0x(x), TID=%0x(x), FMT=%0d(d), RM=%0x(x)", 
                                            R.data.operation.name(),
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

    // -------------------------------------------------------------------------
    // HELPER FUNCTIONS
    // -------------------------------------------------------------------------
        /**
        * Compute floating point exponent (unbiased)
        */
    function logic [10:0] get_exp(logic [CVA6Cfg.FLen-1:0] value, logic [1:0] fmt);
        unique case (fmt) 
            2'h0: return value[fpnew_pkg::man_bits(fpnew_pkg::FP32) +: fpnew_pkg::exp_bits(fpnew_pkg::FP32)];
            2'h1: return value[fpnew_pkg::man_bits(fpnew_pkg::FP64) +: fpnew_pkg::exp_bits(fpnew_pkg::FP64)];
        endcase
    endfunction

        /**
        * Compute floating point mantissa
        */
    function logic [51:0] get_mant(logic [CVA6Cfg.FLen-1:0] value, logic [1:0] fmt);
        unique case (fmt) 
            2'h0: return value[fpnew_pkg::man_bits(fpnew_pkg::FP32)-1:0];
            2'h1: return value[fpnew_pkg::man_bits(fpnew_pkg::FP64)-1:0];
        endcase
    endfunction

    function logic operand_is_boxed(logic [CVA6Cfg.FLen-1:0] value, logic [1:0] fmt);
        int unsigned FP_WIDTH;
        logic [CVA6Cfg.FLen-1:0] fp_mask;

        FP_WIDTH = fpnew_pkg::fp_width(fpnew_pkg::fp_format_e'(fmt));

        fp_mask  = (1 << (CVA6Cfg.XLEN - FP_WIDTH)) - 1;

        // NaN-box check
        return ((value & fp_mask<<FP_WIDTH) >> FP_WIDTH) == fp_mask;
    endfunction

        /**
        * Classify floating point operand
        */
    function classmask_e classify_operand(logic [CVA6Cfg.FLen-1:0] value, logic [1:0] fmt);
        logic        sign;
        logic [10:0] exponent;
        logic [51:0] mantissa;
        logic        mantissa_msb;
        logic        is_boxed;
        logic        is_inf, is_nan, is_qnan, is_snan, is_zero, is_subnorm, is_normal;
        logic        exp_all_ones;

        // First check if floating point value is NaN-boxed
        is_boxed = operand_is_boxed(value, fmt);
    
        mantissa = get_mant(value, fmt);
        exponent = get_exp(value, fmt);
        mantissa_msb = (fmt == 2'h0) ? mantissa[fpnew_pkg::man_bits(fpnew_pkg::FP32)-1] : mantissa[fpnew_pkg::man_bits(fpnew_pkg::FP64)-1];
        exp_all_ones = (fmt == 2'h0) ? (exponent == {fpnew_pkg::exp_bits(fpnew_pkg::FP32){1'b1}}) : (exponent == {fpnew_pkg::exp_bits(fpnew_pkg::FP64){1'b1}});

        sign       = get_operand_sign(value, fmt);
        is_zero    = is_boxed && (exponent == '0 && mantissa == '0);
        is_subnorm = (exponent == '0 && mantissa != '0);
        is_normal  = (exponent != '0 && !exp_all_ones);
        is_inf     = (exp_all_ones && mantissa == '0);
        is_snan    = (exp_all_ones && mantissa != '0 && mantissa_msb == 1'b0);
        is_qnan    = (exp_all_ones && mantissa != '0 && mantissa_msb == 1'b1);

        `uvm_info("CLASSIFICATION", $sformatf("sign=%b, exp=%0h, mant=%0h, zero=%b, subnorm=%b, normal=%b, inf=%b, snan=%b, qnan=%b", 
                sign, exponent, mantissa, is_zero, is_subnorm, is_normal, is_inf, is_snan, is_qnan), UVM_LOW);

        if (is_qnan) return fpnew_pkg::QNAN;
        if (is_snan) return fpnew_pkg::SNAN;
        if (!sign && is_inf) return fpnew_pkg::POSINF;
        if (sign && is_inf) return fpnew_pkg::NEGINF;
        if (!sign && is_normal) return fpnew_pkg::POSNORM;
        if (sign && is_normal) return fpnew_pkg::NEGNORM;
        if (!sign && is_subnorm) return fpnew_pkg::POSSUBNORM;
        if (sign && is_subnorm) return fpnew_pkg::NEGSUBNORM;
        if (!sign && is_zero) return fpnew_pkg::POSZERO;
        if (sign && is_zero) return fpnew_pkg::NEGZERO;
    endfunction: classify_operand

    /**
        * Extract sign bit from operand
        */
    function bit get_operand_sign(logic [CVA6Cfg.FLen-1:0] value, logic [1:0] fmt);
        case (fmt)
            2'h0: return value[fpnew_pkg::fp_width(fpnew_pkg::FP32)-1];
            2'h1: return value[fpnew_pkg::fp_width(fpnew_pkg::FP64)-1];
        endcase
    endfunction: get_operand_sign


    // Coverage enablement flag
    typedef struct {
        bit coverage_enable = 1;  // Control coverage collection
    } fpu_cov_cfg_t;

    // Macro for per-instance coverage tracking
    `define per_instance_fcov option.per_instance = 1; option.name = name;

endpackage : fpu_common_pkg
