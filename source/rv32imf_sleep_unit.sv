module rv32imf_sleep_unit #(
    // No parameters defined in this module
) (
    input  logic clk_i,       // Ungated input clock signal
    input  logic rst_n,       // Asynchronous reset signal (active low)
    output logic clk_gated_o, // Output gated clock signal for the core

    output logic fetch_enable_o,  // Output signal to enable instruction fetching

    input logic if_busy_i,    // Input signal indicating if the Instruction Fetch unit is busy
    input logic ctrl_busy_i,  // Input signal indicating if the Control unit is busy
    input logic lsu_busy_i,   // Input signal indicating if the Load-Store Unit is busy
    input logic apu_busy_i,   // Input signal indicating if the Arithmetic Processing Unit is busy

    input logic wake_from_sleep_i  // Input signal to wake the core from sleep mode
);

  import rv32imf_pkg::*;

  // Registered signal to control instruction fetch enable
  logic fetch_enable_q;
  // Registered signal indicating if any part of the core is busy
  logic core_busy_q;
  // Combinational signal indicating if any part of the core is busy
  logic core_busy_d;
  // Logic signal to enable the core clock gate
  logic clock_en;

  // Determine if the core is busy based on the busy signals from its sub-units
  assign core_busy_d = if_busy_i || ctrl_busy_i || lsu_busy_i || apu_busy_i;

  // Determine when the clock gate should be enabled
  // The clock is enabled if fetching is enabled AND (either a wake-up signal is received OR the core was previously busy)
  assign clock_en = fetch_enable_q && (wake_from_sleep_i || core_busy_q);

  // Sequential logic to update the internal state of the sleep unit
  always_ff @(posedge clk_i, negedge rst_n) begin
    if (!rst_n) begin
      // Reset condition:
      core_busy_q <= 1'b0;  // Initialize core busy status to idle
      fetch_enable_q <= 1'b1;  // Initialize fetch enable to active after reset
    end else begin
      // Normal operation:
      core_busy_q    <= core_busy_d;  // Update the registered core busy status
      fetch_enable_q <= 1'b1;  // Keep fetch enable active as long as not reset
    end
  end

  // Output the fetch enable signal
  assign fetch_enable_o = fetch_enable_q;

  // Instantiate the clock gate module to control the core clock
  rv32imf_clock_gate core_clock_gate_i (
      .clk_i(clk_i),       // Connect the ungated clock input
      .en_i (clock_en),    // Connect the enable signal for the clock gate
      .clk_o(clk_gated_o)  // Connect the output gated clock
  );

endmodule
