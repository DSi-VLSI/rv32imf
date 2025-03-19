


module rv32imf_if_stage #(
) (
    input logic clk,
    input logic rst_n,

    input logic [23:0] m_trap_base_addr_i,
    input logic [23:0] u_trap_base_addr_i,
    input logic [ 1:0] trap_addr_mux_i,

    input logic [31:0] boot_addr_i,
    input logic [31:0] dm_exception_addr_i,
    input logic [31:0] dm_halt_addr_i,

    input logic req_i,


    output logic instr_req_o,
    output logic [31:0] instr_addr_o,
    input logic instr_gnt_i,
    input logic instr_rvalid_i,
    input logic [31:0] instr_rdata_i,
    input logic instr_err_i,
    input logic instr_err_pmp_i,


    output logic instr_valid_id_o,
    output logic [31:0] instr_rdata_id_o,
    output logic is_compressed_id_o,
    output logic illegal_c_insn_id_o,
    output logic [31:0] pc_if_o,
    output logic [31:0] pc_id_o,
    output logic is_fetch_failed_o,

    input logic        clear_instr_valid_i,
    input logic        pc_set_i,
    input logic [31:0] mepc_i,
    input logic [31:0] uepc_i,
    input logic [31:0] depc_i,

    input  logic [3:0] pc_mux_i,
    input  logic [2:0] exc_pc_mux_i,
    input  logic [4:0] m_exc_vec_pc_mux_i,
    input  logic [4:0] u_exc_vec_pc_mux_i,
    output logic       csr_mtvec_init_o,

    input logic [31:0] jump_target_id_i,
    input logic [31:0] jump_target_ex_i,

    input logic [31:0] hwlp_target_i,

    input logic halt_if_i,
    input logic id_ready_i,

    output logic if_busy_o,
    output logic perf_imiss_o
);

  import rv32imf_pkg::*;


  logic if_valid, if_ready;
  logic        prefetch_busy;
  logic        branch_req;
  logic [31:0] branch_addr_n;
  logic        fetch_valid;
  logic        fetch_ready;
  logic [31:0] fetch_rdata;
  logic [31:0] exc_pc;
  logic [23:0] trap_base_addr;
  logic [ 4:0] exc_vec_pc_mux;
  logic        fetch_failed;
  logic        aligner_ready;
  logic        instr_valid;
  logic        illegal_c_insn;
  logic [31:0] instr_aligned;
  logic [31:0] instr_decompressed;
  logic        instr_compressed_int;


  always_comb begin : EXC_PC_MUX
    unique case (trap_addr_mux_i)
      TRAP_MACHINE: trap_base_addr = m_trap_base_addr_i;
      TRAP_USER:    trap_base_addr = u_trap_base_addr_i;
      default:      trap_base_addr = m_trap_base_addr_i;
    endcase

    unique case (trap_addr_mux_i)
      TRAP_MACHINE: exc_vec_pc_mux = m_exc_vec_pc_mux_i;
      TRAP_USER:    exc_vec_pc_mux = u_exc_vec_pc_mux_i;
      default:      exc_vec_pc_mux = m_exc_vec_pc_mux_i;
    endcase

    unique case (exc_pc_mux_i)
      EXC_PC_EXCEPTION: exc_pc = {trap_base_addr, 8'h0};
      EXC_PC_IRQ: exc_pc = {trap_base_addr, 1'b0, exc_vec_pc_mux, 2'b0};
      EXC_PC_DBD: exc_pc = {dm_halt_addr_i[31:2], 2'b0};
      EXC_PC_DBE: exc_pc = {dm_exception_addr_i[31:2], 2'b0};
      default: exc_pc = {trap_base_addr, 8'h0};
    endcase
  end


  always_comb begin
    branch_addr_n = {boot_addr_i[31:2], 2'b0};

    unique case (pc_mux_i)
      PC_BOOT: branch_addr_n = {boot_addr_i[31:2], 2'b0};
      PC_JUMP: branch_addr_n = jump_target_id_i;
      PC_BRANCH: branch_addr_n = jump_target_ex_i;
      PC_EXCEPTION: branch_addr_n = exc_pc;
      PC_MRET: branch_addr_n = mepc_i;
      PC_URET: branch_addr_n = uepc_i;
      PC_DRET: branch_addr_n = depc_i;
      PC_FENCEI: branch_addr_n = pc_id_o + 4;
      PC_HWLOOP: branch_addr_n = hwlp_target_i;
      default: ;
    endcase
  end


  assign csr_mtvec_init_o = (pc_mux_i == PC_BOOT) & pc_set_i;


  assign fetch_failed = 1'b0;


  rv32imf_prefetch_buffer #(
  ) prefetch_buffer_i (
      .clk  (clk),
      .rst_n(rst_n),

      .req_i(req_i),

      .branch_i     (branch_req),
      .branch_addr_i({branch_addr_n[31:1], 1'b0}),

      .hwlp_target_i(hwlp_target_i),

      .fetch_ready_i(fetch_ready),
      .fetch_valid_o(fetch_valid),
      .fetch_rdata_o(fetch_rdata),

      .instr_req_o    (instr_req_o),
      .instr_addr_o   (instr_addr_o),
      .instr_gnt_i    (instr_gnt_i),
      .instr_rvalid_i (instr_rvalid_i),
      .instr_err_i    (instr_err_i),
      .instr_err_pmp_i(instr_err_pmp_i),
      .instr_rdata_i  (instr_rdata_i),

      .busy_o(prefetch_busy)
  );


  always_comb begin
    fetch_ready = 1'b0;
    branch_req  = 1'b0;

    if (pc_set_i) begin
      branch_req = 1'b1;
    end else if (fetch_valid) begin
      if (req_i && if_valid) begin
        fetch_ready = aligner_ready;
      end
    end
  end


  assign if_busy_o    = prefetch_busy;
  assign perf_imiss_o = !fetch_valid && !branch_req;


  always_ff @(posedge clk, negedge rst_n) begin : IF_ID_PIPE_REGISTERS
    if (rst_n == 1'b0) begin
      instr_valid_id_o    <= 1'b0;
      instr_rdata_id_o    <= '0;
      is_fetch_failed_o   <= 1'b0;
      pc_id_o             <= '0;
      is_compressed_id_o  <= 1'b0;
      illegal_c_insn_id_o <= 1'b0;
    end else begin
      if (if_valid && instr_valid) begin
        instr_valid_id_o    <= 1'b1;
        instr_rdata_id_o    <= instr_decompressed;
        is_compressed_id_o  <= instr_compressed_int;
        illegal_c_insn_id_o <= illegal_c_insn;
        is_fetch_failed_o   <= 1'b0;
        pc_id_o             <= pc_if_o;
      end else if (clear_instr_valid_i) begin
        instr_valid_id_o  <= 1'b0;
        is_fetch_failed_o <= fetch_failed;
      end
    end
  end


  assign if_ready = fetch_valid & id_ready_i;
  assign if_valid = (~halt_if_i) & if_ready;


  rv32imf_aligner aligner_i (
      .clk             (clk),
      .rst_n           (rst_n),
      .fetch_valid_i   (fetch_valid),
      .aligner_ready_o (aligner_ready),
      .if_valid_i      (if_valid),
      .fetch_rdata_i   (fetch_rdata),
      .instr_aligned_o (instr_aligned),
      .instr_valid_o   (instr_valid),
      .branch_addr_i   ({branch_addr_n[31:1], 1'b0}),
      .branch_i        (branch_req),
      .hwlp_addr_i     (hwlp_target_i),
      .pc_o            (pc_if_o)
  );

  rv32imf_compressed_decoder #(
  ) compressed_decoder_i (
      .instr_i        (instr_aligned),
      .instr_o        (instr_decompressed),
      .is_compressed_o(instr_compressed_int),
      .illegal_instr_o(illegal_c_insn)
  );

endmodule
