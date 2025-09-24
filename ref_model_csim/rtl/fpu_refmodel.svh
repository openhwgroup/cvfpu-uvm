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
 *  Description   : Reference Model of CVFPU UVM testbench
 *  History       :
 */

class fpu_refmodel extends uvm_object;

  `uvm_object_utils(fpu_refmodel);
  
  logic [CVA6Cfg.XLEN-1:0] m_expected_result;
	fpnew_pkg::status_t 	   m_flags;

  // ------------------------------------------------------------------------
  // Constructor
  // ------------------------------------------------------------------------
  function new(string name = "fpu_refmodel");
      super.new(name);
  endfunction

  // ------------------------------------------------------------------------
  // Call reference model functions to compute expected result
  // ------------------------------------------------------------------------    
  function void compute_expected(input fpu_req_t txn);
    ariane_pkg::fu_op                 operator;
    bit [CVA6Cfg.XLEN-1:0]            op1, op2, op3;
    mpfr_rnd_e                        rounding_mode;
    bit [CVA6Cfg.FLen-1:0]            exp_result;
    env_t                             src_env, dst_env;
    bit                               is_signed;
    bit                               int_format;
    int unsigned                      INT_WIDTH, FP_WIDTH;
    logic [CVA6Cfg.FLen-1:0]          int_mask, all_ones;
    bit                               do_nothing, sign_extend_res;

    print_fpu_req(txn, "FPU_REF_MODEL_REQ", UVM_HIGH);
    
    operator      = txn.data.operation;
    op1           = txn.data.operand_a;
    op2           = txn.data.operand_b;
    op3           = txn.data.imm;
    rounding_mode = mpfr_rnd_e'(txn.rm);
    is_signed     = ~txn.data.imm[0];
    int_format    = txn.data.imm[1];
    dst_env       = get_dest_env(fpnew_pkg::fp_format_e'(txn.fmt));
    src_env       = get_src_env(txn.data.imm[2:0]);

    INT_WIDTH = int_format ? 64 : 32;
    int_mask  = (1 << INT_WIDTH) - 1;

    FP_WIDTH = fpnew_pkg::fp_width(fpnew_pkg::fp_format_e'(txn.fmt));
    
    `uvm_info("FPU_REF_MODEL", 
              $sformatf("TXN INFO: OP=%0s, OP1=%0h (h), OP2=%0h (h), OP3=%0h (h), RND=%0h (h), BIS=%0d (d), ES=%0d (d)", 
              operator, op1, op2, op3, rounding_mode, dst_env.bis, dst_env.es),
              UVM_HIGH)

    unique case (operator)
      FADD:   	m_flags = dpi_fadd(exp_result, op2, op3, rounding_mode, dst_env);
      FSUB:   	m_flags = dpi_fsub(exp_result, op2, op3, rounding_mode, dst_env);
      FMUL:   	m_flags = dpi_fmul(exp_result, op1, op2, rounding_mode, dst_env);
      FDIV:   	m_flags = dpi_fdiv(exp_result, op1, op2, rounding_mode, dst_env);
      FMADD:  	m_flags = dpi_fma(exp_result, op1, op2, op3, rounding_mode, dst_env);
      FNMADD: 	m_flags = dpi_fnma(exp_result, op1, op2, op3, rounding_mode, dst_env);
      FMSUB:  	m_flags = dpi_fms(exp_result, op1, op2, op3, rounding_mode, dst_env);
      FNMSUB: 	m_flags = dpi_fnms(exp_result, op1, op2, op3, rounding_mode, dst_env);
      FCMP:   	m_flags = dpi_fcmp(exp_result, op1, op2, rounding_mode, dst_env);
      FSQRT:  	m_flags = dpi_fsqrt(exp_result, op1, rounding_mode, dst_env);
      FMIN_MAX: m_flags = dpi_fmin_max(exp_result, op1, op2, rounding_mode, dst_env);
      FSGNJ: 	m_flags = dpi_fsgnj(exp_result, op1, op2, rounding_mode, dst_env);
      FCVT_F2I: m_flags = dpi_fcvt_f2i(exp_result, op1, rounding_mode, dst_env, is_signed, int_format);
      FCVT_I2F: m_flags = dpi_fcvt_i2f(exp_result, op1 & int_mask, rounding_mode, dst_env, is_signed, int_format);
      FCVT_F2F: m_flags = dpi_fcvt_f2f(exp_result, op1, rounding_mode, src_env, dst_env);
      FCLASS: 	m_flags = dpi_fclass(exp_result, op1, dst_env);
      FMV_F2X: m_flags = dpi_fmv_f2x(exp_result, op1, dst_env, NCHUNKS);
      FMV_X2F: m_flags = dpi_fsgnj(exp_result, op1, op2, rounding_mode, dst_env);
    endcase

    sign_extend_res = (operator == FCVT_F2I) || (operator == FMV_F2X);
    do_nothing      = (operator == FCMP    ) || (operator == FCLASS);
    all_ones = ('1) << FP_WIDTH;

    if (do_nothing || sign_extend_res) begin
      m_expected_result = exp_result;
    end else begin
    // NaN-box result
      m_expected_result = exp_result & ((1 << FP_WIDTH) - 1) | all_ones;            
    end
    
   `uvm_info("FPU_REF_MODEL_RSP", $sformatf("RESULT=%0x(x), FLAGS= %0x", m_expected_result, m_flags), UVM_HIGH);  
  endfunction

  // -----------------------------------------------------------
  //  Compute destination environment 
  // -----------------------------------------------------------
  function env_t get_dest_env (input fpnew_pkg::fp_format_e fmt);
    env_t env;
    // Formats
    unique case (fmt)
      // FP32 (single precision)
      2'b00:   env = '{bis : 32-1, es : 8-1};
      // FP64 (double precision)
      2'b01:   env = '{bis : 64-1, es : 11-1};
      // FP16 (half precision)
      2'b10:  env = '{bis : 16-1, es : 5-1};
      // FP8
      default: env = '{bis : 8-1, es : 5-1};
    endcase
    return env;
  endfunction

  // -----------------------------------------------------------
  //  Compute source environment 
  // -----------------------------------------------------------
  function env_t get_src_env (input logic[2:0] fmt);
    env_t env;
    // Formats
    unique case (fmt)
      // FP32 (single precision)
      3'b000:   env = '{bis : 32-1, es : 8-1};
      // FP64 (double precision)
      3'b001:   env = '{bis : 64-1, es : 11-1};
      // FP16 (half precision)
      3'b010:  env = '{bis : 16-1, es : 5-1};
      // FP16ALT (half precision)
      3'b110:  env = '{bis : 16-1, es : 5-1};
      // FP8
      3'b011:  env = '{bis : 8-1, es : 5-1};
      default: ;// Do nothing
    endcase

    return env;
  endfunction

endclass: fpu_refmodel
