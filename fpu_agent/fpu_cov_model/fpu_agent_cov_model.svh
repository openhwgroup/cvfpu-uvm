
/*
 *  Copyright (c) 2026 OpenHW Foundation
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
 *  Creation Date : April, 2026
 *  Description   : Coverage model of the CVFPU UVM testbench
 *  History       :
 */

`uvm_analysis_imp_decl(_req)
`uvm_analysis_imp_decl(_rsp)
`uvm_analysis_imp_decl(_cov_flush)

class fpu_agent_cov_model extends uvm_component;

    `uvm_component_utils(fpu_agent_cov_model)

    uvm_analysis_imp_req #(fpu_req_t, fpu_agent_cov_model) ap_cov_req;
    uvm_analysis_imp_rsp #(fpu_rsp_t, fpu_agent_cov_model) ap_cov_rsp;
    uvm_analysis_imp_cov_flush #(bit, fpu_agent_cov_model) ap_cov_flush;

    fpu_req_t req;
    fpu_rsp_t rsp;

    // Covergroups
    covergroup cg_fpu_request(string name = "cg_fpu_request");
        type_option.merge_instances = 1;
        option.get_inst_coverage = 1;
        option.per_instance = 1;        

        // Coverage for floating-point operations
        cp_operation: coverpoint req.data.operation {
            bins fadd        = { FADD     };
            bins fsub        = { FSUB     };
            bins fmul        = { FMUL     };
            bins fdiv        = { FDIV     };
            bins fsqrt       = { FSQRT    };
            bins fmadd       = { FMADD    };
            bins fmsub       = { FMSUB    };
            bins fnmsub      = { FNMSUB   };
            bins fnmadd      = { FNMADD   };
            bins fcmp        = { FCMP     };
            bins fmin_max    = { FMIN_MAX };
            bins fsgnj       = { FSGNJ    };
            bins fcvt_f2f    = { FCVT_F2F };
            bins fcvt_f2i    = { FCVT_F2I };
            bins fcvt_i2f    = { FCVT_I2F };
            bins fmv_f2x     = { FMV_F2X  };
            bins fmv_x2f     = { FMV_X2F  };
            bins fclass      = { FCLASS   };
        }
        
        cp_fmt: coverpoint req.fmt {
            bins FP32 = {2'b00};
            bins FP64 = {2'b01};
            ignore_bins UNSUPPORTED_FMTS = {[2:3]}; // FP16, FP8, and FP16ALT formats are not covered for now
        }
        
        cp_rm: coverpoint req.rm {
            bins RNE  = {3'b000};  // Round to Nearest, ties to Even
            bins RTZ  = {3'b001};  // Round towards Zero
            bins RDN  = {3'b010};  // Round Down
            bins RUP  = {3'b011};  // Round Up
            // FIXME: The RMM rounding mode is currently not supported by the reference model
            ignore_bins RMM  = {3'b100};  // Round to Nearest, ties away from zero
        }

        cp_operand_a_class: coverpoint classify_operand(req.data.operand_a, req.data.operation == FCVT_F2F ? req.data.imm[1:0] : req.fmt){
            bins OP_A_ZERO      = {ZERO};
            bins OP_A_SUBNORMAL = {SUBNORMAL};
            bins OP_A_NORMAL    = {NORMAL};
            bins OP_A_INF       = {INF};
            bins OP_A_QNAN      = {QNAN};
            bins OP_A_SNAN      = {SNAN};
        }

        cp_operand_b_class: coverpoint classify_operand(req.data.operand_b, req.data.operation == FCVT_F2F ? req.data.imm[1:0] : req.fmt){
            bins OP_B_ZERO      = {ZERO};
            bins OP_B_SUBNORMAL = {SUBNORMAL};
            bins OP_B_NORMAL    = {NORMAL};
            bins OP_B_INF       = {INF};
            bins OP_B_QNAN      = {QNAN};
            bins OP_B_SNAN      = {SNAN};
        }

        cp_operand_c_class: coverpoint classify_operand(req.data.imm, req.data.operation == FCVT_F2F ? req.data.imm[1:0] : req.fmt){
            bins OP_C_ZERO      = {ZERO};
            bins OP_C_SUBNORMAL = {SUBNORMAL};
            bins OP_C_NORMAL    = {NORMAL};
            bins OP_C_INF       = {INF};
            bins OP_C_QNAN      = {QNAN};
            bins OP_C_SNAN      = {SNAN};
        }

        cp_operand_a_sign: coverpoint get_operand_sign(req.data.operand_a, req.data.operation == FCVT_F2F ? req.data.imm[1:0] : req.fmt) {
            bins OP_A_POS = {1'b0};
            bins OP_A_NEG = {1'b1};
        }

        cp_operand_b_sign: coverpoint get_operand_sign(req.data.operand_b, req.data.operation == FCVT_F2F ? req.data.imm[1:0] : req.fmt) {
            bins OP_B_POS = {1'b0};
            bins OP_B_NEG = {1'b1};
        }

        cp_operand_c_sign: coverpoint get_operand_sign(req.data.imm, req.data.operation == FCVT_F2F ? req.data.imm[1:0] : req.fmt) {
            bins OP_C_POS = {1'b0};
            bins OP_C_NEG = {1'b1};
        }

        // Cross-coverage: Operation x Format
        cp_op_x_fmt: cross cp_operation, cp_fmt;

        cp_opA_x_sign: cross cp_operand_a_class, cp_operand_a_sign;
        cp_opB_x_sign: cross cp_operand_b_class, cp_operand_b_sign;
        cp_opC_x_sign: cross cp_operand_c_class, cp_operand_c_sign; 
    endgroup
    
    covergroup cg_fpu_response(string name = "cg_fpu_response");
        type_option.merge_instances = 1;
        option.get_inst_coverage = 1;
        option.per_instance = 1;        
        // option.name = name;
                
        cp_fp_exception: coverpoint rsp.exception.cause {
            // Exact match for 0 (no bits set)
            bins NO_EXCEPTION = {'h0};
            wildcard bins NX = {5'b????1}; // Bit 0: Inexact
            wildcard bins UF = {5'b???1?}; // Bit 1: Underflow
            wildcard bins OF = {5'b??1??}; // Bit 2: Overflow
            wildcard bins DZ = {5'b?1???}; // Bit 3: Divide by Zero
            wildcard bins NV = {5'b1????}; // Bit 4: Invalid Operation
        }
    endgroup

    covergroup cg_fpu_flush(string name = "cg_fpu_flush") with function sample(bit flush);
        type_option.merge_instances = 1;
        option.get_inst_coverage = 1;
        option.per_instance = 1;        
        // option.name = name;

        cp_flush: coverpoint flush {
            bins flush_detected = {1'b1};
        }
    endgroup
    
    function new(string name = "fpu_agent_cov_model", uvm_component parent = null);
        super.new(name, parent);
        cg_fpu_request = new("cg_fpu_request");
        cg_fpu_response = new("cg_fpu_response");
        cg_fpu_flush = new("cg_fpu_flush");
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        // Create analysis ports
        ap_cov_req = new("ap_cov_req", this);
        ap_cov_rsp = new("ap_cov_rsp", this);
        ap_cov_flush = new("ap_cov_flush", this);
    endfunction
    
    function void write_req(fpu_req_t req);
        this.req = req;
        cg_fpu_request.sample();
    endfunction
    
    function void write_rsp(fpu_rsp_t rsp);
        this.rsp = rsp;
        cg_fpu_response.sample();
    endfunction
    
    function void write_cov_flush(bit flush);
        cg_fpu_flush.sample(flush);
    endfunction

    // ----------------------------------------------------------------
    // API FUNCTIONS
    // ----------------------------------------------------------------
    /**
        * Classify floating point operand
        */
    function fp_op_type_e classify_operand(logic [CVA6Cfg.FLen-1:0] value, logic [1:0] fmt);
        logic [10:0] exponent;
        logic [51:0] mantissa;
        logic mantissa_msb;

        case (fmt) 
            2'h0: begin // FP32
                mantissa = value[fpnew_pkg::man_bits(fpnew_pkg::FP32)-1:0];
                exponent = value[fpnew_pkg::man_bits(fpnew_pkg::FP32) +: fpnew_pkg::exp_bits(fpnew_pkg::FP32)];
                mantissa_msb = mantissa[fpnew_pkg::man_bits(fpnew_pkg::FP32)-1];
            end
            2'h1: begin // FP64
                mantissa = value[fpnew_pkg::man_bits(fpnew_pkg::FP64)-1:0];
                exponent = value[fpnew_pkg::man_bits(fpnew_pkg::FP64) +: fpnew_pkg::exp_bits(fpnew_pkg::FP64)];
                mantissa_msb = mantissa[fpnew_pkg::man_bits(fpnew_pkg::FP64)-1];
            end
        endcase

        if (exponent == '0 && mantissa == '0) return ZERO;
        if (exponent == '0 && mantissa != '0) return SUBNORMAL;
        if (exponent != '0 && exponent != '1) return NORMAL;
        if (exponent == '1 && mantissa == '0) return INF;
        if (exponent == '1 && mantissa != '0 && mantissa_msb == 1'b0) return SNAN;
        return QNAN;
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

endclass //fpu_agent_cov_model
