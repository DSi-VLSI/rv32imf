module rv32imf_clock_gate (
  input  logic clk_i, 
  input  logic en_i,  
  output logic clk_o  
);

  
  logic clk_en;

  
  always_ff @(posedge clk_i) begin
    
    clk_en <= en_i;
  end

  
  
  assign clk_o = clk_i & clk_en;

endmodule
