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
 *  Description   : Sequences of the CVFPU UVM testbench
 *  History       :
 */

///////////////////////////////////////////////////////////
//              FPU BASE SEQUENCE
//////////////////////////////////////////////////////////
class fpu_base_sequence extends uvm_sequence #(fpu_txn);


    `uvm_object_utils( fpu_base_sequence )

    fpu_sequencer  my_sequencer;

    // Number of transactions in a sequence
    int            num_txn;

    ariane_pkg::fu_op operation;    // Operation to perform
    logic [1:0]       fmt;          // Floating point format
    int               op_group_cfg; // CVFPU operation group 

    // -------------------------------------------------------------------------
    // Constructor
    // -------------------------------------------------------------------------
    function new( string name = "base_data_txn_sequence" );
        super.new(name);

        if (!$value$plusargs("NB_TXNS=%d", num_txn )) begin
            num_txn = 10000;
        end // if
        
        `uvm_info( get_full_name(), $sformatf("NUM_TXN=%0d", num_txn), UVM_HIGH );

        // Enable response handler
        use_response_handler(1);
    endfunction: new

    // -------------------------------------------------------------------------
    // API
    // -------------------------------------------------------------------------
    function void set_op (input ariane_pkg::fu_op op);
        operation = op;
    endfunction

    function void set_fmt (input logic [1:0] fmt);
        this.fmt = fmt;
    endfunction

    function void set_op_group (input int op_group_cfg);
        this.op_group_cfg = op_group_cfg;
    endfunction
 
    // If the id list if full, it waits until an id is freed 
    virtual task wait_id_list( );
        int max_list_size;
        max_list_size = (2**CVA6Cfg.TRANS_ID_BITS -1) ;

        while ( my_sequencer.q_inflight_tid.size >= max_list_size) begin
            `uvm_info("FPU SEQUENCE ID LIST FULL", $sformatf("ID list size %0d(d) is full, waiting for a slot to be free",  my_sequencer.q_inflight_tid.size), UVM_HIGH);
            #10;
        end 
    endtask: wait_id_list

    // -------------------------------------------------------------------------
    // Pre Body
    // -------------------------------------------------------------------------
    virtual task pre_body();
        $cast(my_sequencer, get_sequencer());
    endtask: pre_body

    // -------------------------------------------------------------------------
    // Body
    // -------------------------------------------------------------------------
    virtual task body( );
        super.body();
    endtask

    // -------------------------------------------------------------------------
    // Pre Body
    // -------------------------------------------------------------------------
    virtual task post_body( );
        super.post_body();
        `uvm_info("FPU SEQUENCE IS NOT EMPTY", $sformatf("ID list size %0d(d) is not empty",  my_sequencer.q_inflight_tid.size), UVM_HIGH);
        
        // Waiting for the reception of all responses in the case of id management
        wait( my_sequencer.q_inflight_tid.size == 0 );
        `uvm_info("FPU SEQUENCE IS EMPTY", $sformatf("ID list size %0d(d) is empty",  my_sequencer.q_inflight_tid.size), UVM_HIGH);
    endtask

    // Customized the finish item sequence from sequence base lib 
    // The task now waits for the ID to be free before moving into the next item 
    //
    virtual task finish_item (  uvm_sequence_item 	item,	  	
                                int 	set_priority	 = 	-1);

        super.finish_item(item, set_priority);
        wait_id_list();
    endtask    

endclass: fpu_base_sequence

///////////////////////////////////////////////////////////
//              FPU SINGLE OPERATION SEQUENCE
//////////////////////////////////////////////////////////
class fpu_single_op_seq extends  fpu_base_sequence;
  
    `uvm_object_utils( fpu_single_op_seq );

    fpu_txn       item;

    // -------------------------------------------------------------------------
    // Constructor
    // -------------------------------------------------------------------------
    function new( string name = "single_txn_sequence" );
        super.new(name);
    endfunction: new

    // -------------------------------------------------------------------------
    // Body
    // -------------------------------------------------------------------------
    virtual task body( );
        super.body();


        item = fpu_txn::type_id::create("fpu single request");

        for (int i = 0; i < num_txn; i++) begin
            // --------------------------------------------------------------------------------
            // to generate unique TID a list of tid in flight is passed on to the sequence
            // --------------------------------------------------------------------------------
            item.q_inflight_tid = my_sequencer.q_inflight_tid;

            // --------------------------------
            // Randomize transaction item
            // --------------------------------
            if ( !item.randomize() with 
                {
                    m_operation == operation;
                } ) 
            begin
                `uvm_fatal("body","Randomization failed");    
            end
            // --------------------------------------------------------------------------------
            // It is used when the response is received from the driver
            // --------------------------------------------------------------------------------
            my_sequencer.q_inflight_tid[item.m_trans_id] = item.m_trans_id;

            start_item( item );
            finish_item( item );
        end
  endtask: body

endclass: fpu_single_op_seq

///////////////////////////////////////////////////////////
//              FPU RANDOM SEQUENCE
//////////////////////////////////////////////////////////
class fpu_random_op_seq extends  fpu_base_sequence;
  
    `uvm_object_utils( fpu_random_op_seq );
    
    fpu_txn       item;

    // -------------------------------------------------------------------------
    // Constructor
    // -------------------------------------------------------------------------
    function new( string name = "single_txn_sequence" );
        super.new(name);
    endfunction: new

    // -------------------------------------------------------------------------
    // Body
    // -------------------------------------------------------------------------
    virtual task body( );
        super.body();

        item = fpu_txn::type_id::create("fpu single request");

        for (int i = 0; i < num_txn; i++) begin
            // --------------------------------------------------------------------------------
            // to generate unique TID a list of tid in flight is passed on to the sequence
            // --------------------------------------------------------------------------------
            item.q_inflight_tid = my_sequencer.q_inflight_tid;

            // --------------------------------
            // Randomize transaction item
            // --------------------------------
            if ( !item.randomize() ) 
            begin
                `uvm_fatal("body","Randomization failed");    
            end
            // --------------------------------------------------------------------------------
            // It is used when the response is received from the driver
            // --------------------------------------------------------------------------------
            my_sequencer.q_inflight_tid[item.m_trans_id] = item.m_trans_id;

            start_item( item );
            finish_item( item );            
        end
  endtask: body
endclass: fpu_random_op_seq

///////////////////////////////////////////////////////////
//              FPU OPERATION GROUP SEQUENCE
//////////////////////////////////////////////////////////
class fpu_op_group_seq extends  fpu_base_sequence;
  
    `uvm_object_utils( fpu_op_group_seq );

    fpu_txn       item;

    // -------------------------------------------------------------------------
    // Constructor
    // -------------------------------------------------------------------------
    function new( string name = "single_txn_sequence" );
        super.new(name);
    endfunction: new

    // -------------------------------------------------------------------------
    // Body
    // -------------------------------------------------------------------------
    virtual task body( );
        super.body();


        item = fpu_txn::type_id::create("fpu single request");

        for (int i = 0; i < num_txn; i++) begin
            // --------------------------------------------------------------------------------
            // to generate unique TID a list of tid in flight is passed on to the sequence
            // --------------------------------------------------------------------------------
            item.q_inflight_tid = my_sequencer.q_inflight_tid;

            // --------------------------------
            // Randomize transaction item
            // --------------------------------
            if ( !item.randomize() with 
                {
                    (m_op_group_cfg == op_group_cfg);
                    (m_op_group_cfg == 0) -> m_operation inside {FADD, FSUB, FMUL, FMADD, FMSUB, FNMADD, FNMSUB};
                    (m_op_group_cfg == 1) -> m_operation inside {FDIV, FSQRT};
                    (m_op_group_cfg == 2) -> m_operation inside {FCMP, FMIN_MAX, FSGNJ, FCLASS};
                    (m_op_group_cfg == 3) -> m_operation inside {FCVT_I2F, FCVT_F2F, FCVT_F2I, FMV_X2F, FMV_F2X};
                } ) 
            begin
                `uvm_fatal("body","Randomization failed");    
            end
            // --------------------------------------------------------------------------------
            // It is used when the response is received from the driver
            // --------------------------------------------------------------------------------
            my_sequencer.q_inflight_tid[item.m_trans_id] = item.m_trans_id;

            start_item( item );
            finish_item( item );
        end
  endtask: body

endclass: fpu_op_group_seq

class bug_f2i_seq extends  fpu_base_sequence;
  
    `uvm_object_utils( bug_f2i_seq );

    fpu_txn       item;

    // -------------------------------------------------------------------------
    // Constructor
    // -------------------------------------------------------------------------
    function new( string name = "single_txn_sequence" );
        super.new(name);
    endfunction: new

    // -------------------------------------------------------------------------
    // Body
    // -------------------------------------------------------------------------
    virtual task body( );
        super.body();

        item = fpu_txn::type_id::create("fpu single request");

        // --------------------------------------------------------------------------------
        // to generate unique TID a list of tid in flight is passed on to the sequence
        // --------------------------------------------------------------------------------
        item.q_inflight_tid = my_sequencer.q_inflight_tid;

        // --------------------------------
        // Randomize transaction item
        // --------------------------------
        if ( !item.randomize() with 
            {
                m_operation == FCVT_F2I;
                m_operand_a == 64'hc1e0000000000020;
                m_fmt       == 1;
                m_rm        == 0;
                m_imm       == 0;
            } ) 
        begin
            `uvm_fatal("body","Randomization failed");    
        end
        // --------------------------------------------------------------------------------
        // It is used when the response is received from the driver
        // --------------------------------------------------------------------------------
        my_sequencer.q_inflight_tid[item.m_trans_id] = item.m_trans_id;

        start_item( item );
        finish_item( item );

        // --------------------------------
        // Randomize transaction item
        // --------------------------------
        if ( !item.randomize() with 
            {
                m_operation == FCVT_F2I;
                m_operand_a == 64'hcf000000;
                m_fmt       == 0;
                m_rm        == 0;
                m_imm       == 0;
            } ) 
        begin
            `uvm_fatal("body","Randomization failed");    
        end

        // --------------------------------------------------------------------------------
        // It is used when the response is received from the driver
        // --------------------------------------------------------------------------------
        my_sequencer.q_inflight_tid[item.m_trans_id] = item.m_trans_id;

        start_item( item );
        finish_item( item );
  endtask: body

