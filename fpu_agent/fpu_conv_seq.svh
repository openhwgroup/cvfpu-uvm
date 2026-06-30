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