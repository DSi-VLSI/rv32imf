module rv32imf_sleep_unit #(
    
) (
    input  logic clk_i,       
    input  logic rst_n,       
    output logic clk_gated_o, 

    output logic fetch_enable_o,  

    input logic if_busy_i,    
    input logic ctrl_busy_i,  
    input logic lsu_busy_i,   
    input logic apu_busy_i,   

    input logic wake_from_sleep_i  
);

  import rv32imf_pkg::*;

  
  logic fetch_enable_q;
  
  logic core_busy_q;
  
  logic core_busy_d;
  
  logic clock_en;

  
  assign core_busy_d = if_busy_i || ctrl_busy_i || lsu_busy_i || apu_busy_i;

  
  
  assign clock_en = fetch_enable_q && (wake_from_sleep_i || core_busy_q);

  
  always_ff @(posedge clk_i, negedge rst_n) begin
    if (!rst_n) begin
      
      core_busy_q <= 1'b0;  
      fetch_enable_q <= 1'b1;  
    end else begin
      
      core_busy_q    <= core_busy_d;  
      fetch_enable_q <= 1'b1;  
    end
  end

  
  assign fetch_enable_o = fetch_enable_q;

  
  rv32imf_clock_gate core_clock_gate_i (
      .clk_i(clk_i),       
      .en_i (clock_en),    
      .clk_o(clk_gated_o)  
  );

endmodule