endclass: bug_f2i_seq

///////////////////////////////////////////////////////////
//              FPU UNIT OPERATION SEQUENCE
//////////////////////////////////////////////////////////
class fpu_unit_seq extends  fpu_base_sequence;
  
    `uvm_object_utils( fpu_unit_seq );

    fpu_txn       item;

    // -------------------------------------------------------------------------
    // Constructor
    // -------------------------------------------------------------------------
    function new( string name = "single_txn_sequence" );
        super.new(name);
    endfunction: new

    // -------------------------------------------------------------------------
    // Body
    // -------------------------------------------------------------------------
    virtual task body( );
        super.body();


        item = fpu_txn::type_id::create("fpu single request");

        for (int i = 0; i < num_txn; i++) begin
            // --------------------------------------------------------------------------------
            // to generate unique TID a list of tid in flight is passed on to the sequence
            // --------------------------------------------------------------------------------
            item.q_inflight_tid = my_sequencer.q_inflight_tid;

            // --------------------------------
            // Randomize transaction item
            // --------------------------------
            if ( !item.randomize() with 
                {
                    //-----------------------------------------------
                    //  ISSUE #145 + PR #147 ( tested and it works )
                    // m_operation == FCVT_F2I;
                    // m_operand_a == 64'hC1E0000000000000;
                    // m_fmt == 1;
                    // m_imm == 0;
                    // m_rm == 0;
                    //-----------------------------------------------
                    // ISSUE #120 -> no error in current version with THMULTI
                    // m_operation == FDIV;
                    // m_operand_a == 'h0;
                    // m_operand_b == 'h7F800000;
                    // m_fmt == 0;
                    //-----------------------------------------------
                    // ISSUE #139 -> no error in current version with THMULTI
                    // m_operation == FDIV;
                    // m_operand_a == 'h7f7fffff;
                    // m_operand_b == 'h3f7fffff;
                    // m_fmt == 0;
                    //-----------------------------------------------
                    // ISSUE #121 -> no error in current version with THMULTI
                    // m_operation == FDIV;
                    // m_operand_a == 'h00000001;
                    // m_operand_b == 'h3F800000;
                    // m_fmt       == 0;
                    //-----------------------------------------------
                    m_operation inside {FMV_F2X, FMV_X2F};
                } ) 
            begin
                `uvm_fatal("body","Randomization failed");    
            end
            // --------------------------------------------------------------------------------
            // It is used when the response is received from the driver
            // --------------------------------------------------------------------------------
            my_sequencer.q_inflight_tid[item.m_trans_id] = item.m_trans_id;

            start_item( item );
            finish_item( item );
        end
  endtask: body

