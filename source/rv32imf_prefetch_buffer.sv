// Module definition for the prefetch buffer
module rv32imf_prefetch_buffer #(
) (
    // Input clock signal
    input logic clk,
    // Input reset signal (active low)
    input logic rst_n,

    // Input signal indicating a new fetch request from the core
    input logic        req_i,
    // Input signal indicating a branch instruction has occurred
    input logic        branch_i,
    // Input signal providing the target address of the branch
    input logic [31:0] branch_addr_i,

    // Input signal for a hardware loop prefetch target address (not used in the logic)
    input logic [31:0] hwlp_target_i,

    // Input signal indicating the instruction fetch unit is ready for a new instruction
    input  logic        fetch_ready_i,
    // Output signal indicating a prefetched instruction is valid and ready for fetch
    output logic        fetch_valid_o,
    // Output signal providing the prefetched instruction data
    output logic [31:0] fetch_rdata_o,

    // Output signal indicating a request to the instruction OBI interface
    output logic        instr_req_o,
    // Input signal indicating the instruction OBI interface has granted the request
    input  logic        instr_gnt_i,
    // Output signal providing the address for the instruction fetch request
    output logic [31:0] instr_addr_o,
    // Input signal providing the instruction data from the OBI response
    input  logic [31:0] instr_rdata_i,
    // Input signal indicating a valid instruction response from the OBI
    input  logic        instr_rvalid_i,
    // Input signal indicating an error in the instruction OBI response
    input  logic        instr_err_i,
    // Input signal indicating a PMP (Physical Memory Protection) error in the instruction fetch
    input  logic        instr_err_pmp_i,

    // Output signal indicating if the prefetch buffer is busy
    output logic busy_o
);

  // Local parameter defining the depth of the prefetch FIFO
  localparam int FifoDepth = 2;
  // Local parameter defining the address depth for the prefetch FIFO
  localparam int unsigned FifoAddrDepth = $clog2(FifoDepth);

  // Signals connecting to the prefetch controller
  logic                   trans_valid;
  logic                   trans_ready;
  logic [           31:0] trans_addr;

  // Signals connecting to the prefetch FIFO
  logic                   fifo_flush;
  logic                   fifo_flush_but_first;
  logic [FifoAddrDepth:0] fifo_cnt;

  logic [           31:0] fifo_rdata;
  logic                   fifo_push;
  logic                   fifo_pop;
  logic                   fifo_empty;

  // Signals receiving response from the instruction OBI interface
  logic                   resp_valid;
  logic [           31:0] resp_rdata;
  logic                   resp_err;

  // Instantiate the prefetch controller module
  rv32imf_prefetch_controller #(
      .DEPTH(FifoDepth)
  ) prefetch_controller_i (
      .clk  (clk),
      .rst_n(rst_n),

      .req_i        (req_i),
      .branch_i     (branch_i),
      .branch_addr_i(branch_addr_i),
      .busy_o       (busy_o),

      .hwlp_target_i(hwlp_target_i),

      .trans_valid_o(trans_valid),
      .trans_ready_i(trans_ready),
      .trans_addr_o (trans_addr),

      .resp_valid_i(resp_valid),

      .fetch_ready_i(fetch_ready_i),
      .fetch_valid_o(fetch_valid_o),

      .fifo_push_o (fifo_push),
      .fifo_pop_o  (fifo_pop),
      .fifo_flush_o(fifo_flush),
      .fifo_cnt_i  (fifo_cnt),
      .fifo_empty_i(fifo_empty)
  );

  // Instantiate the prefetch FIFO module
  rv32imf_fifo #(
      .FALL_THROUGH(1'b0),
      .DATA_WIDTH  (32),
      .DEPTH       (FifoDepth)
  ) fifo_i (
      .clk_i            (clk),
      .rst_ni           (rst_n),
      .flush_i          (fifo_flush),
      .flush_but_first_i('0),          // Not used in this instantiation
      .testmode_i       (1'b0),
      .full_o           (),            // Not used
      .empty_o          (fifo_empty),
      .cnt_o            (fifo_cnt),
      .data_i           (resp_rdata),
      .push_i           (fifo_push),
      .data_o           (fifo_rdata),
      .pop_i            (fifo_pop)
  );

  // Assign the fetch output data, prioritizing FIFO data if available
  assign fetch_rdata_o = fifo_empty ? resp_rdata : fifo_rdata;

  // Instantiate the OBI interface for instruction fetching
  rv32imf_obi_interface #(
      .TRANS_STABLE(0)
  ) instruction_obi_i (
      .clk  (clk),
      .rst_n(rst_n),

      .trans_valid_i(trans_valid),
      .trans_ready_o(trans_ready),
      .trans_addr_i ({trans_addr[31:2], 2'b00}),  // Align address to word boundary
      .trans_we_i   (1'b0),                       // Instruction fetch is always read
      .trans_be_i   (4'b1111),                    // Fetch the entire word
      .trans_wdata_i(32'b0),                      // No write data for fetch
      .trans_atop_i (6'b0),                       // No atomic operation for fetch

      .resp_valid_o(resp_valid),
      .resp_rdata_o(resp_rdata),
      .resp_err_o  (resp_err),

      .obi_req_o   (instr_req_o),
      .obi_gnt_i   (instr_gnt_i),
      .obi_addr_o  (instr_addr_o),
      .obi_we_o    (),                // Not used for fetch
      .obi_be_o    (),                // Not used for fetch
      .obi_wdata_o (),                // Not used for fetch
      .obi_atop_o  (),                // Not used for fetch
      .obi_rdata_i (instr_rdata_i),
      .obi_rvalid_i(instr_rvalid_i),
      .obi_err_i   (instr_err_i)
  );

endmodule
