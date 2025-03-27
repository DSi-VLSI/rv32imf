module rv32imf_core #(
) (

    input logic clk_i,
    input logic rst_ni,

    input logic [31:0] boot_addr_i,
    input logic [31:0] mtvec_addr_i,
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


    output logic apu_busy_o,

    output logic apu_req_o,
    input  logic apu_gnt_i,

    output logic [ 2:0][31:0] apu_operands_o,
    output logic [ 5:0]       apu_op_o,
    output logic [14:0]       apu_flags_o,

    input logic        apu_rvalid_i,
    input logic [31:0] apu_result_i,
    input logic [ 4:0] apu_flags_i,


    input  logic [31:0] irq_i,
    output logic        irq_ack_o,
    output logic [ 4:0] irq_id_o
);

  import rv32imf_pkg::*;


  localparam int N_PMP_ENTRIES = 16;
  localparam int DEBUG_TRIGGER_EN = 1;

  logic [5:0] data_atop_o;
  logic       irq_sec_i;
  logic       sec_lvl_o;

  localparam N_HWLP = 2;

  logic        instr_valid_id;
  logic [31:0] instr_rdata_id;
  logic        is_compressed_id;
  logic        illegal_c_insn_id;
  logic        is_fetch_failed_id;

  logic        clear_instr_valid;
  logic        pc_set;

  logic [ 3:0] pc_mux_id;
  logic [ 2:0] exc_pc_mux_id;
  logic [ 4:0] m_exc_vec_pc_mux_id;
  logic [ 4:0] u_exc_vec_pc_mux_id;
  logic [ 4:0] exc_cause;

  logic [ 1:0] trap_addr_mux;

  logic [31:0] pc_if;
  logic [31:0] pc_id;


  logic        is_decoding;

  logic        useincr_addr_ex;
  logic        data_misaligned;

  logic        mult_multicycle;


  logic [31:0] jump_target_id, jump_target_ex;
  logic               branch_in_ex;
  logic               branch_decision;
  logic        [ 1:0] ctrl_transfer_insn_in_dec;

  logic               ctrl_busy;
  logic               if_busy;
  logic               lsu_busy;

  logic        [31:0] pc_ex;


  logic               alu_en_ex;
  alu_opcode_e        alu_operator_ex;
  logic        [31:0] alu_operand_a_ex;
  logic        [31:0] alu_operand_b_ex;
  logic        [31:0] alu_operand_c_ex;
  logic        [ 4:0] bmask_a_ex;
  logic        [ 4:0] bmask_b_ex;
  logic        [ 1:0] imm_vec_ext_ex;
  logic        [ 1:0] alu_vec_mode_ex;
  logic alu_is_clpx_ex, alu_is_subrot_ex;
  logic        [        1:0]       alu_clpx_shift_ex;


  mul_opcode_e                     mult_operator_ex;
  logic        [       31:0]       mult_operand_a_ex;
  logic        [       31:0]       mult_operand_b_ex;
  logic        [       31:0]       mult_operand_c_ex;
  logic                            mult_en_ex;
  logic                            mult_sel_subword_ex;
  logic        [        1:0]       mult_signed_mode_ex;
  logic        [        4:0]       mult_imm_ex;
  logic        [       31:0]       mult_dot_op_a_ex;
  logic        [       31:0]       mult_dot_op_b_ex;
  logic        [       31:0]       mult_dot_op_c_ex;
  logic        [        1:0]       mult_dot_signed_ex;
  logic                            mult_is_clpx_ex;
  logic        [        1:0]       mult_clpx_shift_ex;
  logic                            mult_clpx_img_ex;


  logic                            fs_off;
  logic        [   C_RM-1:0]       frm_csr;
  logic        [C_FFLAG-1:0]       fflags_csr;
  logic                            fflags_we;
  logic                            fregs_we;


  logic                            apu_en_ex;
  logic        [       14:0]       apu_flags_ex;
  logic        [        5:0]       apu_op_ex;
  logic        [        1:0]       apu_lat_ex;
  logic        [        2:0][31:0] apu_operands_ex;
  logic        [        5:0]       apu_waddr_ex;

  logic        [        2:0][ 5:0] apu_read_regs;
  logic        [        2:0]       apu_read_regs_valid;
  logic                            apu_read_dep;
  logic                            apu_read_dep_for_jalr;
  logic        [        1:0][ 5:0] apu_write_regs;
  logic        [        1:0]       apu_write_regs_valid;
  logic                            apu_write_dep;

  logic                            perf_apu_type;
  logic                            perf_apu_cont;
  logic                            perf_apu_dep;
  logic                            perf_apu_wb;


  logic        [        5:0]       regfile_waddr_ex;
  logic                            regfile_we_ex;
  logic        [        5:0]       regfile_waddr_fw_wb_o;
  logic                            regfile_we_wb;
  logic                            regfile_we_wb_power;
  logic        [       31:0]       regfile_wdata;

  logic        [        5:0]       regfile_alu_waddr_ex;
  logic                            regfile_alu_we_ex;

  logic        [        5:0]       regfile_alu_waddr_fw;
  logic                            regfile_alu_we_fw;
  logic                            regfile_alu_we_fw_power;
  logic        [       31:0]       regfile_alu_wdata_fw;


  logic                            csr_access_ex;
  csr_opcode_e                     csr_op_ex;
  logic [23:0] mtvec, utvec;
  logic        [ 1:0] mtvec_mode;
  logic        [ 1:0] utvec_mode;

  csr_opcode_e        csr_op;
  csr_num_e           csr_addr;
  csr_num_e           csr_addr_int;
  logic        [31:0] csr_rdata;
  logic        [31:0] csr_wdata;
  priv_lvl_t          current_priv_lvl;


  logic               data_we_ex;
  logic        [ 5:0] data_atop_ex;
  logic        [ 1:0] data_type_ex;
  logic        [ 1:0] data_sign_ext_ex;
  logic        [ 1:0] data_reg_offset_ex;
  logic               data_req_ex;
  logic               data_load_event_ex;
  logic               data_misaligned_ex;

  logic               p_elw_start;
  logic               p_elw_finish;

  logic        [31:0] lsu_rdata;


  logic               halt_if;
  logic               id_ready;
  logic               ex_ready;

  logic               id_valid;
  logic               ex_valid;
  logic               wb_valid;

  logic               lsu_ready_ex;
  logic               lsu_ready_wb;

  logic               apu_ready_wb;


  logic               instr_req_int;


  logic m_irq_enable, u_irq_enable;
  logic csr_irq_sec;
  logic [31:0] mepc, uepc, depc;
  logic [             31:0]       mie_bypass;
  logic [             31:0]       mip;

  logic                           csr_save_cause;
  logic                           csr_save_if;
  logic                           csr_save_id;
  logic                           csr_save_ex;
  logic [              5:0]       csr_cause;
  logic                           csr_restore_mret_id;
  logic                           csr_restore_uret_id;
  logic                           csr_restore_dret_id;
  logic                           csr_mtvec_init;


  logic [             31:0]       mcounteren;


  logic                           debug_mode;
  logic [              2:0]       debug_cause;
  logic                           debug_csr_save;
  logic                           debug_single_step;
  logic                           debug_ebreakm;
  logic                           debug_ebreaku;
  logic                           trigger_match;
  logic                           debug_p_elw_no_sleep;


  logic [       N_HWLP-1:0][31:0] hwlp_start;
  logic [       N_HWLP-1:0][31:0] hwlp_end;
  logic [       N_HWLP-1:0][31:0] hwlp_cnt;

  logic [             31:0]       hwlp_target;


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

  logic                           perf_imiss;


  logic                           wake_from_sleep;


  logic [N_PMP_ENTRIES-1:0][31:0] pmp_addr;
  logic [N_PMP_ENTRIES-1:0][ 7:0] pmp_cfg;

  logic                           data_req_pmp;
  logic [             31:0]       data_addr_pmp;
  logic                           data_gnt_pmp;
  logic                           data_err_pmp;
  logic                           data_err_ack;
  logic                           instr_req_pmp;
  logic                           instr_gnt_pmp;
  logic [             31:0]       instr_addr_pmp;
  logic                           instr_err_pmp;


  assign m_exc_vec_pc_mux_id = (mtvec_mode == 2'b0) ? 5'h0 : exc_cause;
  assign u_exc_vec_pc_mux_id = (utvec_mode == 2'b0) ? 5'h0 : exc_cause;


  assign irq_sec_i = 1'b0;


  assign apu_flags_o = apu_flags_ex;










  logic clk;
  logic fetch_enable;

  rv32imf_sleep_unit #() sleep_unit_i (

      .clk_ungated_i(clk_i),
      .rst_n        (rst_ni),
      .clk_gated_o  (clk),


      .fetch_enable_o(fetch_enable),


      .if_busy_i  (if_busy),
      .ctrl_busy_i(ctrl_busy),
      .lsu_busy_i (lsu_busy),
      .apu_busy_i (apu_busy_o),


      .p_elw_start_i (p_elw_start),
      .p_elw_finish_i(p_elw_finish),


      .wake_from_sleep_i(wake_from_sleep)
  );










  rv32imf_if_stage #() if_stage_i (
      .clk  (clk),
      .rst_n(rst_ni),


      .boot_addr_i        (boot_addr_i[31:0]),
      .dm_exception_addr_i(dm_exception_addr_i[31:0]),


      .dm_halt_addr_i(dm_halt_addr_i[31:0]),


      .m_trap_base_addr_i(mtvec),
      .u_trap_base_addr_i(utvec),
      .trap_addr_mux_i   (trap_addr_mux),


      .req_i(instr_req_int),


      .instr_req_o    (instr_req_pmp),
      .instr_addr_o   (instr_addr_pmp),
      .instr_gnt_i    (instr_gnt_pmp),
      .instr_rvalid_i (instr_rvalid_i),
      .instr_rdata_i  (instr_rdata_i),
      .instr_err_i    (1'b0),
      .instr_err_pmp_i(instr_err_pmp),


      .instr_valid_id_o (instr_valid_id),
      .instr_rdata_id_o (instr_rdata_id),
      .is_fetch_failed_o(is_fetch_failed_id),


      .clear_instr_valid_i(clear_instr_valid),
      .pc_set_i           (pc_set),

      .mepc_i(mepc),
      .uepc_i(uepc),

      .depc_i(depc),

      .pc_mux_i    (pc_mux_id),
      .exc_pc_mux_i(exc_pc_mux_id),


      .pc_id_o(pc_id),
      .pc_if_o(pc_if),

      .is_compressed_id_o (is_compressed_id),
      .illegal_c_insn_id_o(illegal_c_insn_id),

      .m_exc_vec_pc_mux_i(m_exc_vec_pc_mux_id),
      .u_exc_vec_pc_mux_i(u_exc_vec_pc_mux_id),

      .csr_mtvec_init_o(csr_mtvec_init),


      .hwlp_target_i(hwlp_target),



      .jump_target_id_i(jump_target_id),
      .jump_target_ex_i(jump_target_ex),


      .halt_if_i (halt_if),
      .id_ready_i(id_ready),

      .if_busy_o   (if_busy),
      .perf_imiss_o(perf_imiss)
  );










  rv32imf_id_stage #(
      .N_HWLP(N_HWLP)
  ) id_stage_i (
      .clk          (clk),
      .clk_ungated_i(clk_i),
      .rst_n        (rst_ni),


      .ctrl_busy_o  (ctrl_busy),
      .is_decoding_o(is_decoding),


      .instr_valid_i(instr_valid_id),
      .instr_rdata_i(instr_rdata_id),
      .instr_req_o  (instr_req_int),


      .branch_in_ex_o             (branch_in_ex),
      .branch_decision_i          (branch_decision),
      .jump_target_o              (jump_target_id),
      .ctrl_transfer_insn_in_dec_o(ctrl_transfer_insn_in_dec),


      .clear_instr_valid_o(clear_instr_valid),
      .pc_set_o           (pc_set),
      .pc_mux_o           (pc_mux_id),
      .exc_pc_mux_o       (exc_pc_mux_id),
      .exc_cause_o        (exc_cause),
      .trap_addr_mux_o    (trap_addr_mux),

      .is_fetch_failed_i(is_fetch_failed_id),

      .pc_id_i(pc_id),

      .is_compressed_i (is_compressed_id),
      .illegal_c_insn_i(illegal_c_insn_id),


      .halt_if_o(halt_if),

      .id_ready_o(id_ready),
      .ex_ready_i(ex_ready),
      .wb_ready_i(lsu_ready_wb),

      .id_valid_o(id_valid),
      .ex_valid_i(ex_valid),


      .pc_ex_o(pc_ex),

      .alu_en_ex_o        (alu_en_ex),
      .alu_operator_ex_o  (alu_operator_ex),
      .alu_operand_a_ex_o (alu_operand_a_ex),
      .alu_operand_b_ex_o (alu_operand_b_ex),
      .alu_operand_c_ex_o (alu_operand_c_ex),
      .bmask_a_ex_o       (bmask_a_ex),
      .bmask_b_ex_o       (bmask_b_ex),
      .imm_vec_ext_ex_o   (imm_vec_ext_ex),
      .alu_vec_mode_ex_o  (alu_vec_mode_ex),
      .alu_is_clpx_ex_o   (alu_is_clpx_ex),
      .alu_is_subrot_ex_o (alu_is_subrot_ex),
      .alu_clpx_shift_ex_o(alu_clpx_shift_ex),

      .regfile_waddr_ex_o(regfile_waddr_ex),
      .regfile_we_ex_o   (regfile_we_ex),

      .regfile_alu_we_ex_o   (regfile_alu_we_ex),
      .regfile_alu_waddr_ex_o(regfile_alu_waddr_ex),


      .mult_operator_ex_o   (mult_operator_ex),
      .mult_en_ex_o         (mult_en_ex),
      .mult_sel_subword_ex_o(mult_sel_subword_ex),
      .mult_signed_mode_ex_o(mult_signed_mode_ex),
      .mult_operand_a_ex_o  (mult_operand_a_ex),
      .mult_operand_b_ex_o  (mult_operand_b_ex),
      .mult_operand_c_ex_o  (mult_operand_c_ex),
      .mult_imm_ex_o        (mult_imm_ex),

      .mult_dot_op_a_ex_o  (mult_dot_op_a_ex),
      .mult_dot_op_b_ex_o  (mult_dot_op_b_ex),
      .mult_dot_op_c_ex_o  (mult_dot_op_c_ex),
      .mult_dot_signed_ex_o(mult_dot_signed_ex),
      .mult_is_clpx_ex_o   (mult_is_clpx_ex),
      .mult_clpx_shift_ex_o(mult_clpx_shift_ex),
      .mult_clpx_img_ex_o  (mult_clpx_img_ex),


      .fs_off_i(fs_off),
      .frm_i   (frm_csr),


      .apu_en_ex_o      (apu_en_ex),
      .apu_op_ex_o      (apu_op_ex),
      .apu_lat_ex_o     (apu_lat_ex),
      .apu_operands_ex_o(apu_operands_ex),
      .apu_flags_ex_o   (apu_flags_ex),
      .apu_waddr_ex_o   (apu_waddr_ex),

      .apu_read_regs_o        (apu_read_regs),
      .apu_read_regs_valid_o  (apu_read_regs_valid),
      .apu_read_dep_i         (apu_read_dep),
      .apu_read_dep_for_jalr_i(apu_read_dep_for_jalr),
      .apu_write_regs_o       (apu_write_regs),
      .apu_write_regs_valid_o (apu_write_regs_valid),
      .apu_write_dep_i        (apu_write_dep),
      .apu_perf_dep_o         (perf_apu_dep),
      .apu_busy_i             (apu_busy_o),


      .csr_access_ex_o      (csr_access_ex),
      .csr_op_ex_o          (csr_op_ex),
      .current_priv_lvl_i   (current_priv_lvl),
      .csr_irq_sec_o        (csr_irq_sec),
      .csr_cause_o          (csr_cause),
      .csr_save_if_o        (csr_save_if),
      .csr_save_id_o        (csr_save_id),
      .csr_save_ex_o        (csr_save_ex),
      .csr_restore_mret_id_o(csr_restore_mret_id),
      .csr_restore_uret_id_o(csr_restore_uret_id),

      .csr_restore_dret_id_o(csr_restore_dret_id),

      .csr_save_cause_o(csr_save_cause),

      .hwlp_target_o(hwlp_target),

      .data_req_ex_o       (data_req_ex),
      .data_we_ex_o        (data_we_ex),
      .atop_ex_o           (data_atop_ex),
      .data_type_ex_o      (data_type_ex),
      .data_sign_ext_ex_o  (data_sign_ext_ex),
      .data_reg_offset_ex_o(data_reg_offset_ex),
      .data_load_event_ex_o(data_load_event_ex),

      .data_misaligned_ex_o(data_misaligned_ex),

      .prepost_useincr_ex_o(useincr_addr_ex),
      .data_misaligned_i   (data_misaligned),
      .data_err_i          (data_err_pmp),
      .data_err_ack_o      (data_err_ack),


      .irq_i         (irq_i),
      .irq_sec_i     (1'b0),
      .mie_bypass_i  (mie_bypass),
      .mip_o         (mip),
      .m_irq_enable_i(m_irq_enable),
      .u_irq_enable_i(u_irq_enable),
      .irq_ack_o     (irq_ack_o),
      .irq_id_o      (irq_id_o),


      .debug_mode_o          (debug_mode),
      .debug_cause_o         (debug_cause),
      .debug_csr_save_o      (debug_csr_save),
      .debug_single_step_i   (debug_single_step),
      .debug_ebreakm_i       (debug_ebreakm),
      .debug_ebreaku_i       (debug_ebreaku),
      .trigger_match_i       (trigger_match),
      .debug_p_elw_no_sleep_o(debug_p_elw_no_sleep),


      .wake_from_sleep_o(wake_from_sleep),


      .regfile_waddr_wb_i   (regfile_waddr_fw_wb_o),
      .regfile_we_wb_i      (regfile_we_wb),
      .regfile_we_wb_power_i(regfile_we_wb_power),
      .regfile_wdata_wb_i   (regfile_wdata),

      .regfile_alu_waddr_fw_i   (regfile_alu_waddr_fw),
      .regfile_alu_we_fw_i      (regfile_alu_we_fw),
      .regfile_alu_we_fw_power_i(regfile_alu_we_fw_power),
      .regfile_alu_wdata_fw_i   (regfile_alu_wdata_fw),


      .mult_multicycle_i(mult_multicycle),


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

      .perf_imiss_i(perf_imiss),
      .mcounteren_i(mcounteren)
  );










  rv32imf_ex_stage #() ex_stage_i (

      .clk  (clk),
      .rst_n(rst_ni),


      .alu_en_i        (alu_en_ex),
      .alu_operator_i  (alu_operator_ex),
      .alu_operand_a_i (alu_operand_a_ex),
      .alu_operand_b_i (alu_operand_b_ex),
      .alu_operand_c_i (alu_operand_c_ex),
      .bmask_a_i       (bmask_a_ex),
      .bmask_b_i       (bmask_b_ex),
      .imm_vec_ext_i   (imm_vec_ext_ex),
      .alu_vec_mode_i  (alu_vec_mode_ex),
      .alu_is_clpx_i   (alu_is_clpx_ex),
      .alu_is_subrot_i (alu_is_subrot_ex),
      .alu_clpx_shift_i(alu_clpx_shift_ex),


      .mult_operator_i   (mult_operator_ex),
      .mult_operand_a_i  (mult_operand_a_ex),
      .mult_operand_b_i  (mult_operand_b_ex),
      .mult_operand_c_i  (mult_operand_c_ex),
      .mult_en_i         (mult_en_ex),
      .mult_sel_subword_i(mult_sel_subword_ex),
      .mult_signed_mode_i(mult_signed_mode_ex),
      .mult_imm_i        (mult_imm_ex),
      .mult_dot_op_a_i   (mult_dot_op_a_ex),
      .mult_dot_op_b_i   (mult_dot_op_b_ex),
      .mult_dot_op_c_i   (mult_dot_op_c_ex),
      .mult_dot_signed_i (mult_dot_signed_ex),
      .mult_is_clpx_i    (mult_is_clpx_ex),
      .mult_clpx_shift_i (mult_clpx_shift_ex),
      .mult_clpx_img_i   (mult_clpx_img_ex),

      .mult_multicycle_o(mult_multicycle),

      .data_req_i          (data_req_o),
      .data_rvalid_i       (data_rvalid_i),
      .data_misaligned_ex_i(data_misaligned_ex),
      .data_misaligned_i   (data_misaligned),

      .ctrl_transfer_insn_in_dec_i(ctrl_transfer_insn_in_dec),


      .fpu_fflags_we_o(fflags_we),
      .fpu_fflags_o   (fflags_csr),


      .apu_en_i      (apu_en_ex),
      .apu_op_i      (apu_op_ex),
      .apu_lat_i     (apu_lat_ex),
      .apu_operands_i(apu_operands_ex),
      .apu_waddr_i   (apu_waddr_ex),

      .apu_read_regs_i        (apu_read_regs),
      .apu_read_regs_valid_i  (apu_read_regs_valid),
      .apu_read_dep_o         (apu_read_dep),
      .apu_read_dep_for_jalr_o(apu_read_dep_for_jalr),
      .apu_write_regs_i       (apu_write_regs),
      .apu_write_regs_valid_i (apu_write_regs_valid),
      .apu_write_dep_o        (apu_write_dep),

      .apu_perf_type_o(perf_apu_type),
      .apu_perf_cont_o(perf_apu_cont),
      .apu_perf_wb_o  (perf_apu_wb),
      .apu_ready_wb_o (apu_ready_wb),
      .apu_busy_o     (apu_busy_o),



      .apu_req_o(apu_req_o),
      .apu_gnt_i(apu_gnt_i),

      .apu_operands_o(apu_operands_o),
      .apu_op_o      (apu_op_o),

      .apu_rvalid_i(apu_rvalid_i),
      .apu_result_i(apu_result_i),
      .apu_flags_i (apu_flags_i),

      .lsu_en_i   (data_req_ex),
      .lsu_rdata_i(lsu_rdata),


      .csr_access_i(csr_access_ex),
      .csr_rdata_i (csr_rdata),


      .branch_in_ex_i     (branch_in_ex),
      .regfile_alu_waddr_i(regfile_alu_waddr_ex),
      .regfile_alu_we_i   (regfile_alu_we_ex),

      .regfile_waddr_i(regfile_waddr_ex),
      .regfile_we_i   (regfile_we_ex),


      .regfile_waddr_wb_o   (regfile_waddr_fw_wb_o),
      .regfile_we_wb_o      (regfile_we_wb),
      .regfile_we_wb_power_o(regfile_we_wb_power),
      .regfile_wdata_wb_o   (regfile_wdata),


      .jump_target_o    (jump_target_ex),
      .branch_decision_o(branch_decision),


      .regfile_alu_waddr_fw_o   (regfile_alu_waddr_fw),
      .regfile_alu_we_fw_o      (regfile_alu_we_fw),
      .regfile_alu_we_fw_power_o(regfile_alu_we_fw_power),
      .regfile_alu_wdata_fw_o   (regfile_alu_wdata_fw),


      .is_decoding_i (is_decoding),
      .lsu_ready_ex_i(lsu_ready_ex),
      .lsu_err_i     (data_err_pmp),

      .ex_ready_o(ex_ready),
      .ex_valid_o(ex_valid),
      .wb_ready_i(lsu_ready_wb)
  );











  rv32imf_load_store_unit #() load_store_unit_i (
      .clk  (clk),
      .rst_n(rst_ni),


      .data_req_o    (data_req_pmp),
      .data_gnt_i    (data_gnt_pmp),
      .data_rvalid_i (data_rvalid_i),
      .data_err_i    (1'b0),
      .data_err_pmp_i(data_err_pmp),

      .data_addr_o (data_addr_pmp),
      .data_we_o   (data_we_o),
      .data_atop_o (data_atop_o),
      .data_be_o   (data_be_o),
      .data_wdata_o(data_wdata_o),
      .data_rdata_i(data_rdata_i),


      .data_we_ex_i        (data_we_ex),
      .data_atop_ex_i      (data_atop_ex),
      .data_type_ex_i      (data_type_ex),
      .data_wdata_ex_i     (alu_operand_c_ex),
      .data_reg_offset_ex_i(data_reg_offset_ex),
      .data_load_event_ex_i(data_load_event_ex),
      .data_sign_ext_ex_i  (data_sign_ext_ex),

      .data_rdata_ex_o  (lsu_rdata),
      .data_req_ex_i    (data_req_ex),
      .operand_a_ex_i   (alu_operand_a_ex),
      .operand_b_ex_i   (alu_operand_b_ex),
      .addr_useincr_ex_i(useincr_addr_ex),

      .data_misaligned_ex_i(data_misaligned_ex),
      .data_misaligned_o   (data_misaligned),

      .p_elw_start_o (p_elw_start),
      .p_elw_finish_o(p_elw_finish),


      .lsu_ready_ex_o(lsu_ready_ex),
      .lsu_ready_wb_o(lsu_ready_wb),

      .busy_o(lsu_busy)
  );


  assign wb_valid = lsu_ready_wb;












  rv32imf_cs_registers #(
      .N_HWLP          (N_HWLP),
      .N_PMP_ENTRIES   (N_PMP_ENTRIES),
      .DEBUG_TRIGGER_EN(DEBUG_TRIGGER_EN)
  ) cs_registers_i (
      .clk  (clk),
      .rst_n(rst_ni),


      .hart_id_i   (hart_id_i),
      .mtvec_o     (mtvec),
      .utvec_o     (utvec),
      .mtvec_mode_o(mtvec_mode),
      .utvec_mode_o(utvec_mode),

      .mtvec_addr_i    (mtvec_addr_i[31:0]),
      .csr_mtvec_init_i(csr_mtvec_init),

      .csr_addr_i (csr_addr),
      .csr_wdata_i(csr_wdata),
      .csr_op_i   (csr_op),
      .csr_rdata_o(csr_rdata),

      .fs_off_o   (fs_off),
      .frm_o      (frm_csr),
      .fflags_i   (fflags_csr),
      .fflags_we_i(fflags_we),
      .fregs_we_i (fregs_we),


      .mie_bypass_o  (mie_bypass),
      .mip_i         (mip),
      .m_irq_enable_o(m_irq_enable),
      .u_irq_enable_o(u_irq_enable),
      .csr_irq_sec_i (csr_irq_sec),
      .sec_lvl_o     (sec_lvl_o),
      .mepc_o        (mepc),
      .uepc_o        (uepc),


      .mcounteren_o(mcounteren),


      .debug_mode_i       (debug_mode),
      .debug_cause_i      (debug_cause),
      .debug_csr_save_i   (debug_csr_save),
      .depc_o             (depc),
      .debug_single_step_o(debug_single_step),
      .debug_ebreakm_o    (debug_ebreakm),
      .debug_ebreaku_o    (debug_ebreaku),
      .trigger_match_o    (trigger_match),

      .priv_lvl_o(current_priv_lvl),

      .pmp_addr_o(pmp_addr),
      .pmp_cfg_o (pmp_cfg),

      .pc_if_i(pc_if),
      .pc_id_i(pc_id),
      .pc_ex_i(pc_ex),

      .csr_save_if_i     (csr_save_if),
      .csr_save_id_i     (csr_save_id),
      .csr_save_ex_i     (csr_save_ex),
      .csr_restore_mret_i(csr_restore_mret_id),
      .csr_restore_uret_i(csr_restore_uret_id),

      .csr_restore_dret_i(csr_restore_dret_id),

      .csr_cause_i     (csr_cause),
      .csr_save_cause_i(csr_save_cause),


      .hwlp_start_i(hwlp_start),
      .hwlp_end_i  (hwlp_end),
      .hwlp_cnt_i  (hwlp_cnt),


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
      .apu_typeconflict_i      (perf_apu_type),
      .apu_contention_i        (perf_apu_cont),
      .apu_dep_i               (perf_apu_dep),
      .apu_wb_i                (perf_apu_wb)
  );


  assign csr_addr = csr_addr_int;
  assign csr_wdata = alu_operand_a_ex;
  assign csr_op = csr_op_ex;

  assign csr_addr_int = csr_num_e'(csr_access_ex ? alu_operand_b_ex[11:0] : '0);


  assign fregs_we     = ((regfile_alu_we_fw && regfile_alu_waddr_fw[5])
                        || (regfile_we_wb     && regfile_waddr_fw_wb_o[5]));

  assign instr_req_o = instr_req_pmp;
  assign instr_addr_o = instr_addr_pmp;
  assign instr_gnt_pmp = instr_gnt_i;
  assign instr_err_pmp = 1'b0;

  assign data_req_o = data_req_pmp;
  assign data_addr_o = data_addr_pmp;
  assign data_gnt_pmp = data_gnt_i;
  assign data_err_pmp = 1'b0;

endmodule