endclass: fpu_unit_seq


///////////////////////////////////////////////////////////
//       FPU SINGLE OPERATION SINGLE FMT SEQUENCE
//////////////////////////////////////////////////////////
class fpu_fmt_single_op_seq extends  fpu_base_sequence;
  
    `uvm_object_utils( fpu_fmt_single_op_seq );

    fpu_txn       item;

    // -------------------------------------------------------------------------
    // Constructor
    // -------------------------------------------------------------------------
    function new( string name = "single_txn_sequence" );
        super.new(name);
    endfunction: new

    // -------------------------------------------------------------------------
    // Body
    // -------------------------------------------------------------------------
    virtual task body( );
        super.body();
        item = fpu_txn::type_id::create("fpu single request");

        for (int i = 0; i < num_txn; i++) begin
            // --------------------------------------------------------------------------------
            // to generate unique TID a list of tid in flight is passed on to the sequence
            // --------------------------------------------------------------------------------
            item.q_inflight_tid = my_sequencer.q_inflight_tid;
            // --------------------------------
            // Randomize transaction item
            // --------------------------------
            if ( !item.randomize() with 
                {
                    m_operation == operation;
                    m_fmt       == fmt;
                } ) 
            begin
                `uvm_fatal("body","Randomization failed");    
            end
            // --------------------------------------------------------------------------------
            // It is used when the response is received from the driver
            // --------------------------------------------------------------------------------
            my_sequencer.q_inflight_tid[item.m_trans_id] = item.m_trans_id;

            start_item( item );
            finish_item( item );
        end
  endtask: body

