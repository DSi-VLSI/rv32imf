module rv32imf_ff_one #(
    parameter LEN = 32
) (
    input logic [LEN-1:0] in_i,

    output logic [$clog2(LEN)-1:0] first_one_o,
    output logic                   no_ones_o
);

  localparam NUM_LEVELS = $clog2(LEN);

  logic [          LEN-1:0][NUM_LEVELS-1:0] index_lut;
  logic [2**NUM_LEVELS-1:0]                 sel_nodes;
  logic [2**NUM_LEVELS-1:0][NUM_LEVELS-1:0] index_nodes;






  generate
    genvar j;
    for (j = 0; j < LEN; j++) begin : gen_index_lut
      assign index_lut[j] = $unsigned(j);
    end
  endgenerate

  generate
    genvar k;
    genvar l;
    genvar level;

    assign sel_nodes[2**NUM_LEVELS-1] = 1'b0;

    for (level = 0; level < NUM_LEVELS; level++) begin : gen_tree

      if (level < NUM_LEVELS - 1) begin : gen_non_root_level
        for (l = 0; l < 2 ** level; l++) begin : gen_node
          assign sel_nodes[2**level-1+l]   = sel_nodes[2**(level+1)-1+l*2] | sel_nodes[2**(level+1)-1+l*2+1];
          assign index_nodes[2**level-1+l] = (sel_nodes[2**(level+1)-1+l*2] == 1'b1) ?
                                           index_nodes[2**(level+1)-1+l*2] : index_nodes[2**(level+1)-1+l*2+1];
        end
      end

      if (level == NUM_LEVELS - 1) begin : gen_root_level
        for (k = 0; k < 2 ** level; k++) begin : gen_node

          if (k * 2 < LEN - 1) begin : gen_two
            assign sel_nodes[2**level-1+k] = in_i[k*2] | in_i[k*2+1];
            assign index_nodes[2**level-1+k] = (in_i[k*2] == 1'b1) ? index_lut[k*2] : index_lut[k*2+1];
          end

          if (k * 2 == LEN - 1) begin : gen_one
            assign sel_nodes[2**level-1+k]   = in_i[k*2];
            assign index_nodes[2**level-1+k] = index_lut[k*2];
          end

          if (k * 2 > LEN - 1) begin : gen_out_of_range
            assign sel_nodes[2**level-1+k]   = 1'b0;
            assign index_nodes[2**level-1+k] = '0;
          end
        end
      end

    end
  endgenerate





  assign first_one_o = index_nodes[0];
  assign no_ones_o   = ~sel_nodes[0];

endmodule
