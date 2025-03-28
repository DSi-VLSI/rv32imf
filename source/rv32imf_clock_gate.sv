// Module definition for a clock gate
module rv32imf_clock_gate (
    // Input clock signal
    input  logic clk_i,
    // Input enable signal for the clock gate
    input  logic en_i,
    // Output gated clock signal
    output logic clk_o
);

  // Internal logic signal to hold the enable value
  logic clk_en;

  // Sequential block triggered at the positive edge of the input clock
  always_ff @(posedge clk_i) begin
    // Register the enable input to create the gated clock enable
    clk_en <= en_i;
  end

  // Continuous assignment to generate the output gated clock
  // The output clock is high only when the input clock and enable are high
  assign clk_o = clk_i & clk_en;

endmodule