endclass: fpu_fmt_single_op_seq

///////////////////////////////////////////////////////////
//              FPU RANDOM SINGLE FMT SEQUENCE
//////////////////////////////////////////////////////////
class fpu_fmt_random_op_seq extends  fpu_base_sequence;
  
    `uvm_object_utils( fpu_fmt_random_op_seq );
    
    fpu_txn       item;

    // -------------------------------------------------------------------------
    // Constructor
    // -------------------------------------------------------------------------
    function new( string name = "single_txn_sequence" );
        super.new(name);
    endfunction: new

    // -------------------------------------------------------------------------
    // Body
    // -------------------------------------------------------------------------
    virtual task body( );
        super.body();

        item = fpu_txn::type_id::create("fpu single request");

        for (int i = 0; i < num_txn; i++) begin
            // --------------------------------------------------------------------------------
            // to generate unique TID a list of tid in flight is passed on to the sequence
            // --------------------------------------------------------------------------------
            item.q_inflight_tid = my_sequencer.q_inflight_tid;

            // --------------------------------
            // Randomize transaction item
            // --------------------------------
            if ( !item.randomize() with { m_fmt == fmt; } ) 
            begin
                `uvm_fatal("body","Randomization failed");    
            end
            // --------------------------------------------------------------------------------
            // It is used when the response is received from the driver
            // --------------------------------------------------------------------------------
            my_sequencer.q_inflight_tid[item.m_trans_id] = item.m_trans_id;

            start_item( item );
            finish_item( item );            
        end
  endtask: body
endclass: fpu_fmt_random_op_seq


///////////////////////////////////////////////////////////
//              FPU OPERATION GROUP SINGLE FMT SEQUENCE
//////////////////////////////////////////////////////////
class fpu_fmt_op_group_seq extends  fpu_base_sequence;
  
    `uvm_object_utils( fpu_fmt_op_group_seq );

    fpu_txn       item;

    // -------------------------------------------------------------------------
    // Constructor
    // -------------------------------------------------------------------------
    function new( string name = "single_txn_sequence" );
        super.new(name);
    endfunction: new

    // -------------------------------------------------------------------------
    // Body
    // -------------------------------------------------------------------------
    virtual task body( );
        super.body();


        item = fpu_txn::type_id::create("fpu single request");

        for (int i = 0; i < num_txn; i++) begin
            // --------------------------------------------------------------------------------
            // to generate unique TID a list of tid in flight is passed on to the sequence
            // --------------------------------------------------------------------------------
            item.q_inflight_tid = my_sequencer.q_inflight_tid;

            // --------------------------------
            // Randomize transaction item
            // --------------------------------
            if ( !item.randomize() with 
                {
                    m_fmt == fmt;
                    m_op_group_cfg == op_group_cfg;
                    (m_op_group_cfg == 0) -> m_operation inside {FADD, FSUB, FMUL, FMADD, FMSUB, FNMADD, FNMSUB};
                    (m_op_group_cfg == 1) -> m_operation inside {FDIV, FSQRT};
                    (m_op_group_cfg == 2) -> m_operation inside {FCMP, FMIN_MAX, FSGNJ, FCLASS};
                    (m_op_group_cfg == 3) -> m_operation inside {FCVT_I2F, FCVT_F2F, FCVT_F2I, FMV_X2F, FMV_F2X};
                } ) 
            begin
                `uvm_fatal("body","Randomization failed");    
            end
            // --------------------------------------------------------------------------------
            // It is used when the response is received from the driver
            // --------------------------------------------------------------------------------
            my_sequencer.q_inflight_tid[item.m_trans_id] = item.m_trans_id;

            start_item( item );
            finish_item( item );
        end
  endtask: body

endclass: fpu_fmt_op_group_seq