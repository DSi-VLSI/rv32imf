module rv32imf #(
) (
    input logic clk_i,  // Clock input
    input logic rst_ni, // Asynchronous reset input (active low)

    input logic [31:0] boot_addr_i,         // Boot address input
    input logic [31:0] dm_halt_addr_i,      // Debug module halt address input
    input logic [31:0] hart_id_i,           // Hart ID input
    input logic [31:0] dm_exception_addr_i, // Debug module exception address input

    output logic        instr_req_o,     // Instruction request output
    input  logic        instr_gnt_i,     // Instruction grant input
    input  logic        instr_rvalid_i,  // Instruction response valid input
    output logic [31:0] instr_addr_o,    // Instruction address output
    input  logic [31:0] instr_rdata_i,   // Instruction response data input

    output logic        data_req_o,     // Data request output
    input  logic        data_gnt_i,     // Data grant input
    input  logic        data_rvalid_i,  // Data response valid input
    output logic        data_we_o,      // Data write enable output
    output logic [ 3:0] data_be_o,      // Data byte enable output
    output logic [31:0] data_addr_o,    // Data address output
    output logic [31:0] data_wdata_o,   // Data write data output
    input  logic [31:0] data_rdata_i,   // Data response data input

    input  logic [31:0] irq_i,      // Interrupt request input
    output logic        irq_ack_o,  // Interrupt acknowledge output
    output logic [ 4:0] irq_id_o,   // Interrupt ID output

    input  logic [63:0] time_i       // Time input
);

  logic              apu_busy;  // APU busy signal
  logic              apu_req;  // APU request signal
  logic [ 2:0][31:0] apu_operands;  // APU operands
  logic [ 5:0]       apu_op;  // APU operation code
  logic [14:0]       apu_flags;  // APU flags

  logic              apu_gnt;  // APU grant signal
  logic              apu_rvalid;  // APU result valid signal
  logic [31:0]       apu_rdata;  // APU result data
  logic [ 4:0]       apu_rflags;  // APU result flags

  logic apu_clk_en, apu_clk;  // APU clock enable and clock signals

  rv32imf_core #() core_i (  // Instantiate the RV32IMF core
      .clk_i (clk_i),  // Connect clock input
      .rst_ni(rst_ni), // Connect reset input

      .boot_addr_i        (boot_addr_i),         // Connect boot address
      .mtvec_addr_i       ('0),                  // Connect machine trap vector base address
      .dm_halt_addr_i     (dm_halt_addr_i),      // Connect debug module halt address
      .hart_id_i          (hart_id_i),           // Connect hart ID
      .dm_exception_addr_i(dm_exception_addr_i), // Connect debug exception address

      .instr_req_o   (instr_req_o),     // Connect instruction request output
      .instr_gnt_i   (instr_gnt_i),     // Connect instruction grant input
      .instr_rvalid_i(instr_rvalid_i),  // Connect instruction response valid
      .instr_addr_o  (instr_addr_o),    // Connect instruction address output
      .instr_rdata_i (instr_rdata_i),   // Connect instruction response data

      .data_req_o   (data_req_o),     // Connect data request output
      .data_gnt_i   (data_gnt_i),     // Connect data grant input
      .data_rvalid_i(data_rvalid_i),  // Connect data response valid
      .data_we_o    (data_we_o),      // Connect data write enable output
      .data_be_o    (data_be_o),      // Connect data byte enable output
      .data_addr_o  (data_addr_o),    // Connect data address output
      .data_wdata_o (data_wdata_o),   // Connect data write data output
      .data_rdata_i (data_rdata_i),   // Connect data response data

      .apu_busy_o    (apu_busy),      // Connect APU busy output
      .apu_req_o     (apu_req),       // Connect APU request output
      .apu_gnt_i     (apu_gnt),       // Connect APU grant input
      .apu_operands_o(apu_operands),  // Connect APU operands output
      .apu_op_o      (apu_op),        // Connect APU operation code output
      .apu_flags_o   (apu_flags),     // Connect APU flags output
      .apu_rvalid_i  (apu_rvalid),    // Connect APU result valid input
      .apu_result_i  (apu_rdata),     // Connect APU result input
      .apu_flags_i   (apu_rflags),    // Connect APU flags input

      .irq_i    (irq_i),      // Connect interrupt request input
      .irq_ack_o(irq_ack_o),  // Connect interrupt acknowledge output
      .irq_id_o (irq_id_o),   // Connect interrupt ID output
      .time_i   (time_i)      // Connect time input
  );

  assign apu_clk_en = apu_req | apu_busy;  // Enable APU clock when requested or busy

  rv32imf_clock_gate core_clock_gate_i (  // Instantiate the APU clock gate
      .clk_i(clk_i),       // Connect main clock input
      .en_i (apu_clk_en),  // Connect enable signal
      .clk_o(apu_clk)      // Connect gated clock output
  );

  rv32imf_fp_wrapper #() fp_wrapper_i (  // Instantiate the floating-point wrapper
      .clk_i         (apu_clk),       // Connect APU clock
      .rst_ni        (rst_ni),        // Connect reset input
      .apu_req_i     (apu_req),       // Connect APU request input
      .apu_gnt_o     (apu_gnt),       // Connect APU grant output
      .apu_operands_i(apu_operands),  // Connect APU operands input
      .apu_op_i      (apu_op),        // Connect APU operation code input
      .apu_flags_i   (apu_flags),     // Connect APU flags input
      .apu_rvalid_o  (apu_rvalid),    // Connect APU result valid output
      .apu_rdata_o   (apu_rdata),     // Connect APU result data output
      .apu_rflags_o  (apu_rflags)     // Connect APU result flags output
  );

endmodule
