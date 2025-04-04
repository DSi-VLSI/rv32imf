module rv32imf_id_stage
  import rv32imf_pkg::*;
#(
    // Number of hardware loops
    parameter int N_HWLP = 2,
    // Number of bits required to represent hardware loops
    parameter int N_HWLP_BITS = $clog2(N_HWLP)
) (
    ////////////////////////////////////////////////////////////////////////////////////////////////
    // Clock and Reset
    ////////////////////////////////////////////////////////////////////////////////////////////////

    // Clock signal
    input logic clk,
    // Ungated clock signal
    input logic clk_ungated_i,
    // Active-low reset signal
    input logic rst_n,

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // Control Signals
    ////////////////////////////////////////////////////////////////////////////////////////////////

    // Indicates if the control unit is busy
    output logic ctrl_busy_o,
    // Indicates if the instruction is being decoded
    output logic is_decoding_o,

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // Instruction Fetch Interface
    ////////////////////////////////////////////////////////////////////////////////////////////////

    // Instruction valid signal
    input  logic        instr_valid_i,
    // Instruction data
    input  logic [31:0] instr_rdata_i,
    // Instruction request signal
    output logic        instr_req_o,
    // Indicates if the instruction is compressed
    input  logic        is_compressed_i,
    // Indicates if the compressed instruction is illegal
    input  logic        illegal_c_insn_i,

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // Branch and Jump Signals
    ////////////////////////////////////////////////////////////////////////////////////////////////

    // Indicates if a branch is in the execute stage
    output logic        branch_in_ex_o,
    // Branch decision signal
    input  logic        branch_decision_i,
    // Jump target address
    output logic [31:0] jump_target_o,
    // Control transfer instruction in decode stage
    output logic [ 1:0] ctrl_transfer_insn_in_dec_o,

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // Program Counter Control
    ////////////////////////////////////////////////////////////////////////////////////////////////

    // Clear instruction valid signal
    output logic       clear_instr_valid_o,
    // Program counter set signal
    output logic       pc_set_o,
    // Program counter multiplexer select
    output logic [3:0] pc_mux_o,
    // Exception program counter multiplexer select
    output logic [2:0] exc_pc_mux_o,
    // Trap address multiplexer select
    output logic [1:0] trap_addr_mux_o,

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // Fetch Status
    ////////////////////////////////////////////////////////////////////////////////////////////////

    // Indicates if the fetch failed
    input logic is_fetch_failed_i,

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // Program Counter Input
    ////////////////////////////////////////////////////////////////////////////////////////////////

    // Program counter value in the ID stage
    input logic [31:0] pc_id_i,

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // Halt Signals
    ////////////////////////////////////////////////////////////////////////////////////////////////

    // Halt instruction fetch signal
    output logic halt_if_o,

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // Pipeline Control
    ////////////////////////////////////////////////////////////////////////////////////////////////

    // Indicates if the ID stage is ready
    output logic id_ready_o,
    // Indicates if the EX stage is ready
    input  logic ex_ready_i,
    // Indicates if the WB stage is ready
    input  logic wb_ready_i,

    // Indicates if the ID stage is valid
    output logic id_valid_o,
    // Indicates if the EX stage is valid
    input  logic ex_valid_i,

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // Program Counter Output
    ////////////////////////////////////////////////////////////////////////////////////////////////

    // Program counter value in the EX stage
    output logic [31:0] pc_ex_o,

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // ALU Operand Outputs
    ////////////////////////////////////////////////////////////////////////////////////////////////

    // ALU operand A
    output logic [31:0] alu_operand_a_ex_o,
    // ALU operand B
    output logic [31:0] alu_operand_b_ex_o,
    // ALU operand C
    output logic [31:0] alu_operand_c_ex_o,
    // Bitmask A
    output logic [ 4:0] bmask_a_ex_o,
    // Bitmask B
    output logic [ 4:0] bmask_b_ex_o,
    // Immediate vector extension
    output logic [ 1:0] imm_vec_ext_ex_o,
    // ALU vector mode
    output logic [ 1:0] alu_vec_mode_ex_o,

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // Register File Outputs
    ////////////////////////////////////////////////////////////////////////////////////////////////

    // Register file write address
    output logic [5:0] regfile_waddr_ex_o,
    // Register file write enable
    output logic       regfile_we_ex_o,

    // Register file ALU write address
    output logic [5:0] regfile_alu_waddr_ex_o,
    // Register file ALU write enable
    output logic       regfile_alu_we_ex_o,

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // ALU Control Signals
    ////////////////////////////////////////////////////////////////////////////////////////////////

    // ALU enable signal
    output logic              alu_en_ex_o,
    // ALU operation code
    output alu_opcode_e       alu_operator_ex_o,
    // Indicates if the ALU operation is CLPX
    output logic              alu_is_clpx_ex_o,
    // Indicates if the ALU operation is SUBROT
    output logic              alu_is_subrot_ex_o,
    // ALU CLPX shift amount
    output logic        [1:0] alu_clpx_shift_ex_o,

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // Multiplier Control Signals
    ////////////////////////////////////////////////////////////////////////////////////////////////

    // Multiplier operation code
    output mul_opcode_e        mult_operator_ex_o,
    // Multiplier operand A
    output logic        [31:0] mult_operand_a_ex_o,
    // Multiplier operand B
    output logic        [31:0] mult_operand_b_ex_o,
    // Multiplier operand C
    output logic        [31:0] mult_operand_c_ex_o,
    // Multiplier enable signal
    output logic               mult_en_ex_o,
    // Multiplier subword selection
    output logic               mult_sel_subword_ex_o,
    // Multiplier signed mode
    output logic        [ 1:0] mult_signed_mode_ex_o,
    // Multiplier immediate value
    output logic        [ 4:0] mult_imm_ex_o,

    // Multiplier dot product operand A
    output logic [31:0] mult_dot_op_a_ex_o,
    // Multiplier dot product operand B
    output logic [31:0] mult_dot_op_b_ex_o,
    // Multiplier dot product operand C
    output logic [31:0] mult_dot_op_c_ex_o,
    // Multiplier dot signed mode
    output logic [ 1:0] mult_dot_signed_ex_o,
    // Indicates if the multiplier operation is CLPX
    output logic        mult_is_clpx_ex_o,
    // Multiplier CLPX shift amount
    output logic [ 1:0] mult_clpx_shift_ex_o,
    // Multiplier CLPX image flag
    output logic        mult_clpx_img_ex_o,

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // APU Control Signals
    ////////////////////////////////////////////////////////////////////////////////////////////////

    // APU enable signal
    output logic              apu_en_ex_o,
    // APU operation code
    output logic [ 5:0]       apu_op_ex_o,
    // APU latency
    output logic [ 1:0]       apu_lat_ex_o,
    // APU operands
    output logic [ 2:0][31:0] apu_operands_ex_o,
    // APU flags
    output logic [14:0]       apu_flags_ex_o,
    // APU write address
    output logic [ 5:0]       apu_waddr_ex_o,

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // APU Register Signals
    ////////////////////////////////////////////////////////////////////////////////////////////////

    // APU read registers
    output logic [2:0][5:0] apu_read_regs_o,
    // APU read registers valid
    output logic [2:0]      apu_read_regs_valid_o,
    // APU read dependency signal
    input  logic            apu_read_dep_i,
    // APU read dependency for JALR
    input  logic            apu_read_dep_for_jalr_i,
    // APU write registers
    output logic [1:0][5:0] apu_write_regs_o,
    // APU write registers valid
    output logic [1:0]      apu_write_regs_valid_o,
    // APU write dependency signal
    input  logic            apu_write_dep_i,
    // APU performance dependency signal
    output logic            apu_perf_dep_o,
    // APU busy signal
    input  logic            apu_busy_i,

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // Floating-Point Unit Signals
    ////////////////////////////////////////////////////////////////////////////////////////////////

    // Floating-point status off
    input logic            fs_off_i,
    // Floating-point rounding mode
    input logic [C_RM-1:0] frm_i,

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // CSR Signals
    ////////////////////////////////////////////////////////////////////////////////////////////////

    // CSR access enable
    output logic              csr_access_ex_o,
    // CSR operation code
    output csr_opcode_e       csr_op_ex_o,
    // Current privilege level
    input  priv_lvl_t         current_priv_lvl_i,
    // CSR IRQ secondary flag
    output logic              csr_irq_sec_o,
    // CSR cause
    output logic        [5:0] csr_cause_o,
    // CSR save IF flag
    output logic              csr_save_if_o,
    // CSR save ID flag
    output logic              csr_save_id_o,
    // CSR save EX flag
    output logic              csr_save_ex_o,
    // CSR restore MRET flag
    output logic              csr_restore_mret_id_o,
    // CSR restore URET flag
    output logic              csr_restore_uret_id_o,
    // CSR restore DRET flag
    output logic              csr_restore_dret_id_o,
    // CSR save cause flag
    output logic              csr_save_cause_o,

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // Hardware Loop Signals
    ////////////////////////////////////////////////////////////////////////////////////////////////

    // Hardware loop target address
    output logic [31:0] hwlp_target_o,

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // Data Memory Signals
    ////////////////////////////////////////////////////////////////////////////////////////////////

    // Data request signal
    output logic       data_req_ex_o,
    // Data write enable
    output logic       data_we_ex_o,
    // Data type
    output logic [1:0] data_type_ex_o,
    // Data sign extension
    output logic [1:0] data_sign_ext_ex_o,
    // Data register offset
    output logic [1:0] data_reg_offset_ex_o,

    // Data misaligned flag
    output logic data_misaligned_ex_o,

    // Pre/post increment usage
    output logic prepost_useincr_ex_o,
    // Data misaligned input
    input  logic data_misaligned_i,
    // Data error input
    input  logic data_err_i,
    // Data error acknowledgment
    output logic data_err_ack_o,

    // Atomic operation type
    output logic [5:0] atop_ex_o,

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // Interrupt Signals
    ////////////////////////////////////////////////////////////////////////////////////////////////

    // IRQ input
    input  logic [31:0] irq_i,
    // IRQ secondary input
    input  logic        irq_sec_i,
    // MIE bypass input
    input  logic [31:0] mie_bypass_i,
    // MIP output
    output logic [31:0] mip_o,
    // Machine IRQ enable
    input  logic        m_irq_enable_i,
    // User IRQ enable
    input  logic        u_irq_enable_i,
    // IRQ acknowledgment
    output logic        irq_ack_o,
    // IRQ ID
    output logic [ 4:0] irq_id_o,
    // Exception cause
    output logic [ 4:0] exc_cause_o,

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // Debug Signals
    ////////////////////////////////////////////////////////////////////////////////////////////////

    // Debug mode enable
    output logic       debug_mode_o,
    // Debug cause
    output logic [2:0] debug_cause_o,
    // Debug CSR save flag
    output logic       debug_csr_save_o,
    // Debug single-step enable
    input  logic       debug_single_step_i,
    // Debug EBREAK in machine mode
    input  logic       debug_ebreakm_i,
    // Debug EBREAK in user mode
    input  logic       debug_ebreaku_i,
    // Trigger match signal
    input  logic       trigger_match_i,
    // Debug ELW no sleep flag
    output logic       debug_p_elw_no_sleep_o,

    // Wake from sleep signal
    output logic wake_from_sleep_o,

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // Register File Writeback Signals
    ////////////////////////////////////////////////////////////////////////////////////////////////

    // Register file write address in WB stage
    input logic [5:0] regfile_waddr_wb_i,
    // Register file write enable in WB stage
    input logic regfile_we_wb_i,
    // Register file write enable power in WB stage
    input logic regfile_we_wb_power_i,
    // Register file write data in WB stage
    input logic [31:0] regfile_wdata_wb_i,

    // Register file ALU write address in FW stage
    input logic [ 5:0] regfile_alu_waddr_fw_i,
    // Register file ALU write enable in FW stage
    input logic        regfile_alu_we_fw_i,
    // Register file ALU write enable power in FW stage
    input logic        regfile_alu_we_fw_power_i,
    // Register file ALU write data in FW stage
    input logic [31:0] regfile_alu_wdata_fw_i,

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // Multiplier Signals
    ////////////////////////////////////////////////////////////////////////////////////////////////

    // Multiplier multicycle flag
    input logic mult_multicycle_i,

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // Performance Monitoring Signals
    ////////////////////////////////////////////////////////////////////////////////////////////////

    // Performance monitoring event: retired instructions
    output logic mhpmevent_minstret_o,
    // Performance monitoring event: load instructions
    output logic mhpmevent_load_o,
    // Performance monitoring event: store instructions
    output logic mhpmevent_store_o,
    // Performance monitoring event: jump instructions
    output logic mhpmevent_jump_o,
    // Performance monitoring event: branch instructions
    output logic mhpmevent_branch_o,
    // Performance monitoring event: branch taken
    output logic mhpmevent_branch_taken_o,
    // Performance monitoring event: compressed instructions
    output logic mhpmevent_compressed_o,
    // Performance monitoring event: jump register stall
    output logic mhpmevent_jr_stall_o,
    // Performance monitoring event: instruction cache miss
    output logic mhpmevent_imiss_o,
    // Performance monitoring event: load stall
    output logic mhpmevent_ld_stall_o,
    // Performance monitoring event: pipeline stall
    output logic mhpmevent_pipe_stall_o,

    // Performance monitoring input: instruction cache miss
    input logic        perf_imiss_i,
    // Machine counter enable
    input logic [31:0] mcounteren_i
);

  localparam int RegS1MSB = 19;
  localparam int RegS1LSB = 15;

  localparam int RegS2MSB = 24;
  localparam int RegS2LSB = 20;

  localparam int RegS4MSB = 31;
  localparam int RegS4LSB = 27;

  localparam int RegDMSB = 11;
  localparam int RegDLSB = 7;

  logic [31:0] instr;

  logic        deassert_we;

  logic        illegal_insn_dec;
  logic        ebrk_insn_dec;
  logic        mret_insn_dec;
  logic        uret_insn_dec;

  logic        dret_insn_dec;

  logic        ecall_insn_dec;
  logic        wfi_insn_dec;

  logic        fencei_insn_dec;

  logic        rega_used_dec;
  logic        regb_used_dec;
  logic        regc_used_dec;

  logic        branch_taken_ex;
  logic [ 1:0] ctrl_transfer_insn_in_id;
  logic [ 1:0] ctrl_transfer_insn_in_dec;

  logic        misaligned_stall;
  logic        jr_stall;
  logic        load_stall;
  logic        csr_apu_stall;
  logic        hwlp_mask;
  logic        halt_id;
  logic        halt_if;

  logic        debug_wfi_no_sleep;

  logic [31:0] imm_i_type;
  logic [31:0] imm_iz_type;
  logic [31:0] imm_s_type;
  logic [31:0] imm_sb_type;
  logic [31:0] imm_u_type;
  logic [31:0] imm_uj_type;
  logic [31:0] imm_z_type;
  logic [31:0] imm_s2_type;
  logic [31:0] imm_bi_type;
  logic [31:0] imm_s3_type;
  logic [31:0] imm_vs_type;
  logic [31:0] imm_vu_type;
  logic [31:0] imm_shuffleb_type;
  logic [31:0] imm_shuffleh_type;
  logic [31:0] imm_shuffle_type;
  logic [31:0] imm_clip_type;

  logic [31:0] imm_a;
  logic [31:0] imm_b;

  logic [31:0] jump_target;

  logic        irq_req_ctrl;
  logic        irq_sec_ctrl;
  logic        irq_wu_ctrl;
  logic [ 4:0] irq_id_ctrl;

  logic [ 5:0] regfile_addr_ra_id;
  logic [ 5:0] regfile_addr_rb_id;
  logic [ 5:0] regfile_addr_rc_id;

  logic        regfile_fp_a;
  logic        regfile_fp_b;
  logic        regfile_fp_c;
  logic        regfile_fp_d;

  logic [ 5:0] regfile_waddr_id;
  logic [ 5:0] regfile_alu_waddr_id;
  logic regfile_alu_we_id, regfile_alu_we_dec_id;

  logic        [                                31:0]       regfile_data_ra_id;
  logic        [                                31:0]       regfile_data_rb_id;
  logic        [                                31:0]       regfile_data_rc_id;

  logic                                                     alu_en;
  alu_opcode_e                                              alu_operator;
  logic        [                                 2:0]       alu_op_a_mux_sel;
  logic        [                                 2:0]       alu_op_b_mux_sel;
  logic        [                                 1:0]       alu_op_c_mux_sel;
  logic        [                                 1:0]       regc_mux;

  logic        [                                 0:0]       imm_a_mux_sel;
  logic        [                                 3:0]       imm_b_mux_sel;
  logic        [                                 1:0]       ctrl_transfer_target_mux_sel;

  mul_opcode_e                                              mult_operator;
  logic                                                     mult_en;
  logic                                                     mult_int_en;
  logic                                                     mult_sel_subword;
  logic        [                                 1:0]       mult_signed_mode;
  logic                                                     mult_dot_en;
  logic        [                                 1:0]       mult_dot_signed;

  logic        [ rv32imf_fpu_pkg::FP_FORMAT_BITS-1:0]       fpu_src_fmt;
  logic        [ rv32imf_fpu_pkg::FP_FORMAT_BITS-1:0]       fpu_dst_fmt;
  logic        [rv32imf_fpu_pkg::INT_FORMAT_BITS-1:0]       fpu_int_fmt;

  logic                                                     apu_en;
  logic        [                                 5:0]       apu_op;
  logic        [                                 1:0]       apu_lat;
  logic        [                                 2:0][31:0] apu_operands;
  logic        [                                14:0]       apu_flags;
  logic        [                                 5:0]       apu_waddr;

  logic        [                                 2:0][ 5:0] apu_read_regs;
  logic        [                                 2:0]       apu_read_regs_valid;
  logic        [                                 1:0][ 5:0] apu_write_regs;
  logic        [                                 1:0]       apu_write_regs_valid;

  logic                                                     apu_stall;
  logic        [                                 2:0]       fp_rnd_mode;

  logic                                                     regfile_we_id;
  logic                                                     regfile_alu_waddr_mux_sel;

  logic                                                     data_we_id;
  logic        [                                 1:0]       data_type_id;
  logic        [                                 1:0]       data_sign_ext_id;
  logic        [                                 1:0]       data_reg_offset_id;
  logic                                                     data_req_id;
  logic                                                     data_load_event_id;

  logic        [                                 5:0]       atop_id;

  logic        [                                 2:0]       hwlp_we;
  logic        [                                 1:0]       hwlp_target_mux_sel;
  logic        [                                 1:0]       hwlp_start_mux_sel;
  logic                                                     hwlp_cnt_mux_sel;

  logic        [                          N_HWLP-1:0]       hwlp_dec_cnt;

  logic                                                     csr_access;
  csr_opcode_e                                              csr_op;
  logic                                                     csr_status;

  logic                                                     prepost_useincr;

  logic        [                                 1:0]       operand_a_fw_mux_sel;
  logic        [                                 1:0]       operand_b_fw_mux_sel;
  logic        [                                 1:0]       operand_c_fw_mux_sel;
  logic        [                                31:0]       operand_a_fw_id;
  logic        [                                31:0]       operand_b_fw_id;
  logic        [                                31:0]       operand_c_fw_id;

  logic [31:0] operand_b, operand_b_vec;
  logic [31:0] operand_c, operand_c_vec;

  logic [31:0] alu_operand_a;
  logic [31:0] alu_operand_b;
  logic [31:0] alu_operand_c;

  logic [ 0:0] bmask_a_mux;
  logic [ 1:0] bmask_b_mux;
  logic        alu_bmask_a_mux_sel;
  logic        alu_bmask_b_mux_sel;
  logic [ 0:0] mult_imm_mux;

  logic [ 4:0] bmask_a_id_imm;
  logic [ 4:0] bmask_b_id_imm;
  logic [ 4:0] bmask_a_id;
  logic [ 4:0] bmask_b_id;
  logic [ 1:0] imm_vec_ext_id;
  logic [ 4:0] mult_imm_id;

  logic        alu_vec;
  logic [ 1:0] alu_vec_mode;
  logic        scalar_replication;
  logic        scalar_replication_c;

  logic        reg_d_ex_is_reg_a_id;
  logic        reg_d_ex_is_reg_b_id;
  logic        reg_d_ex_is_reg_c_id;
  logic        reg_d_wb_is_reg_a_id;
  logic        reg_d_wb_is_reg_b_id;
  logic        reg_d_wb_is_reg_c_id;
  logic        reg_d_alu_is_reg_a_id;
  logic        reg_d_alu_is_reg_b_id;
  logic        reg_d_alu_is_reg_c_id;

  logic is_clpx, is_subrot;

  logic mret_dec;
  logic uret_dec;
  logic dret_dec;

  logic id_valid_q;
  logic minstret;
  logic perf_pipeline_stall;

  assign instr = instr_rdata_i;

  assign imm_i_type = {{20{instr[31]}}, instr[31:20]};
  assign imm_iz_type = {20'b0, instr[31:20]};
  assign imm_s_type = {{20{instr[31]}}, instr[31:25], instr[11:7]};
  assign imm_sb_type = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
  assign imm_u_type = {instr[31:12], 12'b0};
  assign imm_uj_type = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};

  assign imm_z_type = {27'b0, instr[RegS1MSB:RegS1LSB]};

  assign imm_s2_type = {27'b0, instr[24:20]};
  assign imm_bi_type = {{27{instr[24]}}, instr[24:20]};
  assign imm_s3_type = {27'b0, instr[29:25]};
  assign imm_vs_type = {{26{instr[24]}}, instr[24:20], instr[25]};
  assign imm_vu_type = {26'b0, instr[24:20], instr[25]};

  assign imm_shuffleb_type = {
    6'b0, instr[28:27], 6'b0, instr[24:23], 6'b0, instr[22:21], 6'b0, instr[20], instr[25]
  };
  assign imm_shuffleh_type = {15'h0, instr[20], 15'h0, instr[25]};

  assign imm_clip_type = (32'h1 << instr[24:20]) - 1;

  assign regfile_addr_ra_id = {regfile_fp_a, instr[RegS1MSB:RegS1LSB]};
  assign regfile_addr_rb_id = {regfile_fp_b, instr[RegS2MSB:RegS2LSB]};

  always_comb begin
    unique case (regc_mux)
      REGC_ZERO: regfile_addr_rc_id = '0;
      REGC_RD:   regfile_addr_rc_id = {regfile_fp_c, instr[RegDMSB:RegDLSB]};
      REGC_S1:   regfile_addr_rc_id = {regfile_fp_c, instr[RegS1MSB:RegS1LSB]};
      REGC_S4:   regfile_addr_rc_id = {regfile_fp_c, instr[RegS4MSB:RegS4LSB]};
    endcase
  end

  assign regfile_waddr_id = {regfile_fp_d, instr[RegDMSB:RegDLSB]};

  assign regfile_alu_waddr_id = regfile_alu_waddr_mux_sel ? regfile_waddr_id : regfile_addr_ra_id;

  assign reg_d_ex_is_reg_a_id  = (regfile_waddr_ex_o     == regfile_addr_ra_id)
                                 && (rega_used_dec == 1'b1) && (regfile_addr_ra_id != '0);
  assign reg_d_ex_is_reg_b_id  = (regfile_waddr_ex_o     == regfile_addr_rb_id)
                                 && (regb_used_dec == 1'b1) && (regfile_addr_rb_id != '0);
  assign reg_d_ex_is_reg_c_id  = (regfile_waddr_ex_o     == regfile_addr_rc_id)
                                 && (regc_used_dec == 1'b1) && (regfile_addr_rc_id != '0);
  assign reg_d_wb_is_reg_a_id  = (regfile_waddr_wb_i     == regfile_addr_ra_id)
                                 && (rega_used_dec == 1'b1) && (regfile_addr_ra_id != '0);
  assign reg_d_wb_is_reg_b_id  = (regfile_waddr_wb_i     == regfile_addr_rb_id)
                                 && (regb_used_dec == 1'b1) && (regfile_addr_rb_id != '0);
  assign reg_d_wb_is_reg_c_id  = (regfile_waddr_wb_i     == regfile_addr_rc_id)
                                 && (regc_used_dec == 1'b1) && (regfile_addr_rc_id != '0);
  assign reg_d_alu_is_reg_a_id = (regfile_alu_waddr_fw_i == regfile_addr_ra_id)
                                 && (rega_used_dec == 1'b1) && (regfile_addr_ra_id != '0);
  assign reg_d_alu_is_reg_b_id = (regfile_alu_waddr_fw_i == regfile_addr_rb_id)
                                 && (regb_used_dec == 1'b1) && (regfile_addr_rb_id != '0);
  assign reg_d_alu_is_reg_c_id = (regfile_alu_waddr_fw_i == regfile_addr_rc_id)
                                 && (regc_used_dec == 1'b1) && (regfile_addr_rc_id != '0);

  assign clear_instr_valid_o = id_ready_o | halt_id | branch_taken_ex;

  assign branch_taken_ex = branch_in_ex_o && branch_decision_i;

  assign mult_en = mult_int_en | mult_dot_en;

  always_comb begin : jump_target_mux
    unique case (ctrl_transfer_target_mux_sel)
      JT_JAL:  jump_target = pc_id_i + imm_uj_type;
      JT_COND: jump_target = pc_id_i + imm_sb_type;

      JT_JALR: jump_target = regfile_data_ra_id + imm_i_type;
      default: jump_target = regfile_data_ra_id + imm_i_type;
    endcase
  end

  assign jump_target_o = jump_target;

  always_comb begin : alu_operand_a_mux
    case (alu_op_a_mux_sel)
      OP_A_REGA_OR_FWD: alu_operand_a = operand_a_fw_id;
      OP_A_REGB_OR_FWD: alu_operand_a = operand_b_fw_id;
      OP_A_REGC_OR_FWD: alu_operand_a = operand_c_fw_id;
      OP_A_CURRPC:      alu_operand_a = pc_id_i;
      OP_A_IMM:         alu_operand_a = imm_a;
      default:          alu_operand_a = operand_a_fw_id;
    endcase
    ;
  end

  always_comb begin : immediate_a_mux
    unique case (imm_a_mux_sel)
      IMMA_Z:    imm_a = imm_z_type;
      IMMA_ZERO: imm_a = '0;
    endcase
  end

  always_comb begin : operand_a_fw_mux
    case (operand_a_fw_mux_sel)
      SEL_FW_EX:   operand_a_fw_id = regfile_alu_wdata_fw_i;
      SEL_FW_WB:   operand_a_fw_id = regfile_wdata_wb_i;
      SEL_REGFILE: operand_a_fw_id = regfile_data_ra_id;
      default:     operand_a_fw_id = regfile_data_ra_id;
    endcase
    ;
  end

  always_comb begin : immediate_b_mux
    unique case (imm_b_mux_sel)
      IMMB_I:      imm_b = imm_i_type;
      IMMB_S:      imm_b = imm_s_type;
      IMMB_U:      imm_b = imm_u_type;
      IMMB_PCINCR: imm_b = is_compressed_i ? 32'h2 : 32'h4;
      IMMB_S2:     imm_b = imm_s2_type;
      IMMB_BI:     imm_b = imm_bi_type;
      IMMB_S3:     imm_b = imm_s3_type;
      IMMB_VS:     imm_b = imm_vs_type;
      IMMB_VU:     imm_b = imm_vu_type;
      IMMB_SHUF:   imm_b = imm_shuffle_type;
      IMMB_CLIP:   imm_b = {1'b0, imm_clip_type[31:1]};
      default:     imm_b = imm_i_type;
    endcase
  end

  always_comb begin : alu_operand_b_mux
    case (alu_op_b_mux_sel)
      OP_B_REGA_OR_FWD: operand_b = operand_a_fw_id;
      OP_B_REGB_OR_FWD: operand_b = operand_b_fw_id;
      OP_B_REGC_OR_FWD: operand_b = operand_c_fw_id;
      OP_B_IMM:         operand_b = imm_b;
      OP_B_BMASK:       operand_b = $unsigned(operand_b_fw_id[4:0]);
      default:          operand_b = operand_b_fw_id;
    endcase
  end

  always_comb begin
    if (alu_vec_mode == VEC_MODE8) begin
      operand_b_vec    = {4{operand_b[7:0]}};
      imm_shuffle_type = imm_shuffleb_type;
    end else begin
      operand_b_vec    = {2{operand_b[15:0]}};
      imm_shuffle_type = imm_shuffleh_type;
    end
  end

  assign alu_operand_b = (scalar_replication == 1'b1) ? operand_b_vec : operand_b;

  always_comb begin : operand_b_fw_mux
    case (operand_b_fw_mux_sel)
      SEL_FW_EX:   operand_b_fw_id = regfile_alu_wdata_fw_i;
      SEL_FW_WB:   operand_b_fw_id = regfile_wdata_wb_i;
      SEL_REGFILE: operand_b_fw_id = regfile_data_rb_id;
      default:     operand_b_fw_id = regfile_data_rb_id;
    endcase
    ;
  end

  always_comb begin : alu_operand_c_mux
    case (alu_op_c_mux_sel)
      OP_C_REGC_OR_FWD: operand_c = operand_c_fw_id;
      OP_C_REGB_OR_FWD: operand_c = operand_b_fw_id;
      OP_C_JT:          operand_c = jump_target;
      default:          operand_c = operand_c_fw_id;
    endcase
  end

  always_comb begin
    if (alu_vec_mode == VEC_MODE8) begin
      operand_c_vec = {4{operand_c[7:0]}};
    end else begin
      operand_c_vec = {2{operand_c[15:0]}};
    end
  end

  assign alu_operand_c = (scalar_replication_c == 1'b1) ? operand_c_vec : operand_c;

  always_comb begin : operand_c_fw_mux
    case (operand_c_fw_mux_sel)
      SEL_FW_EX:   operand_c_fw_id = regfile_alu_wdata_fw_i;
      SEL_FW_WB:   operand_c_fw_id = regfile_wdata_wb_i;
      SEL_REGFILE: operand_c_fw_id = regfile_data_rc_id;
      default:     operand_c_fw_id = regfile_data_rc_id;
    endcase
    ;
  end

  always_comb begin
    unique case (bmask_a_mux)
      BMASK_A_ZERO: bmask_a_id_imm = '0;
      BMASK_A_S3:   bmask_a_id_imm = imm_s3_type[4:0];
    endcase
  end
  always_comb begin
    unique case (bmask_b_mux)
      BMASK_B_ZERO: bmask_b_id_imm = '0;
      BMASK_B_ONE:  bmask_b_id_imm = 5'd1;
      BMASK_B_S2:   bmask_b_id_imm = imm_s2_type[4:0];
      BMASK_B_S3:   bmask_b_id_imm = imm_s3_type[4:0];
    endcase
  end

  always_comb begin
    unique case (alu_bmask_a_mux_sel)
      BMASK_A_IMM: bmask_a_id = bmask_a_id_imm;
      BMASK_A_REG: bmask_a_id = operand_b_fw_id[9:5];
    endcase
  end
  always_comb begin
    unique case (alu_bmask_b_mux_sel)
      BMASK_B_IMM: bmask_b_id = bmask_b_id_imm;
      BMASK_B_REG: bmask_b_id = operand_b_fw_id[4:0];
    endcase
  end

  assign imm_vec_ext_id = imm_vu_type[1:0];

  always_comb begin
    unique case (mult_imm_mux)
      MIMM_ZERO: mult_imm_id = '0;
      MIMM_S3:   mult_imm_id = imm_s3_type[4:0];
    endcase
  end

  assign apu_operands[0] = alu_operand_a;
  assign apu_operands[1] = alu_operand_b;
  assign apu_operands[2] = alu_operand_c;

  assign apu_waddr = regfile_alu_waddr_id;

  assign apu_flags = {fpu_int_fmt, fpu_src_fmt, fpu_dst_fmt, fp_rnd_mode};

  always_comb begin
    unique case (alu_op_a_mux_sel)
      OP_A_CURRPC: begin
        if (ctrl_transfer_target_mux_sel == JT_JALR) begin
          apu_read_regs[0]       = regfile_addr_ra_id;
          apu_read_regs_valid[0] = 1'b1;
        end else begin
          apu_read_regs[0]       = regfile_addr_ra_id;
          apu_read_regs_valid[0] = 1'b0;
        end
      end
      OP_A_REGA_OR_FWD: begin
        apu_read_regs[0]       = regfile_addr_ra_id;
        apu_read_regs_valid[0] = 1'b1;
      end
      OP_A_REGB_OR_FWD, OP_A_REGC_OR_FWD: begin
        apu_read_regs[0]       = regfile_addr_rb_id;
        apu_read_regs_valid[0] = 1'b1;
      end
      default: begin
        apu_read_regs[0]       = regfile_addr_ra_id;
        apu_read_regs_valid[0] = 1'b0;
      end
    endcase
  end

  always_comb begin
    unique case (alu_op_b_mux_sel)
      OP_B_REGA_OR_FWD: begin
        apu_read_regs[1]       = regfile_addr_ra_id;
        apu_read_regs_valid[1] = 1'b1;
      end
      OP_B_REGB_OR_FWD, OP_B_BMASK: begin
        apu_read_regs[1]       = regfile_addr_rb_id;
        apu_read_regs_valid[1] = 1'b1;
      end
      OP_B_REGC_OR_FWD: begin
        apu_read_regs[1]       = regfile_addr_rc_id;
        apu_read_regs_valid[1] = 1'b1;
      end
      OP_B_IMM: begin
        if (alu_bmask_b_mux_sel == BMASK_B_REG) begin
          apu_read_regs[1]       = regfile_addr_rb_id;
          apu_read_regs_valid[1] = 1'b1;
        end else begin
          apu_read_regs[1]       = regfile_addr_rb_id;
          apu_read_regs_valid[1] = 1'b0;
        end
      end
      default: begin
        apu_read_regs[1]       = regfile_addr_rb_id;
        apu_read_regs_valid[1] = 1'b0;
      end
    endcase
  end

  always_comb begin
    unique case (alu_op_c_mux_sel)
      OP_C_REGB_OR_FWD: begin
        apu_read_regs[2]       = regfile_addr_rb_id;
        apu_read_regs_valid[2] = 1'b1;
      end
      OP_C_REGC_OR_FWD: begin
        if ((alu_op_a_mux_sel != OP_A_REGC_OR_FWD) && (ctrl_transfer_target_mux_sel != JT_JALR) &&
                !((alu_op_b_mux_sel == OP_B_IMM) && (alu_bmask_b_mux_sel == BMASK_B_REG)) &&
                !(alu_op_b_mux_sel == OP_B_BMASK)) begin
          apu_read_regs[2]       = regfile_addr_rc_id;
          apu_read_regs_valid[2] = 1'b1;
        end else begin
          apu_read_regs[2]       = regfile_addr_rc_id;
          apu_read_regs_valid[2] = 1'b0;
        end
      end
      default: begin
        apu_read_regs[2]       = regfile_addr_rc_id;
        apu_read_regs_valid[2] = 1'b0;
      end
    endcase
  end

  assign apu_write_regs[0] = regfile_alu_waddr_id;
  assign apu_write_regs_valid[0] = regfile_alu_we_id;

  assign apu_write_regs[1] = regfile_waddr_id;
  assign apu_write_regs_valid[1] = regfile_we_id;

  assign apu_read_regs_o = apu_read_regs;
  assign apu_read_regs_valid_o = apu_read_regs_valid;

  assign apu_write_regs_o = apu_write_regs;
  assign apu_write_regs_valid_o = apu_write_regs_valid;

  assign apu_perf_dep_o = apu_stall;

  assign csr_apu_stall = (csr_access & (apu_en_ex_o & (apu_lat_ex_o[1] == 1'b1) | apu_busy_i));

  rv32imf_register_file #(
      .ADDR_WIDTH(6),
      .DATA_WIDTH(32)
  ) register_file_i (
      .clk  (clk),
      .rst_n(rst_n),

      .raddr_a_i(regfile_addr_ra_id),
      .rdata_a_o(regfile_data_ra_id),

      .raddr_b_i(regfile_addr_rb_id),
      .rdata_b_o(regfile_data_rb_id),

      .raddr_c_i(regfile_addr_rc_id),
      .rdata_c_o(regfile_data_rc_id),

      .waddr_a_i(regfile_waddr_wb_i),
      .wdata_a_i(regfile_wdata_wb_i),
      .we_a_i   (regfile_we_wb_power_i),

      .waddr_b_i(regfile_alu_waddr_fw_i),
      .wdata_b_i(regfile_alu_wdata_fw_i),
      .we_b_i   (regfile_alu_we_fw_power_i)
  );

  rv32imf_decoder #() decoder_i (

      .deassert_we_i(deassert_we),

      .illegal_insn_o(illegal_insn_dec),
      .ebrk_insn_o   (ebrk_insn_dec),

      .mret_insn_o(mret_insn_dec),
      .uret_insn_o(uret_insn_dec),
      .dret_insn_o(dret_insn_dec),

      .mret_dec_o(mret_dec),
      .uret_dec_o(uret_dec),
      .dret_dec_o(dret_dec),

      .ecall_insn_o(ecall_insn_dec),
      .wfi_o       (wfi_insn_dec),

      .fencei_insn_o(fencei_insn_dec),

      .rega_used_o(rega_used_dec),
      .regb_used_o(regb_used_dec),
      .regc_used_o(regc_used_dec),

      .reg_fp_a_o(regfile_fp_a),
      .reg_fp_b_o(regfile_fp_b),
      .reg_fp_c_o(regfile_fp_c),
      .reg_fp_d_o(regfile_fp_d),

      .bmask_a_mux_o        (bmask_a_mux),
      .bmask_b_mux_o        (bmask_b_mux),
      .alu_bmask_a_mux_sel_o(alu_bmask_a_mux_sel),
      .alu_bmask_b_mux_sel_o(alu_bmask_b_mux_sel),

      .instr_rdata_i   (instr),
      .illegal_c_insn_i(illegal_c_insn_i),

      .alu_en_o              (alu_en),
      .alu_operator_o        (alu_operator),
      .alu_op_a_mux_sel_o    (alu_op_a_mux_sel),
      .alu_op_b_mux_sel_o    (alu_op_b_mux_sel),
      .alu_op_c_mux_sel_o    (alu_op_c_mux_sel),
      .alu_vec_o             (alu_vec),
      .alu_vec_mode_o        (alu_vec_mode),
      .scalar_replication_o  (scalar_replication),
      .scalar_replication_c_o(scalar_replication_c),
      .imm_a_mux_sel_o       (imm_a_mux_sel),
      .imm_b_mux_sel_o       (imm_b_mux_sel),
      .regc_mux_o            (regc_mux),
      .is_clpx_o             (is_clpx),
      .is_subrot_o           (is_subrot),

      .mult_operator_o   (mult_operator),
      .mult_int_en_o     (mult_int_en),
      .mult_sel_subword_o(mult_sel_subword),
      .mult_signed_mode_o(mult_signed_mode),
      .mult_imm_mux_o    (mult_imm_mux),
      .mult_dot_en_o     (mult_dot_en),
      .mult_dot_signed_o (mult_dot_signed),

      .fs_off_i     (fs_off_i),
      .frm_i        (frm_i),
      .fpu_src_fmt_o(fpu_src_fmt),
      .fpu_dst_fmt_o(fpu_dst_fmt),
      .fpu_int_fmt_o(fpu_int_fmt),
      .apu_en_o     (apu_en),
      .apu_op_o     (apu_op),
      .apu_lat_o    (apu_lat),
      .fp_rnd_mode_o(fp_rnd_mode),

      .regfile_mem_we_o       (regfile_we_id),
      .regfile_alu_we_o       (regfile_alu_we_id),
      .regfile_alu_we_dec_o   (regfile_alu_we_dec_id),
      .regfile_alu_waddr_sel_o(regfile_alu_waddr_mux_sel),

      .csr_access_o      (csr_access),
      .csr_status_o      (csr_status),
      .csr_op_o          (csr_op),
      .current_priv_lvl_i(current_priv_lvl_i),

      .data_req_o           (data_req_id),
      .data_we_o            (data_we_id),
      .prepost_useincr_o    (prepost_useincr),
      .data_type_o          (data_type_id),
      .data_sign_extension_o(data_sign_ext_id),
      .data_reg_offset_o    (data_reg_offset_id),
      .data_load_event_o    (data_load_event_id),

      .atop_o(atop_id),

      .hwlp_we_o            (hwlp_we),
      .hwlp_target_mux_sel_o(hwlp_target_mux_sel),
      .hwlp_start_mux_sel_o (hwlp_start_mux_sel),
      .hwlp_cnt_mux_sel_o   (hwlp_cnt_mux_sel),

      .debug_mode_i        (debug_mode_o),
      .debug_wfi_no_sleep_i(debug_wfi_no_sleep),

      .ctrl_transfer_insn_in_dec_o   (ctrl_transfer_insn_in_dec_o),
      .ctrl_transfer_insn_in_id_o    (ctrl_transfer_insn_in_id),
      .ctrl_transfer_target_mux_sel_o(ctrl_transfer_target_mux_sel),

      .mcounteren_i(mcounteren_i)

  );

  rv32imf_controller #() controller_i (
      .clk          (clk),
      .clk_ungated_i(clk_ungated_i),
      .rst_n        (rst_n),

      .ctrl_busy_o      (ctrl_busy_o),
      .is_decoding_o    (is_decoding_o),
      .is_fetch_failed_i(is_fetch_failed_i),

      .deassert_we_o(deassert_we),

      .illegal_insn_i(illegal_insn_dec),
      .ecall_insn_i  (ecall_insn_dec),
      .mret_insn_i   (mret_insn_dec),
      .uret_insn_i   (uret_insn_dec),

      .dret_insn_i(dret_insn_dec),

      .mret_dec_i(mret_dec),
      .uret_dec_i(uret_dec),
      .dret_dec_i(dret_dec),

      .wfi_i        (wfi_insn_dec),
      .ebrk_insn_i  (ebrk_insn_dec),
      .fencei_insn_i(fencei_insn_dec),
      .csr_status_i (csr_status),

      .hwlp_mask_o(hwlp_mask),

      .instr_valid_i(instr_valid_i),

      .instr_req_o(instr_req_o),

      .pc_set_o       (pc_set_o),
      .pc_mux_o       (pc_mux_o),
      .exc_pc_mux_o   (exc_pc_mux_o),
      .exc_cause_o    (exc_cause_o),
      .trap_addr_mux_o(trap_addr_mux_o),

      .pc_id_i(pc_id_i),

      .hwlp_targ_addr_o(hwlp_target_o),

      .data_req_ex_i    (data_req_ex_o),
      .data_we_ex_i     (data_we_ex_o),
      .data_misaligned_i(data_misaligned_i),
      .data_load_event_i(data_load_event_id),
      .data_err_i       (data_err_i),
      .data_err_ack_o   (data_err_ack_o),

      .mult_multicycle_i(mult_multicycle_i),

      .apu_en_i               (apu_en),
      .apu_read_dep_i         (apu_read_dep_i),
      .apu_read_dep_for_jalr_i(apu_read_dep_for_jalr_i),
      .apu_write_dep_i        (apu_write_dep_i),

      .apu_stall_o(apu_stall),

      .branch_taken_ex_i          (branch_taken_ex),
      .ctrl_transfer_insn_in_id_i (ctrl_transfer_insn_in_id),
      .ctrl_transfer_insn_in_dec_i(ctrl_transfer_insn_in_dec_o),

      .irq_wu_ctrl_i     (irq_wu_ctrl),
      .irq_req_ctrl_i    (irq_req_ctrl),
      .irq_sec_ctrl_i    (irq_sec_ctrl),
      .irq_id_ctrl_i     (irq_id_ctrl),
      .current_priv_lvl_i(current_priv_lvl_i),
      .irq_ack_o         (irq_ack_o),
      .irq_id_o          (irq_id_o),

      .debug_mode_o          (debug_mode_o),
      .debug_cause_o         (debug_cause_o),
      .debug_csr_save_o      (debug_csr_save_o),
      .debug_single_step_i   (debug_single_step_i),
      .debug_ebreakm_i       (debug_ebreakm_i),
      .debug_ebreaku_i       (debug_ebreaku_i),
      .trigger_match_i       (trigger_match_i),
      .debug_p_elw_no_sleep_o(debug_p_elw_no_sleep_o),
      .debug_wfi_no_sleep_o  (debug_wfi_no_sleep),

      .wake_from_sleep_o(wake_from_sleep_o),

      .csr_save_cause_o     (csr_save_cause_o),
      .csr_cause_o          (csr_cause_o),
      .csr_save_if_o        (csr_save_if_o),
      .csr_save_id_o        (csr_save_id_o),
      .csr_save_ex_o        (csr_save_ex_o),
      .csr_restore_mret_id_o(csr_restore_mret_id_o),
      .csr_restore_uret_id_o(csr_restore_uret_id_o),

      .csr_restore_dret_id_o(csr_restore_dret_id_o),

      .csr_irq_sec_o(csr_irq_sec_o),

      .regfile_we_id_i       (regfile_alu_we_dec_id),
      .regfile_alu_waddr_id_i(regfile_alu_waddr_id),

      .regfile_we_ex_i   (regfile_we_ex_o),
      .regfile_waddr_ex_i(regfile_waddr_ex_o),
      .regfile_we_wb_i   (regfile_we_wb_i),

      .regfile_alu_we_fw_i(regfile_alu_we_fw_i),

      .reg_d_ex_is_reg_a_i (reg_d_ex_is_reg_a_id),
      .reg_d_ex_is_reg_b_i (reg_d_ex_is_reg_b_id),
      .reg_d_ex_is_reg_c_i (reg_d_ex_is_reg_c_id),
      .reg_d_wb_is_reg_a_i (reg_d_wb_is_reg_a_id),
      .reg_d_wb_is_reg_b_i (reg_d_wb_is_reg_b_id),
      .reg_d_wb_is_reg_c_i (reg_d_wb_is_reg_c_id),
      .reg_d_alu_is_reg_a_i(reg_d_alu_is_reg_a_id),
      .reg_d_alu_is_reg_b_i(reg_d_alu_is_reg_b_id),
      .reg_d_alu_is_reg_c_i(reg_d_alu_is_reg_c_id),

      .operand_a_fw_mux_sel_o(operand_a_fw_mux_sel),
      .operand_b_fw_mux_sel_o(operand_b_fw_mux_sel),
      .operand_c_fw_mux_sel_o(operand_c_fw_mux_sel),

      .halt_if_o(halt_if),
      .halt_id_o(halt_id),

      .misaligned_stall_o(misaligned_stall),
      .jr_stall_o        (jr_stall),
      .load_stall_o      (load_stall),

      .id_ready_i(id_ready_o),
      .id_valid_i(id_valid_o),

      .ex_valid_i(ex_valid_i),

      .wb_ready_i(wb_ready_i),

      .perf_pipeline_stall_o(perf_pipeline_stall)
  );

  rv32imf_int_controller #() int_controller_i (
      .clk  (clk),
      .rst_n(rst_n),

      .irq_i    (irq_i),
      .irq_sec_i(irq_sec_i),

      .irq_req_ctrl_o(irq_req_ctrl),
      .irq_sec_ctrl_o(irq_sec_ctrl),
      .irq_id_ctrl_o (irq_id_ctrl),
      .irq_wu_ctrl_o (irq_wu_ctrl),

      .mie_bypass_i      (mie_bypass_i),
      .mip_o             (mip_o),
      .m_ie_i            (m_irq_enable_i),
      .u_ie_i            (u_irq_enable_i),
      .current_priv_lvl_i(current_priv_lvl_i)
  );

  always_ff @(posedge clk, negedge rst_n) begin : ID_EX_PIPE_REGISTERS
    if (rst_n == 1'b0) begin
      alu_en_ex_o            <= '0;
      alu_operator_ex_o      <= ALU_SLTU;
      alu_operand_a_ex_o     <= '0;
      alu_operand_b_ex_o     <= '0;
      alu_operand_c_ex_o     <= '0;
      bmask_a_ex_o           <= '0;
      bmask_b_ex_o           <= '0;
      imm_vec_ext_ex_o       <= '0;
      alu_vec_mode_ex_o      <= '0;
      alu_clpx_shift_ex_o    <= 2'b0;
      alu_is_clpx_ex_o       <= 1'b0;
      alu_is_subrot_ex_o     <= 1'b0;

      mult_operator_ex_o     <= MUL_MAC32;
      mult_operand_a_ex_o    <= '0;
      mult_operand_b_ex_o    <= '0;
      mult_operand_c_ex_o    <= '0;
      mult_en_ex_o           <= 1'b0;
      mult_sel_subword_ex_o  <= 1'b0;
      mult_signed_mode_ex_o  <= 2'b00;
      mult_imm_ex_o          <= '0;

      mult_dot_op_a_ex_o     <= '0;
      mult_dot_op_b_ex_o     <= '0;
      mult_dot_op_c_ex_o     <= '0;
      mult_dot_signed_ex_o   <= '0;
      mult_is_clpx_ex_o      <= 1'b0;
      mult_clpx_shift_ex_o   <= 2'b0;
      mult_clpx_img_ex_o     <= 1'b0;

      apu_en_ex_o            <= '0;
      apu_op_ex_o            <= '0;
      apu_lat_ex_o           <= '0;
      apu_operands_ex_o[0]   <= '0;
      apu_operands_ex_o[1]   <= '0;
      apu_operands_ex_o[2]   <= '0;
      apu_flags_ex_o         <= '0;
      apu_waddr_ex_o         <= '0;

      regfile_waddr_ex_o     <= 6'b0;
      regfile_we_ex_o        <= 1'b0;

      regfile_alu_waddr_ex_o <= 6'b0;
      regfile_alu_we_ex_o    <= 1'b0;
      prepost_useincr_ex_o   <= 1'b0;

      csr_access_ex_o        <= 1'b0;
      csr_op_ex_o            <= CSR_OP_READ;

      data_we_ex_o           <= 1'b0;
      data_type_ex_o         <= 2'b0;
      data_sign_ext_ex_o     <= 2'b0;
      data_reg_offset_ex_o   <= 2'b0;
      data_req_ex_o          <= 1'b0;
      atop_ex_o              <= 5'b0;

      data_misaligned_ex_o   <= 1'b0;

      pc_ex_o                <= '0;

      branch_in_ex_o         <= 1'b0;

    end else if (data_misaligned_i) begin

      if (ex_ready_i) begin

        if (prepost_useincr_ex_o == 1'b1) begin
          alu_operand_a_ex_o <= operand_a_fw_id;
        end

        alu_operand_b_ex_o   <= 32'h4;
        regfile_alu_we_ex_o  <= 1'b0;
        prepost_useincr_ex_o <= 1'b1;

        data_misaligned_ex_o <= 1'b1;
      end
    end else if (mult_multicycle_i) begin
      mult_operand_c_ex_o <= operand_c_fw_id;
    end else begin

      if (id_valid_o) begin
        alu_en_ex_o <= alu_en;
        if (alu_en) begin
          alu_operator_ex_o  <= alu_operator;
          alu_operand_a_ex_o <= alu_operand_a;
          if (alu_op_b_mux_sel == OP_B_REGB_OR_FWD
            && (alu_operator == ALU_CLIP || alu_operator == ALU_CLIPU)) begin
            alu_operand_b_ex_o <= {1'b0, alu_operand_b[30:0]};
          end else begin
            alu_operand_b_ex_o <= alu_operand_b;
          end
          alu_operand_c_ex_o  <= alu_operand_c;
          bmask_a_ex_o        <= bmask_a_id;
          bmask_b_ex_o        <= bmask_b_id;
          imm_vec_ext_ex_o    <= imm_vec_ext_id;
          alu_vec_mode_ex_o   <= alu_vec_mode;
          alu_is_clpx_ex_o    <= is_clpx;
          alu_clpx_shift_ex_o <= instr[14:13];
          alu_is_subrot_ex_o  <= is_subrot;
        end

        mult_en_ex_o <= mult_en;
        if (mult_int_en) begin
          mult_operator_ex_o    <= mult_operator;
          mult_sel_subword_ex_o <= mult_sel_subword;
          mult_signed_mode_ex_o <= mult_signed_mode;
          mult_operand_a_ex_o   <= alu_operand_a;
          mult_operand_b_ex_o   <= alu_operand_b;
          mult_operand_c_ex_o   <= alu_operand_c;
          mult_imm_ex_o         <= mult_imm_id;
        end
        if (mult_dot_en) begin
          mult_operator_ex_o   <= mult_operator;
          mult_dot_signed_ex_o <= mult_dot_signed;
          mult_dot_op_a_ex_o   <= alu_operand_a;
          mult_dot_op_b_ex_o   <= alu_operand_b;
          mult_dot_op_c_ex_o   <= alu_operand_c;
          mult_is_clpx_ex_o    <= is_clpx;
          mult_clpx_shift_ex_o <= instr[14:13];
          mult_clpx_img_ex_o   <= instr[25];
        end

        apu_en_ex_o <= apu_en;
        if (apu_en) begin
          apu_op_ex_o       <= apu_op;
          apu_lat_ex_o      <= apu_lat;
          apu_operands_ex_o <= apu_operands;
          apu_flags_ex_o    <= apu_flags;
          apu_waddr_ex_o    <= apu_waddr;
        end

        regfile_we_ex_o <= regfile_we_id;
        if (regfile_we_id) begin
          regfile_waddr_ex_o <= regfile_waddr_id;
        end

        regfile_alu_we_ex_o <= regfile_alu_we_id;
        if (regfile_alu_we_id) begin
          regfile_alu_waddr_ex_o <= regfile_alu_waddr_id;
        end

        prepost_useincr_ex_o <= prepost_useincr;

        csr_access_ex_o      <= csr_access;
        csr_op_ex_o          <= csr_op;

        data_req_ex_o        <= data_req_id;
        if (data_req_id) begin
          data_we_ex_o         <= data_we_id;
          data_type_ex_o       <= data_type_id;
          data_sign_ext_ex_o   <= data_sign_ext_id;
          data_reg_offset_ex_o <= data_reg_offset_id;
          atop_ex_o            <= atop_id;
        end else begin
        end

        data_misaligned_ex_o <= 1'b0;

        if ((ctrl_transfer_insn_in_id == BRANCH_COND) || data_req_id) begin
          pc_ex_o <= pc_id_i;
        end

        branch_in_ex_o <= ctrl_transfer_insn_in_id == BRANCH_COND;
      end else if (ex_ready_i) begin

        regfile_we_ex_o      <= 1'b0;

        regfile_alu_we_ex_o  <= 1'b0;

        csr_op_ex_o          <= CSR_OP_READ;

        data_req_ex_o        <= 1'b0;

        data_misaligned_ex_o <= 1'b0;

        branch_in_ex_o       <= 1'b0;

        apu_en_ex_o          <= 1'b0;

        alu_operator_ex_o    <= ALU_SLTU;

        mult_en_ex_o         <= 1'b0;

        alu_en_ex_o          <= 1'b1;

      end else if (csr_access_ex_o) begin

        regfile_alu_we_ex_o <= 1'b0;
      end
    end
  end

  assign minstret = id_valid_o && is_decoding_o &&
                  !(illegal_insn_dec || ebrk_insn_dec || ecall_insn_dec);

  always_ff @(posedge clk, negedge rst_n) begin
    if (rst_n == 1'b0) begin
      id_valid_q               <= 1'b0;
      mhpmevent_minstret_o     <= 1'b0;
      mhpmevent_load_o         <= 1'b0;
      mhpmevent_store_o        <= 1'b0;
      mhpmevent_jump_o         <= 1'b0;
      mhpmevent_branch_o       <= 1'b0;
      mhpmevent_compressed_o   <= 1'b0;
      mhpmevent_branch_taken_o <= 1'b0;
      mhpmevent_jr_stall_o     <= 1'b0;
      mhpmevent_imiss_o        <= 1'b0;
      mhpmevent_ld_stall_o     <= 1'b0;
      mhpmevent_pipe_stall_o   <= 1'b0;
    end else begin

      id_valid_q <= id_valid_o;

      mhpmevent_minstret_o <= minstret;
      mhpmevent_load_o <= minstret && data_req_id && !data_we_id;
      mhpmevent_store_o <= minstret && data_req_id && data_we_id;
      mhpmevent_jump_o <= minstret && ((ctrl_transfer_insn_in_id == BRANCH_JAL)
                      || (ctrl_transfer_insn_in_id == BRANCH_JALR));
      mhpmevent_branch_o <= minstret && (ctrl_transfer_insn_in_id == BRANCH_COND);
      mhpmevent_compressed_o <= minstret && is_compressed_i;

      mhpmevent_branch_taken_o <= mhpmevent_branch_o && branch_decision_i;

      mhpmevent_imiss_o <= perf_imiss_i;

      mhpmevent_jr_stall_o <= jr_stall && !halt_id && id_valid_q;

      mhpmevent_ld_stall_o <= load_stall && !halt_id && id_valid_q;

      mhpmevent_pipe_stall_o <= perf_pipeline_stall;
    end
  end

  assign id_ready_o = ((~misaligned_stall) & (~jr_stall) & (~load_stall) & (~apu_stall)
                     & (~csr_apu_stall) & ex_ready_i);
  assign id_valid_o = (~halt_id) & id_ready_o;
  assign halt_if_o = halt_if;

endmodule
