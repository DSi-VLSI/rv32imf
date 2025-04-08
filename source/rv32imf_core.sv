// Module definition for the RV32IMF core.
module rv32imf_core #(
) (

    // Clock input.
    input logic clk_i,
    // Asynchronous reset input (active low).
    input logic rst_ni,

    // Boot address input.
    input logic [31:0] boot_addr_i,
    // Machine trap vector base address input.
    input logic [31:0] mtvec_addr_i,
    // Debug module halt address input.
    input logic [31:0] dm_halt_addr_i,
    // Hart ID input.
    input logic [31:0] hart_id_i,
    // Debug module exception address input.
    input logic [31:0] dm_exception_addr_i,


    // Instruction request output.
    output logic        instr_req_o,
    // Instruction grant input.
    input  logic        instr_gnt_i,
    // Instruction read valid input.
    input  logic        instr_rvalid_i,
    // Instruction address output.
    output logic [31:0] instr_addr_o,
    // Instruction read data input.
    input  logic [31:0] instr_rdata_i,


    // Data request output.
    output logic        data_req_o,
    // Data grant input.
    input  logic        data_gnt_i,
    // Data read valid input.
    input  logic        data_rvalid_i,
    // Data write enable output.
    output logic        data_we_o,
    // Data byte enable output.
    output logic [ 3:0] data_be_o,
    // Data address output.
    output logic [31:0] data_addr_o,
    // Data write data output.
    output logic [31:0] data_wdata_o,
    // Data read data input.
    input  logic [31:0] data_rdata_i,


    // APU busy output.
    output logic apu_busy_o,

    // APU request output.
    output logic apu_req_o,
    // APU grant input.
    input  logic apu_gnt_i,

    // APU operands output.
    output logic [ 2:0][31:0] apu_operands_o,
    // APU operation code output.
    output logic [ 5:0]       apu_op_o,
    // APU flags output.
    output logic [14:0]       apu_flags_o,

    // APU result valid input.
    input logic        apu_rvalid_i,
    // APU result input.
    input logic [31:0] apu_result_i,
    // APU flags input.
    input logic [ 4:0] apu_flags_i,


    // Interrupt request input.
    input  logic [31:0] irq_i,
    // Interrupt acknowledge output.
    output logic        irq_ack_o,
    // Interrupt ID output.
    output logic [ 4:0] irq_id_o,

    input logic [63:0] time_i  // Time input for cycle counting
);

  // Import the package definition.
  import rv32imf_pkg::*;


  // Local parameter for the number of PMP entries.
  localparam int NumPmpEntries = 16;
  // Local parameter to enable debug triggers.
  localparam int DebugTriggerEn = 1;

  // Data atomic operation type output.
  logic [5:0] data_atop_o;
  // Secure interrupt input.
  logic       irq_sec_i;
  // Secure level output.
  logic       sec_lvl_o;

  // Local parameter for the number of hardware loops.
  localparam int NumHwlp = 2;

  // Instruction valid signal in the ID stage.
  logic        instr_valid_id;
  // Instruction read data in the ID stage.
  logic [31:0] instr_rdata_id;
  // Flag indicating if the instruction is compressed in the ID stage.
  logic        is_compressed_id;
  // Flag indicating an illegal compressed instruction in the ID stage.
  logic        illegal_c_insn_id;
  // Flag indicating instruction fetch failure in the ID stage.
  logic        is_fetch_failed_id;

  // Signal to clear the instruction valid flag.
  logic        clear_instr_valid;
  // Signal to set the program counter.
  logic        pc_set;

  // Program counter mux select in the ID stage.
  logic [ 3:0] pc_mux_id;
  // Exception program counter mux select in the ID stage.
  logic [ 2:0] exc_pc_mux_id;
  // Machine exception vector PC mux select in the ID stage.
  logic [ 4:0] m_exc_vec_pc_mux_id;
  // User exception vector PC mux select in the ID stage.
  logic [ 4:0] u_exc_vec_pc_mux_id;
  // Exception cause.
  logic [ 4:0] exc_cause;

  // Trap address mux select.
  logic [ 1:0] trap_addr_mux;

  // Program counter in the IF stage.
  logic [31:0] pc_if;
  // Program counter in the ID stage.
  logic [31:0] pc_id;


  // Flag indicating if the core is decoding an instruction.
  logic        is_decoding;

  // Flag indicating if the address should be incremented in EX stage.
  logic        useincr_addr_ex;
  // Flag indicating a data misalignment.
  logic        data_misaligned;

  // Flag indicating a multi-cycle multiplier operation.
  logic        mult_multicycle;


  // Jump target address in the ID and EX stages.
  logic [31:0] jump_target_id, jump_target_ex;
  // Flag indicating a branch instruction in the EX stage.
  logic               branch_in_ex;
  // Decision of the branch instruction.
  logic               branch_decision;
  // Control transfer instruction type in the decode stage.
  logic        [ 1:0] ctrl_transfer_insn_in_dec;

  // Flag indicating control unit busy.
  logic               ctrl_busy;
  // Flag indicating instruction fetch unit busy.
  logic               if_busy;
  // Flag indicating load-store unit busy.
  logic               lsu_busy;

  // Program counter in the EX stage.
  logic        [31:0] pc_ex;


  // ALU enable signal in the EX stage.
  logic               alu_en_ex;
  // ALU operation code in the EX stage.
  alu_opcode_e        alu_operator_ex;
  // ALU operand A in the EX stage.
  logic        [31:0] alu_operand_a_ex;
  // ALU operand B in the EX stage.
  logic        [31:0] alu_operand_b_ex;
  // ALU operand C in the EX stage.
  logic        [31:0] alu_operand_c_ex;
  // Bitmask A in the EX stage.
  logic        [ 4:0] bmask_a_ex;
  // Bitmask B in the EX stage.
  logic        [ 4:0] bmask_b_ex;
  // Immediate vector extension mode in the EX stage.
  logic        [ 1:0] imm_vec_ext_ex;
  // ALU vector mode in the EX stage.
  logic        [ 1:0] alu_vec_mode_ex;
  // Flag indicating complex ALU operation in the EX stage.
  logic alu_is_clpx_ex, alu_is_subrot_ex;
  // Complex ALU shift amount in the EX stage.
  logic        [        1:0]       alu_clpx_shift_ex;


  // Multiplier operation code in the EX stage.
  mul_opcode_e                     mult_operator_ex;
  // Multiplier operand A in the EX stage.
  logic        [       31:0]       mult_operand_a_ex;
  // Multiplier operand B in the EX stage.
  logic        [       31:0]       mult_operand_b_ex;
  // Multiplier operand C in the EX stage.
  logic        [       31:0]       mult_operand_c_ex;
  // Multiplier enable signal in the EX stage.
  logic                            mult_en_ex;
  // Multiplier subword select in the EX stage.
  logic                            mult_sel_subword_ex;
  // Multiplier signed mode in the EX stage.
  logic        [        1:0]       mult_signed_mode_ex;
  // Multiplier immediate value in the EX stage.
  logic        [        4:0]       mult_imm_ex;
  // Multiplier dot product operand A in the EX stage.
  logic        [       31:0]       mult_dot_op_a_ex;
  // Multiplier dot product operand B in the EX stage.
  logic        [       31:0]       mult_dot_op_b_ex;
  // Multiplier dot product operand C in the EX stage.
  logic        [       31:0]       mult_dot_op_c_ex;
  // Multiplier dot product signed mode in the EX stage.
  logic        [        1:0]       mult_dot_signed_ex;
  // Flag indicating complex multiplier operation in the EX stage.
  logic                            mult_is_clpx_ex;
  // Complex multiplier shift amount in the EX stage.
  logic        [        1:0]       mult_clpx_shift_ex;
  // Complex multiplier imaginary part select in the EX stage.
  logic                            mult_clpx_img_ex;


  // Floating-point unit off flag.
  logic                            fs_off;
  // Floating-point rounding mode CSR value.
  logic        [   C_RM-1:0]       frm_csr;
  // Floating-point flags CSR value.
  logic        [C_FFLAG-1:0]       fflags_csr;
  // Floating-point flags write enable.
  logic                            fflags_we;
  // Floating-point registers write enable.
  logic                            fregs_we;


  // APU enable signal in the EX stage.
  logic        [        5:0]       apu_waddr_ex;
  // APU flags in the EX stage.
  logic        [       14:0]       apu_flags_ex;
  // APU operation code in the EX stage.
  logic        [        5:0]       apu_op_ex;
  // APU latency in the EX stage.
  logic        [        1:0]       apu_lat_ex;
  // APU operands in the EX stage.
  logic        [        2:0][31:0] apu_operands_ex;
  // APU write address in the EX stage.

  // APU read register addresses.
  logic        [        2:0][ 5:0] apu_read_regs;
  // APU read register valid flags.
  logic        [        2:0]       apu_read_regs_valid;
  // APU read dependency flag.
  logic                            apu_read_dep;
  // APU read dependency flag for JALR instruction.
  logic                            apu_read_dep_for_jalr;
  // APU write register addresses.
  logic        [        1:0][ 5:0] apu_write_regs;
  // APU write register valid flags.
  logic        [        1:0]       apu_write_regs_valid;
  // APU write dependency flag.
  logic                            apu_write_dep;

  // APU performance type.
  logic                            perf_apu_type;
  // APU performance contention.
  logic                            perf_apu_cont;
  // APU performance dependency.
  logic                            perf_apu_dep;
  // APU performance writeback.
  logic                            perf_apu_wb;


  // Register file write address in the EX stage.
  logic        [        5:0]       regfile_waddr_ex;
  // Register file write enable in the EX stage.
  logic                            regfile_we_ex;
  // Register file write address forward/writeback output.
  logic        [        5:0]       regfile_waddr_fw_wb_o;
  // Register file write enable in the writeback stage.
  logic                            regfile_we_wb;
  // Register file write enable in the writeback stage (for power).
  logic                            regfile_we_wb_power;
  // Register file write data.
  logic        [       31:0]       regfile_wdata;

  // Register file write address for ALU result in EX stage.
  logic        [        5:0]       regfile_alu_waddr_ex;
  // Register file write enable for ALU result in EX stage.
  logic                            regfile_alu_we_ex;

  // Register file write address for ALU result forwarding.
  logic        [        5:0]       regfile_alu_waddr_fw;
  // Register file write enable for ALU result forwarding.
  logic                            regfile_alu_we_fw;
  // Register file write enable for ALU result forwarding (for power).
  logic                            regfile_alu_we_fw_power;
  // Register file write data for ALU result forwarding.
  logic        [       31:0]       regfile_alu_wdata_fw;


  // CSR access enable in the EX stage.
  logic                            csr_access_ex;
  // CSR operation code in the EX stage.
  csr_opcode_e                     csr_op_ex;
  // Machine and user trap vector base addresses.
  logic [23:0] mtvec, utvec;
  // Machine and user trap vector modes.
  logic        [ 1:0] mtvec_mode;
  logic        [ 1:0] utvec_mode;

  // CSR operation code.
  csr_opcode_e        csr_op;
  // CSR address.
  csr_num_e           csr_addr;
  // Internal CSR address.
  csr_num_e           csr_addr_int;
  // CSR read data.
  logic        [31:0] csr_rdata;
  // CSR write data.
  logic        [31:0] csr_wdata;
  // Current privilege level.
  priv_lvl_t          current_priv_lvl;


  // Data write enable in the EX stage.
  logic               data_we_ex;
  // Data atomic operation type in the EX stage.
  logic        [ 5:0] data_atop_ex;
  // Data type in the EX stage.
  logic        [ 1:0] data_type_ex;
  // Data sign extension type in the EX stage.
  logic        [ 1:0] data_sign_ext_ex;
  // Data register offset type in the EX stage.
  logic        [ 1:0] data_reg_offset_ex;
  // Data request in the EX stage.
  logic               data_req_ex;
  // Data misalignment in the EX stage.
  logic               data_misaligned_ex;

  // Load-store unit read data.
  logic        [31:0] lsu_rdata;


  // Halt signal for the IF stage.
  logic               halt_if;
  // Ready signal for the ID stage.
  logic               id_ready;
  // Ready signal for the EX stage.
  logic               ex_ready;

  // Valid signal for the ID stage.
  logic               id_valid;
  // Valid signal for the EX stage.
  logic               ex_valid;
  // Valid signal for the WB stage (LSU).
  logic               wb_valid;

  // Ready signal from LSU to EX stage.
  logic               lsu_ready_ex;
  // Ready signal from LSU to WB stage.
  logic               lsu_ready_wb;

  // Ready signal from APU to WB stage.
  logic               apu_ready_wb;


  // Internal instruction request signal.
  logic               instr_req_int;


  // Machine and user interrupt enable flags.
  logic m_irq_enable, u_irq_enable;
  // CSR interrupt secure flag.
  logic csr_irq_sec;
  // Machine and user exception program counters, debug exception PC.
  logic [31:0] mepc, uepc, depc;
  // Machine interrupt enable bypass.
  logic [             31:0]       mie_bypass;
  // Machine interrupt pending.
  logic [             31:0]       mip;

  // Flags for saving CSR state during exceptions/interrupts.
  logic                           csr_save_cause;
  logic                           csr_save_if;
  logic                           csr_save_id;
  logic                           csr_save_ex;
  // Exception cause value.
  logic [              5:0]       csr_cause;
  // Flags for restoring CSR state during returns from exceptions.
  logic                           csr_restore_mret_id;
  logic                           csr_restore_uret_id;
  logic                           csr_restore_dret_id;
  // Flag to initialize the machine trap vector.
  logic                           csr_mtvec_init;


  // Machine counter enable.
  logic [             31:0]       mcounteren;


  // Debug mode flag.
  logic                           debug_mode;
  // Debug cause value.
  logic [              2:0]       debug_cause;
  // Flag to save CSR state during debug entry.
  logic                           debug_csr_save;
  // Single-step enable flag.
  logic                           debug_single_step;
  // Machine mode ebreak flag.
  logic                           debug_ebreakm;
  // User mode ebreak flag.
  logic                           debug_ebreaku;
  // Trigger match flag.
  logic                           trigger_match;
  // Debug port early load/write no sleep flag.
  logic                           debug_p_elw_no_sleep;


  // Hardware loop start and end addresses, and counter values.
  logic [      NumHwlp-1:0][31:0] hwlp_start;
  logic [      NumHwlp-1:0][31:0] hwlp_end;
  logic [      NumHwlp-1:0][31:0] hwlp_cnt;

  // Hardware loop target address.
  logic [             31:0]       hwlp_target;


  // Performance monitoring event flags.
  logic                           mhpmevent_minstret;
  logic                           mhpmevent_load;
  logic                           mhpmevent_store;
  logic                           mhpmevent_jump;
  logic                           mhpmevent_branch;
  logic                           mhpmevent_branch_taken;
  logic                           mhpmevent_compressed;
  logic                           mhpmevent_jr_stall;
  logic                           mhpmevent_imiss;
  logic                           mhpmevent_ld_stall;
  logic                           mhpmevent_pipe_stall;

  // Performance monitoring instruction miss flag.
  logic                           perf_imiss;


  // Flag indicating wake-up from sleep mode.
  logic                           wake_from_sleep;


  // Physical memory protection address and configuration registers.
  logic [NumPmpEntries-1:0][31:0] pmp_addr;
  logic [NumPmpEntries-1:0][ 7:0] pmp_cfg;

  // PMP signals for data access.
  logic                           data_req_pmp;
  logic [             31:0]       data_addr_pmp;
  logic                           data_gnt_pmp;
  logic                           data_err_pmp;
  logic                           data_err_ack;
  // PMP signals for instruction access.
  logic                           instr_req_pmp;
  logic                           instr_gnt_pmp;
  logic [             31:0]       instr_addr_pmp;
  logic                           instr_err_pmp;


  // Assign the machine exception vector PC based on the mode.
  assign m_exc_vec_pc_mux_id = (mtvec_mode == 2'b0) ? 5'h0 : exc_cause;
  // Assign the user exception vector PC based on the mode.
  assign u_exc_vec_pc_mux_id = (utvec_mode == 2'b0) ? 5'h0 : exc_cause;


  // Assign secure interrupt input (currently tied to 0).
  assign irq_sec_i = 1'b0;


  // Assign APU flags output.
  assign apu_flags_o = apu_flags_ex;










  // Internal clock signal.
  logic clk;
  // Instruction fetch enable signal.
  logic fetch_enable;

  // Instantiate the sleep unit module.
  rv32imf_sleep_unit #() sleep_unit_i (

      // Clock input.
      .clk_i      (clk_i),
      // Reset input.
      .rst_n      (rst_ni),
      // Gated clock output.
      .clk_gated_o(clk),


      // Fetch enable output.
      .fetch_enable_o(fetch_enable),


      // Instruction fetch unit busy input.
      .if_busy_i  (if_busy),
      // Control unit busy input.
      .ctrl_busy_i(ctrl_busy),
      // Load-store unit busy input.
      .lsu_busy_i (lsu_busy),
      // APU busy input.
      .apu_busy_i (apu_busy_o),

      // Wake-up from sleep input.
      .wake_from_sleep_i(wake_from_sleep)
  );










  // Instantiate the instruction fetch stage module.
  rv32imf_if_stage #() if_stage_i (
      // Clock input.
      .clk  (clk),
      // Reset input.
      .rst_n(rst_ni),


      // Boot address input.
      .boot_addr_i        (boot_addr_i[31:0]),
      // Debug exception address input.
      .dm_exception_addr_i(dm_exception_addr_i[31:0]),


      // Debug halt address input.
      .dm_halt_addr_i(dm_halt_addr_i[31:0]),


      // Machine trap base address input.
      .m_trap_base_addr_i(mtvec),
      // User trap base address input.
      .u_trap_base_addr_i(utvec),
      // Trap address mux select input.
      .trap_addr_mux_i   (trap_addr_mux),


      // Instruction request input.
      .req_i(instr_req_int),


      // Instruction request output to PMP.
      .instr_req_o    (instr_req_pmp),
      // Instruction address output to PMP.
      .instr_addr_o   (instr_addr_pmp),
      // Instruction grant input from PMP.
      .instr_gnt_i    (instr_gnt_pmp),
      // Instruction read valid input from memory.
      .instr_rvalid_i (instr_rvalid_i),
      // Instruction read data input from memory.
      .instr_rdata_i  (instr_rdata_i),
      // Instruction error input (currently tied to 0).
      .instr_err_i    (1'b0),
      // Instruction error from PMP input.
      .instr_err_pmp_i(instr_err_pmp),


      // Instruction valid output to ID stage.
      .instr_valid_id_o (instr_valid_id),
      // Instruction read data output to ID stage.
      .instr_rdata_id_o (instr_rdata_id),
      // Instruction fetch failed output to ID stage.
      .is_fetch_failed_o(is_fetch_failed_id),


      // Clear instruction valid input from ID stage.
      .clear_instr_valid_i(clear_instr_valid),
      // Program counter set input from ID stage.
      .pc_set_i           (pc_set),

      // Machine exception program counter input.
      .mepc_i(mepc),
      // User exception program counter input.
      .uepc_i(uepc),

      // Debug exception program counter input.
      .depc_i(depc),

      // Program counter mux select input from ID stage.
      .pc_mux_i    (pc_mux_id),
      // Exception program counter mux select input from ID stage.
      .exc_pc_mux_i(exc_pc_mux_id),


      // Program counter output to ID stage.
      .pc_id_o(pc_id),
      // Program counter output of IF stage.
      .pc_if_o(pc_if),

      // Compressed instruction flag output to ID stage.
      .is_compressed_id_o (is_compressed_id),
      // Illegal compressed instruction flag output to ID stage.
      .illegal_c_insn_id_o(illegal_c_insn_id),

      // Machine exception vector PC mux select input from ID stage.
      .m_exc_vec_pc_mux_i(m_exc_vec_pc_mux_id),
      // User exception vector PC mux select input from ID stage.
      .u_exc_vec_pc_mux_i(u_exc_vec_pc_mux_id),

      // CSR machine trap vector initialization output.
      .csr_mtvec_init_o(csr_mtvec_init),


      // Hardware loop target address input from ID stage.
      .hwlp_target_i(hwlp_target),



      // Jump target input from ID and EX stages.
      .jump_target_id_i(jump_target_id),
      .jump_target_ex_i(jump_target_ex),


      // Halt input from ID stage.
      .halt_if_i (halt_if),
      // Ready input from ID stage.
      .id_ready_i(id_ready),

      // Instruction fetch unit busy output.
      .if_busy_o   (if_busy),
      // Performance instruction miss output.
      .perf_imiss_o(perf_imiss)
  );










  // Instantiate the instruction decode stage module.
  rv32imf_id_stage #(
      // Parameter for the number of hardware loops.
      .N_HWLP(NumHwlp)
  ) id_stage_i (
      // Clock input.
      .clk          (clk),
      // Ungated clock input.
      .clk_ungated_i(clk_i),
      // Reset input.
      .rst_n        (rst_ni),


      // Control unit busy output.
      .ctrl_busy_o  (ctrl_busy),
      // Decoding in progress output.
      .is_decoding_o(is_decoding),


      // Instruction valid input from IF stage.
      .instr_valid_i(instr_valid_id),
      // Instruction read data input from IF stage.
      .instr_rdata_i(instr_rdata_id),
      // Instruction request output to IF stage.
      .instr_req_o  (instr_req_int),


      // Branch in EX stage output.
      .branch_in_ex_o             (branch_in_ex),
      // Branch decision input from EX stage.
      .branch_decision_i          (branch_decision),
      // Jump target output.
      .jump_target_o              (jump_target_id),
      // Control transfer instruction type output.
      .ctrl_transfer_insn_in_dec_o(ctrl_transfer_insn_in_dec),


      // Clear instruction valid output to IF stage.
      .clear_instr_valid_o(clear_instr_valid),
      // Program counter set output to IF stage.
      .pc_set_o           (pc_set),
      // Program counter mux select output to IF stage.
      .pc_mux_o           (pc_mux_id),
      // Exception program counter mux select output to IF stage.
      .exc_pc_mux_o       (exc_pc_mux_id),
      // Exception cause output.
      .exc_cause_o        (exc_cause),
      // Trap address mux select output to IF stage.
      .trap_addr_mux_o    (trap_addr_mux),

      // Instruction fetch failed input from IF stage.
      .is_fetch_failed_i(is_fetch_failed_id),

      // Program counter input from IF stage.
      .pc_id_i(pc_id),

      // Compressed instruction flag input from IF stage.
      .is_compressed_i (is_compressed_id),
      // Illegal compressed instruction flag input from IF stage.
      .illegal_c_insn_i(illegal_c_insn_id),


      // Halt output to IF stage.
      .halt_if_o(halt_if),

      // Ready output to IF stage.
      .id_ready_o(id_ready),
      // Ready input from EX stage.
      .ex_ready_i(ex_ready),
      // Ready input from WB stage (LSU).
      .wb_ready_i(lsu_ready_wb),

      // Valid output to EX stage.
      .id_valid_o(id_valid),
      // Valid input from EX stage.
      .ex_valid_i(ex_valid),


      // Program counter output to EX stage.
      .pc_ex_o(pc_ex),

      // ALU enable output to EX stage.
      .alu_en_ex_o        (alu_en_ex),
      // ALU operation code output to EX stage.
      .alu_operator_ex_o  (alu_operator_ex),
      // ALU operand A output to EX stage.
      .alu_operand_a_ex_o (alu_operand_a_ex),
      // ALU operand B output to EX stage.
      .alu_operand_b_ex_o (alu_operand_b_ex),
      // ALU operand C output to EX stage.
      .alu_operand_c_ex_o (alu_operand_c_ex),
      // Bitmask A output to EX stage.
      .bmask_a_ex_o       (bmask_a_ex),
      // Bitmask B output to EX stage.
      .bmask_b_ex_o       (bmask_b_ex),
      // Immediate vector extension mode output to EX stage.
      .imm_vec_ext_ex_o   (imm_vec_ext_ex),
      // ALU vector mode output to EX stage.
      .alu_vec_mode_ex_o  (alu_vec_mode_ex),
      // Complex ALU flag output to EX stage.
      .alu_is_clpx_ex_o   (alu_is_clpx_ex),
      // Subroutine ALU flag output to EX stage.
      .alu_is_subrot_ex_o (alu_is_subrot_ex),
      // Complex ALU shift amount output to EX stage.
      .alu_clpx_shift_ex_o(alu_clpx_shift_ex),

      // Register file write address output to EX stage.
      .regfile_waddr_ex_o(regfile_waddr_ex),
      // Register file write enable output to EX stage.
      .regfile_we_ex_o   (regfile_we_ex),

      // Register file ALU write enable output to EX stage.
      .regfile_alu_we_ex_o(regfile_alu_we_ex),
      // Register file ALU write address output to EX stage.
      .regfile_alu_waddr_ex_o(regfile_alu_waddr_ex),


      // Multiplier operation code output to EX stage.
      .mult_operator_ex_o   (mult_operator_ex),
      // Multiplier enable output to EX stage.
      .mult_en_ex_o         (mult_en_ex),
      // Multiplier subword select output to EX stage.
      .mult_sel_subword_ex_o(mult_sel_subword_ex),
      // Multiplier signed mode output to EX stage.
      .mult_signed_mode_ex_o(mult_signed_mode_ex),
      // Multiplier operand A output to EX stage.
      .mult_operand_a_ex_o  (mult_operand_a_ex),
      // Multiplier operand B output to EX stage.
      .mult_operand_b_ex_o  (mult_operand_b_ex),
      // Multiplier operand C output to EX stage.
      .mult_operand_c_ex_o  (mult_operand_c_ex),
      // Multiplier immediate output to EX stage.
      .mult_imm_ex_o        (mult_imm_ex),

      // Multiplier dot product operand A output to EX stage.
      .mult_dot_op_a_ex_o(mult_dot_op_a_ex),
      // Multiplier dot product operand B output to EX stage.
      .mult_dot_op_b_ex_o(mult_dot_op_b_ex),
      // Multiplier dot product operand C output to EX stage.
      .mult_dot_op_c_ex_o(mult_dot_op_c_ex),
      // Multiplier dot product signed output to EX stage.
      .mult_dot_signed_ex_o(mult_dot_signed_ex),
      // Complex multiplier flag output to EX stage.
      .mult_is_clpx_ex_o(mult_is_clpx_ex),
      // Complex multiplier shift amount output to EX stage.
      .mult_clpx_shift_ex_o(mult_clpx_shift_ex),
      // Complex multiplier imaginary part select output to EX stage.
      .mult_clpx_img_ex_o(mult_clpx_img_ex),


      // Floating-point unit off input.
      .fs_off_i(fs_off),
      // Floating-point rounding mode input.
      .frm_i   (frm_csr),


      // APU enable output to EX stage.
      .apu_en_ex_o      (apu_en_ex),
      // APU operation code output to EX stage.
      .apu_op_ex_o      (apu_op_ex),
      // APU latency output to EX stage.
      .apu_lat_ex_o     (apu_lat_ex),
      // APU operands output to EX stage.
      .apu_operands_ex_o(apu_operands_ex),
      // APU flags output to EX stage.
      .apu_flags_ex_o   (apu_flags_ex),
      // APU write address output to EX stage.
      .apu_waddr_ex_o   (apu_waddr_ex),

      // APU read register addresses output.
      .apu_read_regs_o        (apu_read_regs),
      // APU read register valid flags output.
      .apu_read_regs_valid_o  (apu_read_regs_valid),
      // APU read dependency input from EX stage.
      .apu_read_dep_i         (apu_read_dep),
      // APU read dependency for JALR input from EX stage.
      .apu_read_dep_for_jalr_i(apu_read_dep_for_jalr),
      // APU write register addresses output.
      .apu_write_regs_o       (apu_write_regs),
      // APU write register valid flags output.
      .apu_write_regs_valid_o (apu_write_regs_valid),
      // APU write dependency input from EX stage.
      .apu_write_dep_i        (apu_write_dep),
      // APU performance dependency output.
      .apu_perf_dep_o         (perf_apu_dep),
      // APU busy input.
      .apu_busy_i             (apu_busy_o),


      // CSR access enable output to EX stage.
      .csr_access_ex_o      (csr_access_ex),
      // CSR operation code output to EX stage.
      .csr_op_ex_o          (csr_op_ex),
      // Current privilege level input.
      .current_priv_lvl_i   (current_priv_lvl),
      // CSR interrupt secure flag output.
      .csr_irq_sec_o        (csr_irq_sec),
      // CSR cause output.
      .csr_cause_o          (csr_cause),
      // CSR save IF flag output.
      .csr_save_if_o        (csr_save_if),
      // CSR save ID flag output.
      .csr_save_id_o        (csr_save_id),
      // CSR save EX flag output.
      .csr_save_ex_o        (csr_save_ex),
      // CSR restore MRET flag output.
      .csr_restore_mret_id_o(csr_restore_mret_id),
      // CSR restore URET flag output.
      .csr_restore_uret_id_o(csr_restore_uret_id),

      // CSR restore DRET flag output.
      .csr_restore_dret_id_o(csr_restore_dret_id),

      // CSR save cause flag output.
      .csr_save_cause_o(csr_save_cause),

      // Hardware loop target address output.
      .hwlp_target_o(hwlp_target),

      // Data request output to EX stage.
      .data_req_ex_o       (data_req_ex),
      // Data write enable output to EX stage.
      .data_we_ex_o        (data_we_ex),
      // Atomic operation type output to EX stage.
      .atop_ex_o           (data_atop_ex),
      // Data type output to EX stage.
      .data_type_ex_o      (data_type_ex),
      // Data sign extension output to EX stage.
      .data_sign_ext_ex_o  (data_sign_ext_ex),
      // Data register offset output to EX stage.
      .data_reg_offset_ex_o(data_reg_offset_ex),

      // Data misalignment output to EX stage.
      .data_misaligned_ex_o(data_misaligned_ex),

      // Pre/post increment usage output to EX stage.
      .prepost_useincr_ex_o(useincr_addr_ex),
      // Data misalignment input from LSU.
      .data_misaligned_i   (data_misaligned),
      // Data error input from LSU.
      .data_err_i          (data_err_pmp),
      // Data error acknowledge output to LSU.
      .data_err_ack_o      (data_err_ack),


      // Interrupt request input.
      .irq_i         (irq_i),
      // Secure interrupt input.
      .irq_sec_i     (1'b0),
      // Machine interrupt enable bypass input.
      .mie_bypass_i  (mie_bypass),
      // Machine interrupt pending output.
      .mip_o         (mip),
      // Machine interrupt enable input.
      .m_irq_enable_i(m_irq_enable),
      // User interrupt enable input.
      .u_irq_enable_i(u_irq_enable),
      // Interrupt acknowledge output.
      .irq_ack_o     (irq_ack_o),
      // Interrupt ID output.
      .irq_id_o      (irq_id_o),


      // Debug mode output.
      .debug_mode_o          (debug_mode),
      // Debug cause output.
      .debug_cause_o         (debug_cause),
      // Debug CSR save output.
      .debug_csr_save_o      (debug_csr_save),
      // Debug single step input.
      .debug_single_step_i   (debug_single_step),
      // Debug ebreakm input.
      .debug_ebreakm_i       (debug_ebreakm),
      // Debug ebreaku input.
      .debug_ebreaku_i       (debug_ebreaku),
      // Trigger match input.
      .trigger_match_i       (trigger_match),
      // Debug port early load/write no sleep output.
      .debug_p_elw_no_sleep_o(debug_p_elw_no_sleep),


      // Wake from sleep output.
      .wake_from_sleep_o(wake_from_sleep),


      // Register file write address input from WB stage.
      .regfile_waddr_wb_i   (regfile_waddr_fw_wb_o),
      // Register file write enable input from WB stage.
      .regfile_we_wb_i      (regfile_we_wb),
      // Register file write enable power input from WB stage.
      .regfile_we_wb_power_i(regfile_we_wb_power),
      // Register file write data input from WB stage.
      .regfile_wdata_wb_i   (regfile_wdata),

      // Register file ALU write address input from forwarding.
      .regfile_alu_waddr_fw_i   (regfile_alu_waddr_fw),
      // Register file ALU write enable input from forwarding.
      .regfile_alu_we_fw_i      (regfile_alu_we_fw),
      // Register file ALU write enable power input from forwarding.
      .regfile_alu_we_fw_power_i(regfile_alu_we_fw_power),
      // Register file ALU write data input from forwarding.
      .regfile_alu_wdata_fw_i   (regfile_alu_wdata_fw),


      // Multiplier multi-cycle input from EX stage.
      .mult_multicycle_i(mult_multicycle),


      // Performance monitoring outputs.
      .mhpmevent_minstret_o    (mhpmevent_minstret),
      .mhpmevent_load_o        (mhpmevent_load),
      .mhpmevent_store_o       (mhpmevent_store),
      .mhpmevent_jump_o        (mhpmevent_jump),
      .mhpmevent_branch_o      (mhpmevent_branch),
      .mhpmevent_branch_taken_o(mhpmevent_branch_taken),
      .mhpmevent_compressed_o  (mhpmevent_compressed),
      .mhpmevent_jr_stall_o    (mhpmevent_jr_stall),
      .mhpmevent_imiss_o       (mhpmevent_imiss),
      .mhpmevent_ld_stall_o    (mhpmevent_ld_stall),
      .mhpmevent_pipe_stall_o  (mhpmevent_pipe_stall),

      // Performance instruction miss input.
      .perf_imiss_i(perf_imiss),
      // Machine counter enable input.
      .mcounteren_i(mcounteren)
  );










  // Instantiate the execution stage module.
  rv32imf_ex_stage #() ex_stage_i (

      // Clock input.
      .clk  (clk),
      // Reset input.
      .rst_n(rst_ni),


      // ALU enable input from ID stage.
      .alu_en_i        (alu_en_ex),
      // ALU operation code input from ID stage.
      .alu_operator_i  (alu_operator_ex),
      // ALU operand A input from ID stage.
      .alu_operand_a_i (alu_operand_a_ex),
      // ALU operand B input from ID stage.
      .alu_operand_b_i (alu_operand_b_ex),
      // ALU operand C input from ID stage.
      .alu_operand_c_i (alu_operand_c_ex),
      // Bitmask A input from ID stage.
      .bmask_a_i       (bmask_a_ex),
      // Bitmask B input from ID stage.
      .bmask_b_i       (bmask_b_ex),
      // Immediate vector extension mode input from ID stage.
      .imm_vec_ext_i   (imm_vec_ext_ex),
      // ALU vector mode input from ID stage.
      .alu_vec_mode_i  (alu_vec_mode_ex),
      // Complex ALU flag input from ID stage.
      .alu_is_clpx_i   (alu_is_clpx_ex),
      // Subroutine ALU flag input from ID stage.
      .alu_is_subrot_i (alu_is_subrot_ex),
      // Complex ALU shift amount input from ID stage.
      .alu_clpx_shift_i(alu_clpx_shift_ex),


      // Multiplier operation code input from ID stage.
      .mult_operator_i   (mult_operator_ex),
      // Multiplier operand A input from ID stage.
      .mult_operand_a_i  (mult_operand_a_ex),
      // Multiplier operand B input from ID stage.
      .mult_operand_b_i  (mult_operand_b_ex),
      // Multiplier operand C input from ID stage.
      .mult_operand_c_i  (mult_operand_c_ex),
      // Multiplier enable input from ID stage.
      .mult_en_i         (mult_en_ex),
      // Multiplier subword select input from ID stage.
      .mult_sel_subword_i(mult_sel_subword_ex),
      // Multiplier signed mode input from ID stage.
      .mult_signed_mode_i(mult_signed_mode_ex),
      // Multiplier immediate input from ID stage.
      .mult_imm_i        (mult_imm_ex),
      // Multiplier dot product operand A input from ID stage.
      .mult_dot_op_a_i   (mult_dot_op_a_ex),
      // Multiplier dot product operand B input from ID stage.
      .mult_dot_op_b_i   (mult_dot_op_b_ex),
      // Multiplier dot product operand C input from ID stage.
      .mult_dot_op_c_i   (mult_dot_op_c_ex),
      // Multiplier dot product signed input from ID stage.
      .mult_dot_signed_i (mult_dot_signed_ex),
      // Complex multiplier flag input from ID stage.
      .mult_is_clpx_i    (mult_is_clpx_ex),
      // Complex multiplier shift amount input from ID stage.
      .mult_clpx_shift_i (mult_clpx_shift_ex),
      // Complex multiplier imaginary part select input from ID stage.
      .mult_clpx_img_i   (mult_clpx_img_ex),

      // Multiplier multi-cycle output to ID stage.
      .mult_multicycle_o(mult_multicycle),

      // Data request input from LSU.
      .data_req_i          (data_req_o),
      // Data read valid input from LSU.
      .data_rvalid_i       (data_rvalid_i),
      // Data misalignment input from ID stage.
      .data_misaligned_ex_i(data_misaligned_ex),
      // Data misalignment input from LSU.
      .data_misaligned_i   (data_misaligned),

      // Control transfer instruction type input from ID stage.
      .ctrl_transfer_insn_in_dec_i(ctrl_transfer_insn_in_dec),


      // Floating-point flags write enable output.
      .fpu_fflags_we_o(fflags_we),
      // Floating-point flags output.
      .fpu_fflags_o   (fflags_csr),


      // APU enable input from ID stage.
      .apu_en_i      (apu_en_ex),
      // APU operation code input from ID stage.
      .apu_op_i      (apu_op_ex),
      // APU latency input from ID stage.
      .apu_lat_i     (apu_lat_ex),
      // APU operands input from ID stage.
      .apu_operands_i(apu_operands_ex),
      // APU write address input from ID stage.
      .apu_waddr_i   (apu_waddr_ex),

      // APU read register addresses input from ID stage.
      .apu_read_regs_i        (apu_read_regs),
      // APU read register valid flags input from ID stage.
      .apu_read_regs_valid_i  (apu_read_regs_valid),
      // APU read dependency output to ID stage.
      .apu_read_dep_o         (apu_read_dep),
      // APU read dependency for JALR output to ID stage.
      .apu_read_dep_for_jalr_o(apu_read_dep_for_jalr),
      // APU write register addresses input from ID stage.
      .apu_write_regs_i       (apu_write_regs),
      // APU write register valid flags input from ID stage.
      .apu_write_regs_valid_i (apu_write_regs_valid),
      // APU write dependency output to ID stage.
      .apu_write_dep_o        (apu_write_dep),

      // APU performance type output.
      .apu_perf_type_o(perf_apu_type),
      // APU performance contention output.
      .apu_perf_cont_o(perf_apu_cont),
      // APU performance writeback output.
      .apu_perf_wb_o  (perf_apu_wb),
      // APU ready to writeback output.
      .apu_ready_wb_o (apu_ready_wb),
      // APU busy output.
      .apu_busy_o     (apu_busy_o),



      // APU request output.
      .apu_req_o(apu_req_o),
      // APU grant input.
      .apu_gnt_i(apu_gnt_i),

      // APU operands output.
      .apu_operands_o(apu_operands_o),
      // APU operation code output.
      .apu_op_o      (apu_op_o),

      // APU result valid input.
      .apu_rvalid_i(apu_rvalid_i),
      // APU result input.
      .apu_result_i(apu_result_i),
      // APU flags input.
      .apu_flags_i (apu_flags_i),

      // LSU enable input from ID stage.
      .lsu_en_i   (data_req_ex),
      // LSU read data input from LSU.
      .lsu_rdata_i(lsu_rdata),


      // CSR access enable input from ID stage.
      .csr_access_i(csr_access_ex),
      // CSR read data input from CSR registers.
      .csr_rdata_i (csr_rdata),


      // Branch in EX stage input from ID stage.
      .branch_in_ex_i  (branch_in_ex),
      // Register file ALU write address input from ID stage.
      .regfile_alu_waddr_i(regfile_alu_waddr_ex),
      // Register file ALU write enable input from ID stage.
      .regfile_alu_we_i   (regfile_alu_we_ex),

      // Register file write address input from ID stage.
      .regfile_waddr_i(regfile_waddr_ex),
      // Register file write enable input from ID stage.
      .regfile_we_i   (regfile_we_ex),


      // Register file write address output to WB stage.
      .regfile_waddr_wb_o   (regfile_waddr_fw_wb_o),
      // Register file write enable output to WB stage.
      .regfile_we_wb_o      (regfile_we_wb),
      // Register file write enable power output to WB stage.
      .regfile_we_wb_power_o(regfile_we_wb_power),
      // Register file write data output to WB stage.
      .regfile_wdata_wb_o   (regfile_wdata),


      // Jump target output to IF stage.
      .jump_target_o    (jump_target_ex),
      // Branch decision output to ID stage.
      .branch_decision_o(branch_decision),


      // Register file ALU write address output for forwarding.
      .regfile_alu_waddr_fw_o   (regfile_alu_waddr_fw),
      // Register file ALU write enable output for forwarding.
      .regfile_alu_we_fw_o      (regfile_alu_we_fw),
      // Register file ALU write enable power output for forwarding.
      .regfile_alu_we_fw_power_o(regfile_alu_we_fw_power),
      // Register file ALU write data output for forwarding.
      .regfile_alu_wdata_fw_o   (regfile_alu_wdata_fw),


      // Decoding in progress input from ID stage.
      .is_decoding_i (is_decoding),
      // LSU ready input from LSU.
      .lsu_ready_ex_i(lsu_ready_ex),
      // LSU error input from LSU.
      .lsu_err_i     (data_err_pmp),

      // Ready output to ID stage.
      .ex_ready_o(ex_ready),
      // Valid output to WB stage (LSU).
      .ex_valid_o(ex_valid),
      // Ready input from WB stage (LSU).
      .wb_ready_i(lsu_ready_wb)
  );











  // Instantiate the load-store unit module.
  rv32imf_load_store_unit #() load_store_unit_i (
      // Clock input.
      .clk  (clk),
      // Reset input.
      .rst_n(rst_ni),


      // Data request output to PMP.
      .data_req_o    (data_req_pmp),
      // Data grant input from PMP.
      .data_gnt_i    (data_gnt_pmp),
      // Data read valid input from memory.
      .data_rvalid_i (data_rvalid_i),
      // Data error input (currently tied to 0).
      .data_err_i    (1'b0),
      // Data error from PMP input.
      .data_err_pmp_i(data_err_pmp),

      // Data address output to memory.
      .data_addr_o (data_addr_pmp),
      // Data write enable output to memory.
      .data_we_o   (data_we_o),
      // Data atomic operation type output to memory.
      .data_atop_o (data_atop_o),
      // Data byte enable output to memory.
      .data_be_o   (data_be_o),
      // Data write data output to memory.
      .data_wdata_o(data_wdata_o),
      // Data read data input from memory.
      .data_rdata_i(data_rdata_i),


      // Data write enable input from EX stage.
      .data_we_ex_i        (data_we_ex),
      // Data atomic operation type input from EX stage.
      .data_atop_ex_i      (data_atop_ex),
      // Data type input from EX stage.
      .data_type_ex_i      (data_type_ex),
      // Data write data input from EX stage.
      .data_wdata_ex_i     (alu_operand_c_ex),
      // Data register offset input from EX stage.
      .data_reg_offset_ex_i(data_reg_offset_ex),
      // Data sign extension input from EX stage.
      .data_sign_ext_ex_i  (data_sign_ext_ex),

      // Data read data output to EX stage.
      .data_rdata_ex_o  (lsu_rdata),
      // Data request input from EX stage.
      .data_req_ex_i    (data_req_ex),
      // Operand A input from EX stage.
      .operand_a_ex_i   (alu_operand_a_ex),
      // Operand B input from EX stage.
      .operand_b_ex_i   (alu_operand_b_ex),
      // Address increment usage input from EX stage.
      .addr_useincr_ex_i(useincr_addr_ex),

      // Data misalignment input from EX stage.
      .data_misaligned_ex_i(data_misaligned_ex),
      // Data misalignment output.
      .data_misaligned_o   (data_misaligned),

      // Ready output to EX stage.
      .lsu_ready_ex_o(lsu_ready_ex),
      // Ready output to ID stage.
      .lsu_ready_wb_o(lsu_ready_wb),

      // Busy output.
      .busy_o(lsu_busy)
  );


  // Assign WB stage valid signal.
  assign wb_valid = lsu_ready_wb;












  // Instantiate the control and status registers module.
  rv32imf_cs_registers #(
      // Parameter for the number of hardware loops.
      .N_HWLP          (NumHwlp),
      // Parameter for the number of PMP entries.
      .N_PMP_ENTRIES   (NumPmpEntries),
      // Parameter to enable debug triggers.
      .DEBUG_TRIGGER_EN(DebugTriggerEn)
  ) cs_registers_i (
      // Clock input.
      .clk  (clk),
      // Reset input.
      .rst_n(rst_ni),


      // Hart ID input.
      .hart_id_i   (hart_id_i),
      // Machine trap vector base address output.
      .mtvec_o     (mtvec),
      // User trap vector base address output.
      .utvec_o     (utvec),
      // Machine trap vector mode output.
      .mtvec_mode_o(mtvec_mode),
      // User trap vector mode output.
      .utvec_mode_o(utvec_mode),

      // Machine trap vector base address input.
      .mtvec_addr_i(mtvec_addr_i[31:0]),
      // CSR machine trap vector initialization input.
      .csr_mtvec_init_i(csr_mtvec_init),

      // CSR address input.
      .csr_addr_i (csr_addr),
      // CSR write data input.
      .csr_wdata_i(csr_wdata),
      // CSR operation input.
      .csr_op_i   (csr_op),
      // CSR read data output.
      .csr_rdata_o(csr_rdata),

      // Floating-point unit off output.
      .fs_off_o   (fs_off),
      // Floating-point rounding mode output.
      .frm_o      (frm_csr),
      // Floating-point flags input.
      .fflags_i   (fflags_csr),
      // Floating-point flags write enable input.
      .fflags_we_i(fflags_we),
      // Floating-point registers write enable input.
      .fregs_we_i (fregs_we),


      // Machine interrupt enable bypass output.
      .mie_bypass_o  (mie_bypass),
      // Machine interrupt pending input.
      .mip_i         (mip),
      // Machine interrupt enable output.
      .m_irq_enable_o(m_irq_enable),
      // User interrupt enable output.
      .u_irq_enable_o(u_irq_enable),
      // CSR interrupt secure flag input.
      .csr_irq_sec_i (csr_irq_sec),
      // Secure level output.
      .sec_lvl_o     (sec_lvl_o),
      // Machine exception program counter output.
      .mepc_o        (mepc),
      // User exception program counter output.
      .uepc_o        (uepc),


      // Machine counter enable output.
      .mcounteren_o(mcounteren),


      // Debug mode input.
      .debug_mode_i       (debug_mode),
      // Debug cause input.
      .debug_cause_i      (debug_cause),
      // Debug CSR save input.
      .debug_csr_save_i   (debug_csr_save),
      // Debug exception program counter output.
      .depc_o             (depc),
      // Debug single step output.
      .debug_single_step_o(debug_single_step),
      // Debug ebreakm output.
      .debug_ebreakm_o    (debug_ebreakm),
      // Debug ebreaku output.
      .debug_ebreaku_o    (debug_ebreaku),
      // Trigger match output.
      .trigger_match_o    (trigger_match),

      // Privilege level output.
      .priv_lvl_o(current_priv_lvl),

      // PMP address output.
      .pmp_addr_o(pmp_addr),
      // PMP configuration output.
      .pmp_cfg_o (pmp_cfg),

      // Program counter input from IF, ID, and EX stages.
      .pc_if_i(pc_if),
      .pc_id_i(pc_id),
      .pc_ex_i(pc_ex),

      // CSR save IF input.
      .csr_save_if_i   (csr_save_if),
      // CSR save ID input.
      .csr_save_id_i   (csr_save_id),
      // CSR save EX input.
      .csr_save_ex_i   (csr_save_ex),
      // CSR restore MRET input.
      .csr_restore_mret_i(csr_restore_mret_id),
      // CSR restore URET input.
      .csr_restore_uret_i(csr_restore_uret_id),

      // CSR restore DRET input.
      .csr_restore_dret_i(csr_restore_dret_id),

      // CSR cause input.
      .csr_cause_i     (csr_cause),
      // CSR save cause input.
      .csr_save_cause_i(csr_save_cause),


      // Hardware loop start address input.
      .hwlp_start_i(hwlp_start),
      // Hardware loop end address input.
      .hwlp_end_i  (hwlp_end),
      // Hardware loop counter input.
      .hwlp_cnt_i  (hwlp_cnt),


      // Performance monitoring event inputs.
      .mhpmevent_minstret_i    (mhpmevent_minstret),
      .mhpmevent_load_i        (mhpmevent_load),
      .mhpmevent_store_i       (mhpmevent_store),
      .mhpmevent_jump_i        (mhpmevent_jump),
      .mhpmevent_branch_i      (mhpmevent_branch),
      .mhpmevent_branch_taken_i(mhpmevent_branch_taken),
      .mhpmevent_compressed_i  (mhpmevent_compressed),
      .mhpmevent_jr_stall_i    (mhpmevent_jr_stall),
      .mhpmevent_imiss_i       (mhpmevent_imiss),
      .mhpmevent_ld_stall_i    (mhpmevent_ld_stall),
      .mhpmevent_pipe_stall_i  (mhpmevent_pipe_stall),
      // APU type conflict input.
      .apu_typeconflict_i      (perf_apu_type),
      // APU contention input.
      .apu_contention_i        (perf_apu_cont),
      // APU dependency input.
      .apu_dep_i               (perf_apu_dep),
      // APU writeback input.
      .apu_wb_i                (perf_apu_wb),
      .time_i                  (time_i)
  );


  // Assign CSR address based on EX stage ALU output.
  assign csr_addr = csr_addr_int;
  // Assign CSR write data based on EX stage ALU output.
  assign csr_wdata = alu_operand_a_ex;
  // Assign CSR operation based on EX stage output.
  assign csr_op = csr_op_ex;

  // Assign internal CSR address.
  assign csr_addr_int = csr_num_e'(csr_access_ex ? alu_operand_b_ex[11:0] : '0);


  // Assign floating-point registers write enable.
  assign fregs_we     = ((regfile_alu_we_fw && regfile_alu_waddr_fw[5])
                           || (regfile_we_wb     && regfile_waddr_fw_wb_o[5]));

  // Assign instruction request output.
  assign instr_req_o = instr_req_pmp;
  // Assign instruction address output.
  assign instr_addr_o = instr_addr_pmp;
  // Assign instruction grant input to PMP.
  assign instr_gnt_pmp = instr_gnt_i;
  // Assign instruction error from PMP (currently tied to 0).
  assign instr_err_pmp = 1'b0;

  // Assign data request output.
  assign data_req_o = data_req_pmp;
  // Assign data address output.
  assign data_addr_o = data_addr_pmp;
  // Assign data grant input to PMP.
  assign data_gnt_pmp = data_gnt_i;
  // Assign data error from PMP (currently tied to 0).
  assign data_err_pmp = 1'b0;

endmodule
