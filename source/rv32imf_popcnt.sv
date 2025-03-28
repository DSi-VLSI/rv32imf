module rv32imf_popcnt (
    input logic [31:0] in_i,     // 32-bit input
    output logic [5:0] result_o  // 6-bit output: population count
);

  // Internal signals for intermediate counts
  logic [15:0][1:0] cnt_l1;  // Count at level 1
  logic [ 7:0][2:0] cnt_l2;  // Count at level 2
  logic [ 3:0][3:0] cnt_l3;  // Count at level 3
  logic [ 1:0][4:0] cnt_l4;  // Count at level 4

  // Generate variables for loops
  genvar l, m, n, p;

  // Generate block for level 1 counting
  generate
    for (l = 0; l < 16; l++) begin : gen_cnt_l1
      // Add pairs of bits to get count of each 2-bit group
      assign cnt_l1[l] = {1'b0, in_i[2*l]} + {1'b0, in_i[2*l+1]};
    end
  endgenerate

  // Generate block for level 2 counting
  generate
    for (m = 0; m < 8; m++) begin : gen_cnt_l2
      // Add pairs of 2-bit counts from level 1
      assign cnt_l2[m] = {1'b0, cnt_l1[2*m]} + {1'b0, cnt_l1[2*m+1]};
    end
  endgenerate

  // Generate block for level 3 counting
  generate
    for (n = 0; n < 4; n++) begin : gen_cnt_l3
      // Add pairs of 3-bit counts from level 2
      assign cnt_l3[n] = {1'b0, cnt_l2[2*n]} + {1'b0, cnt_l2[2*n+1]};
    end
  endgenerate

  // Generate block for level 4 counting
  generate
    for (p = 0; p < 2; p++) begin : gen_cnt_l4
      // Add pairs of 4-bit counts from level 3
      assign cnt_l4[p] = {1'b0, cnt_l3[2*p]} + {1'b0, cnt_l3[2*p+1]};
    end
  endgenerate

  // Final addition to get the total population count
  assign result_o = {1'b0, cnt_l4[0]} + {1'b0, cnt_l4[1]};

endmodule
