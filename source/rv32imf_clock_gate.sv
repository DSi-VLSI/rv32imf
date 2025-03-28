module rv32imf_clock_gate (
  input  logic clk_i, // Input clock signal
  input  logic en_i,  // Enable input signal
  output logic clk_o  // Output gated clock signal
);

  // Internal signal to hold the enable status
  logic clk_en;

  // Use a synchronous always_ff block with positive edge trigger
  always_ff @(posedge clk_i) begin
    // On the rising edge of the clock, update the enable status
    clk_en <= en_i;
  end

  // Assign the output clock by ANDing the input clock with the enable status
  // This will only allow the input clock to pass through when clk_en is high
  assign clk_o = clk_i & clk_en;

endmodule
