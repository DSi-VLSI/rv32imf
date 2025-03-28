module lzc #(
    // Parameter for the input width.
    parameter int unsigned WIDTH = 2,
    // Parameter to select the counting mode (leading zeros or ones).
    parameter bit MODE = 1'b0,
    // Parameter for the output counter width.
    parameter int unsigned CNT_WIDTH = (WIDTH > 32'd1) ? unsigned'($clog2(WIDTH)) : 32'd1
) (

    // Input port for the data.
    input logic [WIDTH-1:0] in_i,

    // Output port for the leading zero/one count.
    output logic [CNT_WIDTH-1:0] cnt_o,

    // Output port indicating if the input is all zeros (or ones in MODE=1).
    output logic empty_o
);

  // Generate block for the case when the width is 1.
  if (WIDTH == 1) begin : gen_degenerate_lzc

    // For width 1, the count is the inverse of the input.
    assign cnt_o[0] = !in_i[0];
    // For width 1, empty indicates the input is zero.
    assign empty_o  = !in_i[0];

  end else begin : gen_lzc

    // Local parameter for the number of levels in the reduction tree.
    localparam int unsigned NumLevels = $clog2(WIDTH);


    // Initial assertion to check if the width is valid.
    initial begin
      assert (WIDTH > 0)
      else $fatal(1, "input must be at least one bit wide");
    end


    // Logic to store the index at each bit position.
    logic [WIDTH-1:0][NumLevels-1:0] index_lut;
    // Logic for the selection nodes in the reduction tree.
    logic [2**NumLevels-1:0] sel_nodes;
    // Logic for the index nodes in the reduction tree.
    logic [2**NumLevels-1:0][NumLevels-1:0] index_nodes;

    // Temporary logic to store the potentially flipped input.
    logic [WIDTH-1:0] in_tmp;


    // Combinational block to flip the input based on the MODE.
    always_comb begin : flip_vector
      for (int unsigned i = 0; i < WIDTH; i++) begin
        // If MODE is 1, reverse the input; otherwise, keep it as is.
        in_tmp[i] = (MODE) ? in_i[WIDTH-1-i] : in_i[i];
      end
    end

    // Generate block to create the initial index lookup table.
    for (genvar j = 0; unsigned'(j) < WIDTH; j++) begin : g_index_lut
      // Assign the index to each bit position.
      assign index_lut[j] = (NumLevels)'(unsigned'(j));
    end

    // Generate block for the levels of the reduction tree.
    for (genvar level = 0; unsigned'(level) < NumLevels; level++) begin : g_levels
      // Handle the last level of the reduction tree.
      if (unsigned'(level) == NumLevels - 1) begin : g_last_level
        // Iterate through the nodes at the current level.
        for (genvar k = 0; k < 2 ** level; k++) begin : g_level

          // If within the bounds of the input width.
          if (unsigned'(k) * 2 < WIDTH - 1) begin : g_reduce
            // OR the corresponding bits in the temporary input.
            assign sel_nodes[2**level-1+k] = in_tmp[k*2] | in_tmp[k*2+1];
            // Select the index based on the first '1' encountered.
            assign index_nodes[2 ** level - 1 + k] = (in_tmp[k * 2] == 1'b1)
              ? index_lut[k * 2] :
                index_lut[k * 2 + 1];
          end

          // Handle the case when only one bit remains.
          if (unsigned'(k) * 2 == WIDTH - 1) begin : g_base
            // Assign the value of the remaining bit.
            assign sel_nodes[2**level-1+k]   = in_tmp[k*2];
            // Assign the index of the remaining bit.
            assign index_nodes[2**level-1+k] = index_lut[k*2];
          end

          // Handle the case when the index is out of range.
          if (unsigned'(k) * 2 > WIDTH - 1) begin : g_out_of_range
            // Assign 0 if out of range.
            assign sel_nodes[2**level-1+k]   = 1'b0;
            // Assign 0 if out of range.
            assign index_nodes[2**level-1+k] = '0;
          end
        end
      end else begin : g_not_last_level
        // Iterate through the nodes at the current level.
        for (genvar l = 0; l < 2 ** level; l++) begin : g_level
          // OR the results from the next level.
          assign sel_nodes[2 ** level - 1 + l] =
            sel_nodes[2 ** (level + 1) - 1 + l * 2] | sel_nodes[2 ** (level + 1) - 1 + l * 2 + 1];
          // Select the index based on the first '1' encountered in the next level.
          assign index_nodes[2 ** level - 1 + l] =
            (sel_nodes[2 ** (level + 1) - 1 + l * 2] == 1'b1)
            ? index_nodes[2 ** (level + 1) - 1 + l * 2] :
              index_nodes[2 ** (level + 1) - 1 + l * 2 + 1];
        end
      end
    end

    // Assign the final count from the root of the index tree.
    assign cnt_o   = NumLevels > unsigned'(0) ? index_nodes[0] : {($clog2(WIDTH)) {1'b0}};
    // Assign the empty output based on the root of the selection tree.
    assign empty_o = NumLevels > unsigned'(0) ? ~sel_nodes[0] : ~(|in_i);

  end : gen_lzc

endmodule : lzc
