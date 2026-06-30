module cvfpu_rsp_arb_sva #(
  parameter int unsigned NumIn      = 64,
  parameter int unsigned IdxWidth   = (NumIn > 32'd1) ? unsigned'($clog2(NumIn)) : 32'd1,
  parameter type idx_t      = logic [IdxWidth-1:0],
  parameter bit          AxiVldRdy  = 1'b1,
  parameter type         DataType   = logic
) (
  input  logic                clk_i,
  input  logic                rst_ni,
  input  logic                flush_i,
  input  idx_t                rr_i,
  input  logic    [NumIn-1:0] req_i,
  input  logic    [NumIn-1:0] gnt_o,
  input  DataType [NumIn-1:0] data_i,
  input  logic                req_o,
  input  logic                gnt_i,
  input  DataType             data_o,
  input  idx_t                idx_o
);
  /* pragma translate_off */

  // A granted input must actually be requesting.
  // generate
  //   for (genvar i = 0; i < NumIn; i++) begin : gen_gnt_matches_req
  //     a_gnt_matches_req: assert property (@(posedge clk_i) disable iff (!rst_ni || flush_i)
  //       gnt_o[i] |-> req_i[i])
  //     else $error("cvfpu_rsp_arb: gnt_o[%0d] asserted while req_i[%0d] is low", i, i);
  //   end
  // endgenerate

  // If the request vector is stable and downstream is not accepting, the grant
  // should remain stable as well.
  a_gnt_stable_under_backpressure: assert property (@(posedge clk_i) disable iff (!rst_ni || flush_i)
    ($stable(req_i) && req_o && !gnt_i) |=> $stable(gnt_o))
  else $error("cvfpu_rsp_arb: gnt_o changed under stable backpressure");

  // ------------------------------------------------------------------------
  // Coverage: all possible request scenarios
  // ------------------------------------------------------------------------
  // Note: this is practical only for relatively small NumIn. With NumIn=64,
  // exhaustive bitmap coverage is not realistic in compiled code.
  if (NumIn <= 8) begin : gen_small_req_mask_cov
    for (genvar m = 0; m < (1 << NumIn); m++) begin : gen_req_mask_cov
      c_req_mask_seen: cover property (@(posedge clk_i) disable iff (!rst_ni || flush_i)
        req_i == m[NumIn-1:0]);
    end
  end

  // Coverage: each requester can be granted.
  generate
    for (genvar i = 0; i < NumIn; i++) begin : gen_grant_cov
      c_grant_seen: cover property (@(posedge clk_i) disable iff (!rst_ni || flush_i)
        gnt_o[i]);
    end
  endgenerate

  // Coverage: singleton requests are seen and granted.
  generate
    for (genvar i = 0; i < NumIn; i++) begin : gen_singleton_cov
      localparam logic [NumIn-1:0] ONEHOT_REQ = logic'(1'b1) << i;

      c_singleton_request_seen: cover property (@(posedge clk_i) disable iff (!rst_ni || flush_i)
        req_i == ONEHOT_REQ);

      c_singleton_request_granted: cover property (@(posedge clk_i) disable iff (!rst_ni || flush_i)
        (req_i == ONEHOT_REQ && gnt_i) ##0 gnt_o[i]);
    end
  endgenerate

  // Coverage: full contention.
  c_all_requesting_seen: cover property (@(posedge clk_i) disable iff (!rst_ni || flush_i)
    req_i == {NumIn{1'b1}});

  generate
    for (genvar i = 0; i < NumIn; i++) begin : gen_full_contention_grant_cov
      c_all_requesting_grant_i: cover property (@(posedge clk_i) disable iff (!rst_ni || flush_i)
        (req_i == {NumIn{1'b1}} && gnt_i) ##0 gnt_o[i]);
    end
  endgenerate

  /* pragma translate_on */

endmodule