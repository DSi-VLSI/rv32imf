module rr_arb_tree #(
    parameter int unsigned NumIn = 64,  // Number of input requests
    parameter int unsigned DataWidth = 32,  // Width of the data
    parameter type DataType = logic [DataWidth-1:0],  // Data type definition
    parameter bit ExtPrio = 1'b0,  // Enable external priority input
    parameter bit AxiVldRdy = 1'b0,  // Use AXI valid/ready handshake
    parameter bit LockIn = 1'b0,  // Enable input locking
    parameter bit FairArb = 1'b1,  // Enable fair arbitration (round-robin)
    parameter int unsigned IdxWidth = (NumIn > 32'd1) ?  // Width of the index output
    unsigned'($clog2(
        NumIn
    )) : 32'd1,
    parameter type idx_t = logic [IdxWidth-1:0]  // Index type definition
) (
    input  logic                clk_i,    // Clock input
    input  logic                rst_ni,   // Asynchronous reset input (active low)
    input  logic                flush_i,  // Flush/reset internal state
    input  idx_t                rr_i,     // External round-robin priority input
    input  logic    [NumIn-1:0] req_i,    // Input request signals
    output logic    [NumIn-1:0] gnt_o,    // Output grant signals
    input  DataType [NumIn-1:0] data_i,   // Input data
    output logic                req_o,    // Overall request output
    input  logic                gnt_i,    // Overall grant input
    output DataType             data_o,   // Output data
    output idx_t                idx_o     // Output index of the granted request
);

  if (NumIn == unsigned'(1)) begin : gen_pass_through
    assign req_o    = req_i[0];  // Pass through request
    assign gnt_o[0] = gnt_i;  // Pass through grant
    assign data_o   = data_i[0];  // Pass through data
    assign idx_o    = '0;  // Output index is always 0
  end else begin : gen_arbiter
    localparam int unsigned NumLevels = unsigned'($clog2(NumIn));  // Number of tree levels

    idx_t    [2**NumLevels-2:0] index_nodes;  // Internal index nodes
    DataType [2**NumLevels-2:0] data_nodes;  // Internal data nodes
    logic    [2**NumLevels-2:0] gnt_nodes;  // Internal grant nodes
    logic    [2**NumLevels-2:0] req_nodes;  // Internal request nodes
    idx_t                       rr_q;  // Round-robin register
    logic    [       NumIn-1:0] req_d;  // Registered request signals

    assign req_o  = req_nodes[0];  // Top-level request output
    assign data_o = data_nodes[0];  // Top-level data output
    assign idx_o  = index_nodes[0];  // Top-level index output

    if (ExtPrio) begin : gen_ext_rr
      assign rr_q  = rr_i;  // Use external round-robin input
      assign req_d = req_i;  // Register input requests
    end else begin : gen_int_rr
      idx_t rr_d;  // Next round-robin value

      if (LockIn) begin : gen_lock
        logic lock_d, lock_q;  // Lock enable logic
        logic [NumIn-1:0] req_q;  // Latched request signals

        assign lock_d = req_o & ~gnt_i;  // Assert lock when request is granted
        assign req_d  = (lock_q) ? req_q : req_i;  // Use latched request if locked

        always_ff @(posedge clk_i or negedge rst_ni) begin : p_lock_reg
          if (!rst_ni) begin
            lock_q <= '0;  // Reset lock
          end else begin
            if (flush_i) begin
              lock_q <= '0;  // Reset lock on flush
            end else begin
              lock_q <= lock_d;  // Update lock state
            end
          end
        end

        always_ff @(posedge clk_i or negedge rst_ni) begin : p_req_regs
          if (!rst_ni) begin
            req_q <= '0;  // Reset latched requests
          end else begin
            if (flush_i) begin
              req_q <= '0;  // Reset latched requests on flush
            end else begin
              req_q <= req_d;  // Update latched requests
            end
          end
        end
      end else begin : gen_no_lock
        assign req_d = req_i;  // Register input requests
      end

      if (FairArb) begin : gen_fair_arb
        logic [NumIn-1:0] upper_mask, lower_mask;  // Masks for fair arbitration
        idx_t upper_idx, lower_idx, next_idx;  // Indices for fair arbitration
        logic upper_empty, lower_empty;  // Empty flags for fair arbitration

        for (genvar i = 0; i < NumIn; i++) begin : gen_mask
          assign upper_mask[i] = (i > rr_q) ? req_d[i] : 1'b0;  // Requests above RR
          assign lower_mask[i] = (i <= rr_q) ? req_d[i] : 1'b0;  // Requests below or at RR
        end

        lzc #(  // Leading zero counter for upper mask
            .WIDTH(NumIn),
            .MODE (1'b0)
        ) i_lzc_upper (
            .in_i   (upper_mask),
            .cnt_o  (upper_idx),
            .empty_o(upper_empty)
        );

        lzc #(  // Leading zero counter for lower mask
            .WIDTH(NumIn),
            .MODE (1'b0)
        ) i_lzc_lower (
            .in_i   (lower_mask),
            .cnt_o  (lower_idx),
            .empty_o()
        );

        assign next_idx = upper_empty ? lower_idx : upper_idx;  // Select next index
        assign rr_d     = (gnt_i && req_o) ? next_idx : rr_q;  // Update RR on grant
      end else begin : gen_unfair_arb
        assign rr_d = (gnt_i && req_o) ?  // Update RR on grant (simple increment)
            ((rr_q == idx_t'(NumIn - 1)) ? '0 : rr_q + 1'b1) : rr_q;
      end

      always_ff @(posedge clk_i or negedge rst_ni) begin : p_rr_regs
        if (!rst_ni) begin
          rr_q <= '0;  // Reset round-robin counter
        end else begin
          if (flush_i) begin
            rr_q <= '0;  // Reset round-robin counter on flush
          end else begin
            rr_q <= rr_d;  // Update round-robin counter
          end
        end
      end
    end

    assign gnt_nodes[0] = gnt_i;  // Top-level grant is the input grant

    for (genvar level = 0; unsigned'(level) < NumLevels; level++) begin : gen_levels
      for (genvar l = 0; l < 2 ** level; l++) begin : gen_level

        logic sel;  // Selection signal for the level

        localparam int unsigned Idx0 = 2 ** level - 1 + l;  // Index of the current node
        localparam int unsigned Idx1 = 2 ** (level + 1) - 1 + l * 2;  // Index of the lower nodes

        if (unsigned'(level) == NumLevels - 1) begin : gen_first_level

          if (unsigned'(l) * 2 < NumIn - 1) begin : gen_reduce
            assign req_nodes[Idx0] = req_d[l*2] | req_d[l*2+1];  // OR requests
            assign sel = ~req_d[l*2] | req_d[l*2+1] &  // Selection logic
                rr_q[NumLevels-1-level];
            assign index_nodes[Idx0] = idx_t'(sel);  // Select index
            assign data_nodes[Idx0] = (sel) ? data_i[l*2+1] : data_i[l*2];  // Select data
            assign gnt_o[l*2] = gnt_nodes[Idx0] &  // Grant to the first input
                (AxiVldRdy | req_d[l*2]) & ~sel;
            assign gnt_o[l*2+1] = gnt_nodes[Idx0] &  // Grant to the second input
                (AxiVldRdy | req_d[l*2+1]) & sel;
          end

          if (unsigned'(l) * 2 == NumIn - 1) begin : gen_first
            assign req_nodes[Idx0] = req_d[l*2];  // Pass through request
            assign index_nodes[Idx0] = '0;  // Index is 0
            assign data_nodes[Idx0] = data_i[l*2];  // Pass through data
            assign gnt_o[l*2] = gnt_nodes[Idx0] &  // Grant to the single input
                (AxiVldRdy | req_d[l*2]);
          end

          if (unsigned'(l) * 2 > NumIn - 1) begin : gen_out_of_range
            assign req_nodes[Idx0]   = 1'b0;  // No request
            assign index_nodes[Idx0] = idx_t'('0);  // Default index
            assign data_nodes[Idx0]  = DataType'('0);  // Default data
          end

        end else begin : gen_other_levels
          assign req_nodes[Idx0] = req_nodes[Idx1] | req_nodes[Idx1+1];  // OR lower level requests
          assign sel = ~req_nodes[Idx1] | req_nodes[Idx1+1] &  // Selection logic
              rr_q[NumLevels-1-level];
          assign index_nodes[Idx0] = (sel) ?  // Select index from lower levels
              idx_t'({1'b1, index_nodes[Idx1+1][NumLevels-unsigned'(level)-2:0]}) :
              idx_t'({1'b0, index_nodes[Idx1][NumLevels-unsigned'(level)-2:0]});
          assign data_nodes[Idx0] = (sel) ? data_nodes[Idx1+1] : data_nodes[Idx1];  // Select data
          assign gnt_nodes[Idx1] = gnt_nodes[Idx0] & ~sel;  // Grant to the first lower level
          assign gnt_nodes[Idx1+1] = gnt_nodes[Idx0] & sel;  // Grant to the second lower level
        end

      end
    end
  end

endmodule : rr_arb_tree
