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
 *  Description : Conversion-unit sequences for the CVFPU UVM testbench.
 *                All sequences extend fpu_base_sequence and use fpu_txn_conv
 *                items so that the factory override path is preserved.
 *
 *  Sequences provided
 *  ──────────────────
 *  fpu_conv_seq          Weighted-random across all conversion stimuli.
 *                        Drop-in replacement for fpu_random_op_seq when
 *                        op_group == 3.
 * 
 *  fpu_f2f_conv_seq      Two-phase sweep: widening (FP32→FP64) then narrowing
 *                        (FP64→FP32), each stimulus repeated across all four
 *                        rounding modes.
 */

// ============================================================================
//  fpu_conv_seq — weighted random across every conversion stimulus
// ============================================================================
class fpu_conv_seq extends fpu_base_sequence;
    `uvm_object_utils(fpu_conv_seq)

    fpu_txn_conv item;

    function new(string name = "fpu_conv_seq");
        super.new(name);
    endfunction : new

    virtual task body();
        super.body();
        item = fpu_txn_conv::type_id::create("fpu_conv_req");

        for (int i = 0; i < num_txn; i++) begin
            item.q_inflight_tid = my_sequencer.q_inflight_tid;

            if (!item.randomize())
                `uvm_fatal("fpu_conv_seq::body", "Randomization failed");

            my_sequencer.q_inflight_tid[item.m_trans_id] = item.m_trans_id;
            start_item(item);
            finish_item(item);
        end
    endtask : body

endclass : fpu_conv_seq