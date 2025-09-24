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
 *  Description   : Sequence item of the CVFPU UVM testbench
 *  History       :
 */

class fpu_txn extends uvm_sequence_item; 
   `uvm_object_utils( fpu_txn )

    //-------------------------------------------------------------------------
    // Random Fields for the FPU transaction
    //-------------------------------------------------------------------------
    rand ariane_pkg::fu_op                 m_operation;    // Operation to perform
    rand logic [CVA6Cfg.XLEN-1:0]          m_operand_a;
    rand logic [CVA6Cfg.XLEN-1:0]          m_operand_b;
    rand logic [CVA6Cfg.XLEN-1:0]          m_imm;
    rand logic [CVA6Cfg.TRANS_ID_BITS-1:0] m_trans_id;
    rand logic [1:0]                       m_fmt;          // FP format
    rand logic [2:0]                       m_rm;           // FP rounding mode
    rand logic [2:0]                       m_frm;          // ( ?? ) For now unused
    rand logic [6:0]                       m_prec;         // FP precision

    rand int                               m_delay;        // Delay between two consecutive txns

    //-------------------------------------------------------------------------
    // Type definitions
    //-------------------------------------------------------------------------
    typedef enum logic [2:0] { 
        INF,
        ZERO,
        SNAN,
        QNAN,
        SUBNORMAL,
        NORMAL
    } fp_op_type_e;

    typedef enum { 
        ALL_ZEROS,
        ALL_ONES,
        WALKING_ONE,
        WALKING_ZERO,
        RANDOM
    } mant_cfg_e;

    typedef enum {
        BOUND_VALUES, 
        RANDOM_INT
    } int_type_cfg_e;

    logic [CVA6Cfg.XLEN-1:0] special_int_values[5] = '{
        64'h7FFF_FFFF_FFFF_FFFF,
        64'hFFFF_FFFF_FFFF_FFFF,
        64'h7FFF_FFFF,
        64'hFFFF_FFFF,
        64'h0
    };
             
    // List containing in flight transcation IDs
    bit [CVA6Cfg.TRANS_ID_BITS-1:0] q_inflight_tid[ bit [CVA6Cfg.TRANS_ID_BITS-1:0] ]; 

    //-------------------------------------------------------------------------
    // Transaction configuration fields
    //-------------------------------------------------------------------------
    rand fp_op_type_e [2:0]  m_fp_op_type;         // Class of floating point operands
    rand fp_double_t [2:0]   m_fp_double_operands; // Double precision floating point operands
    rand fp_single_t [2:0]   m_fp_single_operands; // Single precision floating point operands

    rand mant_cfg_e [2:0]          m_fp_mant_cfg;  // Mantissa type of each floating point operand 
    rand int                       m_op_group_cfg; // Operation group 
    rand int_type_cfg_e            m_int_op_type;  // Type of integer operands
    rand logic [CVA6Cfg.XLEN-1:0]  m_int_operand;  // Interger operands

    // -------------------------------------------------------------------------
    // Randomization Constraints
    // -------------------------------------------------------------------------
    // Supported FP formats
    constraint fp_fmt_c { m_fmt inside {0, 1}; } 
    
    // Randomization ordering
    constraint order_ordering_c { solve m_fmt before m_fp_op_type; }
    constraint order_op_fmt_c   { solve m_operation before m_fmt; }
    constraint order_op_imm_c   { solve m_operation before m_imm; }

    constraint operands_config_c {
        foreach (m_fp_op_type[i]) {
            m_fp_op_type[i] dist {
                NORMAL     := 66,
                SUBNORMAL  := 30,
                ZERO       := 1,
                INF        := 1,
                QNAN       := 1,
                SNAN       := 1
            };
        }
    }

    constraint fp_exp_c {
        foreach (m_fp_op_type[i]) {
            m_fp_op_type[i] inside {QNAN, SNAN, INF} -> { m_fp_double_operands[i].exponent == '1;
                                                          m_fp_single_operands[i].exponent == '1; 
                                                        }
            m_fp_op_type[i] inside {ZERO, SUBNORMAL} -> { m_fp_double_operands[i].exponent == '0;
                                                          m_fp_single_operands[i].exponent == '0;
                                                        }
        }
    }

    constraint fp_mant_cfg_c { 
        foreach (m_fp_mant_cfg[i]) {
            m_fp_mant_cfg[i] dist { ALL_ZEROS    := 10,
                                    ALL_ONES     := 10,
                                    WALKING_ONE  := 30,
                                    WALKING_ZERO := 30,
                                    RANDOM       := 20
                                  };
        }
    }

    constraint double_mant_c {
        foreach (m_fp_op_type[i]) {
            m_fp_op_type[i] inside {ZERO, INF}         -> m_fp_double_operands[i].mantissa == '0;
            m_fp_op_type[i] inside {SNAN}              -> m_fp_double_operands[i].mantissa[FP64_MAN_BITS-1] == 1'b0;
            m_fp_op_type[i] inside {SUBNORMAL, NORMAL} -> {
                (m_fp_mant_cfg[i] == ALL_ZEROS)    ->  m_fp_double_operands[i].mantissa == '0;
                (m_fp_mant_cfg[i] == ALL_ONES)     ->  m_fp_double_operands[i].mantissa == '1;
                (m_fp_mant_cfg[i] == WALKING_ONE)  ->  $countones(m_fp_double_operands[i].mantissa) == 1;
                (m_fp_mant_cfg[i] == WALKING_ZERO) ->  $countones(m_fp_double_operands[i].mantissa) == 51;
            }
        }
    }

    constraint single_mant_c {
        foreach (m_fp_op_type[i]) {
            m_fp_op_type[i] inside {ZERO, INF}         -> m_fp_single_operands[i].mantissa == '0;
            m_fp_op_type[i] inside {SNAN}              -> m_fp_single_operands[i].mantissa[FP32_MAN_BITS-1] == 1'b0;
            m_fp_op_type[i] inside {SUBNORMAL, NORMAL} -> {
                (m_fp_mant_cfg[i] == ALL_ZEROS)    ->  m_fp_single_operands[i].mantissa == '0;
                (m_fp_mant_cfg[i] == ALL_ONES)     ->  m_fp_single_operands[i].mantissa == '1;
                (m_fp_mant_cfg[i] == WALKING_ONE)  ->  $countones(m_fp_single_operands[i].mantissa) == 1;
                (m_fp_mant_cfg[i] == WALKING_ZERO) ->  $countones(m_fp_single_operands[i].mantissa) == 22;
            }
        }
    }

    constraint operands_c {
        if (m_operation == FCVT_F2F)
        {
            (m_imm == 1) -> {
                m_operand_a == m_fp_double_operands[0];
            } 
            (m_imm == 0) -> {
                m_operand_a == m_fp_single_operands[0];
            } 
        }
        else if (m_operation == FCVT_I2F) {
            m_operand_a == m_int_operand;
        }
        else {
            (m_fmt == 1) -> {
                m_operand_a == m_fp_double_operands[0];
                m_operand_b == m_fp_double_operands[1];
                m_imm       == m_fp_double_operands[2];
            } 
            (m_fmt == 0) -> {
                m_operand_a == m_fp_single_operands[0];
                m_operand_b == m_fp_single_operands[1];
                m_imm       == m_fp_single_operands[2];
            } 
        }
    }

    constraint delay_range_c  { m_delay dist { 0 := 50 , [1:10] :/ 30 , [11:25] :/ 15,  [26:31] :/ 4,  [40:100] :/ 1}; }

    constraint int_values_cfg_c { m_int_op_type dist {BOUND_VALUES := 10, RANDOM_INT := 90 }; }

    constraint int_operand_c { (m_int_op_type == BOUND_VALUES) -> {m_int_operand inside {special_int_values} }; }

    // RMM -> Not supported by MPFR library
    constraint rm_c { m_rm <= 3; }

    constraint rm_fcmp_c { (m_operation == FCMP) -> m_rm <= 2; }
    
    constraint rm_fmv_c { (m_operation inside {FMV_F2X, FMV_X2F}) -> m_rm == 3; }

    constraint rm_fmin_max_c { (m_operation == FMIN_MAX) -> m_rm <= 1; }

    // Unused field
    constraint unused_c { m_prec == 0; }

    constraint imm_c { (m_operation inside {FCVT_F2F, FCVT_F2I, FCVT_I2F } ) -> m_imm inside {0, 1, 2, 3}; }

    constraint fpu_operator_c { m_operation inside {[int'(FADD) : int'(FCLASS)]} ; }

    constraint m_req_tid_c   { !(m_trans_id inside {q_inflight_tid});}

    function void post_randomize();
        // NaN Boxing
        // Set all unused high-order bits of narrow formats to '1, 
        // otherwise the value is considered invalid (a NaN)
        int unsigned FP_WIDTH  = m_operation == FCVT_F2F ? fpnew_pkg::fp_width(fpnew_pkg::fp_format_e'(m_imm[1:0])) : fpnew_pkg::fp_width(fpnew_pkg::fp_format_e'(m_fmt));
        logic [CVA6Cfg.XLEN-1:0] all_ones = ('1) << FP_WIDTH;
        
        m_operand_a = m_operand_a & ((1 << FP_WIDTH) - 1) | all_ones;
        m_operand_b = m_operand_b & ((1 << FP_WIDTH) - 1) | all_ones;
        m_imm       = m_imm & ((1 << FP_WIDTH) - 1) | all_ones;
    endfunction

    // -------------------------------------------------------------------------
    // Constructor
    // -------------------------------------------------------------------------
    function new(string name = "fpu_txn");
        super.new(name);
    endfunction: new

endclass: fpu_txn