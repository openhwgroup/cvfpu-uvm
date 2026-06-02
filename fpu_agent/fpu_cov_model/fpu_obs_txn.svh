/*
 *  Copyright (c) 2025 CEA*
 *  *Commissariat a l'Energie Atomique et aux Energies Alternatives (CEA)
 *
 *  SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
 *
 *  Unless required by applicable law or agreed to in writing, any work
 *  distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 *  WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
 *  License for the specific language governing permissions and limitations
 *  under the License.
 */
/*
 *  Authors       : Ihsane TAHIR
 *  Creation Date : 2025
 *  Description   : Observed transaction for the conversion coverage collector.
 *                  Pairs the stimulus fields captured from fpu_txn with the
 *                  DUT response captured by the monitor.
 *
 */

class fpu_obs_txn extends uvm_object;
    `uvm_object_utils(fpu_obs_txn)

    // -------------------------------------------------------------------------
    // Stimulus fields (copied from the sent fpu_txn / fpu_txn_conv)
    // -------------------------------------------------------------------------
    ariane_pkg::fu_op   m_operation;
    logic [1:0]         m_fmt;
    logic [2:0]         m_rm;
    logic [63:0]        m_imm;
    logic [63:0]        m_operand_a;
    logic [63:0]        m_operand_b;

    // -------------------------------------------------------------------------
    // DUT response fields (filled by monitor)
    // -------------------------------------------------------------------------
    logic [63:0]        result_o;      // DUT result word
    logic [4:0]         status_o;      // {NV, DZ, OF, UF, NX}

    // -------------------------------------------------------------------------
    // Convenience flag accessors
    // -------------------------------------------------------------------------
    function logic flag_nv(); return status_o[4]; endfunction
    function logic flag_dz(); return status_o[3]; endfunction
    function logic flag_of(); return status_o[2]; endfunction
    function logic flag_uf(); return status_o[1]; endfunction
    function logic flag_nx(); return status_o[0]; endfunction
    function logic no_flags(); return (status_o == 5'h0); endfunction

    // -------------------------------------------------------------------------
    // Format helpers
    // -------------------------------------------------------------------------
    // src FP format for each operation type
    function logic src_fp_fmt();
        if (m_operation == FCVT_F2F)
            return m_imm[0];   // m_imm[1:0] = src fmt; [0] selects FP32 vs FP64
        else
            return m_fmt[0];   // FCLASS, FCVT_F2I
    endfunction

    // int width for F2I / I2F
    function logic int_wide();   return m_imm[1]; endfunction
    // unsigned flag for F2I / I2F
    function logic unsigned_op(); return m_imm[0]; endfunction

    // F2I: stimulus kind inferred from output flags and input operand
    typedef enum logic [4:0] { 
        F2I_OOR_INT32_POS,
        F2I_OOR_INT32_NEG,
        F2I_OOR_UINT32_POS,
        F2I_OOR_UINT32_NEG,
        F2I_OOR_INT64_POS,
        F2I_OOR_INT64_NEG,
        F2I_OOR_UINT64_POS,
        F2I_OOR_UINT64_NEG,
        F2I_BOUND_INEXACT_INT32, // Within range but inexact
        F2I_BOUND_EXACT_INT32, // Within range but exact
        F2I_BOUND_INEXACT_UINT32,
        F2I_BOUND_EXACT_UINT32,
        F2I_BOUND_INEXACT_INT64,
        F2I_BOUND_EXACT_INT64,
        F2I_BOUND_INEXACT_UINT64,
        F2I_BOUND_EXACT_UINT64
    } f2i_domains_e;

    function f2i_domains_e classify_f2i_stim();
        unique case (m_imm[1:0])
            2'b00:  // INT32
                if ((get_exp(m_operand_a, m_fmt) >= 31) && flag_nv())
                    return (get_operand_sign(m_operand_a, m_fmt)) ? F2I_OOR_INT32_NEG : F2I_OOR_INT32_POS;
                else if (flag_nx())
                    return F2I_BOUND_INEXACT_INT32;
                else if (no_flags())
                    return F2I_BOUND_EXACT_INT32;
            2'b01:  // UINT32
                if ((get_exp(m_operand_a, m_fmt) >= 32) && flag_nv())
                    return (get_operand_sign(m_operand_a, m_fmt)) ? F2I_OOR_UINT32_NEG : F2I_OOR_UINT32_POS;
                else if (flag_nx())
                    return F2I_BOUND_INEXACT_UINT32;
                else if (no_flags())
                    return F2I_BOUND_EXACT_UINT32;
            2'b10:  // INT64
                if ((get_exp(m_operand_a, m_fmt) >= 63) && flag_nv())
                    return (get_operand_sign(m_operand_a, m_fmt)) ? F2I_OOR_INT64_NEG : F2I_OOR_INT64_POS;
                else if (flag_nx())
                    return F2I_BOUND_INEXACT_INT64;
                else if (no_flags())
                    return F2I_BOUND_EXACT_INT64;
            2'b11:  // UINT64
                if ((get_exp(m_operand_a, m_fmt) >= 64) && flag_nv())
                    return (get_operand_sign(m_operand_a, m_fmt)) ? F2I_OOR_UINT64_NEG : F2I_OOR_UINT64_POS;
                else if (flag_nx())
                    return F2I_BOUND_INEXACT_UINT64;
                else if (no_flags())
                    return F2I_BOUND_EXACT_UINT64;
        endcase
    endfunction

    // I2F: stimulus kind inferred from the integer input value
    typedef enum logic [2:0] {
        I2F_STIM_ZERO,
        INT32_I2F_STIM_INT_MIN,
        INT64_I2F_STIM_INT_MIN,
        I2F_STIM_ROUNDS,    // NX flag set — rounding occurred
        I2F_STIM_OTHER
    } i2f_stim_kind_e;

    function i2f_stim_kind_e classify_i2f_stim();
        if (m_operand_a == '0)
            return I2F_STIM_ZERO;
        else if (m_imm[1:0] == 2'b00 && m_operand_a[31:0] == 32'h8000_0000)
            return INT32_I2F_STIM_INT_MIN;
        else if (m_imm[1:0] == 2'b10 && m_operand_a == 64'h8000_0000_0000_0000)
            return INT64_I2F_STIM_INT_MIN;
        else if (flag_nx())
            return I2F_STIM_ROUNDS;
        else
            return I2F_STIM_OTHER;
    endfunction

    // -------------------------------------------------------------------------
    // Constructor
    // -------------------------------------------------------------------------
    function new(string name = "fpu_obs_txn");
        super.new(name);
    endfunction : new

endclass : fpu_obs_txn
