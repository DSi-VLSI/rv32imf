module rv32imf_ff_one #(
    parameter int LEN = 32
) (
    input logic [LEN-1:0] in_i,

    output logic [$clog2(LEN)-1:0] first_one_o,
    output logic                   no_ones_o
);

  // Calculate the number of levels needed for the tree
  localparam int NumLevels = $clog2(LEN);

  // Lookup table to store the original indices
  logic [         LEN-1:0][NumLevels-1:0] index_lut;
  // Nodes in the reduction tree to track if a '1' is present
  logic [2**NumLevels-1:0]                sel_nodes;
  // Nodes in the reduction tree to store the index of the first '1'
  logic [2**NumLevels-1:0][NumLevels-1:0] index_nodes;

  // Generate block to initialize the index lookup table
  generate
    genvar j;
    for (j = 0; j < LEN; j++) begin : gen_index_lut
      assign index_lut[j] = $unsigned(j);
    end
  endgenerate

  // Generate block for the reduction tree
  generate
    genvar k;
    genvar l;
    genvar level;

    // Initialize the last node's select signal to 0
    assign sel_nodes[2**NumLevels-1] = 1'b0;

    // Iterate through each level of the tree
    for (level = 0; level < NumLevels; level++) begin : gen_tree

      // Generate for non-root levels
      if (level < NumLevels - 1) begin : gen_non_root_level
        for (l = 0; l < 2 ** level; l++) begin : gen_node
          // OR the select signals from the next level to determine if a '1' is present in either branch
          assign sel_nodes[2**level-1+l]   = sel_nodes[2**(level+1)-1+l*2]
                                           | sel_nodes[2**(level+1)-1+l*2+1];
          // Select the index from the branch that contains the first '1'
          assign index_nodes[2**level-1+l] = (sel_nodes[2**(level+1)-1+l*2] == 1'b1) ?
                                             index_nodes[2**(level+1)-1+l*2] :
                                             index_nodes[2**(level+1)-1+l*2+1];
        end
      end

      // Generate for the root level (input level)
      if (level == NumLevels - 1) begin : gen_root_level
        for (k = 0; k < 2 ** level; k++) begin : gen_node

          // Generate for nodes with two inputs
          if (k * 2 < LEN - 1) begin : gen_two
            // OR the input bits to determine if a '1' is present
            assign sel_nodes[2**level-1+k] = in_i[k*2] | in_i[k*2+1];
            // Select the index of the first '1'
            assign index_nodes[2**level-1+k] = (in_i[k*2] == 1'b1) ? index_lut[k*2]
                                                                   : index_lut[k*2+1];
          end

          // Generate for node with one input (if LEN is not a power of 2)
          if (k * 2 == LEN - 1) begin : gen_one
            // Assign the input bit to the select signal
            assign sel_nodes[2**level-1+k]   = in_i[k*2];
            // Assign the index of the single input
            assign index_nodes[2**level-1+k] = index_lut[k*2];
          end

          // Generate for nodes with no input (if LEN is not a power of 2)
          if (k * 2 > LEN - 1) begin : gen_out_of_range
            // No input, so select signal is 0
            assign sel_nodes[2**level-1+k]   = 1'b0;
            // No input, so index is don't care
            assign index_nodes[2**level-1+k] = '0;
          end
        end
      end

    end
  endgenerate

  // The index of the first '1' is at the top of the tree
  assign first_one_o = index_nodes[0];
  // If the top of the tree's select signal is 0, then there are no ones
  assign no_ones_o   = ~sel_nodes[0];

endmodule
