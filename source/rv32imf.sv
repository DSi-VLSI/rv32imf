



module rv32imf #(
) (

    input logic clk_i,
    input logic rst_ni,


    input logic [31:0] boot_addr_i,
    input logic [31:0] dm_halt_addr_i,
    input logic [31:0] hart_id_i,
    input logic [31:0] dm_exception_addr_i,


    output logic        instr_req_o,
    input  logic        instr_gnt_i,
    input  logic        instr_rvalid_i,
    output logic [31:0] instr_addr_o,
    input  logic [31:0] instr_rdata_i,


    output logic        data_req_o,
    input  logic        data_gnt_i,
    input  logic        data_rvalid_i,
    output logic        data_we_o,
    output logic [ 3:0] data_be_o,
    output logic [31:0] data_addr_o,
    output logic [31:0] data_wdata_o,
    input  logic [31:0] data_rdata_i,


    input  logic [31:0] irq_i,
    output logic        irq_ack_o,
    output logic [ 4:0] irq_id_o
);

  logic              apu_busy;
  logic              apu_req;
  logic [ 2:0][31:0] apu_operands;
  logic [ 5:0]       apu_op;
  logic [14:0]       apu_flags;

  logic              apu_gnt;
  logic              apu_rvalid;
  logic [31:0]       apu_rdata;
  logic [ 4:0]       apu_rflags;

  logic apu_clk_en, apu_clk;


  rv32imf_core #() core_i (
      .clk_i (clk_i),
      .rst_ni(rst_ni),

      .boot_addr_i        (boot_addr_i),
      .mtvec_addr_i       ('0),
      .dm_halt_addr_i     (dm_halt_addr_i),
      .hart_id_i          (hart_id_i),
      .dm_exception_addr_i(dm_exception_addr_i),

      .instr_req_o   (instr_req_o),
      .instr_gnt_i   (instr_gnt_i),
      .instr_rvalid_i(instr_rvalid_i),
      .instr_addr_o  (instr_addr_o),
      .instr_rdata_i (instr_rdata_i),

      .data_req_o   (data_req_o),
      .data_gnt_i   (data_gnt_i),
      .data_rvalid_i(data_rvalid_i),
      .data_we_o    (data_we_o),
      .data_be_o    (data_be_o),
      .data_addr_o  (data_addr_o),
      .data_wdata_o (data_wdata_o),
      .data_rdata_i (data_rdata_i),

      .apu_busy_o    (apu_busy),
      .apu_req_o     (apu_req),
      .apu_gnt_i     (apu_gnt),
      .apu_operands_o(apu_operands),
      .apu_op_o      (apu_op),
      .apu_flags_o   (apu_flags),
      .apu_rvalid_i  (apu_rvalid),
      .apu_result_i  (apu_rdata),
      .apu_flags_i   (apu_rflags),

      .irq_i    (irq_i),
      .irq_ack_o(irq_ack_o),
      .irq_id_o (irq_id_o)
  );

  assign apu_clk_en = apu_req | apu_busy;


  rv32imf_clock_gate core_clock_gate_i (
      .clk_i(clk_i),
      .en_i (apu_clk_en),
      .clk_o(apu_clk)
  );

  rv32imf_fp_wrapper #() fp_wrapper_i (
      .clk_i         (apu_clk),
      .rst_ni        (rst_ni),
      .apu_req_i     (apu_req),
      .apu_gnt_o     (apu_gnt),
      .apu_operands_i(apu_operands),
      .apu_op_i      (apu_op),
      .apu_flags_i   (apu_flags),
      .apu_rvalid_o  (apu_rvalid),
      .apu_rdata_o   (apu_rdata),
      .apu_rflags_o  (apu_rflags)
  );

endmodule
