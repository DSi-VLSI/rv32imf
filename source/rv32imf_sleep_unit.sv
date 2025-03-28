// Module definition for the sleep unit
module rv32imf_sleep_unit #(

) (
    // Input clock signal
    input  logic clk_i,
    // Input reset signal (active low)
    input  logic rst_n,
    // Output gated clock signal for the core
    output logic clk_gated_o,

    // Output signal to enable instruction fetching
    output logic fetch_enable_o,

    // Input signal indicating if the instruction fetch unit is busy
    input logic if_busy_i,
    // Input signal indicating if the control unit is busy
    input logic ctrl_busy_i,
    // Input signal indicating if the load-store unit is busy
    input logic lsu_busy_i,
    // Input signal indicating if the arithmetic processing unit is busy
    input logic apu_busy_i,

    // Input signal to wake up the core from sleep mode
    input logic wake_from_sleep_i
);

  // Import definitions from the rv32imf package
  import rv32imf_pkg::*;

  // Internal signal to store the fetch enable status
  logic fetch_enable_q;

  // Internal signal to indicate if any core component is busy
  logic core_busy_q;

  // Internal signal to hold the next value of core_busy
  logic core_busy_d;

  // Internal signal to enable the core clock
  logic clock_en;

  // Assign logic to determine if any part of the core is busy
  assign core_busy_d = if_busy_i || ctrl_busy_i || lsu_busy_i || apu_busy_i;

  // Assign logic to enable the clock: fetch is enabled AND (wake up OR core is busy)
  assign clock_en = fetch_enable_q && (wake_from_sleep_i || core_busy_q);

  // Sequential logic block for updating internal signals
  always_ff @(posedge clk_i, negedge rst_n) begin
    // Reset condition: when rst_n is low
    if (!rst_n) begin
      // Initialize core_busy to inactive
      core_busy_q <= 1'b0;
      // Initialize fetch_enable to active
      fetch_enable_q <= 1'b1;
    end else begin
      // Update core_busy with the current busy status
      core_busy_q    <= core_busy_d;
      // Keep fetch_enable active as long as the core is not in deep sleep
      fetch_enable_q <= 1'b1;
    end
  end

  // Assign the internal fetch enable signal to the output
  assign fetch_enable_o = fetch_enable_q;

  // Instantiate the clock gate module
  rv32imf_clock_gate core_clock_gate_i (
      // Connect the input clock
      .clk_i(clk_i),
      // Connect the enable signal for the clock gate
      .en_i (clock_en),
      // Connect the output gated clock
      .clk_o(clk_gated_o)
  );

endmodule
