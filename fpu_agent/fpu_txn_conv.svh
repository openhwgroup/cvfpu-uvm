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
 *  Creation Date : 2026
 *  Description   : 
 *  History       :
 */

class fpu_txn_conv extends fpu_txn;
    `uvm_object_utils(fpu_txn_conv)

    // =========================================================================
    // Stimulus category enum
    // =========================================================================
    typedef enum {
        // ---- FCVT_F2F stimuli -------------------------------------------
        F2F_BELLOW_SUBNORM,
        F2F_LOW_SUBNORM_UF,
        F2F_SUBNORM_NORM,
        F2F_LOW_NORMAL,
        F2F_NARROW_NORMAL,
        F2F_HIGH_NORMAL, 
        F2F_NARROW_OF,            
        F2F_NAN_INF,         // NaN / INF passthrough (either direction)
        // ---- Unconstrained ----------------------------------------------
        CONV_RANDOM          // fully random within {F2I, I2F, F2F}
    } conv_stim_e;

    rand conv_stim_e m_conv_stim;

    // Mirrors m_imm[0] for F2I / I2F: 0 = INT32, 1 = INT64.
    // Keeping it as a named field makes inline constraints in sequences readable.
    rand logic m_int_wide;

    // =========================================================================
    // FP exponent boundary constants
    // =========================================================================
    // FP64 biased exponent (bias = 1023)
    localparam logic [10:0] F64_EXP_FP32_SNMIN = 11'h36A; // 2^-149 ≈ FP32 min subnormal
    localparam logic [10:0] F64_EXP_FP32_NMIN  = 11'h381; // 2^-126: FP32 min normal
    localparam logic [10:0] F64_EXP_FP32_NMAX  = 11'h47D; // 2^127 - 1: last in FP32 normal range
    localparam logic [10:0] F64_EXP_FP32_OF    = 11'h47E; // 2^127: FP32 overflow boundary
    // localparam logic [10:0] F64_EXP_FP32_SUBMAX = 11'h396; // top of FP64→FP32 subnormal zone
    localparam logic [10:0] F64_EXP_NORM_MAX    = 11'h7FE; // max normal (not INF)

    // =========================================================================
    // Solve ordering — extend parent's chain
    // =========================================================================
    constraint order_stim_op_c  { solve m_conv_stim before m_operation;  }
    constraint order_stim_fmt_c { solve m_conv_stim before m_fmt;        }
    constraint order_stim_imm_c { solve m_conv_stim before m_imm;        }
    constraint order_stim_iw_c  { solve m_conv_stim before m_int_wide;   }
    constraint order_iw_imm_c   { solve m_int_wide  before m_imm;        }

    // =========================================================================
    // Restrict operation to conversions only
    // (Intersects with parent's fpu_operator_c — no conflict since all three
    //  conversion ops lie within the FADD..FCLASS range.)
    // =========================================================================
    constraint conv_op_c {
        m_operation inside {FCVT_F2I, FCVT_I2F, FCVT_F2F};
    }

    // =========================================================================
    // Stimulus distribution
    // =========================================================================
    constraint conv_stim_dist_c {
        m_conv_stim dist {
            F2F_BELLOW_SUBNORM := 2,
            F2F_LOW_SUBNORM_UF := 3,
            F2F_SUBNORM_NORM   := 10,
            F2F_LOW_NORMAL     := 5,
            F2F_NARROW_NORMAL  := 10,
            F2F_HIGH_NORMAL    := 5, 
            F2F_NARROW_OF      := 10,            
            F2F_NAN_INF        := 5,
            CONV_RANDOM        := 50
        };
    }

    // =========================================================================
    // Bind each stimulus category to its operation
    // =========================================================================
    constraint conv_stim_op_bind_c {
        m_conv_stim inside {F2F_LOW_SUBNORM_UF, F2F_SUBNORM_NORM, F2F_LOW_NORMAL,
                            F2F_NARROW_NORMAL, F2F_HIGH_NORMAL, F2F_NARROW_OF,
                            F2F_NAN_INF}
            -> m_operation == FCVT_F2F;
        // CONV_RANDOM: any of the three — no binding constraint
    }

    // =========================================================================
    // ---- FCVT_F2I constraints -----------------------------------------------
    // =========================================================================
    constraint f2i_fp32_operand_c {
        if (m_operation == FCVT_F2I) {
            (m_fp_op_type[0] == NORMAL) ->  m_fp_single_operands[0].exponent inside {[30 : 33], [62 : 65]};
            m_fp_single_operands[1] == '0; // Unused
        }
    }

    constraint f2i_fp64_operand_c {
        if (m_operation == FCVT_F2I) {
            (m_fp_op_type[0] == NORMAL) ->  m_fp_double_operands[0].exponent inside {[30 : 33], [62 : 65]};
            m_fp_double_operands[1] == '0; // Unused
        }
    }

    // =========================================================================
    // ---- FCVT_F2F constraints -----------------------------------------------
    // =========================================================================

    // Direction encoding:
    //   Narrowing: src=FP64 (m_imm=1), dst=FP32 (m_fmt=0)
    constraint f2f_direction_c {
        m_conv_stim inside {F2F_LOW_SUBNORM_UF, F2F_SUBNORM_NORM, F2F_LOW_NORMAL,
                            F2F_NARROW_NORMAL, F2F_HIGH_NORMAL, F2F_NARROW_OF,
                            F2F_NAN_INF} -> {
            m_imm  == 64'h1;  // src = FP64
            m_fmt  == 1'b0;   // dst = FP32
        }
        // NaN/INF: accept either direction; at least one must be valid.
        m_conv_stim == F2F_NAN_INF -> {
            (m_imm == 64'h0 && m_fmt == 1'b1) ||
            (m_imm == 64'h1 && m_fmt == 1'b0);
        }
    }

    // --- fp_op_type[0] per F2F stimulus --------------------------------------
    constraint f2f_fp_type_c {
        (m_conv_stim == F2F_BELLOW_SUBNORM) -> m_fp_op_type[0] inside {NORMAL, SUBNORMAL};
        (m_conv_stim == F2F_LOW_SUBNORM_UF) -> m_fp_op_type[0] == NORMAL;
        (m_conv_stim == F2F_SUBNORM_NORM)   -> m_fp_op_type[0] == NORMAL;
        (m_conv_stim == F2F_LOW_NORMAL)     -> m_fp_op_type[0] == NORMAL;
        (m_conv_stim == F2F_NARROW_NORMAL)  -> m_fp_op_type[0] == NORMAL;
        (m_conv_stim == F2F_HIGH_NORMAL)    -> m_fp_op_type[0] == NORMAL;
        (m_conv_stim == F2F_NARROW_OF)      -> m_fp_op_type[0] == NORMAL;
        (m_conv_stim == F2F_NAN_INF)        -> m_fp_op_type[0] inside {INF, QNAN, SNAN};
    }

    // --- FP64 source exponent ranges for narrowing (m_imm == 1) --------------
    // fp_exp_c in parent handles INF/NaN exponents; only NORMAL ranges below.
    constraint f2f_narrow_exp_c {
        if (m_operation == FCVT_F2F && m_imm == 64'h1) {
            // Strictly bellow subnormal boundary → UF
            (m_conv_stim == F2F_BELLOW_SUBNORM) ->
                m_fp_double_operands[0].exponent
                    inside {[0 : F64_EXP_FP32_SNMIN - 2]};
            
            // Around min subnormal boundary → UF or subnormal result
            (m_conv_stim == F2F_LOW_SUBNORM_UF) ->
                m_fp_double_operands[0].exponent
                    inside {[F64_EXP_FP32_SNMIN - 1 : F64_EXP_FP32_SNMIN + 1]};

            // Below FP32 min-normal but above FP32 min-subnormal → UF / subnormal result
            (m_conv_stim == F2F_SUBNORM_NORM) ->
                m_fp_double_operands[0].exponent
                    inside {[F64_EXP_FP32_SNMIN + 2 : F64_EXP_FP32_NMIN - 2]};
            
            (m_conv_stim == F2F_LOW_NORMAL) ->
                m_fp_double_operands[0].exponent
                    inside {[F64_EXP_FP32_NMIN -1 : F64_EXP_FP32_NMIN + 1]};

            // Well within FP32 normal range: no OF / UF / NX expected
            (m_conv_stim == F2F_NARROW_NORMAL) ->
                m_fp_double_operands[0].exponent
                    inside {[F64_EXP_FP32_NMIN + 2 : F64_EXP_FP32_NMAX - 2]};
            
            (m_conv_stim == F2F_HIGH_NORMAL) ->
                m_fp_double_operands[0].exponent
                    inside {[F64_EXP_FP32_NMAX -1 : F64_EXP_FP32_NMAX + 1]};

            // Near / above FP32 overflow boundary → OF flag
            (m_conv_stim == F2F_NARROW_OF) ->
                m_fp_double_operands[0].exponent
                    inside {[F64_EXP_FP32_NMAX + 2 : F64_EXP_NORM_MAX]};
       }
    }

    // =========================================================================
    // post_randomize override
    // =========================================================================
    // For FCVT_I2F the operand is a raw integer; NaN-boxing its bits would
    // corrupt INT_MIN, UINT_MAX, etc.  Skip the parent boxing in that case.
    function void post_randomize();
        if (m_operation == FCVT_I2F)
            return;
        super.post_randomize();
    endfunction

    // =========================================================================
    // Constructor
    // =========================================================================
    function new(string name = "fpu_txn_conv");
        super.new(name);
    endfunction : new

endclass : fpu_txn_conv
