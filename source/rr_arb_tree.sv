module rr_arb_tree #(

    parameter int unsigned NumIn = 64,

    parameter int unsigned DataWidth = 32,

    parameter type DataType = logic [DataWidth-1:0],






    parameter bit ExtPrio = 1'b0,






    parameter bit AxiVldRdy = 1'b0,






    parameter bit LockIn = 1'b0,



    parameter bit FairArb = 1'b1,


    parameter int unsigned IdxWidth = (NumIn > 32'd1) ? unsigned'($clog2(NumIn)) : 32'd1,


    parameter type idx_t = logic [IdxWidth-1:0]
) (

    input logic clk_i,

    input logic rst_ni,

    input logic flush_i,

    input idx_t rr_i,

    input logic [NumIn-1:0] req_i,

    output logic [NumIn-1:0] gnt_o,

    input DataType [NumIn-1:0] data_i,

    output logic req_o,

    input logic gnt_i,

    output DataType data_o,

    output idx_t idx_o
);


  if (NumIn == unsigned'(1)) begin : gen_pass_through
    assign req_o    = req_i[0];
    assign gnt_o[0] = gnt_i;
    assign data_o   = data_i[0];
    assign idx_o    = '0;

  end else begin : gen_arbiter
    localparam int unsigned NumLevels = unsigned'($clog2(NumIn));

    idx_t    [2**NumLevels-2:0] index_nodes;
    DataType [2**NumLevels-2:0] data_nodes;
    logic    [2**NumLevels-2:0] gnt_nodes;
    logic    [2**NumLevels-2:0] req_nodes;
    idx_t                       rr_q;
    logic    [       NumIn-1:0] req_d;


    assign req_o  = req_nodes[0];
    assign data_o = data_nodes[0];
    assign idx_o  = index_nodes[0];

    if (ExtPrio) begin : gen_ext_rr
      assign rr_q  = rr_i;
      assign req_d = req_i;
    end else begin : gen_int_rr
      idx_t rr_d;


      if (LockIn) begin : gen_lock
        logic lock_d, lock_q;
        logic [NumIn-1:0] req_q;

        assign lock_d = req_o & ~gnt_i;
        assign req_d  = (lock_q) ? req_q : req_i;

        always_ff @(posedge clk_i or negedge rst_ni) begin : p_lock_reg
          if (!rst_ni) begin
            lock_q <= '0;
          end else begin
            if (flush_i) begin
              lock_q <= '0;
            end else begin
              lock_q <= lock_d;
            end
          end
        end

        always_ff @(posedge clk_i or negedge rst_ni) begin : p_req_regs
          if (!rst_ni) begin
            req_q <= '0;
          end else begin
            if (flush_i) begin
              req_q <= '0;
            end else begin
              req_q <= req_d;
            end
          end
        end
      end else begin : gen_no_lock
        assign req_d = req_i;
      end

      if (FairArb) begin : gen_fair_arb
        logic [NumIn-1:0] upper_mask, lower_mask;
        idx_t upper_idx, lower_idx, next_idx;
        logic upper_empty, lower_empty;

        for (genvar i = 0; i < NumIn; i++) begin : gen_mask
          assign upper_mask[i] = (i > rr_q) ? req_d[i] : 1'b0;
          assign lower_mask[i] = (i <= rr_q) ? req_d[i] : 1'b0;
        end

        lzc #(
            .WIDTH(NumIn),
            .MODE (1'b0)
        ) i_lzc_upper (
            .in_i   (upper_mask),
            .cnt_o  (upper_idx),
            .empty_o(upper_empty)
        );

        lzc #(
            .WIDTH(NumIn),
            .MODE (1'b0)
        ) i_lzc_lower (
            .in_i   (lower_mask),
            .cnt_o  (lower_idx),
            .empty_o()
        );

        assign next_idx = upper_empty ? lower_idx : upper_idx;
        assign rr_d     = (gnt_i && req_o) ? next_idx : rr_q;

      end else begin : gen_unfair_arb
        assign rr_d = (gnt_i && req_o) ? ((rr_q == idx_t'(NumIn - 1)) ? '0 : rr_q + 1'b1) : rr_q;
      end


      always_ff @(posedge clk_i or negedge rst_ni) begin : p_rr_regs
        if (!rst_ni) begin
          rr_q <= '0;
        end else begin
          if (flush_i) begin
            rr_q <= '0;
          end else begin
            rr_q <= rr_d;
          end
        end
      end
    end

    assign gnt_nodes[0] = gnt_i;


    for (genvar level = 0; unsigned'(level) < NumLevels; level++) begin : gen_levels
      for (genvar l = 0; l < 2 ** level; l++) begin : gen_level

        logic sel;

        localparam int unsigned Idx0 = 2 ** level - 1 + l;
        localparam int unsigned Idx1 = 2 ** (level + 1) - 1 + l * 2;


        if (unsigned'(level) == NumLevels - 1) begin : gen_first_level

          if (unsigned'(l) * 2 < NumIn - 1) begin : gen_reduce
            assign req_nodes[Idx0]   = req_d[l*2] | req_d[l*2+1];


            assign sel               = ~req_d[l*2] | req_d[l*2+1] & rr_q[NumLevels-1-level];

            assign index_nodes[Idx0] = idx_t'(sel);
            assign data_nodes[Idx0]  = (sel) ? data_i[l*2+1] : data_i[l*2];
            assign gnt_o[l*2]        = gnt_nodes[Idx0] & (AxiVldRdy | req_d[l*2]) & ~sel;
            assign gnt_o[l*2+1]      = gnt_nodes[Idx0] & (AxiVldRdy | req_d[l*2+1]) & sel;
          end

          if (unsigned'(l) * 2 == NumIn - 1) begin : gen_first
            assign req_nodes[Idx0]   = req_d[l*2];
            assign index_nodes[Idx0] = '0;
            assign data_nodes[Idx0]  = data_i[l*2];
            assign gnt_o[l*2]        = gnt_nodes[Idx0] & (AxiVldRdy | req_d[l*2]);
          end

          if (unsigned'(l) * 2 > NumIn - 1) begin : gen_out_of_range
            assign req_nodes[Idx0]   = 1'b0;
            assign index_nodes[Idx0] = idx_t'('0);
            assign data_nodes[Idx0]  = DataType'('0);
          end


        end else begin : gen_other_levels
          assign req_nodes[Idx0] = req_nodes[Idx1] | req_nodes[Idx1+1];


          assign sel = ~req_nodes[Idx1] | req_nodes[Idx1+1] & rr_q[NumLevels-1-level];

          assign index_nodes[Idx0] = (sel) ?
            idx_t'({1'b1, index_nodes[Idx1+1][NumLevels-unsigned'(level)-2:0]}) :
            idx_t'({1'b0, index_nodes[Idx1][NumLevels-unsigned'(level)-2:0]});

          assign data_nodes[Idx0] = (sel) ? data_nodes[Idx1+1] : data_nodes[Idx1];
          assign gnt_nodes[Idx1] = gnt_nodes[Idx0] & ~sel;
          assign gnt_nodes[Idx1+1] = gnt_nodes[Idx0] & sel;
        end

      end
    end
  end

endmodule : rr_arb_tree
