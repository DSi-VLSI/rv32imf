module rv32imf_ex_stage
  import rv32imf_pkg::*;  // Import package for definitions
#(
) (
    // Clock input
    input logic clk,
    // Asynchronous reset input (active low)
    input logic rst_n,

    // ALU operation code input
    input alu_opcode_e        alu_operator_i,
    // First ALU operand input
    input logic        [31:0] alu_operand_a_i,
    // Second ALU operand input
    input logic        [31:0] alu_operand_b_i,
    // Third ALU operand input
    input logic        [31:0] alu_operand_c_i,
    // ALU enable input
    input logic               alu_en_i,
    // Bitmask A for ALU input
    input logic        [ 4:0] bmask_a_i,
    // Bitmask B for ALU input
    input logic        [ 4:0] bmask_b_i,
    // Immediate vector extension type for ALU
    input logic        [ 1:0] imm_vec_ext_i,
    // ALU vector mode input
    input logic        [ 1:0] alu_vec_mode_i,
    // ALU is complex operation input
    input logic               alu_is_clpx_i,
    // ALU is sub-rotation operation input
    input logic               alu_is_subrot_i,
    // ALU complex shift amount input
    input logic        [ 1:0] alu_clpx_shift_i,

    // Multiplier operation code input
    input mul_opcode_e        mult_operator_i,
    // First multiplier operand input
    input logic        [31:0] mult_operand_a_i,
    // Second multiplier operand input
    input logic        [31:0] mult_operand_b_i,
    // Third multiplier operand input
    input logic        [31:0] mult_operand_c_i,
    // Multiplier enable input
    input logic               mult_en_i,
    // Multiplier select subword input
    input logic               mult_sel_subword_i,
    // Multiplier signed mode input
    input logic        [ 1:0] mult_signed_mode_i,
    // Multiplier immediate input
    input logic        [ 4:0] mult_imm_i,

    // Multiplier dot product operand A input
    input logic [31:0] mult_dot_op_a_i,
    // Multiplier dot product operand B input
    input logic [31:0] mult_dot_op_b_i,
    // Multiplier dot product operand C input
    input logic [31:0] mult_dot_op_c_i,
    // Multiplier dot product signed mode input
    input logic [ 1:0] mult_dot_signed_i,
    // Multiplier is complex operation input
    input logic        mult_is_clpx_i,
    // Multiplier complex shift amount input
    input logic [ 1:0] mult_clpx_shift_i,
    // Multiplier complex imaginary part input
    input logic        mult_clpx_img_i,

    // Multiplier multi-cycle output
    output logic mult_multicycle_o,

    // Data request input
    input logic data_req_i,
    // Data response valid input
    input logic data_rvalid_i,
    // Data misaligned exception input
    input logic data_misaligned_ex_i,
    // Data misaligned input
    input logic data_misaligned_i,

    // Control transfer instruction type
    input logic [1:0] ctrl_transfer_insn_in_dec_i,

    // FPU flags write enable output
    output logic       fpu_fflags_we_o,
    // FPU flags output
    output logic [4:0] fpu_fflags_o,

    // APU enable input
    input logic             apu_en_i,
    // APU operation code input
    input logic [5:0]       apu_op_i,
    // APU latency input
    input logic [1:0]       apu_lat_i,
    // APU operands input
    input logic [2:0][31:0] apu_operands_i,
    // APU write address input
    input logic [5:0]       apu_waddr_i,
    // APU flags input
    input logic [4:0]       apu_flags_i,

    // APU read register addresses input
    input  logic [2:0][5:0] apu_read_regs_i,
    // APU read register valid flags input
    input  logic [2:0]      apu_read_regs_valid_i,
    // APU read dependency output
    output logic            apu_read_dep_o,
    // APU read dependency for JALR output
    output logic            apu_read_dep_for_jalr_o,
    // APU write register addresses input
    input  logic [1:0][5:0] apu_write_regs_i,
    // APU write register valid flags input
    input  logic [1:0]      apu_write_regs_valid_i,
    // APU write dependency output
    output logic            apu_write_dep_o,

    // APU performance type output
    output logic apu_perf_type_o,
    // APU performance contention output
    output logic apu_perf_cont_o,
    // APU performance writeback contention output
    output logic apu_perf_wb_o,

    // APU busy output
    output logic apu_busy_o,
    // APU ready for writeback output
    output logic apu_ready_wb_o,

    // APU request output
    output logic apu_req_o,
    // APU grant input
    input  logic apu_gnt_i,

    // APU operands output
    output logic [2:0][31:0] apu_operands_o,
    // APU operation code output
    output logic [5:0]       apu_op_o,

    // APU response valid input
    input logic        apu_rvalid_i,
    // APU result input
    input logic [31:0] apu_result_i,

    // LSU enable input
    input logic        lsu_en_i,
    // LSU read data input
    input logic [31:0] lsu_rdata_i,

    // Branch instruction in execute stage input
    input logic       branch_in_ex_i,
    // ALU write address to register file input
    input logic [5:0] regfile_alu_waddr_i,
    // ALU write enable to register file input
    input logic       regfile_alu_we_i,

    // Write enable to register file input
    input logic       regfile_we_i,
    // Write address to register file input
    input logic [5:0] regfile_waddr_i,

    // CSR access input
    input logic        csr_access_i,
    // CSR read data input
    input logic [31:0] csr_rdata_i,

    // Writeback register file write address output
    output logic [5:0] regfile_waddr_wb_o,
    // Writeback register file write enable output
    output logic regfile_we_wb_o,
    // Writeback register file write enable power output
    output logic regfile_we_wb_power_o,
    // Writeback register file write data output
    output logic [31:0] regfile_wdata_wb_o,

    // Forwarding ALU write address to register file output
    output logic [ 5:0] regfile_alu_waddr_fw_o,
    // Forwarding ALU write enable to register file output
    output logic        regfile_alu_we_fw_o,
    // Forwarding ALU write enable power output
    output logic        regfile_alu_we_fw_power_o,
    // Forwarding ALU write data to register file output
    output logic [31:0] regfile_alu_wdata_fw_o,

    // Jump target output
    output logic [31:0] jump_target_o,
    // Branch decision output
    output logic        branch_decision_o,

    // Decoding stage active input
    input logic is_decoding_i,
    // LSU ready in execute stage input
    input logic lsu_ready_ex_i,
    // LSU error input
    input logic lsu_err_i,

    // Execute stage ready output
    output logic ex_ready_o,
    // Execute stage valid output
    output logic ex_valid_o,
    // Writeback stage ready input
    input  logic wb_ready_i
);

  logic [31:0] alu_result;  // Result from ALU
  logic [31:0] mult_result;  // Result from Multiplier
  logic        alu_cmp_result;  // Result from ALU comparison

  logic        regfile_we_lsu;  // Write enable to register file from LSU
  logic [ 5:0] regfile_waddr_lsu;  // Write address to register file from LSU

  logic        wb_contention;  // Writeback contention flag
  logic        wb_contention_lsu;  // Writeback contention flag for LSU

  logic        alu_ready;  // ALU ready flag
  logic        mulh_active;  // MULH operation active flag
  logic        mult_ready;  // Multiplier ready flag

  logic        apu_valid;  // APU operation valid flag
  logic [ 5:0] apu_waddr;  // APU write address
  logic [31:0] apu_result;  // APU result
  logic        apu_stall;  // APU stall flag
  logic        apu_active;  // APU active flag
  logic        apu_singlecycle;  // APU single-cycle operation flag
  logic        apu_multicycle;  // APU multi-cycle operation flag
  logic        apu_req;  // APU request signal
  logic        apu_gnt;  // APU grant signal

  logic        apu_rvalid_q;  // Queued APU response valid
  logic [31:0] apu_result_q;  // Queued APU result
  logic [ 4:0] apu_flags_q;  // Queued APU flags


  always_comb begin
    regfile_alu_wdata_fw_o    = '0;  // Default ALU forward data
    regfile_alu_waddr_fw_o    = '0;  // Default ALU forward address
    regfile_alu_we_fw_o       = 1'b0;  // Default ALU forward write enable
    regfile_alu_we_fw_power_o = 1'b0;  // Default ALU forward write enable power
    wb_contention             = 1'b0;  // Default writeback contention

    if (apu_valid & (apu_singlecycle | apu_multicycle)) begin
      regfile_alu_we_fw_o       = 1'b1;  // Enable forwarding from APU
      regfile_alu_we_fw_power_o = 1'b1;  // Enable forwarding power from APU
      regfile_alu_waddr_fw_o    = apu_waddr;  // Forward APU write address
      regfile_alu_wdata_fw_o    = apu_result;  // Forward APU result

      if (regfile_alu_we_i & ~apu_en_i) begin
        wb_contention = 1'b1;  // Detect writeback contention with ALU
      end
    end else begin
      // Forward from ALU if not APU
      regfile_alu_we_fw_o = regfile_alu_we_i & ~apu_en_i;
      // Forward power from ALU if not APU
      regfile_alu_we_fw_power_o = regfile_alu_we_i & ~apu_en_i;
      // Forward ALU write address
      regfile_alu_waddr_fw_o = regfile_alu_waddr_i;
      // Forward ALU result
      if (alu_en_i) regfile_alu_wdata_fw_o = alu_result;
      // Forward Multiplier result
      if (mult_en_i) regfile_alu_wdata_fw_o = mult_result;
      // Forward CSR read data
      if (csr_access_i) regfile_alu_wdata_fw_o = csr_rdata_i;
    end
  end


  always_comb begin
    regfile_we_wb_o       = 1'b0;  // Default writeback enable
    regfile_we_wb_power_o = 1'b0;  // Default writeback enable power
    regfile_waddr_wb_o    = regfile_waddr_lsu;  // Default writeback address from LSU
    regfile_wdata_wb_o    = lsu_rdata_i;  // Default writeback data from LSU
    wb_contention_lsu     = 1'b0;  // Default LSU writeback contention

    if (regfile_we_lsu) begin
      regfile_we_wb_o       = 1'b1;  // Enable writeback from LSU
      regfile_we_wb_power_o = 1'b1;  // Enable writeback power from LSU
      if (apu_valid & (!apu_singlecycle & !apu_multicycle)) begin
        wb_contention_lsu = 1'b1;  // Detect writeback contention with APU
      end

    end else if (apu_valid & (!apu_singlecycle & !apu_multicycle)) begin
      regfile_we_wb_o       = 1'b1;  // Enable writeback from APU
      regfile_we_wb_power_o = 1'b1;  // Enable writeback power from APU
      regfile_waddr_wb_o    = apu_waddr;  // Writeback APU write address
      regfile_wdata_wb_o    = apu_result;  // Writeback APU result
    end
  end


  assign branch_decision_o = alu_cmp_result;  // Output branch decision from ALU comparison
  assign jump_target_o     = alu_operand_c_i;  // Output jump target from ALU operand C


  rv32imf_alu alu_i (  // Instantiate ALU module
      .clk        (clk),
      .rst_n      (rst_n),
      .enable_i   (alu_en_i),
      .operator_i (alu_operator_i),
      .operand_a_i(alu_operand_a_i),
      .operand_b_i(alu_operand_b_i),
      .operand_c_i(alu_operand_c_i),

      .vector_mode_i(alu_vec_mode_i),
      .bmask_a_i    (bmask_a_i),
      .bmask_b_i    (bmask_b_i),
      .imm_vec_ext_i(imm_vec_ext_i),

      .is_clpx_i   (alu_is_clpx_i),
      .clpx_shift_i(alu_clpx_shift_i),
      .is_subrot_i (alu_is_subrot_i),

      .result_o           (alu_result),
      .comparison_result_o(alu_cmp_result),

      .ready_o   (alu_ready),
      .ex_ready_i(ex_ready_o)
  );


  rv32imf_mult mult_i (  // Instantiate Multiplier module
      .clk  (clk),
      .rst_n(rst_n),

      .enable_i  (mult_en_i),
      .operator_i(mult_operator_i),

      .short_subword_i(mult_sel_subword_i),
      .short_signed_i (mult_signed_mode_i),

      .op_a_i(mult_operand_a_i),
      .op_b_i(mult_operand_b_i),
      .op_c_i(mult_operand_c_i),
      .imm_i (mult_imm_i),

      .dot_op_a_i  (mult_dot_op_a_i),
      .dot_op_b_i  (mult_dot_op_b_i),
      .dot_op_c_i  (mult_dot_op_c_i),
      .dot_signed_i(mult_dot_signed_i),
      .is_clpx_i   (mult_is_clpx_i),
      .clpx_shift_i(mult_clpx_shift_i),
      .clpx_img_i  (mult_clpx_img_i),

      .result_o(mult_result),

      .multicycle_o (mult_multicycle_o),
      .mulh_active_o(mulh_active),
      .ready_o      (mult_ready),
      .ex_ready_i   (ex_ready_o)
  );


  rv32imf_apu_disp apu_disp_i (  // Instantiate APU Dispatcher module
      .clk_i (clk),
      .rst_ni(rst_n),

      .enable_i   (apu_en_i),
      .apu_lat_i  (apu_lat_i),
      .apu_waddr_i(apu_waddr_i),

      .apu_waddr_o      (apu_waddr),
      .apu_multicycle_o (apu_multicycle),
      .apu_singlecycle_o(apu_singlecycle),

      .active_o(apu_active),
      .stall_o (apu_stall),

      .is_decoding_i      (is_decoding_i),
      .read_regs_i        (apu_read_regs_i),
      .read_regs_valid_i  (apu_read_regs_valid_i),
      .read_dep_o         (apu_read_dep_o),
      .read_dep_for_jalr_o(apu_read_dep_for_jalr_o),
      .write_regs_i       (apu_write_regs_i),
      .write_regs_valid_i (apu_write_regs_valid_i),
      .write_dep_o        (apu_write_dep_o),

      .perf_type_o(apu_perf_type_o),
      .perf_cont_o(apu_perf_cont_o),

      .apu_req_o(apu_req),
      .apu_gnt_i(apu_gnt),

      .apu_rvalid_i(apu_valid)
  );

  // APU performance writeback contention
  assign apu_perf_wb_o  = wb_contention | wb_contention_lsu;
  // APU ready for writeback
  assign apu_ready_wb_o = ~(apu_active | apu_en_i | apu_stall) | apu_valid;

  always_ff @(posedge clk, negedge rst_n) begin : APU_Result_Memorization
    if (~rst_n) begin
      apu_rvalid_q <= 1'b0;  // Reset queued APU response valid
      apu_result_q <= 'b0;  // Reset queued APU result
      apu_flags_q  <= 'b0;  // Reset queued APU flags
    end else begin
      if (apu_rvalid_i && apu_multicycle &&
          (data_misaligned_i || data_misaligned_ex_i ||
           ((data_req_i || data_rvalid_i) && regfile_alu_we_i) ||
           (mulh_active && (mult_operator_i == MUL_H)) ||
           ((ctrl_transfer_insn_in_dec_i == BRANCH_JALR) &&
            regfile_alu_we_i && ~apu_read_dep_for_jalr_o))) begin
        apu_rvalid_q <= 1'b1;  // Queue APU response valid
        apu_result_q <= apu_result_i;  // Queue APU result
        apu_flags_q  <= apu_flags_i;  // Queue APU flags
      end else if (apu_rvalid_q && !(data_misaligned_i || data_misaligned_ex_i ||
                                       ((data_req_i || data_rvalid_i) && regfile_alu_we_i) ||
                                       (mulh_active && (mult_operator_i == MUL_H)) ||
                                       ((ctrl_transfer_insn_in_dec_i == BRANCH_JALR) &&
                                        regfile_alu_we_i && ~apu_read_dep_for_jalr_o))) begin
        apu_rvalid_q <= 1'b0;  // Dequeue APU response valid
      end
    end
  end

  assign apu_req_o = apu_req;  // Output APU request
  assign apu_gnt = apu_gnt_i;  // Assign APU grant
  assign apu_valid      = (apu_multicycle && (data_misaligned_i || data_misaligned_ex_i ||
                          ((data_req_i || data_rvalid_i) && regfile_alu_we_i) ||
                          (mulh_active && (mult_operator_i == MUL_H)) ||
                          ((ctrl_transfer_insn_in_dec_i == BRANCH_JALR) &&
                           regfile_alu_we_i && ~apu_read_dep_for_jalr_o)))
                            ? 1'b0 : (apu_rvalid_i || apu_rvalid_q); // APU valid condition
  assign apu_operands_o = apu_operands_i;  // Output APU operands
  assign apu_op_o = apu_op_i;  // Output APU operation code
  assign apu_result = apu_rvalid_q ? apu_result_q : apu_result_i;  // Select APU result
  assign fpu_fflags_we_o = apu_valid;  // FPU flags write enable
  assign fpu_fflags_o = apu_rvalid_q ? apu_flags_q : apu_flags_i;  // Select FPU flags

  assign apu_busy_o = apu_active;  // Output APU busy status


  always_ff @(posedge clk, negedge rst_n) begin : EX_WB_Pipeline_Register
    if (~rst_n) begin
      regfile_waddr_lsu <= '0; // Reset LSU write address
      regfile_we_lsu    <= 1'b0; // Reset LSU write enable
    end else begin
      if (ex_valid_o) begin
        regfile_we_lsu <= regfile_we_i & ~lsu_err_i;  // Enable LSU write if valid and no error
        if (regfile_we_i & ~lsu_err_i) begin
          regfile_waddr_lsu <= regfile_waddr_i;  // Store LSU write address
        end
      end else if (wb_ready_i) begin
        regfile_we_lsu <= 1'b0;  // Disable LSU write if writeback is ready
      end
    end
  end


  // Execute stage ready condition
  assign ex_ready_o = (~apu_stall & alu_ready & mult_ready & lsu_ready_ex_i
                        & wb_ready_i & ~wb_contention) | (branch_in_ex_i);
  // Execute stage valid condition
  assign ex_valid_o = (apu_valid | alu_en_i | mult_en_i | csr_access_i | lsu_en_i)
                        & (alu_ready & mult_ready & lsu_ready_ex_i & wb_ready_i);

endmodule
