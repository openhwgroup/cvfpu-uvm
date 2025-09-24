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
 *  Description   : Top configuration of the CVFPU UVM testbench
 *  History       :
 */

class fpu_top_cfg extends uvm_object;

    `uvm_object_utils(fpu_top_cfg);

    rand bit m_reset_on_the_fly;
    rand bit m_flush_on_the_fly;
        
    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    function new(string name = "fpu_top_cfg");
        super.new(name);
    endfunction

    // ---------------------------------------------
    //          API
    // ---------------------------------------------
    virtual function bit get_reset_on_the_fly();
        return m_reset_on_the_fly;
    endfunction

    virtual function bit get_flush_on_the_fly();
        return m_flush_on_the_fly;
    endfunction

    // ------------------------------------------------------------------------
    // convert2string
    // ------------------------------------------------------------------------
    virtual function string convert2string;
        string s;
        s = super.convert2string();
        s = { s, $sformatf( "Reset on the Fly =%0d, "  ,  m_reset_on_the_fly) };
        s = { s, $sformatf( "Flush on the Fly =%0d, "  ,  m_flush_on_the_fly) };
        return s;
    endfunction: convert2string

    constraint reset_on_the_fly_c    {m_reset_on_the_fly dist {1 := 10, 0 := 90};} // insert reset on the fly 10% of the time
    constraint flush_on_the_fly_c    {m_flush_on_the_fly dist {1 := 10, 0 := 90};} // insert flush on the fly 10% of the time

endclass : fpu_top_cfg

