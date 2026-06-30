module cvfpu_sva
  import ariane_pkg::*;
#(
    parameter config_pkg::cva6_cfg_t CVA6Cfg = config_pkg::cva6_cfg_empty,
    parameter type exception_t = logic,
    parameter type fu_data_t = logic
) (
    input  logic                                   clk_i,
    input  logic                                   rst_ni,
    input  logic                                   flush_i,
    input  logic                                   fpu_valid_i,
    input  logic                                   fpu_ready_o,
    input  fu_data_t                               fu_data_i,

    input  logic [1:0]                             fpu_fmt_i,
    input  logic [2:0]                             fpu_rm_i,
    input  logic [2:0]                             fpu_frm_i,
    input  logic [6:0]                             fpu_prec_i,
    input  logic [CVA6Cfg.TRANS_ID_BITS-1:0]       fpu_trans_id_o,
    input  logic [CVA6Cfg.FLen-1:0]                result_o,
    input  logic                                   fpu_valid_o,
    input  exception_t                             fpu_exception_o,
    input  logic                                   fpu_early_valid_o
);

  /* pragma translate_off */

  // -------------------------------------------------------------------------
  // Input side
  // -------------------------------------------------------------------------
  fpu_valid_i_assert : assert property ( @(posedge clk_i) disable iff(!rst_ni)
    !$isunknown(fpu_valid_i) );
  fpu_ready_o_assert : assert property ( @(posedge clk_i) disable iff(!rst_ni)
    !$isunknown(fpu_ready_o) );
  flush_i_assert     : assert property ( @(posedge clk_i) disable iff(!rst_ni)
    !$isunknown(flush_i) );

  fu_data_i_assert : assert property ( @(posedge clk_i) disable iff(!rst_ni)
    ( fpu_valid_i ) -> !$isunknown( fu_data_i ) );
  fpu_fmt_i_assert : assert property ( @(posedge clk_i) disable iff(!rst_ni)
    ( fpu_valid_i ) -> !$isunknown( fpu_fmt_i ) );
  fpu_rm_i_assert  : assert property ( @(posedge clk_i) disable iff(!rst_ni)
    ( fpu_valid_i ) -> !$isunknown( fpu_rm_i ) );
  fpu_frm_i_assert : assert property ( @(posedge clk_i) disable iff(!rst_ni)
    ( fpu_valid_i ) -> !$isunknown( fpu_frm_i ) );
  fpu_prec_i_assert : assert property ( @(posedge clk_i) disable iff(!rst_ni)
    ( fpu_valid_i ) -> !$isunknown( fpu_prec_i ) );

  // -------------------------------------------------------------------------
  // Output side
  // -------------------------------------------------------------------------
  fpu_valid_o_assert       : assert property ( @(posedge clk_i) disable iff(!rst_ni)
    !$isunknown( fpu_valid_o ) );
  fpu_early_valid_o_assert : assert property ( @(posedge clk_i) disable iff(!rst_ni)
    !$isunknown( fpu_early_valid_o ) );

  fpu_trans_id_o_assert : assert property ( @(posedge clk_i) disable iff(!rst_ni)
    ( fpu_valid_o ) -> !$isunknown( fpu_trans_id_o ) );
  result_o_assert : assert property ( @(posedge clk_i) disable iff(!rst_ni)
    ( fpu_valid_o ) -> !$isunknown( result_o ) );
  fpu_exception_o_assert : assert property ( @(posedge clk_i) disable iff(!rst_ni)
    ( fpu_valid_o ) -> !$isunknown( fpu_exception_o ) );

  /* pragma translate_on */

endmodule