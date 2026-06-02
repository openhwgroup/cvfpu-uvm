class fpu_comput_cov extends uvm_subscriber #(fpu_obs_txn);
    `uvm_component_utils(fpu_comput_cov)

    // -------------------------------------------------------------------------
    // CG_ARITH - FADD & FSUB
    // -------------------------------------------------------------------------
    covergroup cg_fadd_fsub with function sample(
        ariane_pkg::fu_op      op,
        fpnew_pkg::classmask_e op1_class,
        fpnew_pkg::classmask_e op2_class,
        logic                  fmt,       // 0 = FP32, 1 = FP64
        logic [2:0]            rnd_mode,
        logic [4:0]            flags,         // {NV, DZ, OF, UF, NX}
        fpnew_pkg::classmask_e res_class
    );
        option.per_instance = 1;

        cp_op: coverpoint op { 
            bins add = {FADD}; 
            bins sub = {FSUB}; 
        }

        cp_op1_class: coverpoint op1_class; // Covers all 10 classes
        cp_op2_class: coverpoint op2_class; // Covers all 10 classes
        
        cp_res_class: coverpoint res_class {
            bins neg_inf     = {fpnew_pkg::NEGINF};
            bins neg_normal  = {fpnew_pkg::NEGNORM};
            bins neg_subnorm = {fpnew_pkg::NEGSUBNORM};
            bins neg_zero    = {fpnew_pkg::NEGZERO};
            bins pos_zero    = {fpnew_pkg::POSZERO};
            bins pos_subnorm = {fpnew_pkg::POSSUBNORM};
            bins pos_normal  = {fpnew_pkg::POSNORM};
            bins pos_inf     = {fpnew_pkg::POSINF};
            bins qnan        = {fpnew_pkg::QNAN};
            ignore_bins snan = {fpnew_pkg::SNAN};
        }

        cp_fmt: coverpoint fmt;

        cp_rnd_mode: coverpoint rnd_mode {
            bins rne = {3'd0};
            bins rtz = {3'd1};
            bins rdn = {3'd2};
            bins rup = {3'd3};
            ignore_bins rmm = {3'd4};
        }
        
        cp_flags: coverpoint flags {
            bins NO_EXCEPTION = {'h0};
            wildcard bins NX = {5'b????1}; // Bit 0: Inexact
            wildcard bins UF = {5'b???1?}; // Bit 1: Underflow
            wildcard bins OF = {5'b??1??}; // Bit 2: Overflow
            wildcard bins NV = {5'b1????}; // Bit 4: Invalid Operation
        }

        cp_sub_zero_rne: coverpoint (op==FSUB && op1_class==fpnew_pkg::POSZERO && op2_class==fpnew_pkg::POSZERO && rnd_mode==3'd0) {
            bins sub_zero_rne = {1'b1}; // Covers the case of +0 - (+0) with RNE rounding mode yielding a subnormal result
        }

        cp_sub_zero_rdn: coverpoint (op==FSUB && op1_class==fpnew_pkg::POSZERO && op2_class==fpnew_pkg::POSZERO && rnd_mode==3'd2) {
            bins sub_zero_rdn = {1'b1}; // Covers the case of +0 - (+0) with RDN rounding mode yielding a subnormal result
        }

        cp_underflow_normal_res: coverpoint (
            (op inside {FADD, FSUB}) &&
            (op1_class inside {fpnew_pkg::POSSUBNORM, fpnew_pkg::NEGSUBNORM}) &&
            (op2_class inside {fpnew_pkg::POSSUBNORM, fpnew_pkg::NEGSUBNORM}) &&
            (res_class inside {fpnew_pkg::POSNORM, fpnew_pkg::NEGNORM}) &&
            ((flags & 5'b00010) != 5'b0)
        ) {
            bins hit = {1'b1}; // Underflow with normal result: subnormal +/- subnormal -> normal with UF set
        }

        // cx_norm_res_uf: cross cp_op, cp_op1_class, cp_op2_class, cp_res_class, cp_flags {
        //     // Underflow with normal result: FADD/FSUB of two subnormals yielding a normal result
        //     bins underflow_normal = (binsof(cp_op.add) || binsof(cp_op.sub)) &&
        //                              (binsof(cp_op1_class) intersect {fpnew_pkg::POSSUBNORM, fpnew_pkg::NEGSUBNORM}) &&
        //                              (binsof(cp_op2_class) intersect {fpnew_pkg::POSSUBNORM, fpnew_pkg::NEGSUBNORM}) &&
        //                              (binsof(cp_res_class) intersect {fpnew_pkg::POSNORM, fpnew_pkg::NEGNORM}) && binsof(cp_flags.UF);

        //     bins exact_normal = (binsof(cp_op.add) || binsof(cp_op.sub)) &&
        //                              (binsof(cp_op1_class) intersect {fpnew_pkg::POSSUBNORM, fpnew_pkg::NEGSUBNORM}) &&
        //                              (binsof(cp_op2_class) intersect {fpnew_pkg::POSSUBNORM, fpnew_pkg::NEGSUBNORM}) &&
        //                              (binsof(cp_res_class) intersect {fpnew_pkg::POSNORM, fpnew_pkg::NEGNORM}) && binsof(cp_flags.NO_EXCEPTION);
        // }

        // Invalid exception coverage
        // cx_invalid: cross cp_op, cp_op1_class, cp_op2_class, cp_flags {
        //     // FADD/FSUB of infinity with infinity
        //     bins inf_inf = (binsof(cp_op.add) || binsof(cp_op.sub)) &&
        //                     (binsof(cp_op1_class) intersect {fpnew_pkg::POSINF, fpnew_pkg::NEGINF}) &&
        //                     (binsof(cp_op2_class) intersect {fpnew_pkg::POSINF, fpnew_pkg::NEGINF}) && binsof(cp_flags.NV);

        //     // FADD/FSUB of NaN with any operand class
        //     bins nan_any = (binsof(cp_op.add) || binsof(cp_op.sub)) &&
        //                     ((binsof(cp_op1_class) intersect {fpnew_pkg::SNAN}) ||
        //                      (binsof(cp_op2_class) intersect {fpnew_pkg::SNAN})) && binsof(cp_flags.NV);
        // }

        // cx_fadd_fsub_op1_class_x_op2_class_x_fmt: cross cp_op, cp_op1_class, cp_op2_class, cp_fmt;

        // cx_norm_res_uf_x_rnd: cross cp_underflow_normal_res, cp_rnd_mode;
    endgroup

    // -------------------------------------------------------------------------
    // CG_ARITH - FMUL & FDIV
    // -------------------------------------------------------------------------
    covergroup cg_fmul_fdiv with function sample(
        ariane_pkg::fu_op      op,
        fpnew_pkg::classmask_e op1_class,
        fpnew_pkg::classmask_e op2_class,
        logic                  fmt,       // 0 = FP32, 1 = FP64
        logic [2:0]            rnd_mode,
        logic [4:0]            flags,         // {NV, DZ, OF, UF, NX}
        fpnew_pkg::classmask_e res_class
    );
        option.per_instance = 1;

        cp_op: coverpoint op { 
            bins mul = {FMUL}; 
            bins div = {FDIV}; 
        }
        
        cp_op1_class: coverpoint op1_class;
        cp_op2_class: coverpoint op2_class;

        cp_res_class: coverpoint res_class {
            bins neg_inf     = {fpnew_pkg::NEGINF};
            bins neg_normal  = {fpnew_pkg::NEGNORM};
            bins neg_subnorm = {fpnew_pkg::NEGSUBNORM};
            bins neg_zero    = {fpnew_pkg::NEGZERO};
            bins pos_zero    = {fpnew_pkg::POSZERO};
            bins pos_subnorm = {fpnew_pkg::POSSUBNORM};
            bins pos_normal  = {fpnew_pkg::POSNORM};
            bins pos_inf     = {fpnew_pkg::POSINF};
            bins qnan        = {fpnew_pkg::QNAN};
            ignore_bins snan = {fpnew_pkg::SNAN};
        }

        cp_fmt: coverpoint fmt;

        cp_rnd_mode: coverpoint rnd_mode {
            bins rne = {3'd0};
            bins rtz = {3'd1};
            bins rdn = {3'd2};
            bins rup = {3'd3};
            ignore_bins rmm = {3'd4};
        }
        
        cp_flags: coverpoint flags {
            bins NO_EXCEPTION = {'h0};
            wildcard bins NX = {5'b????1}; // Bit 0: Inexact
            wildcard bins UF = {5'b???1?}; // Bit 1: Underflow
            wildcard bins OF = {5'b??1??}; // Bit 2: Overflow
            wildcard bins NV = {5'b1????}; // Bit 4: Invalid Operation
        }

        cx_fmul_fdiv_op1_class_x_op2_class_x_fmt: cross cp_op, cp_op1_class, cp_op2_class, cp_fmt;

        cx_inexact_x_rnd: cross cp_flags, cp_rnd_mode {
            bins inexact_rne = binsof(cp_flags.NX) && binsof(cp_rnd_mode.rne);
            bins inexact_rtz = binsof(cp_flags.NX) && binsof(cp_rnd_mode.rtz);
            bins inexact_rdn = binsof(cp_flags.NX) && binsof(cp_rnd_mode.rdn);
            bins inexact_rup = binsof(cp_flags.NX) && binsof(cp_rnd_mode.rup);
        }
    endgroup

    // -------------------------------------------------------------------------
    // CG_ARITH - FSQRT
    // -------------------------------------------------------------------------
    covergroup cg_fsqrt with function sample(
        fpnew_pkg::classmask_e op1_class,
        logic                  fmt,       // 0 = FP32, 1 = FP64
        logic [2:0]            rnd_mode,
        logic [4:0]            flags,         // {NV, DZ, OF, UF, NX}
        fpnew_pkg::classmask_e res_class
    );
        option.per_instance = 1;

        cp_op1_class: coverpoint op1_class;

        cp_res_class: coverpoint res_class {
            bins neg_inf     = {fpnew_pkg::NEGINF};
            bins neg_normal  = {fpnew_pkg::NEGNORM};
            bins neg_subnorm = {fpnew_pkg::NEGSUBNORM};
            bins neg_zero    = {fpnew_pkg::NEGZERO};
            bins pos_zero    = {fpnew_pkg::POSZERO};
            bins pos_subnorm = {fpnew_pkg::POSSUBNORM};
            bins pos_normal  = {fpnew_pkg::POSNORM};
            bins pos_inf     = {fpnew_pkg::POSINF};
            bins qnan        = {fpnew_pkg::QNAN};
            ignore_bins snan = {fpnew_pkg::SNAN};
        }

        cp_fmt: coverpoint fmt;

        cp_rnd_mode: coverpoint rnd_mode {
            bins rne = {3'd0};
            bins rtz = {3'd1};
            bins rdn = {3'd2};
            bins rup = {3'd3};
            ignore_bins rmm = {3'd4};
        }

        cp_flags: coverpoint flags {
            bins NO_EXCEPTION = {'h0};
            wildcard bins NX = {5'b????1}; // Bit 0: Inexact
            wildcard bins UF = {5'b???1?}; // Bit 1: Underflow
            wildcard bins OF = {5'b??1??}; // Bit 2: Overflow
            wildcard bins NV = {5'b1????}; // Bit 4: Invalid Operation
            ignore_bins DZ = {5'b?1???}; // Bit 3: Divide by Zero (for sqrt of negative)
        }

        cx_op1_class_x_fmt: cross cp_op1_class, cp_fmt;

        cx_inexact_x_rnd: cross cp_flags, cp_rnd_mode {
            bins inexact_rne = binsof(cp_flags.NX) && binsof(cp_rnd_mode.rne);
            bins inexact_rtz = binsof(cp_flags.NX) && binsof(cp_rnd_mode.rtz);
            bins inexact_rdn = binsof(cp_flags.NX) && binsof(cp_rnd_mode.rdn);
            bins inexact_rup = binsof(cp_flags.NX) && binsof(cp_rnd_mode.rup);
        }

    endgroup

    // -------------------------------------------------------------------------
    // CG_ARITH - FMIN & FMAX
    // -------------------------------------------------------------------------
    covergroup cg_fmin_fmax with function sample(
        logic                  min_max, // 0 = FMIN, 1 = FMAX
        fpnew_pkg::classmask_e op1_class,
        fpnew_pkg::classmask_e op2_class,
        logic                  fmt,
        logic [4:0]            flags,         // {NV, DZ, OF, UF, NX}
        fpnew_pkg::classmask_e res_class
    );
        option.per_instance = 1;

        cp_op: coverpoint min_max { 
            bins fmin = {0}; 
            bins fmax = {1}; 
        }
        
        cp_op1_class: coverpoint op1_class;
        cp_op2_class: coverpoint op2_class;

        cp_res_class: coverpoint res_class {
            bins neg_inf     = {fpnew_pkg::NEGINF};
            bins neg_normal  = {fpnew_pkg::NEGNORM};
            bins neg_subnorm = {fpnew_pkg::NEGSUBNORM};
            bins neg_zero    = {fpnew_pkg::NEGZERO};
            bins pos_zero    = {fpnew_pkg::POSZERO};
            bins pos_subnorm = {fpnew_pkg::POSSUBNORM};
            bins pos_normal  = {fpnew_pkg::POSNORM};
            bins pos_inf     = {fpnew_pkg::POSINF};
            bins qnan        = {fpnew_pkg::QNAN};
            ignore_bins snan = {fpnew_pkg::SNAN};
        }

        cp_fmt: coverpoint fmt;

        cp_flags: coverpoint flags {
            bins NO_EXCEPTION = {'h0};
            wildcard bins NV = {5'b1????}; // Bit 4: Invalid Operation
        }

        cx_fadd_fsub_op1_class_x_op2_class_x_fmt: cross cp_op, cp_op1_class, cp_op2_class, cp_fmt;

    endgroup

    // -------------------------------------------------------------------------
    // CG_FMA - Fused Multiply-Add
    // -------------------------------------------------------------------------
    covergroup cg_fma with function sample(
        ariane_pkg::fu_op      op,
        fpnew_pkg::classmask_e op1_class,
        fpnew_pkg::classmask_e op2_class,
        fpnew_pkg::classmask_e op3_class,
        logic                  fmt,
        logic [2:0]            rnd_mode,
        logic [4:0]            flags,         // {NV, DZ, OF, UF, NX}
        fpnew_pkg::classmask_e res_class
    );
        option.per_instance = 1;
 
        cp_op: coverpoint op { 
            bins fmadd = {FMADD}; 
            bins fmsub = {FMSUB}; 
            bins fnmsub = {FNMSUB}; 
            bins fnmadd = {FNMADD}; 
        }
        cp_op1_class: coverpoint op1_class;
        cp_op2_class: coverpoint op2_class;
        cp_op3_class: coverpoint op3_class;

        cp_res_class: coverpoint res_class {
            bins neg_inf     = {fpnew_pkg::NEGINF};
            bins neg_normal  = {fpnew_pkg::NEGNORM};
            bins neg_subnorm = {fpnew_pkg::NEGSUBNORM};
            bins neg_zero    = {fpnew_pkg::NEGZERO};
            bins pos_zero    = {fpnew_pkg::POSZERO};
            bins pos_subnorm = {fpnew_pkg::POSSUBNORM};
            bins pos_normal  = {fpnew_pkg::POSNORM};
            bins pos_inf     = {fpnew_pkg::POSINF};
            bins qnan        = {fpnew_pkg::QNAN};
            ignore_bins snan = {fpnew_pkg::SNAN};
        }

        cp_fmt: coverpoint fmt;
        
        cp_rnd_mode:  coverpoint rnd_mode {
            bins rne = {3'd0};
            bins rtz = {3'd1};
            bins rdn = {3'd2};
            bins rup = {3'd3};
            ignore_bins rmm = {3'd4};
        }
        
        cp_flags: coverpoint flags {
            bins NO_EXCEPTION = {'h0};
            wildcard bins NX = {5'b????1}; // Bit 0: Inexact
            wildcard bins UF = {5'b???1?}; // Bit 1: Underflow
            wildcard bins OF = {5'b??1??}; // Bit 2: Overflow
            wildcard bins NV = {5'b1????}; // Bit 4: Invalid Operation
        }

        cx_inexact_x_rnd: cross cp_flags, cp_rnd_mode {
            bins inexact_rne = binsof(cp_flags.NX) && binsof(cp_rnd_mode.rne);
            bins inexact_rtz = binsof(cp_flags.NX) && binsof(cp_rnd_mode.rtz);
            bins inexact_rdn = binsof(cp_flags.NX) && binsof(cp_rnd_mode.rdn);
            bins inexact_rup = binsof(cp_flags.NX) && binsof(cp_rnd_mode.rup);
        }

        cx_fma_op1_x_op2_x_op3: cross cp_op, cp_op1_class, cp_op2_class, cp_op3_class;
    endgroup

    // =========================================================================
    // UVM subscriber write() — routes each observed txn to the right covergroup
    // =========================================================================
    function void write(fpu_obs_txn t);
        case (t.m_operation)
            // -----------------------------------------------------------------
            FADD, FSUB: begin

                cg_fadd_fsub.sample(
                    t.m_operation,
                    fpu_common_pkg::classify_operand(t.m_operand_b, t.m_fmt),
                    fpu_common_pkg::classify_operand(t.m_imm, t.m_fmt),
                    t.m_fmt[0],
                    t.m_rm,
                    t.status_o,
                    fpu_common_pkg::classify_operand(t.result_o, t.m_fmt)
                );
            end

            FMUL, FDIV: begin

                cg_fmul_fdiv.sample(
                    t.m_operation,
                    fpu_common_pkg::classify_operand(t.m_operand_a, t.m_fmt),
                    fpu_common_pkg::classify_operand(t.m_operand_b, t.m_fmt),
                    t.m_fmt[0],
                    t.m_rm,
                    t.status_o,
                    fpu_common_pkg::classify_operand(t.result_o, t.m_fmt)
                );
            end

            FSQRT: begin

                cg_fsqrt.sample(
                    fpu_common_pkg::classify_operand(t.m_operand_a, t.m_fmt),
                    t.m_fmt[0],
                    t.m_rm,
                    t.status_o,
                    fpu_common_pkg::classify_operand(t.result_o, t.m_fmt)
                );
            end

            FMIN_MAX: begin

                cg_fmin_fmax.sample(
                    t.m_rm[0], // min_max: FMIN if rm[0]=0, FMAX if rm[0]=1
                    fpu_common_pkg::classify_operand(t.m_operand_a, t.m_fmt),
                    fpu_common_pkg::classify_operand(t.m_operand_b, t.m_fmt),
                    t.m_fmt[0],
                    t.status_o,
                    fpu_common_pkg::classify_operand(t.result_o, t.m_fmt)
                );
            end

            FMADD, FMSUB, FNMSUB, FNMADD: begin

                cg_fma.sample(
                    t.m_operation,
                    fpu_common_pkg::classify_operand(t.m_operand_a, t.m_fmt),
                    fpu_common_pkg::classify_operand(t.m_operand_b, t.m_fmt),
                    fpu_common_pkg::classify_operand(t.m_imm, t.m_fmt),
                    t.m_fmt[0],
                    t.m_rm,
                    t.status_o,
                    fpu_common_pkg::classify_operand(t.result_o, t.m_fmt)
                );
            end
            
        endcase
    endfunction : write

    function new(string name = "fpu_comput_cov", uvm_component parent = null);
        super.new(name, parent);
        cg_fadd_fsub = new();
        cg_fmul_fdiv = new();
        cg_fsqrt = new();
        cg_fmin_fmax = new();
        cg_fma = new();
    endfunction : new

endclass : fpu_comput_cov