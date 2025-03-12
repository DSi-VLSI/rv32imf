


module rv32imf_prefetch_buffer #(
) (
    input logic clk,
    input logic rst_n,

    input logic        req_i,
    input logic        branch_i,
    input logic [31:0] branch_addr_i,

    input logic [31:0] hwlp_target_i,

    input  logic        fetch_ready_i,
    output logic        fetch_valid_o,
    output logic [31:0] fetch_rdata_o,

    output logic        instr_req_o,
    input  logic        instr_gnt_i,
    output logic [31:0] instr_addr_o,
    input  logic [31:0] instr_rdata_i,
    input  logic        instr_rvalid_i,
    input  logic        instr_err_i,
    input  logic        instr_err_pmp_i,

    output logic busy_o
);

  localparam int FifoDepth = 2;
  localparam int unsigned FifoAddrDepth = $clog2(FifoDepth);

  logic                   trans_valid;
  logic                   trans_ready;
  logic [           31:0] trans_addr;

  logic                   fifo_flush;
  logic                   fifo_flush_but_first;
  logic [FifoAddrDepth:0] fifo_cnt;

  logic [           31:0] fifo_rdata;
  logic                   fifo_push;
  logic                   fifo_pop;
  logic                   fifo_empty;

  logic                   resp_valid;
  logic [           31:0] resp_rdata;
  logic                   resp_err;


  rv32imf_prefetch_controller #(
      .DEPTH   (FifoDepth)
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


  rv32imf_fifo #(
      .FALL_THROUGH(1'b0),
      .DATA_WIDTH  (32),
      .DEPTH       (FifoDepth)
  ) fifo_i (
      .clk_i            (clk),
      .rst_ni           (rst_n),
      .flush_i          (fifo_flush),
      .flush_but_first_i('0),
      .testmode_i       (1'b0),
      .full_o           (),
      .empty_o          (fifo_empty),
      .cnt_o            (fifo_cnt),
      .data_i           (resp_rdata),
      .push_i           (fifo_push),
      .data_o           (fifo_rdata),
      .pop_i            (fifo_pop)
  );


  assign fetch_rdata_o = fifo_empty ? resp_rdata : fifo_rdata;


  rv32imf_obi_interface #(
      .TRANS_STABLE(0)
  ) instruction_obi_i (
      .clk  (clk),
      .rst_n(rst_n),

      .trans_valid_i(trans_valid),
      .trans_ready_o(trans_ready),
      .trans_addr_i ({trans_addr[31:2], 2'b00}),
      .trans_we_i   (1'b0),
      .trans_be_i   (4'b1111),
      .trans_wdata_i(32'b0),
      .trans_atop_i (6'b0),

      .resp_valid_o(resp_valid),
      .resp_rdata_o(resp_rdata),
      .resp_err_o  (resp_err),

      .obi_req_o   (instr_req_o),
      .obi_gnt_i   (instr_gnt_i),
      .obi_addr_o  (instr_addr_o),
      .obi_we_o    (),
      .obi_be_o    (),
      .obi_wdata_o (),
      .obi_atop_o  (),
      .obi_rdata_i (instr_rdata_i),
      .obi_rvalid_i(instr_rvalid_i),
      .obi_err_i   (instr_err_i)
  );

endmodule
