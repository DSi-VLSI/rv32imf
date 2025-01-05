module rv32imf_controller
  import rv32imf_pkg::*;
#(
) (
    input logic clk,
    input logic clk_ungated_i,
    input logic rst_n,

    output logic ctrl_busy_o,
    output logic is_decoding_o,
    input  logic is_fetch_failed_i,


    output logic deassert_we_o,

    input logic illegal_insn_i,
    input logic ecall_insn_i,
    input logic mret_insn_i,
    input logic uret_insn_i,

    input logic dret_insn_i,

    input logic mret_dec_i,
    input logic uret_dec_i,
    input logic dret_dec_i,

    input logic wfi_i,
    input logic ebrk_insn_i,
    input logic fencei_insn_i,
    input logic csr_status_i,

    output logic hwlp_mask_o,


    input logic instr_valid_i,


    output logic instr_req_o,


    output logic       pc_set_o,
    output logic [3:0] pc_mux_o,
    output logic [2:0] exc_pc_mux_o,
    output logic [1:0] trap_addr_mux_o,

    input  logic [31:0] pc_id_i,
    output logic [31:0] hwlp_targ_addr_o,

    input  logic data_req_ex_i,
    input  logic data_we_ex_i,
    input  logic data_misaligned_i,
    input  logic data_load_event_i,
    input  logic data_err_i,
    output logic data_err_ack_o,


    input logic mult_multicycle_i,


    input logic apu_en_i,
    input logic apu_read_dep_i,
    input logic apu_read_dep_for_jalr_i,
    input logic apu_write_dep_i,

    output logic apu_stall_o,


    input logic       branch_taken_ex_i,
    input logic [1:0] ctrl_transfer_insn_in_id_i,
    input logic [1:0] ctrl_transfer_insn_in_dec_i,


    input logic            irq_req_ctrl_i,
    input logic            irq_sec_ctrl_i,
    input logic      [4:0] irq_id_ctrl_i,
    input logic            irq_wu_ctrl_i,
    input priv_lvl_t       current_priv_lvl_i,

    output logic       irq_ack_o,
    output logic [4:0] irq_id_o,

    output logic [4:0] exc_cause_o,


    output logic       debug_mode_o,
    output logic [2:0] debug_cause_o,
    output logic       debug_csr_save_o,
    input  logic       debug_single_step_i,
    input  logic       debug_ebreakm_i,
    input  logic       debug_ebreaku_i,
    input  logic       trigger_match_i,
    output logic       debug_p_elw_no_sleep_o,
    output logic       debug_wfi_no_sleep_o,


    output logic wake_from_sleep_o,

    output logic       csr_save_if_o,
    output logic       csr_save_id_o,
    output logic       csr_save_ex_o,
    output logic [5:0] csr_cause_o,
    output logic       csr_irq_sec_o,
    output logic       csr_restore_mret_id_o,
    output logic       csr_restore_uret_id_o,

    output logic csr_restore_dret_id_o,

    output logic csr_save_cause_o,



    input logic       regfile_we_id_i,
    input logic [5:0] regfile_alu_waddr_id_i,


    input logic       regfile_we_ex_i,
    input logic [5:0] regfile_waddr_ex_i,
    input logic       regfile_we_wb_i,
    input logic       regfile_alu_we_fw_i,


    output logic [1:0] operand_a_fw_mux_sel_o,
    output logic [1:0] operand_b_fw_mux_sel_o,
    output logic [1:0] operand_c_fw_mux_sel_o,


    input logic reg_d_ex_is_reg_a_i,
    input logic reg_d_ex_is_reg_b_i,
    input logic reg_d_ex_is_reg_c_i,
    input logic reg_d_wb_is_reg_a_i,
    input logic reg_d_wb_is_reg_b_i,
    input logic reg_d_wb_is_reg_c_i,
    input logic reg_d_alu_is_reg_a_i,
    input logic reg_d_alu_is_reg_b_i,
    input logic reg_d_alu_is_reg_c_i,


    output logic halt_if_o,
    output logic halt_id_o,

    output logic misaligned_stall_o,
    output logic jr_stall_o,
    output logic load_stall_o,

    input logic id_ready_i,
    input logic id_valid_i,

    input logic ex_valid_i,

    input logic wb_ready_i,


    output logic perf_pipeline_stall_o
);


  ctrl_state_e ctrl_fsm_cs, ctrl_fsm_ns;


  debug_state_e debug_fsm_cs, debug_fsm_ns;

  logic jump_done, jump_done_q, jump_in_dec, branch_in_id;

  logic data_err_q;

  logic debug_mode_q, debug_mode_n;
  logic ebrk_force_debug_mode;
  logic illegal_insn_q, illegal_insn_n;
  logic debug_req_entry_q, debug_req_entry_n;
  logic debug_force_wakeup_q, debug_force_wakeup_n;

  logic hwlp_end_4_id_d;

  logic debug_req_q;
  logic debug_req_pending;


  logic wfi_active;











  always_comb begin


    instr_req_o = 1'b1;

    data_err_ack_o = 1'b0;

    csr_save_if_o = 1'b0;
    csr_save_id_o = 1'b0;
    csr_save_ex_o = 1'b0;
    csr_restore_mret_id_o = 1'b0;
    csr_restore_uret_id_o = 1'b0;

    csr_restore_dret_id_o = 1'b0;

    csr_save_cause_o = 1'b0;

    exc_cause_o = '0;
    exc_pc_mux_o = EXC_PC_IRQ;
    trap_addr_mux_o = TRAP_MACHINE;

    csr_cause_o = '0;
    csr_irq_sec_o = 1'b0;

    pc_mux_o = PC_BOOT;
    pc_set_o = 1'b0;
    jump_done = jump_done_q;

    ctrl_fsm_ns = ctrl_fsm_cs;

    ctrl_busy_o = 1'b1;

    halt_if_o = 1'b0;
    halt_id_o = 1'b0;
    is_decoding_o = 1'b0;
    irq_ack_o = 1'b0;
    irq_id_o = 5'b0;

    jump_in_dec            = ctrl_transfer_insn_in_dec_i == BRANCH_JALR || ctrl_transfer_insn_in_dec_i == BRANCH_JAL;

    branch_in_id = ctrl_transfer_insn_in_id_i == BRANCH_COND;

    ebrk_force_debug_mode  = (debug_ebreakm_i && current_priv_lvl_i == PRIV_LVL_M) ||
                             (debug_ebreaku_i && current_priv_lvl_i == PRIV_LVL_U);
    debug_csr_save_o = 1'b0;
    debug_cause_o = DBG_CAUSE_EBREAK;
    debug_mode_n = debug_mode_q;

    illegal_insn_n = illegal_insn_q;








    debug_req_entry_n = debug_req_entry_q;

    debug_force_wakeup_n = debug_force_wakeup_q;

    perf_pipeline_stall_o = 1'b0;

    hwlp_mask_o = 1'b0;

    hwlp_end_4_id_d = 1'b0;
    hwlp_targ_addr_o = '0;

    unique case (ctrl_fsm_cs)

      RESET: begin
        is_decoding_o = 1'b0;
        instr_req_o   = 1'b0;
        ctrl_fsm_ns   = BOOT_SET;
      end


      BOOT_SET: begin
        is_decoding_o = 1'b0;
        instr_req_o   = 1'b1;
        pc_mux_o      = PC_BOOT;
        pc_set_o      = 1'b1;
        if (debug_req_pending) begin
          ctrl_fsm_ns = DBG_TAKEN_IF;
          debug_force_wakeup_n = 1'b1;
        end else begin
          ctrl_fsm_ns = FIRST_FETCH;
        end
      end

      WAIT_SLEEP: begin
        is_decoding_o = 1'b0;
        ctrl_busy_o   = 1'b0;
        instr_req_o   = 1'b0;
        halt_if_o     = 1'b1;
        halt_id_o     = 1'b1;
        ctrl_fsm_ns   = SLEEP;
      end


      SLEEP: begin


        is_decoding_o = 1'b0;
        instr_req_o   = 1'b0;
        halt_if_o     = 1'b1;
        halt_id_o     = 1'b1;



        if (wake_from_sleep_o) begin
          if (debug_req_pending) begin
            ctrl_fsm_ns = DBG_TAKEN_IF;
            debug_force_wakeup_n = 1'b1;
          end else begin
            ctrl_fsm_ns = FIRST_FETCH;
          end
        end else begin
          ctrl_busy_o = 1'b0;
        end
      end

      FIRST_FETCH: begin
        is_decoding_o = 1'b0;


        ctrl_fsm_ns   = DECODE;


        if (irq_req_ctrl_i && ~(debug_req_pending || debug_mode_q)) begin





          halt_if_o     = 1'b1;
          halt_id_o     = 1'b1;

          pc_set_o      = 1'b1;
          pc_mux_o      = PC_EXCEPTION;
          exc_pc_mux_o  = EXC_PC_IRQ;
          exc_cause_o   = irq_id_ctrl_i;
          csr_irq_sec_o = irq_sec_ctrl_i;


          irq_ack_o     = 1'b1;
          irq_id_o      = irq_id_ctrl_i;

          if (irq_sec_ctrl_i) trap_addr_mux_o = TRAP_MACHINE;
          else trap_addr_mux_o = current_priv_lvl_i == PRIV_LVL_U ? TRAP_USER : TRAP_MACHINE;

          csr_save_cause_o = 1'b1;
          csr_cause_o      = {1'b1, irq_id_ctrl_i};
          csr_save_if_o    = 1'b1;
        end
      end

      DECODE: begin

        if (branch_taken_ex_i) begin


          is_decoding_o = 1'b0;

          pc_mux_o      = PC_BRANCH;
          pc_set_o      = 1'b1;





        end else if (data_err_i) begin


          is_decoding_o    = 1'b0;
          halt_if_o        = 1'b1;
          halt_id_o        = 1'b1;
          csr_save_ex_o    = 1'b1;
          csr_save_cause_o = 1'b1;
          data_err_ack_o   = 1'b1;


          csr_cause_o      = {1'b0, data_we_ex_i ? EXC_CAUSE_STORE_FAULT : EXC_CAUSE_LOAD_FAULT};
          ctrl_fsm_ns      = FLUSH_WB;

        end else if (is_fetch_failed_i) begin



          is_decoding_o    = 1'b0;
          halt_id_o        = 1'b1;
          halt_if_o        = 1'b1;
          csr_save_if_o    = 1'b1;
          csr_save_cause_o = !debug_mode_q;



          csr_cause_o      = {1'b0, EXC_CAUSE_INSTR_FAULT};
          ctrl_fsm_ns      = FLUSH_WB;


        end else if (instr_valid_i) begin : blk_decode_level1

          is_decoding_o  = 1'b1;
          illegal_insn_n = 1'b0;

          if ((debug_req_pending || trigger_match_i) & ~debug_mode_q) begin

            is_decoding_o     = 1'b1;
            halt_if_o         = 1'b1;
            halt_id_o         = 1'b1;
            ctrl_fsm_ns       = DBG_FLUSH;
            debug_req_entry_n = 1'b1;
          end else if (irq_req_ctrl_i && ~debug_mode_q) begin

            hwlp_mask_o   = 1'b0;

            is_decoding_o = 1'b0;
            halt_if_o     = 1'b1;
            halt_id_o     = 1'b1;

            pc_set_o      = 1'b1;
            pc_mux_o      = PC_EXCEPTION;
            exc_pc_mux_o  = EXC_PC_IRQ;
            exc_cause_o   = irq_id_ctrl_i;
            csr_irq_sec_o = irq_sec_ctrl_i;


            irq_ack_o     = 1'b1;
            irq_id_o      = irq_id_ctrl_i;

            if (irq_sec_ctrl_i) trap_addr_mux_o = TRAP_MACHINE;
            else trap_addr_mux_o = current_priv_lvl_i == PRIV_LVL_U ? TRAP_USER : TRAP_MACHINE;

            csr_save_cause_o = 1'b1;
            csr_cause_o      = {1'b1, irq_id_ctrl_i};
            csr_save_id_o    = 1'b1;
          end else begin

            if (illegal_insn_i) begin

              halt_if_o      = 1'b1;
              halt_id_o      = 1'b0;
              ctrl_fsm_ns    = id_ready_i ? FLUSH_EX : DECODE;
              illegal_insn_n = 1'b1;

            end else begin


              unique case (1'b1)

                jump_in_dec: begin




                  pc_mux_o = PC_JUMP;

                  if ((~jr_stall_o) && (~jump_done_q)) begin
                    pc_set_o  = 1'b1;
                    jump_done = 1'b1;
                  end
                end

                ebrk_insn_i: begin
                  halt_if_o = 1'b1;
                  halt_id_o = 1'b0;

                  if (debug_mode_q) ctrl_fsm_ns = DBG_FLUSH;

                  else if (ebrk_force_debug_mode) begin

                    ctrl_fsm_ns = DBG_FLUSH;
                  end else begin

                    ctrl_fsm_ns = id_ready_i ? FLUSH_EX : DECODE;
                  end

                end

                wfi_active: begin
                  halt_if_o   = 1'b1;
                  halt_id_o   = 1'b0;
                  ctrl_fsm_ns = id_ready_i ? FLUSH_EX : DECODE;
                end

                ecall_insn_i: begin
                  halt_if_o   = 1'b1;
                  halt_id_o   = 1'b0;
                  ctrl_fsm_ns = id_ready_i ? FLUSH_EX : DECODE;
                end

                fencei_insn_i: begin
                  halt_if_o   = 1'b1;
                  halt_id_o   = 1'b0;
                  ctrl_fsm_ns = id_ready_i ? FLUSH_EX : DECODE;
                end

                mret_insn_i | uret_insn_i | dret_insn_i: begin
                  halt_if_o   = 1'b1;
                  halt_id_o   = 1'b0;
                  ctrl_fsm_ns = id_ready_i ? FLUSH_EX : DECODE;
                end

                csr_status_i: begin
                  halt_if_o = 1'b1;
                  if (~id_ready_i) begin
                    ctrl_fsm_ns = DECODE;
                  end else begin
                    ctrl_fsm_ns = FLUSH_EX;
                  end
                end

                data_load_event_i: begin
                  ctrl_fsm_ns = id_ready_i ? ELW_EXE : DECODE;
                  halt_if_o   = 1'b1;
                end

                default: begin

                end

              endcase
            end

            if (debug_single_step_i & ~debug_mode_q) begin

              halt_if_o = 1'b1;








              if (id_ready_i) begin

                unique case (1'b1)

                  illegal_insn_i | ecall_insn_i: begin
                    ctrl_fsm_ns = FLUSH_EX;
                  end

                  (~ebrk_force_debug_mode & ebrk_insn_i): begin
                    ctrl_fsm_ns = FLUSH_EX;
                  end

                  mret_insn_i | uret_insn_i: begin
                    ctrl_fsm_ns = FLUSH_EX;
                  end

                  branch_in_id: begin
                    ctrl_fsm_ns = DBG_WAIT_BRANCH;
                  end

                  default: ctrl_fsm_ns = DBG_FLUSH;
                endcase
              end
            end

          end

        end else begin
          is_decoding_o         = 1'b0;
          perf_pipeline_stall_o = data_load_event_i;
        end
      end


      FLUSH_EX: begin
        is_decoding_o = 1'b0;

        halt_if_o = 1'b1;
        halt_id_o = 1'b1;

        if (data_err_i) begin

          csr_save_ex_o    = 1'b1;
          csr_save_cause_o = 1'b1;
          data_err_ack_o   = 1'b1;

          csr_cause_o      = {1'b0, data_we_ex_i ? EXC_CAUSE_STORE_FAULT : EXC_CAUSE_LOAD_FAULT};
          ctrl_fsm_ns      = FLUSH_WB;


          illegal_insn_n   = 1'b0;
        end else if (ex_valid_i) begin

          ctrl_fsm_ns = FLUSH_WB;

          if (illegal_insn_q) begin
            csr_save_id_o    = 1'b1;
            csr_save_cause_o = !debug_mode_q;
            csr_cause_o      = {1'b0, EXC_CAUSE_ILLEGAL_INSN};
          end else begin
            unique case (1'b1)
              ebrk_insn_i: begin
                csr_save_id_o    = 1'b1;
                csr_save_cause_o = 1'b1;
                csr_cause_o      = {1'b0, EXC_CAUSE_BREAKPOINT};
              end
              ecall_insn_i: begin
                csr_save_id_o = 1'b1;
                csr_save_cause_o = !debug_mode_q;
                csr_cause_o = {
                  1'b0,
                  current_priv_lvl_i == PRIV_LVL_U ? EXC_CAUSE_ECALL_UMODE : EXC_CAUSE_ECALL_MMODE
                };
              end
              default: ;
            endcase
          end

        end
      end


      FLUSH_WB: begin
        is_decoding_o = 1'b0;

        halt_if_o = 1'b1;
        halt_id_o = 1'b1;

        ctrl_fsm_ns = DECODE;

        if (data_err_q) begin

          pc_mux_o        = PC_EXCEPTION;
          pc_set_o        = 1'b1;
          trap_addr_mux_o = TRAP_MACHINE;

          exc_pc_mux_o    = EXC_PC_EXCEPTION;
          exc_cause_o     = data_we_ex_i ? EXC_CAUSE_LOAD_FAULT : EXC_CAUSE_STORE_FAULT;

        end else if (is_fetch_failed_i) begin

          pc_mux_o        = PC_EXCEPTION;
          pc_set_o        = 1'b1;
          trap_addr_mux_o = TRAP_MACHINE;
          exc_pc_mux_o    = debug_mode_q ? EXC_PC_DBE : EXC_PC_EXCEPTION;
          exc_cause_o     = EXC_CAUSE_INSTR_FAULT;

        end else begin
          if (illegal_insn_q) begin

            pc_mux_o        = PC_EXCEPTION;
            pc_set_o        = 1'b1;
            trap_addr_mux_o = TRAP_MACHINE;
            exc_pc_mux_o    = debug_mode_q ? EXC_PC_DBE : EXC_PC_EXCEPTION;
            illegal_insn_n  = 1'b0;
            if (debug_single_step_i && ~debug_mode_q) ctrl_fsm_ns = DBG_TAKEN_IF;
          end else begin
            unique case (1'b1)
              ebrk_insn_i: begin

                pc_mux_o        = PC_EXCEPTION;
                pc_set_o        = 1'b1;
                trap_addr_mux_o = TRAP_MACHINE;
                exc_pc_mux_o    = EXC_PC_EXCEPTION;

                if (debug_single_step_i && ~debug_mode_q) ctrl_fsm_ns = DBG_TAKEN_IF;
              end
              ecall_insn_i: begin

                pc_mux_o        = PC_EXCEPTION;
                pc_set_o        = 1'b1;
                trap_addr_mux_o = TRAP_MACHINE;
                exc_pc_mux_o    = debug_mode_q ? EXC_PC_DBE : EXC_PC_EXCEPTION;

                if (debug_single_step_i && ~debug_mode_q) ctrl_fsm_ns = DBG_TAKEN_IF;
              end

              mret_insn_i: begin
                csr_restore_mret_id_o = !debug_mode_q;
                ctrl_fsm_ns           = XRET_JUMP;
              end
              uret_insn_i: begin
                csr_restore_uret_id_o = !debug_mode_q;
                ctrl_fsm_ns           = XRET_JUMP;
              end
              dret_insn_i: begin
                csr_restore_dret_id_o = 1'b1;
                ctrl_fsm_ns           = XRET_JUMP;
              end

              csr_status_i: begin
              end

              wfi_i: begin
                if (debug_req_pending) begin
                  ctrl_fsm_ns = DBG_TAKEN_IF;
                  debug_force_wakeup_n = 1'b1;
                end else begin
                  ctrl_fsm_ns = WAIT_SLEEP;
                end
              end
              fencei_insn_i: begin


                pc_mux_o = PC_FENCEI;
                pc_set_o = 1'b1;
              end
              default: ;
            endcase
          end
        end

      end

      XRET_JUMP: begin
        is_decoding_o = 1'b0;
        ctrl_fsm_ns   = DECODE;
        unique case (1'b1)
          mret_dec_i: begin

            pc_mux_o     = debug_mode_q ? PC_EXCEPTION : PC_MRET;
            pc_set_o     = 1'b1;
            exc_pc_mux_o = EXC_PC_DBE;
          end
          uret_dec_i: begin

            pc_mux_o     = debug_mode_q ? PC_EXCEPTION : PC_URET;
            pc_set_o     = 1'b1;
            exc_pc_mux_o = EXC_PC_DBE;
          end
          dret_dec_i: begin


            pc_mux_o     = PC_DRET;
            pc_set_o     = 1'b1;
            debug_mode_n = 1'b0;
          end
          default: ;
        endcase

        if (debug_single_step_i && ~debug_mode_q) begin
          ctrl_fsm_ns = DBG_TAKEN_IF;
        end
      end



      DBG_WAIT_BRANCH: begin
        is_decoding_o = 1'b0;
        halt_if_o = 1'b1;

        if (branch_taken_ex_i) begin

          pc_mux_o = PC_BRANCH;
          pc_set_o = 1'b1;
        end

        ctrl_fsm_ns = DBG_FLUSH;
      end










      DBG_TAKEN_ID: begin
        is_decoding_o = 1'b0;
        pc_set_o      = 1'b1;
        pc_mux_o      = PC_EXCEPTION;
        exc_pc_mux_o  = EXC_PC_DBD;


        if (~debug_mode_q) begin
          csr_save_cause_o = 1'b1;
          csr_save_id_o    = 1'b1;
          debug_csr_save_o = 1'b1;
          if (trigger_match_i) debug_cause_o = DBG_CAUSE_TRIGGER;
          else if (ebrk_force_debug_mode & ebrk_insn_i) debug_cause_o = DBG_CAUSE_EBREAK;
          else if (debug_req_entry_q) debug_cause_o = DBG_CAUSE_HALTREQ;

        end
        debug_req_entry_n = 1'b0;
        ctrl_fsm_ns       = DECODE;
        debug_mode_n      = 1'b1;
      end



      DBG_TAKEN_IF: begin
        is_decoding_o    = 1'b0;
        pc_set_o         = 1'b1;
        pc_mux_o         = PC_EXCEPTION;
        exc_pc_mux_o     = EXC_PC_DBD;
        csr_save_cause_o = 1'b1;
        debug_csr_save_o = 1'b1;
        if (debug_force_wakeup_q) debug_cause_o = DBG_CAUSE_HALTREQ;
        else if (debug_single_step_i) debug_cause_o = DBG_CAUSE_STEP;
        csr_save_if_o        = 1'b1;
        ctrl_fsm_ns          = DECODE;
        debug_mode_n         = 1'b1;
        debug_force_wakeup_n = 1'b0;
      end


      DBG_FLUSH: begin
        is_decoding_o = 1'b0;

        halt_if_o = 1'b1;
        halt_id_o = 1'b1;

        perf_pipeline_stall_o = data_load_event_i;

        if (data_err_i) begin

          csr_save_ex_o    = 1'b1;
          csr_save_cause_o = 1'b1;
          data_err_ack_o   = 1'b1;

          csr_cause_o      = {1'b0, data_we_ex_i ? EXC_CAUSE_STORE_FAULT : EXC_CAUSE_LOAD_FAULT};
          ctrl_fsm_ns      = FLUSH_WB;
        end else begin
          if(debug_mode_q                          |
             trigger_match_i                       |
             (ebrk_force_debug_mode & ebrk_insn_i) |
             data_load_event_i                     |
             debug_req_entry_q                     )
            begin
            ctrl_fsm_ns = DBG_TAKEN_ID;
          end else begin

            ctrl_fsm_ns = DBG_TAKEN_IF;
          end
        end
      end


      default: begin
        is_decoding_o = 1'b0;
        instr_req_o   = 1'b0;
        ctrl_fsm_ns   = RESET;
      end
    endcase
  end

  always_comb begin
    load_stall_o  = 1'b0;
    deassert_we_o = 1'b0;


    if (~is_decoding_o) deassert_we_o = 1'b1;


    if (illegal_insn_i) deassert_we_o = 1'b1;


    if (
          ( (data_req_ex_i == 1'b1) && (regfile_we_ex_i == 1'b1) ||
           (wb_ready_i == 1'b0) && (regfile_we_wb_i == 1'b1)
          ) &&
          ( (reg_d_ex_is_reg_a_i == 1'b1) || (reg_d_ex_is_reg_b_i == 1'b1) || (reg_d_ex_is_reg_c_i == 1'b1) ||
            (is_decoding_o && (regfile_we_id_i && !data_misaligned_i) && (regfile_waddr_ex_i == regfile_alu_waddr_id_i)) )
       )
    begin
      deassert_we_o = 1'b1;
      load_stall_o  = 1'b1;
    end





    if ((ctrl_transfer_insn_in_dec_i == BRANCH_JALR) &&
        (((regfile_we_wb_i == 1'b1) && (reg_d_wb_is_reg_a_i == 1'b1)) ||
         ((regfile_we_ex_i == 1'b1) && (reg_d_ex_is_reg_a_i == 1'b1)) ||
         ((regfile_alu_we_fw_i == 1'b1) && (reg_d_alu_is_reg_a_i == 1'b1)) ||
         ((apu_read_dep_for_jalr_i == 1'b1))
        )
       )
    begin
      jr_stall_o    = 1'b1;
      deassert_we_o = 1'b1;
    end else begin
      jr_stall_o = 1'b0;
    end
  end



  assign misaligned_stall_o = data_misaligned_i;


  assign apu_stall_o = apu_read_dep_i | (apu_write_dep_i & ~apu_en_i);


  always_comb begin

    operand_a_fw_mux_sel_o = SEL_REGFILE;
    operand_b_fw_mux_sel_o = SEL_REGFILE;
    operand_c_fw_mux_sel_o = SEL_REGFILE;


    if (regfile_we_wb_i == 1'b1) begin
      if (reg_d_wb_is_reg_a_i == 1'b1) operand_a_fw_mux_sel_o = SEL_FW_WB;
      if (reg_d_wb_is_reg_b_i == 1'b1) operand_b_fw_mux_sel_o = SEL_FW_WB;
      if (reg_d_wb_is_reg_c_i == 1'b1) operand_c_fw_mux_sel_o = SEL_FW_WB;
    end


    if (regfile_alu_we_fw_i == 1'b1) begin
      if (reg_d_alu_is_reg_a_i == 1'b1) operand_a_fw_mux_sel_o = SEL_FW_EX;
      if (reg_d_alu_is_reg_b_i == 1'b1) operand_b_fw_mux_sel_o = SEL_FW_EX;
      if (reg_d_alu_is_reg_c_i == 1'b1) operand_c_fw_mux_sel_o = SEL_FW_EX;
    end


    if (data_misaligned_i) begin
      operand_a_fw_mux_sel_o = SEL_FW_EX;
      operand_b_fw_mux_sel_o = SEL_REGFILE;
    end else if (mult_multicycle_i) begin
      operand_c_fw_mux_sel_o = SEL_FW_EX;
    end
  end


  always_ff @(posedge clk, negedge rst_n) begin : UPDATE_REGS
    if (rst_n == 1'b0) begin
      ctrl_fsm_cs          <= RESET;
      jump_done_q          <= 1'b0;
      data_err_q           <= 1'b0;

      debug_mode_q         <= 1'b0;
      illegal_insn_q       <= 1'b0;

      debug_req_entry_q    <= 1'b0;
      debug_force_wakeup_q <= 1'b0;
    end else begin
      ctrl_fsm_cs          <= ctrl_fsm_ns;


      jump_done_q          <= jump_done & (~id_ready_i);

      data_err_q           <= data_err_i;

      debug_mode_q         <= debug_mode_n;

      illegal_insn_q       <= illegal_insn_n;

      debug_req_entry_q    <= debug_req_entry_n;
      debug_force_wakeup_q <= debug_force_wakeup_n;
    end
  end


  assign wake_from_sleep_o = irq_wu_ctrl_i || debug_req_pending || debug_mode_q;


  assign debug_mode_o = debug_mode_q;
  assign debug_req_pending = debug_req_q;


  assign debug_p_elw_no_sleep_o = debug_mode_q || debug_req_q || debug_single_step_i || trigger_match_i;






  assign debug_wfi_no_sleep_o = debug_mode_q || debug_req_pending || debug_single_step_i || trigger_match_i;


  assign wfi_active = wfi_i & ~debug_wfi_no_sleep_o;


  always_ff @(posedge clk_ungated_i, negedge rst_n)
    if (!rst_n) debug_req_q <= 1'b0;
    else if (debug_mode_q) debug_req_q <= 1'b0;


  always_ff @(posedge clk, negedge rst_n) begin
    if (rst_n == 1'b0) begin
      debug_fsm_cs <= HAVERESET;
    end else begin
      debug_fsm_cs <= debug_fsm_ns;
    end
  end

  always_comb begin
    debug_fsm_ns = debug_fsm_cs;

    case (debug_fsm_cs)
      HAVERESET: begin
        if (debug_mode_n || (ctrl_fsm_ns == FIRST_FETCH)) begin
          if (debug_mode_n) begin
            debug_fsm_ns = HALTED;
          end else begin
            debug_fsm_ns = RUNNING;
          end
        end
      end

      RUNNING: begin
        if (debug_mode_n) begin
          debug_fsm_ns = HALTED;
        end
      end

      HALTED: begin
        if (!debug_mode_n) begin
          debug_fsm_ns = RUNNING;
        end
      end

      default: begin
        debug_fsm_ns = HAVERESET;
      end
    endcase
  end

endmodule
