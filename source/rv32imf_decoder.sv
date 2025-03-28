module rv32imf_decoder
  import rv32imf_pkg::*;
  import rv32imf_fpu_pkg::*;
#(
    parameter int DEBUG_TRIGGER_EN = 1  // Enable debug trigger functionality
) (

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // Inputs
    ////////////////////////////////////////////////////////////////////////////////////////////////

    // Deassert write enable signal
    input logic deassert_we_i,

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // Outputs
    ////////////////////////////////////////////////////////////////////////////////////////////////

    // Indicates illegal instruction
    output logic illegal_insn_o,
    // Indicates EBREAK instruction
    output logic ebrk_insn_o,

    // Indicates MRET instruction
    output logic mret_insn_o,
    // Indicates URET instruction
    output logic uret_insn_o,
    // Indicates DRET instruction
    output logic dret_insn_o,

    // MRET decode signal
    output logic mret_dec_o,
    // URET decode signal
    output logic uret_dec_o,
    // DRET decode signal
    output logic dret_dec_o,

    // Indicates ECALL instruction
    output logic ecall_insn_o,
    // Indicates WFI instruction
    output logic wfi_o,

    // Indicates FENCE.I instruction
    output logic fencei_insn_o,

    // Indicates if register A is used
    output logic rega_used_o,
    // Indicates if register B is used
    output logic regb_used_o,
    // Indicates if register C is used
    output logic regc_used_o,

    // Indicates if floating-point register A is used
    output logic reg_fp_a_o,
    // Indicates if floating-point register B is used
    output logic reg_fp_b_o,
    // Indicates if floating-point register C is used
    output logic reg_fp_c_o,
    // Indicates if floating-point register D is used
    output logic reg_fp_d_o,

    // Bitmask A multiplexer output
    output logic [0:0] bmask_a_mux_o,
    // Bitmask B multiplexer output
    output logic [1:0] bmask_b_mux_o,
    // ALU bitmask A multiplexer select
    output logic       alu_bmask_a_mux_sel_o,
    // ALU bitmask B multiplexer select
    output logic       alu_bmask_b_mux_sel_o,

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // Instruction inputs
    ////////////////////////////////////////////////////////////////////////////////////////////////

    // Instruction data input
    input logic [31:0] instr_rdata_i,
    // Indicates illegal compressed instruction
    input logic        illegal_c_insn_i,

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // ALU block outputs
    ////////////////////////////////////////////////////////////////////////////////////////////////

    // ALU enable signal
    output logic              alu_en_o,
    // ALU operation code
    output alu_opcode_e       alu_operator_o,
    // ALU operand A multiplexer select
    output logic        [2:0] alu_op_a_mux_sel_o,
    // ALU operand B multiplexer select
    output logic        [2:0] alu_op_b_mux_sel_o,
    // ALU operand C multiplexer select
    output logic        [1:0] alu_op_c_mux_sel_o,
    // ALU vector operation enable
    output logic              alu_vec_o,
    // ALU vector mode
    output logic        [1:0] alu_vec_mode_o,
    // Scalar replication enable
    output logic              scalar_replication_o,
    // Scalar replication for operand C
    output logic              scalar_replication_c_o,
    // Immediate A multiplexer select
    output logic        [0:0] imm_a_mux_sel_o,
    // Immediate B multiplexer select
    output logic        [3:0] imm_b_mux_sel_o,
    // Register C multiplexer output
    output logic        [1:0] regc_mux_o,
    // Indicates CLPX instruction
    output logic              is_clpx_o,
    // Indicates SUBROT instruction
    output logic              is_subrot_o,

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // MUL block outputs
    ////////////////////////////////////////////////////////////////////////////////////////////////

    // Multiplier operation code
    output mul_opcode_e       mult_operator_o,
    // Multiplier integer enable
    output logic              mult_int_en_o,
    // Multiplier dot enable
    output logic              mult_dot_en_o,
    // Multiplier immediate multiplexer output
    output logic        [0:0] mult_imm_mux_o,
    // Multiplier subword selection
    output logic              mult_sel_subword_o,
    // Multiplier signed mode
    output logic        [1:0] mult_signed_mode_o,
    // Multiplier dot signed mode
    output logic        [1:0] mult_dot_signed_o,

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // FPU block inputs
    ////////////////////////////////////////////////////////////////////////////////////////////////

    // Floating-point status off
    input logic            fs_off_i,
    // Floating-point rounding mode
    input logic [C_RM-1:0] frm_i,

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // FPU block outputs
    ////////////////////////////////////////////////////////////////////////////////////////////////

    // FPU destination format
    output logic [ rv32imf_fpu_pkg::FP_FORMAT_BITS-1:0] fpu_dst_fmt_o,
    // FPU source format
    output logic [ rv32imf_fpu_pkg::FP_FORMAT_BITS-1:0] fpu_src_fmt_o,
    // FPU integer format
    output logic [rv32imf_fpu_pkg::INT_FORMAT_BITS-1:0] fpu_int_fmt_o,

    // APU enable signal
    output logic       apu_en_o,
    // APU operation code
    output logic [5:0] apu_op_o,
    // APU latency
    output logic [1:0] apu_lat_o,
    // Floating-point rounding mode
    output logic [2:0] fp_rnd_mode_o,

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // Register file outputs
    ////////////////////////////////////////////////////////////////////////////////////////////////

    // Register file memory write enable
    output logic regfile_mem_we_o,
    // Register file ALU write enable
    output logic regfile_alu_we_o,
    // Register file ALU write enable decode
    output logic regfile_alu_we_dec_o,
    // Register file ALU write address select
    output logic regfile_alu_waddr_sel_o,

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // CSR block outputs
    ////////////////////////////////////////////////////////////////////////////////////////////////

    // CSR access enable
    output logic        csr_access_o,
    // CSR status
    output logic        csr_status_o,
    // CSR operation code
    output csr_opcode_e csr_op_o,
    // Current privilege level
    input  priv_lvl_t   current_priv_lvl_i,

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // Data memory outputs
    ////////////////////////////////////////////////////////////////////////////////////////////////

    // Data request signal
    output logic       data_req_o,
    // Data write enable
    output logic       data_we_o,
    // Pre/post increment usage
    output logic       prepost_useincr_o,
    // Data type
    output logic [1:0] data_type_o,
    // Data sign extension
    output logic [1:0] data_sign_extension_o,
    // Data register offset
    output logic [1:0] data_reg_offset_o,
    // Data load event
    output logic       data_load_event_o,

    // Atomic operation type
    output logic [5:0] atop_o,

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // Hardware loop outputs
    ////////////////////////////////////////////////////////////////////////////////////////////////

    // Hardware loop write enable
    output logic [2:0] hwlp_we_o,
    // Hardware loop target multiplexer select
    output logic [1:0] hwlp_target_mux_sel_o,
    // Hardware loop start multiplexer select
    output logic [1:0] hwlp_start_mux_sel_o,
    // Hardware loop count multiplexer select
    output logic       hwlp_cnt_mux_sel_o,

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // Debug inputs
    ////////////////////////////////////////////////////////////////////////////////////////////////

    // Debug mode enable
    input logic debug_mode_i,
    // Debug WFI no sleep enable
    input logic debug_wfi_no_sleep_i,

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // Control transfer outputs
    ////////////////////////////////////////////////////////////////////////////////////////////////

    // Control transfer instruction in decode stage
    output logic [1:0] ctrl_transfer_insn_in_dec_o,
    // Control transfer instruction in ID stage
    output logic [1:0] ctrl_transfer_insn_in_id_o,
    // Control transfer target multiplexer select
    output logic [1:0] ctrl_transfer_target_mux_sel_o,

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // Counter inputs
    ////////////////////////////////////////////////////////////////////////////////////////////////

    // Machine counter enable
    input logic [31:0] mcounteren_i
);

  // Internal signals
  logic regfile_mem_we;  // Register file memory write enable
  logic regfile_alu_we;  // Register file ALU write enable
  logic data_req;  // Data request signal
  logic [2:0] hwlp_we;  // Hardware loop write enable
  logic csr_illegal;  // CSR illegal operation flag
  logic [1:0] ctrl_transfer_insn;  // Control transfer instruction type

  csr_opcode_e csr_op;  // CSR operation type

  logic alu_en;  // ALU enable signal
  logic mult_int_en;  // Multiplier integer enable signal
  logic mult_dot_en;  // Multiplier dot enable signal
  logic apu_en;  // APU enable signal

  logic check_fprm;  // Check floating-point rounding mode

  logic [rv32imf_fpu_pkg::OP_BITS-1:0] fpu_op;  // FPU operation
  logic fpu_op_mod;  // FPU operation modifier
  logic fpu_vec_op;  // FPU vector operation

  // Floating-point operation group enumeration
  typedef enum logic [1:0] {
    ADDMUL,  // Add or multiply group
    DIVSQRT, // Divide or square root group
    NONCOMP, // Non-computational group
    CONV     // Conversion group
  } fp_op_group_t;
  fp_op_group_t fp_op_group;

  // Instruction decoder block
  always_comb begin : instruction_decoder
    // Default assignments for control signals
    ctrl_transfer_insn             = BRANCH_NONE;
    ctrl_transfer_target_mux_sel_o = JT_JAL;

    alu_en                         = 1'b1;
    alu_operator_o                 = ALU_SLTU;
    alu_op_a_mux_sel_o             = OP_A_REGA_OR_FWD;
    alu_op_b_mux_sel_o             = OP_B_REGB_OR_FWD;
    alu_op_c_mux_sel_o             = OP_C_REGC_OR_FWD;
    alu_vec_o                      = 1'b0;
    alu_vec_mode_o                 = VEC_MODE32;
    scalar_replication_o           = 1'b0;
    scalar_replication_c_o         = 1'b0;
    regc_mux_o                     = REGC_ZERO;
    imm_a_mux_sel_o                = IMMA_ZERO;
    imm_b_mux_sel_o                = IMMB_I;

    mult_int_en                    = 1'b0;
    mult_dot_en                    = 1'b0;
    mult_operator_o                = MUL_I;
    mult_imm_mux_o                 = MIMM_ZERO;
    mult_signed_mode_o             = 2'b00;
    mult_sel_subword_o             = 1'b0;
    mult_dot_signed_o              = 2'b00;

    apu_en                         = 1'b0;
    apu_op_o                       = '0;
    apu_lat_o                      = '0;
    fp_rnd_mode_o                  = '0;
    fpu_op                         = rv32imf_fpu_pkg::SGNJ;
    fpu_op_mod                     = 1'b0;
    fpu_vec_op                     = 1'b0;
    fpu_dst_fmt_o                  = rv32imf_fpu_pkg::FP32;
    fpu_src_fmt_o                  = rv32imf_fpu_pkg::FP32;
    fpu_int_fmt_o                  = rv32imf_fpu_pkg::INT32;
    check_fprm                     = 1'b0;
    fp_op_group                    = ADDMUL;

    regfile_mem_we                 = 1'b0;
    regfile_alu_we                 = 1'b0;
    regfile_alu_waddr_sel_o        = 1'b1;

    prepost_useincr_o              = 1'b1;

    hwlp_we                        = 3'b0;
    hwlp_target_mux_sel_o          = 2'b0;
    hwlp_start_mux_sel_o           = 2'b0;
    hwlp_cnt_mux_sel_o             = 1'b0;

    csr_access_o                   = 1'b0;
    csr_status_o                   = 1'b0;
    csr_illegal                    = 1'b0;
    csr_op                         = CSR_OP_READ;
    mret_insn_o                    = 1'b0;
    uret_insn_o                    = 1'b0;

    dret_insn_o                    = 1'b0;

    data_we_o                      = 1'b0;
    data_type_o                    = 2'b00;
    data_sign_extension_o          = 2'b00;
    data_reg_offset_o              = 2'b00;
    data_req                       = 1'b0;
    data_load_event_o              = 1'b0;

    atop_o                         = 6'b000000;

    illegal_insn_o                 = 1'b0;
    ebrk_insn_o                    = 1'b0;
    ecall_insn_o                   = 1'b0;
    wfi_o                          = 1'b0;

    fencei_insn_o                  = 1'b0;

    rega_used_o                    = 1'b0;
    regb_used_o                    = 1'b0;
    regc_used_o                    = 1'b0;
    reg_fp_a_o                     = 1'b0;
    reg_fp_b_o                     = 1'b0;
    reg_fp_c_o                     = 1'b0;
    reg_fp_d_o                     = 1'b0;

    bmask_a_mux_o                  = BMASK_A_ZERO;
    bmask_b_mux_o                  = BMASK_B_ZERO;
    alu_bmask_a_mux_sel_o          = BMASK_A_IMM;
    alu_bmask_b_mux_sel_o          = BMASK_B_IMM;

    is_clpx_o                      = 1'b0;
    is_subrot_o                    = 1'b0;

    mret_dec_o                     = 1'b0;
    uret_dec_o                     = 1'b0;
    dret_dec_o                     = 1'b0;

    // Decode specific instructions based on opcode
    unique case (instr_rdata_i[6:0])

      OPCODE_JAL: begin
        // JAL instruction decoding
        ctrl_transfer_target_mux_sel_o = JT_JAL;
        ctrl_transfer_insn             = BRANCH_JAL;

        alu_op_a_mux_sel_o             = OP_A_CURRPC;
        alu_op_b_mux_sel_o             = OP_B_IMM;
        imm_b_mux_sel_o                = IMMB_PCINCR;
        alu_operator_o                 = ALU_ADD;
        regfile_alu_we                 = 1'b1;

      end

      OPCODE_JALR: begin
        // JALR instruction decoding
        ctrl_transfer_target_mux_sel_o = JT_JALR;
        ctrl_transfer_insn             = BRANCH_JALR;

        alu_op_a_mux_sel_o             = OP_A_CURRPC;
        alu_op_b_mux_sel_o             = OP_B_IMM;
        imm_b_mux_sel_o                = IMMB_PCINCR;
        alu_operator_o                 = ALU_ADD;
        regfile_alu_we                 = 1'b1;

        rega_used_o                    = 1'b1;

        if (instr_rdata_i[14:12] != 3'b0) begin
          ctrl_transfer_insn = BRANCH_NONE;
          regfile_alu_we     = 1'b0;
          illegal_insn_o     = 1'b1;
        end
      end

      OPCODE_BRANCH: begin
        // Branch instruction decoding
        ctrl_transfer_target_mux_sel_o = JT_COND;
        ctrl_transfer_insn             = BRANCH_COND;
        alu_op_c_mux_sel_o             = OP_C_JT;
        rega_used_o                    = 1'b1;
        regb_used_o                    = 1'b1;

        unique case (instr_rdata_i[14:12])
          3'b000:  alu_operator_o = ALU_EQ;
          3'b001:  alu_operator_o = ALU_NE;
          3'b100:  alu_operator_o = ALU_LTS;
          3'b101:  alu_operator_o = ALU_GES;
          3'b110:  alu_operator_o = ALU_LTU;
          3'b111:  alu_operator_o = ALU_GEU;
          default: illegal_insn_o = 1'b1;
        endcase
      end

      OPCODE_STORE: begin
        // Store instruction decoding
        data_req           = 1'b1;
        data_we_o          = 1'b1;
        rega_used_o        = 1'b1;
        regb_used_o        = 1'b1;
        alu_operator_o     = ALU_ADD;

        alu_op_c_mux_sel_o = OP_C_REGB_OR_FWD;

        imm_b_mux_sel_o    = IMMB_S;
        alu_op_b_mux_sel_o = OP_B_IMM;

        unique case (instr_rdata_i[14:12])
          3'b000: data_type_o = 2'b10;
          3'b001: data_type_o = 2'b01;
          3'b010: data_type_o = 2'b00;
          default: begin
            illegal_insn_o = 1'b1;
            data_req       = 1'b0;
            data_we_o      = 1'b0;
          end
        endcase
      end

      OPCODE_LOAD: begin
        // Load instruction decoding
        data_req              = 1'b1;
        regfile_mem_we        = 1'b1;
        rega_used_o           = 1'b1;
        alu_operator_o        = ALU_ADD;

        alu_op_b_mux_sel_o    = OP_B_IMM;
        imm_b_mux_sel_o       = IMMB_I;

        data_sign_extension_o = {1'b0, ~instr_rdata_i[14]};

        unique case (instr_rdata_i[14:12])
          3'b000, 3'b100: data_type_o = 2'b10;
          3'b001, 3'b101: data_type_o = 2'b01;
          3'b010:         data_type_o = 2'b00;
          default: begin
            illegal_insn_o = 1'b1;
          end
        endcase
      end

      OPCODE_AMO: begin
        // AMO instruction decoding
        illegal_insn_o = 1'b1;
      end

      OPCODE_LUI: begin
        // LUI instruction decoding
        alu_op_a_mux_sel_o = OP_A_IMM;
        alu_op_b_mux_sel_o = OP_B_IMM;
        imm_a_mux_sel_o    = IMMA_ZERO;
        imm_b_mux_sel_o    = IMMB_U;
        alu_operator_o     = ALU_ADD;
        regfile_alu_we     = 1'b1;
      end

      OPCODE_AUIPC: begin
        // AUIPC instruction decoding
        alu_op_a_mux_sel_o = OP_A_CURRPC;
        alu_op_b_mux_sel_o = OP_B_IMM;
        imm_b_mux_sel_o    = IMMB_U;
        alu_operator_o     = ALU_ADD;
        regfile_alu_we     = 1'b1;
      end

      OPCODE_OPIMM: begin
        // OPIMM instruction decoding
        alu_op_b_mux_sel_o = OP_B_IMM;
        imm_b_mux_sel_o    = IMMB_I;
        regfile_alu_we     = 1'b1;
        rega_used_o        = 1'b1;

        unique case (instr_rdata_i[14:12])
          3'b000: alu_operator_o = ALU_ADD;
          3'b010: alu_operator_o = ALU_SLTS;
          3'b011: alu_operator_o = ALU_SLTU;
          3'b100: alu_operator_o = ALU_XOR;
          3'b110: alu_operator_o = ALU_OR;
          3'b111: alu_operator_o = ALU_AND;

          3'b001: begin
            alu_operator_o = ALU_SLL;
            if (instr_rdata_i[31:25] != 7'b0) illegal_insn_o = 1'b1;
          end

          3'b101: begin
            if (instr_rdata_i[31:25] == 7'b0) alu_operator_o = ALU_SRL;
            else if (instr_rdata_i[31:25] == 7'b010_0000) alu_operator_o = ALU_SRA;
            else illegal_insn_o = 1'b1;
          end
        endcase
      end

      OPCODE_OP: begin
        // OP instruction decoding
        if (instr_rdata_i[31:30] == 2'b11) begin
          illegal_insn_o = 1'b1;
        end else if (instr_rdata_i[31:30] == 2'b10) begin
          illegal_insn_o = 1'b1;
        end else begin
          regfile_alu_we = 1'b1;
          rega_used_o    = 1'b1;

          if (~instr_rdata_i[28]) regb_used_o = 1'b1;

          unique case ({
            instr_rdata_i[30:25], instr_rdata_i[14:12]
          })
            {6'b00_0000, 3'b000} : alu_operator_o = ALU_ADD;
            {6'b10_0000, 3'b000} : alu_operator_o = ALU_SUB;
            {6'b00_0000, 3'b010} : alu_operator_o = ALU_SLTS;
            {6'b00_0000, 3'b011} : alu_operator_o = ALU_SLTU;
            {6'b00_0000, 3'b100} : alu_operator_o = ALU_XOR;
            {6'b00_0000, 3'b110} : alu_operator_o = ALU_OR;
            {6'b00_0000, 3'b111} : alu_operator_o = ALU_AND;
            {6'b00_0000, 3'b001} : alu_operator_o = ALU_SLL;
            {6'b00_0000, 3'b101} : alu_operator_o = ALU_SRL;
            {6'b10_0000, 3'b101} : alu_operator_o = ALU_SRA;

            {
              6'b00_0001, 3'b000
            } : begin
              alu_en          = 1'b0;
              mult_int_en     = 1'b1;
              mult_operator_o = MUL_MAC32;
              regc_mux_o      = REGC_ZERO;
            end
            {
              6'b00_0001, 3'b001
            } : begin
              alu_en             = 1'b0;
              mult_int_en        = 1'b1;
              regc_used_o        = 1'b1;
              regc_mux_o         = REGC_ZERO;
              mult_signed_mode_o = 2'b11;
              mult_operator_o    = MUL_H;
            end
            {
              6'b00_0001, 3'b010
            } : begin
              alu_en             = 1'b0;
              mult_int_en        = 1'b1;
              regc_used_o        = 1'b1;
              regc_mux_o         = REGC_ZERO;
              mult_signed_mode_o = 2'b01;
              mult_operator_o    = MUL_H;
            end
            {
              6'b00_0001, 3'b011
            } : begin
              alu_en             = 1'b0;
              mult_int_en        = 1'b1;
              regc_used_o        = 1'b1;
              regc_mux_o         = REGC_ZERO;
              mult_signed_mode_o = 2'b00;
              mult_operator_o    = MUL_H;
            end
            {
              6'b00_0001, 3'b100
            } : begin
              alu_op_a_mux_sel_o = OP_A_REGB_OR_FWD;
              alu_op_b_mux_sel_o = OP_B_REGA_OR_FWD;
              regb_used_o        = 1'b1;
              alu_operator_o     = ALU_DIV;
            end
            {
              6'b00_0001, 3'b101
            } : begin
              alu_op_a_mux_sel_o = OP_A_REGB_OR_FWD;
              alu_op_b_mux_sel_o = OP_B_REGA_OR_FWD;
              regb_used_o        = 1'b1;
              alu_operator_o     = ALU_DIVU;
            end
            {
              6'b00_0001, 3'b110
            } : begin
              alu_op_a_mux_sel_o = OP_A_REGB_OR_FWD;
              alu_op_b_mux_sel_o = OP_B_REGA_OR_FWD;
              regb_used_o        = 1'b1;
              alu_operator_o     = ALU_REM;
            end
            {
              6'b00_0001, 3'b111
            } : begin
              alu_op_a_mux_sel_o = OP_A_REGB_OR_FWD;
              alu_op_b_mux_sel_o = OP_B_REGA_OR_FWD;
              regb_used_o        = 1'b1;
              alu_operator_o     = ALU_REMU;
            end

            default: begin
              illegal_insn_o = 1'b1;
            end
          endcase
        end
      end

      OPCODE_OP_FP: begin
        // OP_FP instruction decoding
        if (fs_off_i == 1'b0) begin
          alu_en        = 1'b0;
          apu_en        = 1'b1;

          rega_used_o   = 1'b1;
          regb_used_o   = 1'b1;
          reg_fp_a_o    = 1'b1;
          reg_fp_b_o    = 1'b1;
          reg_fp_d_o    = 1'b1;

          check_fprm    = 1'b1;
          fp_rnd_mode_o = instr_rdata_i[14:12];

          unique case (instr_rdata_i[26:25])
            2'b00: fpu_dst_fmt_o = rv32imf_fpu_pkg::FP32;
            2'b01: fpu_dst_fmt_o = rv32imf_fpu_pkg::FP64;
            2'b10: begin
              if (instr_rdata_i[14:12] == 3'b101) fpu_dst_fmt_o = rv32imf_fpu_pkg::FP16ALT;
              else fpu_dst_fmt_o = rv32imf_fpu_pkg::FP16;
            end
            2'b11: fpu_dst_fmt_o = rv32imf_fpu_pkg::FP8;
          endcase

          fpu_src_fmt_o = fpu_dst_fmt_o;

          unique case (instr_rdata_i[31:27])
            5'b00000: begin
              fpu_op             = rv32imf_fpu_pkg::ADD;
              fp_op_group        = ADDMUL;
              alu_op_b_mux_sel_o = OP_B_REGA_OR_FWD;
              alu_op_c_mux_sel_o = OP_C_REGB_OR_FWD;
            end
            5'b00001: begin
              fpu_op             = rv32imf_fpu_pkg::ADD;
              fpu_op_mod         = 1'b1;
              fp_op_group        = ADDMUL;
              alu_op_b_mux_sel_o = OP_B_REGA_OR_FWD;
              alu_op_c_mux_sel_o = OP_C_REGB_OR_FWD;
            end
            5'b00010: begin
              fpu_op      = rv32imf_fpu_pkg::MUL;
              fp_op_group = ADDMUL;
            end
            5'b00011: begin
              fpu_op      = rv32imf_fpu_pkg::DIV;
              fp_op_group = DIVSQRT;
            end
            5'b01011: begin
              regb_used_o = 1'b0;
              fpu_op      = rv32imf_fpu_pkg::SQRT;
              fp_op_group = DIVSQRT;
              if (instr_rdata_i[24:20] != 5'b00000) illegal_insn_o = 1'b1;
            end
            5'b00100: begin
              fpu_op      = rv32imf_fpu_pkg::SGNJ;
              fp_op_group = NONCOMP;
              check_fprm  = 1'b0;
              if (C_XF16ALT) begin
                if (!(instr_rdata_i[14:12] inside {[3'b000 : 3'b010], [3'b100 : 3'b110]})) begin
                  illegal_insn_o = 1'b1;
                end
                if (instr_rdata_i[14]) begin
                  fpu_dst_fmt_o = rv32imf_fpu_pkg::FP16ALT;
                  fpu_src_fmt_o = rv32imf_fpu_pkg::FP16ALT;
                end else begin
                  fp_rnd_mode_o = {1'b0, instr_rdata_i[13:12]};
                end
              end else begin
                if (!(instr_rdata_i[14:12] inside {[3'b000 : 3'b010]})) illegal_insn_o = 1'b1;
              end
            end
            5'b00101: begin
              fpu_op      = rv32imf_fpu_pkg::MINMAX;
              fp_op_group = NONCOMP;
              check_fprm  = 1'b0;
              if (C_XF16ALT) begin
                if (!(instr_rdata_i[14:12] inside {[3'b000 : 3'b001], [3'b100 : 3'b101]})) begin
                  illegal_insn_o = 1'b1;
                end
                if (instr_rdata_i[14]) begin
                  fpu_dst_fmt_o = rv32imf_fpu_pkg::FP16ALT;
                  fpu_src_fmt_o = rv32imf_fpu_pkg::FP16ALT;
                end else begin
                  fp_rnd_mode_o = {1'b0, instr_rdata_i[13:12]};
                end
              end else begin
                if (!(instr_rdata_i[14:12] inside {[3'b000 : 3'b001]})) illegal_insn_o = 1'b1;
              end
            end
            5'b01000: begin
              regb_used_o = 1'b0;
              fpu_op      = rv32imf_fpu_pkg::F2F;
              fp_op_group = CONV;
              if (instr_rdata_i[24:23]) illegal_insn_o = 1'b1;
              unique case (instr_rdata_i[22:20])
                3'b000: begin
                  if (!(C_RVF && (C_XF16 || C_XF16ALT || C_XF8))) illegal_insn_o = 1'b1;
                  fpu_src_fmt_o = rv32imf_fpu_pkg::FP32;
                end
                3'b001: begin
                  if (~C_RVD) illegal_insn_o = 1'b1;
                  fpu_src_fmt_o = rv32imf_fpu_pkg::FP64;
                end
                3'b010: begin
                  if (~C_XF16) illegal_insn_o = 1'b1;
                  fpu_src_fmt_o = rv32imf_fpu_pkg::FP16;
                end
                3'b110: begin
                  if (~C_XF16ALT) illegal_insn_o = 1'b1;
                  fpu_src_fmt_o = rv32imf_fpu_pkg::FP16ALT;
                end
                3'b011: begin
                  if (~C_XF8) illegal_insn_o = 1'b1;
                  fpu_src_fmt_o = rv32imf_fpu_pkg::FP8;
                end
                default: illegal_insn_o = 1'b1;
              endcase
            end
            5'b01001: begin
              if (~C_XF16 && ~C_XF16ALT && ~C_XF8) illegal_insn_o = 1;
              fpu_op        = rv32imf_fpu_pkg::MUL;
              fp_op_group   = ADDMUL;
              fpu_dst_fmt_o = rv32imf_fpu_pkg::FP32;
            end
            5'b01010: begin
              if (~C_XF16 && ~C_XF16ALT && ~C_XF8) illegal_insn_o = 1;
              regc_used_o   = 1'b1;
              regc_mux_o    = REGC_RD;
              reg_fp_c_o    = 1'b1;
              fpu_op        = rv32imf_fpu_pkg::FMADD;
              fp_op_group   = ADDMUL;
              fpu_dst_fmt_o = rv32imf_fpu_pkg::FP32;
            end
            5'b10100: begin
              fpu_op      = rv32imf_fpu_pkg::CMP;
              fp_op_group = NONCOMP;
              reg_fp_d_o  = 1'b0;
              check_fprm  = 1'b0;
              if (C_XF16ALT) begin
                if (!(instr_rdata_i[14:12] inside {[3'b000 : 3'b010], [3'b100 : 3'b110]})) begin
                  illegal_insn_o = 1'b1;
                end
                if (instr_rdata_i[14]) begin
                  fpu_dst_fmt_o = rv32imf_fpu_pkg::FP16ALT;
                  fpu_src_fmt_o = rv32imf_fpu_pkg::FP16ALT;
                end else begin
                  fp_rnd_mode_o = {1'b0, instr_rdata_i[13:12]};
                end
              end else begin
                if (!(instr_rdata_i[14:12] inside {[3'b000 : 3'b010]})) illegal_insn_o = 1'b1;
              end
            end
            5'b11000: begin
              regb_used_o = 1'b0;
              reg_fp_d_o  = 1'b0;
              fpu_op      = rv32imf_fpu_pkg::F2I;
              fp_op_group = CONV;
              fpu_op_mod  = instr_rdata_i[20];
              unique case (instr_rdata_i[26:25])
                2'b00: begin
                  if (~C_RVF) illegal_insn_o = 1;
                  else fpu_src_fmt_o = rv32imf_fpu_pkg::FP32;
                end
                2'b01: begin
                  if (~C_RVD) illegal_insn_o = 1;
                  else fpu_src_fmt_o = rv32imf_fpu_pkg::FP64;
                end
                2'b10: begin
                  if (instr_rdata_i[14:12] == 3'b101) begin
                    if (~C_XF16ALT) illegal_insn_o = 1;
                    else fpu_src_fmt_o = rv32imf_fpu_pkg::FP16ALT;
                  end else if (~C_XF16) begin
                    illegal_insn_o = 1;
                  end else begin
                    fpu_src_fmt_o = rv32imf_fpu_pkg::FP16;
                  end
                end
                2'b11: begin
                  if (~C_XF8) illegal_insn_o = 1;
                  else fpu_src_fmt_o = rv32imf_fpu_pkg::FP8;
                end
              endcase
              if (instr_rdata_i[24:21]) illegal_insn_o = 1'b1;
            end
            5'b11010: begin
              regb_used_o = 1'b0;
              reg_fp_a_o  = 1'b0;
              fpu_op      = rv32imf_fpu_pkg::I2F;
              fp_op_group = CONV;
              fpu_op_mod  = instr_rdata_i[20];
              if (instr_rdata_i[24:21]) illegal_insn_o = 1'b1;
            end
            5'b11100: begin
              regb_used_o = 1'b0;
              reg_fp_d_o  = 1'b0;
              fp_op_group = NONCOMP;
              check_fprm  = 1'b0;
              if ((instr_rdata_i[14:12] == 3'b000)
                || (C_XF16ALT && instr_rdata_i[14:12] == 3'b100)) begin
                alu_op_b_mux_sel_o = OP_B_REGA_OR_FWD;
                fpu_op             = rv32imf_fpu_pkg::SGNJ;
                fpu_op_mod         = 1'b1;
                fp_rnd_mode_o      = 3'b011;
                if (instr_rdata_i[14]) begin
                  fpu_dst_fmt_o = rv32imf_fpu_pkg::FP16ALT;
                  fpu_src_fmt_o = rv32imf_fpu_pkg::FP16ALT;
                end
              end else if (instr_rdata_i[14:12] == 3'b001
                || (C_XF16ALT && instr_rdata_i[14:12] == 3'b101)) begin
                fpu_op        = rv32imf_fpu_pkg::CLASSIFY;
                fp_rnd_mode_o = 3'b000;
                if (instr_rdata_i[14]) begin
                  fpu_dst_fmt_o = rv32imf_fpu_pkg::FP16ALT;
                  fpu_src_fmt_o = rv32imf_fpu_pkg::FP16ALT;
                end
              end else begin
                illegal_insn_o = 1'b1;
              end
              if (instr_rdata_i[24:20]) illegal_insn_o = 1'b1;
            end
            5'b11110: begin
              regb_used_o        = 1'b0;
              reg_fp_a_o         = 1'b0;
              alu_op_b_mux_sel_o = OP_B_REGA_OR_FWD;
              fpu_op             = rv32imf_fpu_pkg::SGNJ;
              fpu_op_mod         = 1'b0;
              fp_op_group        = NONCOMP;
              fp_rnd_mode_o      = 3'b011;
              check_fprm         = 1'b0;
              if ((instr_rdata_i[14:12] == 3'b000)
                || (C_XF16ALT && instr_rdata_i[14:12] == 3'b100)) begin
                if (instr_rdata_i[14]) begin
                  fpu_dst_fmt_o = rv32imf_fpu_pkg::FP16ALT;
                  fpu_src_fmt_o = rv32imf_fpu_pkg::FP16ALT;
                end
              end else begin
                illegal_insn_o = 1'b1;
              end
              if (instr_rdata_i[24:20] != 5'b00000) illegal_insn_o = 1'b1;
            end
            default: illegal_insn_o = 1'b1;
          endcase

          if (~C_RVF && fpu_dst_fmt_o == rv32imf_fpu_pkg::FP32) illegal_insn_o = 1'b1;
          if ((~C_RVD) && fpu_dst_fmt_o == rv32imf_fpu_pkg::FP64) illegal_insn_o = 1'b1;
          if ((~C_XF16) && fpu_dst_fmt_o == rv32imf_fpu_pkg::FP16) illegal_insn_o = 1'b1;
          if ((~C_XF16ALT) && fpu_dst_fmt_o == rv32imf_fpu_pkg::FP16ALT) begin
            illegal_insn_o = 1'b1;
          end
          if ((~C_XF8) && fpu_dst_fmt_o == rv32imf_fpu_pkg::FP8) illegal_insn_o = 1'b1;

          if (check_fprm) begin
            unique case (instr_rdata_i[14:12]) inside
              3'b000, 3'b001, 3'b010, 3'b011, 3'b100: ;
              3'b101: begin
                if (~C_XF16ALT || fpu_dst_fmt_o != rv32imf_fpu_pkg::FP16ALT) illegal_insn_o = 1'b1;
                unique case (frm_i) inside
                  3'b000, 3'b001, 3'b010, 3'b011, 3'b100: fp_rnd_mode_o = frm_i;
                  default:                                illegal_insn_o = 1'b1;
                endcase
              end
              3'b111: begin
                unique case (frm_i) inside
                  3'b000, 3'b001, 3'b010, 3'b011, 3'b100: fp_rnd_mode_o = frm_i;
                  default:                                illegal_insn_o = 1'b1;
                endcase
              end
              default:                                illegal_insn_o = 1'b1;
            endcase
          end

          case (fp_op_group)
            ADDMUL: begin
              unique case (fpu_dst_fmt_o)
                rv32imf_fpu_pkg::FP32: apu_lat_o = 1;
                rv32imf_fpu_pkg::FP64: apu_lat_o = (C_LAT_FP64 < 2) ? C_LAT_FP64 + 1 : 2'h3;
                rv32imf_fpu_pkg::FP16: apu_lat_o = (C_LAT_FP16 < 2) ? C_LAT_FP16 + 1 : 2'h3;
                rv32imf_fpu_pkg::FP16ALT:
                apu_lat_o = (C_LAT_FP16ALT < 2) ? C_LAT_FP16ALT + 1 : 2'h3;
                rv32imf_fpu_pkg::FP8: apu_lat_o = (C_LAT_FP8 < 2) ? C_LAT_FP8 + 1 : 2'h3;
                default: ;
              endcase
            end
            DIVSQRT: apu_lat_o = 2'h3;
            NONCOMP, CONV: apu_lat_o = 1;
            default: begin
            end
          endcase

          apu_op_o = {fpu_vec_op, fpu_op_mod, fpu_op};
        end else begin
          illegal_insn_o = 1'b1;
        end
      end

      OPCODE_OP_FMADD, OPCODE_OP_FMSUB, OPCODE_OP_FNMSUB, OPCODE_OP_FNMADD: begin
        // FMADD, FMSUB, FNMSUB, FNMADD instruction decoding
        if (fs_off_i == 1'b0) begin
          alu_en        = 1'b0;
          apu_en        = 1'b1;

          rega_used_o   = 1'b1;
          regb_used_o   = 1'b1;
          regc_used_o   = 1'b1;
          regc_mux_o    = REGC_S4;
          reg_fp_a_o    = 1'b1;
          reg_fp_b_o    = 1'b1;
          reg_fp_c_o    = 1'b1;
          reg_fp_d_o    = 1'b1;
          fp_rnd_mode_o = instr_rdata_i[14:12];

          unique case (instr_rdata_i[26:25])
            2'b00: fpu_dst_fmt_o = rv32imf_fpu_pkg::FP32;
            2'b01: fpu_dst_fmt_o = rv32imf_fpu_pkg::FP64;
            2'b10: begin
              if (instr_rdata_i[14:12] == 3'b101) fpu_dst_fmt_o = rv32imf_fpu_pkg::FP16ALT;
              else fpu_dst_fmt_o = rv32imf_fpu_pkg::FP16;
            end
            2'b11: fpu_dst_fmt_o = rv32imf_fpu_pkg::FP8;
          endcase

          fpu_src_fmt_o = fpu_dst_fmt_o;

          unique case (instr_rdata_i[6:0])
            OPCODE_OP_FMADD: begin
              fpu_op = rv32imf_fpu_pkg::FMADD;
            end
            OPCODE_OP_FMSUB: begin
              fpu_op     = rv32imf_fpu_pkg::FMADD;
              fpu_op_mod = 1'b1;
            end
            OPCODE_OP_FNMSUB: begin
              fpu_op = rv32imf_fpu_pkg::FNMSUB;
            end
            OPCODE_OP_FNMADD: begin
              fpu_op     = rv32imf_fpu_pkg::FNMSUB;
              fpu_op_mod = 1'b1;
            end
            default: ;
          endcase

          if (~C_RVF && fpu_dst_fmt_o == rv32imf_fpu_pkg::FP32) illegal_insn_o = 1'b1;
          if ((~C_RVD) && fpu_dst_fmt_o == rv32imf_fpu_pkg::FP64) illegal_insn_o = 1'b1;
          if ((~C_XF16) && fpu_dst_fmt_o == rv32imf_fpu_pkg::FP16) illegal_insn_o = 1'b1;
          if ((~C_XF16ALT) && fpu_dst_fmt_o == rv32imf_fpu_pkg::FP16ALT) begin
            illegal_insn_o = 1'b1;
          end
          if ((~C_XF8) && fpu_dst_fmt_o == rv32imf_fpu_pkg::FP8) illegal_insn_o = 1'b1;

          unique case (instr_rdata_i[14:12]) inside
            3'b000, 3'b001, 3'b010, 3'b011, 3'b100: ;
            3'b101: begin
              if (~C_XF16ALT || fpu_dst_fmt_o != rv32imf_fpu_pkg::FP16ALT) illegal_insn_o = 1'b1;
              unique case (frm_i) inside
                3'b000, 3'b001, 3'b010, 3'b011, 3'b100: fp_rnd_mode_o = frm_i;
                default:                                illegal_insn_o = 1'b1;
              endcase
            end
            3'b111: begin
              unique case (frm_i) inside
                3'b000, 3'b001, 3'b010, 3'b011, 3'b100: fp_rnd_mode_o = frm_i;
                default:                                illegal_insn_o = 1'b1;
              endcase
            end
            default:                                illegal_insn_o = 1'b1;
          endcase

          unique case (fpu_dst_fmt_o)
            rv32imf_fpu_pkg::FP32:    apu_lat_o = 1;
            rv32imf_fpu_pkg::FP64:    apu_lat_o = (C_LAT_FP64 < 2) ? C_LAT_FP64 + 1 : 2'h3;
            rv32imf_fpu_pkg::FP16:    apu_lat_o = (C_LAT_FP16 < 2) ? C_LAT_FP16 + 1 : 2'h3;
            rv32imf_fpu_pkg::FP16ALT: apu_lat_o = (C_LAT_FP16ALT < 2) ? C_LAT_FP16ALT + 1 : 2'h3;
            rv32imf_fpu_pkg::FP8:     apu_lat_o = (C_LAT_FP8 < 2) ? C_LAT_FP8 + 1 : 2'h3;
            default:                  ;
          endcase

          apu_op_o = {fpu_vec_op, fpu_op_mod, fpu_op};
        end else begin
          illegal_insn_o = 1'b1;
        end
      end

      OPCODE_STORE_FP: begin
        // Store FP instruction decoding
        if (fs_off_i == 1'b0) begin
          data_req           = 1'b1;
          data_we_o          = 1'b1;
          rega_used_o        = 1'b1;
          regb_used_o        = 1'b1;
          alu_operator_o     = ALU_ADD;
          reg_fp_b_o         = 1'b1;

          imm_b_mux_sel_o    = IMMB_S;
          alu_op_b_mux_sel_o = OP_B_IMM;

          alu_op_c_mux_sel_o = OP_C_REGB_OR_FWD;

          unique case (instr_rdata_i[14:12])
            3'b000:  if (C_XF8) data_type_o = 2'b10;
 else illegal_insn_o = 1'b1;
            3'b001:  if (C_XF16 | C_XF16ALT) data_type_o = 2'b01;
 else illegal_insn_o = 1'b1;
            3'b010:  if (C_RVF) data_type_o = 2'b00;
 else illegal_insn_o = 1'b1;
            3'b011:  if (C_RVD) data_type_o = 2'b00;
 else illegal_insn_o = 1'b1;
            default: illegal_insn_o = 1'b1;
          endcase

          if (illegal_insn_o) begin
            data_req  = 1'b0;
            data_we_o = 1'b0;
          end
        end else begin
          illegal_insn_o = 1'b1;
        end
      end

      OPCODE_LOAD_FP: begin
        // Load FP instruction decoding
        if (fs_off_i == 1'b0) begin
          data_req              = 1'b1;
          regfile_mem_we        = 1'b1;
          reg_fp_d_o            = 1'b1;
          rega_used_o           = 1'b1;
          alu_operator_o        = ALU_ADD;

          imm_b_mux_sel_o       = IMMB_I;
          alu_op_b_mux_sel_o    = OP_B_IMM;

          data_sign_extension_o = 2'b10;

          unique case (instr_rdata_i[14:12])
            3'b000:  if (C_XF8) data_type_o = 2'b10;
 else illegal_insn_o = 1'b1;
            3'b001:  if (C_XF16 | C_XF16ALT) data_type_o = 2'b01;
 else illegal_insn_o = 1'b1;
            3'b010:  if (C_RVF) data_type_o = 2'b00;
 else illegal_insn_o = 1'b1;
            3'b011:  if (C_RVD) data_type_o = 2'b00;
 else illegal_insn_o = 1'b1;
            default: illegal_insn_o = 1'b1;
          endcase
        end else begin
          illegal_insn_o = 1'b1;
        end
      end

      OPCODE_CUSTOM_0: begin
        // Custom 0 instruction decoding
        illegal_insn_o = 1'b1;
      end

      OPCODE_CUSTOM_1: begin
        // Custom 1 instruction decoding
        illegal_insn_o = 1'b1;
      end

      OPCODE_CUSTOM_2: begin
        // Custom 2 instruction decoding
        illegal_insn_o = 1'b1;
      end

      OPCODE_CUSTOM_3: begin
        // Custom 3 instruction decoding
        illegal_insn_o = 1'b1;
      end

      OPCODE_FENCE: begin
        // Fence instruction decoding
        unique case (instr_rdata_i[14:12])
          3'b000: begin
            fencei_insn_o = 1'b1;
          end
          3'b001: begin
            fencei_insn_o = 1'b1;
          end
          default: illegal_insn_o = 1'b1;
        endcase
      end

      OPCODE_SYSTEM: begin
        // System instruction decoding
        if (instr_rdata_i[14:12] == 3'b000) begin
          // Handle specific system instructions
          if ({instr_rdata_i[19:15], instr_rdata_i[11:7]} == '0) begin
            unique case (instr_rdata_i[31:20])
              12'h000: ecall_insn_o = 1'b1;  // ECALL instruction
              12'h001: ebrk_insn_o = 1'b1;  // EBREAK instruction
              12'h302: begin
                illegal_insn_o = 1'b0;
                mret_insn_o    = ~illegal_insn_o;
                mret_dec_o     = 1'b1;
              end
              12'h002: begin
                illegal_insn_o = 1'b1;
                uret_insn_o    = ~illegal_insn_o;
                uret_dec_o     = 1'b1;
              end
              12'h7b2: begin
                illegal_insn_o = !debug_mode_i;
                dret_insn_o    = debug_mode_i;
                dret_dec_o     = 1'b1;
              end
              12'h105: begin
                wfi_o = 1'b1;
                if (debug_wfi_no_sleep_i) begin
                  alu_op_b_mux_sel_o = OP_B_IMM;
                  imm_b_mux_sel_o = IMMB_I;
                  alu_operator_o = ALU_ADD;
                end
              end
              default: illegal_insn_o = 1'b1;
            endcase
          end else illegal_insn_o = 1'b1;
        end else begin
          // Handle CSR instructions
          csr_access_o       = 1'b1;
          regfile_alu_we     = 1'b1;
          alu_op_b_mux_sel_o = OP_B_IMM;
          imm_a_mux_sel_o    = IMMA_Z;
          imm_b_mux_sel_o    = IMMB_I;

          if (instr_rdata_i[14] == 1'b1) begin
            alu_op_a_mux_sel_o = OP_A_IMM;
          end else begin
            rega_used_o        = 1'b1;
            alu_op_a_mux_sel_o = OP_A_REGA_OR_FWD;
          end

          unique case (instr_rdata_i[13:12])
            2'b01:   csr_op = CSR_OP_WRITE;
            2'b10:   csr_op = instr_rdata_i[19:15] == 5'b0 ? CSR_OP_READ : CSR_OP_SET;
            2'b11:   csr_op = instr_rdata_i[19:15] == 5'b0 ? CSR_OP_READ : CSR_OP_CLEAR;
            default: csr_illegal = 1'b1;
          endcase

          if (instr_rdata_i[29:28] > current_priv_lvl_i) begin
            csr_illegal = 1'b1;
          end

          case (instr_rdata_i[31:20])
            CSR_FFLAGS: if (fs_off_i == 1'b1) csr_illegal = 1'b1;
            CSR_FRM, CSR_FCSR:
            if (fs_off_i == 1'b1) begin
              csr_illegal = 1'b1;
            end else begin
              if (csr_op != CSR_OP_READ) csr_status_o = 1'b1;
            end
            CSR_MVENDORID, CSR_MARCHID, CSR_MIMPID, CSR_MHARTID:
            if (csr_op != CSR_OP_READ) csr_illegal = 1'b1;
            CSR_MSTATUS, CSR_MEPC, CSR_MTVEC, CSR_MCAUSE: csr_status_o = 1'b1;
            CSR_MISA, CSR_MIE, CSR_MSCRATCH, CSR_MTVAL, CSR_MIP: ;
            CSR_MCYCLE, CSR_MINSTRET, CSR_MHPMCOUNTER3, CSR_MHPMCOUNTER4, CSR_MHPMCOUNTER5,
            CSR_MHPMCOUNTER6, CSR_MHPMCOUNTER7, CSR_MHPMCOUNTER8, CSR_MHPMCOUNTER9,
            CSR_MHPMCOUNTER10, CSR_MHPMCOUNTER11, CSR_MHPMCOUNTER12, CSR_MHPMCOUNTER13,
            CSR_MHPMCOUNTER14, CSR_MHPMCOUNTER15, CSR_MHPMCOUNTER16, CSR_MHPMCOUNTER17,
            CSR_MHPMCOUNTER18, CSR_MHPMCOUNTER19, CSR_MHPMCOUNTER20, CSR_MHPMCOUNTER21,
            CSR_MHPMCOUNTER22, CSR_MHPMCOUNTER23, CSR_MHPMCOUNTER24, CSR_MHPMCOUNTER25,
            CSR_MHPMCOUNTER26, CSR_MHPMCOUNTER27, CSR_MHPMCOUNTER28, CSR_MHPMCOUNTER29,
            CSR_MHPMCOUNTER30, CSR_MHPMCOUNTER31, CSR_MCYCLEH, CSR_MINSTRETH, CSR_MHPMCOUNTER3H,
            CSR_MHPMCOUNTER4H, CSR_MHPMCOUNTER5H, CSR_MHPMCOUNTER6H, CSR_MHPMCOUNTER7H,
            CSR_MHPMCOUNTER8H, CSR_MHPMCOUNTER9H, CSR_MHPMCOUNTER10H, CSR_MHPMCOUNTER11H,
            CSR_MHPMCOUNTER12H, CSR_MHPMCOUNTER13H, CSR_MHPMCOUNTER14H, CSR_MHPMCOUNTER15H,
            CSR_MHPMCOUNTER16H, CSR_MHPMCOUNTER17H, CSR_MHPMCOUNTER18H, CSR_MHPMCOUNTER19H,
            CSR_MHPMCOUNTER20H, CSR_MHPMCOUNTER21H, CSR_MHPMCOUNTER22H, CSR_MHPMCOUNTER23H,
            CSR_MHPMCOUNTER24H, CSR_MHPMCOUNTER25H, CSR_MHPMCOUNTER26H, CSR_MHPMCOUNTER27H,
            CSR_MHPMCOUNTER28H, CSR_MHPMCOUNTER29H, CSR_MHPMCOUNTER30H, CSR_MHPMCOUNTER31H,
            CSR_MCOUNTINHIBIT, CSR_MHPMEVENT3, CSR_MHPMEVENT4, CSR_MHPMEVENT5, CSR_MHPMEVENT6,
            CSR_MHPMEVENT7, CSR_MHPMEVENT8, CSR_MHPMEVENT9, CSR_MHPMEVENT10, CSR_MHPMEVENT11,
            CSR_MHPMEVENT12, CSR_MHPMEVENT13, CSR_MHPMEVENT14, CSR_MHPMEVENT15, CSR_MHPMEVENT16,
            CSR_MHPMEVENT17, CSR_MHPMEVENT18, CSR_MHPMEVENT19, CSR_MHPMEVENT20, CSR_MHPMEVENT21,
            CSR_MHPMEVENT22, CSR_MHPMEVENT23, CSR_MHPMEVENT24, CSR_MHPMEVENT25, CSR_MHPMEVENT26,
            CSR_MHPMEVENT27, CSR_MHPMEVENT28, CSR_MHPMEVENT29, CSR_MHPMEVENT30, CSR_MHPMEVENT31:
            csr_status_o = 1'b1;
            CSR_CYCLE, CSR_INSTRET, CSR_HPMCOUNTER3, CSR_HPMCOUNTER4, CSR_HPMCOUNTER5,
            CSR_HPMCOUNTER6, CSR_HPMCOUNTER7, CSR_HPMCOUNTER8, CSR_HPMCOUNTER9, CSR_HPMCOUNTER10,
            CSR_HPMCOUNTER11, CSR_HPMCOUNTER12, CSR_HPMCOUNTER13, CSR_HPMCOUNTER14,
            CSR_HPMCOUNTER15, CSR_HPMCOUNTER16, CSR_HPMCOUNTER17, CSR_HPMCOUNTER18,
            CSR_HPMCOUNTER19, CSR_HPMCOUNTER20, CSR_HPMCOUNTER21, CSR_HPMCOUNTER22,
            CSR_HPMCOUNTER23, CSR_HPMCOUNTER24, CSR_HPMCOUNTER25, CSR_HPMCOUNTER26,
            CSR_HPMCOUNTER27, CSR_HPMCOUNTER28, CSR_HPMCOUNTER29, CSR_HPMCOUNTER30,
            CSR_HPMCOUNTER31, CSR_CYCLEH, CSR_INSTRETH, CSR_HPMCOUNTER3H, CSR_HPMCOUNTER4H,
            CSR_HPMCOUNTER5H, CSR_HPMCOUNTER6H, CSR_HPMCOUNTER7H, CSR_HPMCOUNTER8H,
            CSR_HPMCOUNTER9H, CSR_HPMCOUNTER10H, CSR_HPMCOUNTER11H, CSR_HPMCOUNTER12H,
            CSR_HPMCOUNTER13H, CSR_HPMCOUNTER14H, CSR_HPMCOUNTER15H, CSR_HPMCOUNTER16H,
            CSR_HPMCOUNTER17H, CSR_HPMCOUNTER18H, CSR_HPMCOUNTER19H, CSR_HPMCOUNTER20H,
            CSR_HPMCOUNTER21H, CSR_HPMCOUNTER22H, CSR_HPMCOUNTER23H, CSR_HPMCOUNTER24H,
            CSR_HPMCOUNTER25H, CSR_HPMCOUNTER26H, CSR_HPMCOUNTER27H, CSR_HPMCOUNTER28H,
            CSR_HPMCOUNTER29H, CSR_HPMCOUNTER30H, CSR_HPMCOUNTER31H:
            if ((csr_op != CSR_OP_READ)) begin
              csr_illegal = 1'b1;
            end else begin
              csr_status_o = 1'b1;
            end
            CSR_MCOUNTEREN: csr_illegal = 1'b1;
            CSR_DCSR, CSR_DPC, CSR_DSCRATCH0, CSR_DSCRATCH1:
            if (!debug_mode_i) begin
              csr_illegal = 1'b1;
            end else begin
              csr_status_o = 1'b1;
            end
            CSR_TSELECT, CSR_TDATA1, CSR_TDATA2, CSR_TDATA3, CSR_TINFO, CSR_MCONTEXT, CSR_SCONTEXT:
            if (DEBUG_TRIGGER_EN != 1) csr_illegal = 1'b1;
            CSR_LPSTART0, CSR_LPEND0, CSR_LPCOUNT0, CSR_LPSTART1, CSR_LPEND1, CSR_LPCOUNT1:
            csr_illegal = 1'b1;
            CSR_UHARTID: csr_illegal = 1'b1;
            CSR_PRIVLV: csr_illegal = 1'b1;
            CSR_ZFINX: csr_illegal = 1'b1;
            CSR_PMPCFG0, CSR_PMPCFG1, CSR_PMPCFG2, CSR_PMPCFG3, CSR_PMPADDR0, CSR_PMPADDR1,
            CSR_PMPADDR2, CSR_PMPADDR3, CSR_PMPADDR4, CSR_PMPADDR5, CSR_PMPADDR6, CSR_PMPADDR7,
            CSR_PMPADDR8, CSR_PMPADDR9, CSR_PMPADDR10, CSR_PMPADDR11, CSR_PMPADDR12, CSR_PMPADDR13,
            CSR_PMPADDR14, CSR_PMPADDR15:
            csr_illegal = 1'b1;
            CSR_USTATUS, CSR_UEPC, CSR_UTVEC, CSR_UCAUSE: csr_illegal = 1'b1;
            default: csr_illegal = 1'b1;
          endcase

          illegal_insn_o = csr_illegal;
        end
      end
      default: illegal_insn_o = 1'b1;
    endcase

    // Handle compressed instruction illegal flag
    if (illegal_c_insn_i) begin
      illegal_insn_o = 1'b1;
    end
  end

  // Output assignments
  assign alu_en_o                    = (deassert_we_i) ? 1'b0 : alu_en;
  assign mult_int_en_o               = (deassert_we_i) ? 1'b0 : mult_int_en;
  assign mult_dot_en_o               = (deassert_we_i) ? 1'b0 : mult_dot_en;
  assign apu_en_o                    = (deassert_we_i) ? 1'b0 : apu_en;
  assign regfile_mem_we_o            = (deassert_we_i) ? 1'b0 : regfile_mem_we;
  assign regfile_alu_we_o            = (deassert_we_i) ? 1'b0 : regfile_alu_we;
  assign data_req_o                  = (deassert_we_i) ? 1'b0 : data_req;
  assign hwlp_we_o                   = (deassert_we_i) ? 3'b0 : hwlp_we;
  assign csr_op_o                    = (deassert_we_i) ? CSR_OP_READ : csr_op;
  assign ctrl_transfer_insn_in_id_o  = (deassert_we_i) ? BRANCH_NONE : ctrl_transfer_insn;

  assign ctrl_transfer_insn_in_dec_o = ctrl_transfer_insn;
  assign regfile_alu_we_dec_o        = regfile_alu_we;

endmodule
