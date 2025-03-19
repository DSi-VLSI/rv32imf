

module rv32imf_clock_gate (
    input  logic clk_i,
    input  logic en_i,
    output logic clk_o
);

  logic clk_en;

  always_latch begin
    if (clk_i == 1'b0) clk_en <= en_i;
  end

  assign clk_o = clk_i & clk_en;

endmodule
