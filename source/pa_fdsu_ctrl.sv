module pa_fdsu_ctrl (
    cp0_fpu_icg_en,  // Input: FPU ICG enable from CP0
    cp0_yy_clk_en,  // Input: Clock enable from CP0
    cpurst_b,  // Input: Asynchronous reset (active low)
    ctrl_fdsu_ex1_sel,  // Input: Select signal for FDSU in EX1
    ctrl_xx_ex1_cmplt_dp,  // Input: EX1 complete with data path
    ctrl_xx_ex1_inst_vld,  // Input: EX1 instruction valid
    ctrl_xx_ex1_stall,  // Input: EX1 pipeline stall
    ctrl_xx_ex1_warm_up,  // Input: EX1 warm-up signal
    ctrl_xx_ex2_warm_up,  // Input: EX2 warm-up signal
    ctrl_xx_ex3_warm_up,  // Input: EX3 warm-up signal
    ex1_div,  // Input: EX1 division operation
    ex1_expnt_adder_op0,  // Input: EX1 exponent adder operand 0
    ex1_of_result_lfn,  // Input: EX1 overflow result is LFN
    ex1_op0_id,  // Input: EX1 operand 0 ID
    ex1_op0_norm,  // Input: EX1 operand 0 normalized
    ex1_op1_id_vld,  // Input: EX1 operand 1 ID valid
    ex1_op1_norm,  // Input: EX1 operand 1 normalized
    ex1_oper_id_expnt,  // Input: EX1 operand ID exponent
    ex1_oper_id_expnt_f,  // Output: EX1 operand ID exponent (final)
    ex1_pipedown,  // Output: EX1 pipeline down signal
    ex1_pipedown_gate,  // Output: EX1 pipeline down gate signal
    ex1_result_sign,  // Input: EX1 result sign
    ex1_rm,  // Input: EX1 rounding mode
    ex1_save_op0,  // Output: EX1 save operand 0 signal
    ex1_save_op0_gate,  // Output: EX1 save operand 0 gate signal
    ex1_sqrt,  // Input: EX1 square root operation
    ex1_srt_skip,  // Input: EX1 SRT skip signal
    ex2_expnt_adder_op0,  // Output: EX2 exponent adder operand 0
    ex2_of,  // Input: EX2 overflow
    ex2_pipe_clk,  // Output: EX2 pipeline clock
    ex2_pipedown,  // Output: EX2 pipeline down signal
    ex2_potnt_of,  // Input: EX2 potential overflow
    ex2_potnt_uf,  // Input: EX2 potential underflow
    ex2_result_inf,  // Input: EX2 result infinity
    ex2_result_lfn,  // Input: EX2 result LFN
    ex2_rslt_denorm,  // Input: EX2 result denormal
    ex2_srt_expnt_rst,  // Input: EX2 SRT exponent reset
    ex2_srt_first_round,  // Output: EX2 SRT first round signal
    ex2_uf,  // Input: EX2 underflow
    ex2_uf_srt_skip,  // Input: EX2 underflow SRT skip
    ex3_expnt_adjust_result,  // Input: EX3 exponent adjust result
    ex3_pipedown,  // Output: EX3 pipeline down signal
    ex3_rslt_denorm,  // Input: EX3 result denormal
    fdsu_ex1_sel,  // Output: FDSU select signal for EX1
    fdsu_fpu_debug_info,  // Output: FDSU FPU debug information
    fdsu_fpu_ex1_cmplt,  // Output: FDSU FPU EX1 complete
    fdsu_fpu_ex1_cmplt_dp,  // Output: FDSU FPU EX1 complete with data path
    fdsu_fpu_ex1_stall,  // Output: FDSU FPU EX1 stall
    fdsu_fpu_no_op,  // Output: FDSU FPU no operation
    fdsu_frbus_wb_vld,  // Output: FDSU FRBUS writeback valid
    fdsu_yy_div,  // Output: FDSU division operation
    fdsu_yy_expnt_rst,  // Output: FDSU exponent reset
    fdsu_yy_of,  // Output: FDSU overflow
    fdsu_yy_of_rm_lfn,  // Output: FDSU overflow result is LFN
    fdsu_yy_op0_norm,  // Output: FDSU operand 0 normalized
    fdsu_yy_op1_norm,  // Output: FDSU operand 1 normalized
    fdsu_yy_potnt_of,  // Output: FDSU potential overflow
    fdsu_yy_potnt_uf,  // Output: FDSU potential underflow
    fdsu_yy_result_inf,  // Output: FDSU result infinity
    fdsu_yy_result_lfn,  // Output: FDSU result LFN
    fdsu_yy_result_sign,  // Output: FDSU result sign
    fdsu_yy_rm,  // Output: FDSU rounding mode
    fdsu_yy_rslt_denorm,  // Output: FDSU result denormal
    fdsu_yy_sqrt,  // Output: FDSU square root operation
    fdsu_yy_uf,  // Output: FDSU underflow
    fdsu_yy_wb_freg,  // Output: FDSU writeback register
    forever_cpuclk,  // Input: Forever CPU clock
    frbus_fdsu_wb_grant,  // Input: FRBUS writeback grant for FDSU
    idu_fpu_ex1_dst_freg,  // Input: IDU FPU EX1 destination register
    idu_fpu_ex1_eu_sel,  // Input: IDU FPU EX1 execution unit select
    pad_yy_icg_scan_en,  // Input: ICG scan enable
    rtu_xx_ex1_cancel,  // Input: RTU EX1 cancel signal
    rtu_xx_ex2_cancel,  // Input: RTU EX2 cancel signal
    rtu_yy_xx_async_flush,  // Input: Asynchronous flush signal
    rtu_yy_xx_flush,  // Input: Flush signal
    srt_remainder_zero,  // Input: SRT remainder is zero
    ex1_op1_sel,  // Output: EX1 operand 1 select signal
    srt_sm_on  // Output: SRT state machine is on
);


  input cp0_fpu_icg_en;
  input cp0_yy_clk_en;
  input cpurst_b;
  input ctrl_fdsu_ex1_sel;
  input ctrl_xx_ex1_cmplt_dp;
  input ctrl_xx_ex1_inst_vld;
  input ctrl_xx_ex1_stall;
  input ctrl_xx_ex1_warm_up;
  input ctrl_xx_ex2_warm_up;
  input ctrl_xx_ex3_warm_up;
  input ex1_div;
  input [12:0] ex1_expnt_adder_op0;
  input ex1_of_result_lfn;
  input ex1_op0_id;
  input ex1_op0_norm;
  input ex1_op1_id_vld;
  input ex1_op1_norm;
  input [12:0] ex1_oper_id_expnt;
  input ex1_result_sign;
  input [2 : 0] ex1_rm;
  input ex1_sqrt;
  input ex1_srt_skip;
  input ex2_of;
  input ex2_potnt_of;
  input ex2_potnt_uf;
  input ex2_result_inf;
  input ex2_result_lfn;
  input ex2_rslt_denorm;
  input [9 : 0] ex2_srt_expnt_rst;
  input ex2_uf;
  input ex2_uf_srt_skip;
  input [9 : 0] ex3_expnt_adjust_result;
  input ex3_rslt_denorm;
  input forever_cpuclk;
  input frbus_fdsu_wb_grant;
  input [4 : 0] idu_fpu_ex1_dst_freg;
  input [2 : 0] idu_fpu_ex1_eu_sel;
  input pad_yy_icg_scan_en;
  input rtu_xx_ex1_cancel;
  input rtu_xx_ex2_cancel;
  input rtu_yy_xx_async_flush;
  input rtu_yy_xx_flush;
  input srt_remainder_zero;
  output ex1_op1_sel;
  output [12:0] ex1_oper_id_expnt_f;
  output ex1_pipedown;
  output ex1_pipedown_gate;
  output ex1_save_op0;
  output ex1_save_op0_gate;
  output [9 : 0] ex2_expnt_adder_op0;
  output ex2_pipe_clk;
  output ex2_pipedown;
  output ex2_srt_first_round;
  output ex3_pipedown;
  output fdsu_ex1_sel;
  output [4 : 0] fdsu_fpu_debug_info;
  output fdsu_fpu_ex1_cmplt;
  output fdsu_fpu_ex1_cmplt_dp;
  output fdsu_fpu_ex1_stall;
  output fdsu_fpu_no_op;
  output fdsu_frbus_wb_vld;
  output fdsu_yy_div;
  output [9 : 0] fdsu_yy_expnt_rst;
  output fdsu_yy_of;
  output fdsu_yy_of_rm_lfn;
  output fdsu_yy_op0_norm;
  output fdsu_yy_op1_norm;
  output fdsu_yy_potnt_of;
  output fdsu_yy_potnt_uf;
  output fdsu_yy_result_inf;
  output fdsu_yy_result_lfn;
  output fdsu_yy_result_sign;
  output [2 : 0] fdsu_yy_rm;
  output fdsu_yy_rslt_denorm;
  output fdsu_yy_sqrt;
  output fdsu_yy_uf;
  output [4 : 0] fdsu_yy_wb_freg;
  output srt_sm_on;


  reg          ex2_srt_first_round;
  reg  [2 : 0] fdsu_cur_state;
  reg          fdsu_div;
  reg  [9 : 0] fdsu_expnt_rst;
  reg  [2 : 0] fdsu_next_state;
  reg          fdsu_of;
  reg          fdsu_of_rm_lfn;
  reg          fdsu_potnt_of;
  reg          fdsu_potnt_uf;
  reg          fdsu_result_inf;
  reg          fdsu_result_lfn;
  reg          fdsu_result_sign;
  reg  [2 : 0] fdsu_rm;
  reg          fdsu_sqrt;
  reg          fdsu_uf;
  reg  [4 : 0] fdsu_wb_freg;
  reg          fdsu_yy_rslt_denorm;
  reg  [4 : 0] srt_cnt;
  reg  [1 : 0] wb_cur_state;
  reg  [1 : 0] wb_nxt_state;


  wire         cp0_fpu_icg_en;
  wire         cp0_yy_clk_en;
  wire         cpurst_b;
  wire         ctrl_fdsu_ex1_sel;
  wire         ctrl_fdsu_ex1_stall;
  wire         ctrl_fdsu_wb_vld;
  wire         ctrl_iter_start;
  wire         ctrl_iter_start_gate;
  wire         ctrl_pack;
  wire         ctrl_result_vld;
  wire         ctrl_round;
  wire         ctrl_sm_cmplt;
  wire         ctrl_sm_ex1;
  wire         ctrl_sm_idle;
  wire         ctrl_sm_start;
  wire         ctrl_sm_start_gate;
  wire         ctrl_srt_idle;
  wire         ctrl_srt_itering;
  wire         ctrl_wb_idle;
  wire         ctrl_wb_sm_cmplt;
  wire         ctrl_wb_sm_ex2;
  wire         ctrl_wb_sm_idle;
  wire         ctrl_wfi2;
  wire         ctrl_wfwb;
  wire         ctrl_xx_ex1_cmplt_dp;
  wire         ctrl_xx_ex1_inst_vld;
  wire         ctrl_xx_ex1_stall;
  wire         ctrl_xx_ex1_warm_up;
  wire         ctrl_xx_ex2_warm_up;
  wire         ctrl_xx_ex3_warm_up;
  wire         ex1_div;
  wire [ 12:0] ex1_expnt_adder_op0;
  wire         ex1_of_result_lfn;
  wire         ex1_op0_id;
  wire         ex1_op1_id_vld;
  wire         ex1_op1_sel;
  wire [ 12:0] ex1_oper_id_expnt;
  wire [ 12:0] ex1_oper_id_expnt_f;
  wire         ex1_pipe_clk;
  wire         ex1_pipe_clk_en;
  wire         ex1_pipedown;
  wire         ex1_pipedown_gate;
  wire         ex1_result_sign;
  wire [2 : 0] ex1_rm;
  wire         ex1_save_op0;
  wire         ex1_save_op0_gate;
  wire         ex1_sqrt;
  wire         ex1_srt_skip;
  wire [4 : 0] ex1_wb_freg;
  wire [9 : 0] ex2_expnt_adder_op0;
  wire         ex2_of;
  wire         ex2_pipe_clk;
  wire         ex2_pipe_clk_en;
  wire         ex2_pipedown;
  wire         ex2_potnt_of;
  wire         ex2_potnt_uf;
  wire         ex2_result_inf;
  wire         ex2_result_lfn;
  wire         ex2_rslt_denorm;
  wire [9 : 0] ex2_srt_expnt_rst;
  wire         ex2_uf;
  wire         ex2_uf_srt_skip;
  wire [9 : 0] ex3_expnt_adjust_result;
  wire         ex3_pipedown;
  wire         ex3_rslt_denorm;
  wire         expnt_rst_clk;
  wire         expnt_rst_clk_en;
  wire         fdsu_busy;
  wire         fdsu_clk;
  wire         fdsu_clk_en;
  wire         fdsu_dn_stall;
  wire         fdsu_ex1_inst_vld;
  wire         fdsu_ex1_res_vld;
  wire         fdsu_ex1_sel;
  wire         fdsu_flush;
  wire [4 : 0] fdsu_fpu_debug_info;
  wire         fdsu_fpu_ex1_cmplt;
  wire         fdsu_fpu_ex1_cmplt_dp;
  wire         fdsu_fpu_ex1_stall;
  wire         fdsu_fpu_no_op;
  wire         fdsu_frbus_wb_vld;
  wire         fdsu_op0_norm;
  wire         fdsu_op1_norm;
  wire         fdsu_wb_grant;
  wire         fdsu_yy_div;
  wire [9 : 0] fdsu_yy_expnt_rst;
  wire         fdsu_yy_of;
  wire         fdsu_yy_of_rm_lfn;
  wire         fdsu_yy_op0_norm;
  wire         fdsu_yy_op1_norm;
  wire         fdsu_yy_potnt_of;
  wire         fdsu_yy_potnt_uf;
  wire         fdsu_yy_result_inf;
  wire         fdsu_yy_result_lfn;
  wire         fdsu_yy_result_sign;
  wire [2 : 0] fdsu_yy_rm;
  wire         fdsu_yy_sqrt;
  wire         fdsu_yy_uf;
  wire [4 : 0] fdsu_yy_wb_freg;
  wire         forever_cpuclk;
  wire         frbus_fdsu_wb_grant;
  wire [4 : 0] idu_fpu_ex1_dst_freg;
  wire [2 : 0] idu_fpu_ex1_eu_sel;
  wire         pad_yy_icg_scan_en;
  wire         rtu_xx_ex1_cancel;
  wire         rtu_xx_ex2_cancel;
  wire         rtu_yy_xx_async_flush;
  wire         rtu_yy_xx_flush;
  wire [4 : 0] srt_cnt_ini;
  wire         srt_cnt_zero;
  wire         srt_last_round;
  wire         srt_remainder_zero;
  wire         srt_skip;
  wire         srt_sm_on;

  // Assign EX1 WB register
  assign ex1_wb_freg[4:0] = idu_fpu_ex1_dst_freg[4:0];
  // FDSU EX1 instruction valid
  assign fdsu_ex1_inst_vld = ctrl_xx_ex1_inst_vld && ctrl_fdsu_ex1_sel;
  // Select FDSU for EX1 based on EU select
  assign fdsu_ex1_sel = idu_fpu_ex1_eu_sel[2];


  // FDSU EX1 result valid
  assign fdsu_ex1_res_vld = fdsu_ex1_inst_vld && ex1_srt_skip;
  // Assign writeback grant signal
  assign fdsu_wb_grant = frbus_fdsu_wb_grant;

  assign ctrl_iter_start = ctrl_sm_start && !fdsu_dn_stall  // Start iteration condition
      || ctrl_wfi2;  // OR wait for instruction 2
  assign ctrl_iter_start_gate = ctrl_sm_start_gate && !fdsu_dn_stall  // Gated start iteration
      || ctrl_wfi2;  // OR wait for instruction 2
  assign ctrl_sm_start = fdsu_ex1_inst_vld && ctrl_srt_idle  // Start state machine condition
      && !ex1_srt_skip;  // AND not SRT skip
  assign ctrl_sm_start_gate = fdsu_ex1_inst_vld && ctrl_srt_idle;  // Gated start condition

  assign srt_last_round = (srt_skip ||  // Last SRT round condition
      srt_remainder_zero ||  // OR remainder is zero
      srt_cnt_zero)  // OR SRT count is zero
      && ctrl_srt_itering;  // AND SRT is iterating
  assign srt_skip = ex2_of ||  // Skip SRT condition
      ex2_uf_srt_skip;  // OR underflow SRT skip
  assign srt_cnt_zero = ~|srt_cnt[4:0];  // SRT count is zero
  assign fdsu_dn_stall = ctrl_sm_start && ex1_op1_id_vld;  // Stall condition

  parameter int IDLE = 3'b000;  // Define IDLE state
  parameter int WFI2 = 3'b001;  // Define Wait For Instruction 2 state
  parameter int ITER = 3'b010;  // Define ITERATION state
  parameter int RND = 3'b011;  // Define ROUNDING state
  parameter int PACK = 3'b100;  // Define PACKING state
  parameter int WFWB = 3'b101;  // Define Wait For Write Back state

  always @(posedge fdsu_clk or negedge cpurst_b) begin
    if (!cpurst_b) fdsu_cur_state[2:0] <= IDLE;  // Reset state to IDLE
    else if (fdsu_flush) fdsu_cur_state[2:0] <= IDLE;  // Flush: go to IDLE
    else fdsu_cur_state[2:0] <= fdsu_next_state[2:0];  // Update current state
  end


  always @( ctrl_sm_start
        or fdsu_dn_stall
        or srt_last_round
        or fdsu_cur_state[2:0]
        or fdsu_wb_grant)
begin
    case (fdsu_cur_state[2:0])
      IDLE: begin
        if (ctrl_sm_start)
          if (fdsu_dn_stall) fdsu_next_state[2:0] = WFI2;  // Go to WFI2 if stalled
          else fdsu_next_state[2:0] = ITER;  // Go to ITER if not stalled
        else fdsu_next_state[2:0] = IDLE;  // Stay in IDLE
      end
      WFI2: fdsu_next_state[2:0] = ITER;  // Go to ITER
      ITER: begin
        if (srt_last_round) fdsu_next_state[2:0] = RND;  // Go to RND if last SRT round
        else fdsu_next_state[2:0] = ITER;  // Stay in ITER
      end
      RND: fdsu_next_state[2:0] = PACK;  // Go to PACK
      PACK: begin
        if (fdsu_wb_grant)
          if (ctrl_sm_start)
            if (fdsu_dn_stall) fdsu_next_state[2:0] = WFI2;  // Go to WFI2 if stalled
            else fdsu_next_state[2:0] = ITER;  // Go to ITER if not stalled
          else fdsu_next_state[2:0] = IDLE;  // Go to IDLE
        else fdsu_next_state[2:0] = WFWB;  // Go to WFWB
      end
      WFWB: begin
        if (fdsu_wb_grant)
          if (ctrl_sm_start)
            if (fdsu_dn_stall) fdsu_next_state[2:0] = WFI2;  // Go to WFI2 if stalled
            else fdsu_next_state[2:0] = ITER;  // Go to ITER if not stalled
          else fdsu_next_state[2:0] = IDLE;  // Go to IDLE
        else fdsu_next_state[2:0] = WFWB;  // Stay in WFWB
      end
      default: fdsu_next_state[2:0] = IDLE;  // Default to IDLE
    endcase

  end

  assign ctrl_sm_idle = fdsu_cur_state[2:0] == IDLE;  // State is IDLE
  assign ctrl_wfi2 = fdsu_cur_state[2:0] == WFI2;  // State is WFI2
  assign ctrl_srt_itering = fdsu_cur_state[2:0] == ITER;  // State is ITER
  assign ctrl_round = fdsu_cur_state[2:0] == RND;  // State is RND
  assign ctrl_pack = fdsu_cur_state[2:0] == PACK;  // State is PACK
  assign ctrl_wfwb = fdsu_cur_state[2:0] == WFWB;  // State is WFWB

  assign ctrl_sm_cmplt = ctrl_pack || ctrl_wfwb;  // SM complete condition
  assign ctrl_srt_idle = ctrl_sm_idle  // SRT idle condition
      || fdsu_wb_grant;  // OR writeback granted
  assign ctrl_sm_ex1 = ctrl_srt_idle || ctrl_wfi2;  // EX1 SM condition


  always @(posedge fdsu_clk) begin
    if (fdsu_flush) srt_cnt[4:0] <= 5'b0;  // Reset SRT counter
    else if (ctrl_iter_start) srt_cnt[4:0] <= srt_cnt_ini[4:0];  // Initialize SRT counter
    else if (ctrl_srt_itering) srt_cnt[4:0] <= srt_cnt[4:0] - 5'd1;  // Decrement SRT counter
    else srt_cnt[4:0] <= srt_cnt[4:0];  // Keep current SRT count
  end


  assign srt_cnt_ini[4:0] = 5'b01110;  // Initial value for SRT counter



  always @(posedge fdsu_clk or negedge cpurst_b) begin
    if (!cpurst_b) ex2_srt_first_round <= 1'b0;  // Reset first round flag
    else if (fdsu_flush) ex2_srt_first_round <= 1'b0;  // Reset first round flag on flush
    else if (ex1_pipedown) ex2_srt_first_round <= 1'b1;  // Set first round flag
    else ex2_srt_first_round <= 1'b0;  // Clear first round flag
  end


  parameter int WB_IDLE = 2'b00,  // Define Write Back IDLE state
  WB_EX2 = 2'b10,  // Define Write Back EX2 state
  WB_CMPLT = 2'b01;  // Define Write Back COMPLETE state

  always @(posedge fdsu_clk or negedge cpurst_b) begin
    if (!cpurst_b) wb_cur_state[1:0] <= WB_IDLE;  // Reset WB state to IDLE
    else if (fdsu_flush) wb_cur_state[1:0] <= WB_IDLE;  // Flush: go to WB_IDLE
    else wb_cur_state[1:0] <= wb_nxt_state[1:0];  // Update WB current state
  end


  always @( ctrl_fdsu_wb_vld
        or fdsu_dn_stall
        or ctrl_xx_ex1_stall
        or fdsu_ex1_inst_vld
        or ctrl_iter_start
        or fdsu_ex1_res_vld
        or wb_cur_state[1:0])
begin
    case (wb_cur_state[1:0])
      WB_IDLE:
      if (fdsu_ex1_inst_vld)
        if (ctrl_xx_ex1_stall || fdsu_ex1_res_vld || fdsu_dn_stall)
          wb_nxt_state[1:0] = WB_IDLE;  // Stay in WB_IDLE
        else wb_nxt_state[1:0] = WB_EX2;  // Go to WB_EX2
      else wb_nxt_state[1:0] = WB_IDLE;  // Stay in WB_IDLE
      WB_EX2:


      if (ctrl_fdsu_wb_vld)
        if (ctrl_iter_start && !ctrl_xx_ex1_stall) wb_nxt_state[1:0] = WB_EX2;  // Stay in WB_EX2
        else wb_nxt_state[1:0] = WB_IDLE;  // Go to WB_IDLE
      else wb_nxt_state[1:0] = WB_CMPLT;  // Go to WB_CMPLT
      WB_CMPLT:
      if (ctrl_fdsu_wb_vld)
        if (ctrl_iter_start && !ctrl_xx_ex1_stall) wb_nxt_state[1:0] = WB_EX2;  // Go to WB_EX2
        else wb_nxt_state[1:0] = WB_IDLE;  // Go to WB_IDLE
      else wb_nxt_state[1:0] = WB_CMPLT;  // Stay in WB_CMPLT
      default: wb_nxt_state[1:0] = WB_IDLE;  // Default to WB_IDLE
    endcase

  end

  assign ctrl_wb_idle = wb_cur_state[1:0] == WB_IDLE  // WB is idle
      || wb_cur_state[1:0] == WB_CMPLT && ctrl_fdsu_wb_vld;
  assign ctrl_wb_sm_idle = wb_cur_state[1:0] == WB_IDLE;  // WB SM is idle
  assign ctrl_wb_sm_ex2 = wb_cur_state[1:0] == WB_EX2;  // WB SM is in EX2
  assign ctrl_wb_sm_cmplt = wb_cur_state[1:0] == WB_EX2  // WB SM is complete
      || wb_cur_state[1:0] == WB_CMPLT;

  assign ctrl_result_vld = ctrl_sm_cmplt && ctrl_wb_sm_cmplt;  // Result valid condition
  assign ctrl_fdsu_wb_vld = ctrl_result_vld && frbus_fdsu_wb_grant;  // FDSU WB valid

  // Stall condition OR down stall
  assign ctrl_fdsu_ex1_stall = fdsu_ex1_inst_vld && !ctrl_sm_ex1 && !ctrl_wb_idle
      || fdsu_ex1_inst_vld && fdsu_dn_stall;


  always @(posedge ex1_pipe_clk) begin
    if (ex1_pipedown) begin
      fdsu_wb_freg[4:0] <= ex1_wb_freg[4:0];  // Pipeline WB register
      fdsu_result_sign  <= ex1_result_sign;  // Pipeline result sign
      fdsu_of_rm_lfn    <= ex1_of_result_lfn;  // Pipeline overflow LFN
      fdsu_div          <= ex1_div;  // Pipeline division flag
      fdsu_sqrt         <= ex1_sqrt;  // Pipeline square root flag
      fdsu_rm[2:0]      <= ex1_rm[2:0];  // Pipeline rounding mode
    end else begin
      fdsu_wb_freg[4:0] <= fdsu_wb_freg[4:0];  // Keep WB register
      fdsu_result_sign  <= fdsu_result_sign;  // Keep result sign
      fdsu_of_rm_lfn    <= fdsu_of_rm_lfn;  // Keep overflow LFN
      fdsu_div          <= fdsu_div;  // Keep division flag
      fdsu_sqrt         <= fdsu_sqrt;  // Keep square root flag
      fdsu_rm[2:0]      <= fdsu_rm[2:0];  // Keep rounding mode
    end
  end


  assign fdsu_op0_norm = 1'b1;  // Assume operand 0 is normalized
  assign fdsu_op1_norm = 1'b1;  // Assume operand 1 is normalized


  always @(posedge expnt_rst_clk) begin
    if (ex1_save_op0) fdsu_expnt_rst[9:0] <= ex1_oper_id_expnt[9:0];  // Save operand 0 exponent
    else if (ex1_pipedown)
      fdsu_expnt_rst[9:0] <= ex1_expnt_adder_op0[9:0];  // Pipeline EX1 exponent
    else if (ex2_pipedown) fdsu_expnt_rst[9:0] <= ex2_srt_expnt_rst[9:0];  // Pipeline EX2 exponent
    else if (ex3_pipedown)
      fdsu_expnt_rst[9:0] <= ex3_expnt_adjust_result[9:0];  // Pipeline EX3 exponent
    else fdsu_expnt_rst[9:0] <= fdsu_expnt_rst[9:0];  // Keep current exponent
  end

  assign ex1_oper_id_expnt_f[12:0] = {3'd1, fdsu_expnt_rst[9:0]};  // Format exponent

  always @(posedge expnt_rst_clk) begin
    if (ex2_pipedown) fdsu_yy_rslt_denorm <= ex2_rslt_denorm;  // Pipeline EX2 denormal
    else if (ex3_pipedown) fdsu_yy_rslt_denorm <= ex3_rslt_denorm;  // Pipeline EX3 denormal
    else fdsu_yy_rslt_denorm <= fdsu_yy_rslt_denorm;  // Keep current denormal
  end


  always @(posedge ex2_pipe_clk) begin
    if (ex2_pipedown) begin
      fdsu_result_inf <= ex2_result_inf;  // Pipeline EX2 infinity
      fdsu_result_lfn <= ex2_result_lfn;  // Pipeline EX2 LFN
      fdsu_of         <= ex2_of;  // Pipeline EX2 overflow
      fdsu_uf         <= ex2_uf;  // Pipeline EX2 underflow
      fdsu_potnt_of   <= ex2_potnt_of;  // Pipeline EX2 potential overflow
      fdsu_potnt_uf   <= ex2_potnt_uf;  // Pipeline EX2 potential underflow
    end else begin
      fdsu_result_inf <= fdsu_result_inf;  // Keep infinity
      fdsu_result_lfn <= fdsu_result_lfn;  // Keep LFN
      fdsu_of         <= fdsu_of;  // Keep overflow
      fdsu_uf         <= fdsu_uf;  // Keep underflow
      fdsu_potnt_of   <= fdsu_potnt_of;  // Keep potential overflow
      fdsu_potnt_uf   <= fdsu_potnt_uf;  // Keep potential underflow
    end
  end


  assign fdsu_flush = rtu_xx_ex1_cancel && ctrl_wb_idle  // Flush from RTU EX1
      || rtu_xx_ex2_cancel && ctrl_wb_sm_ex2  // Flush from RTU EX2
      || ctrl_xx_ex1_warm_up  // Warm-up flush
      || rtu_yy_xx_async_flush;  // Asynchronous flush


  assign fdsu_busy = fdsu_ex1_inst_vld  // FDSU is busy
      || !ctrl_sm_idle  // OR state machine is not idle
      || !ctrl_wb_sm_idle;  // OR writeback SM is not idle
  assign fdsu_clk_en = fdsu_busy  // Enable clock when busy
      || !ctrl_sm_idle  // OR state machine is not idle
      || rtu_yy_xx_flush;  // OR during flush

  gated_clk_cell x_fdsu_clk (  // Gated clock cell for FDSU
      .clk_in            (forever_cpuclk),
      .clk_out           (fdsu_clk),
      .external_en       (1'b0),
      .global_en         (cp0_yy_clk_en),
      .local_en          (fdsu_clk_en),
      .module_en         (cp0_fpu_icg_en),
      .pad_yy_icg_scan_en(pad_yy_icg_scan_en)
  );


  assign ex1_pipe_clk_en = ex1_pipedown_gate;  // Enable EX1 pipe clock

  gated_clk_cell x_ex1_pipe_clk (  // Gated clock cell for EX1 pipeline
      .clk_in            (forever_cpuclk),
      .clk_out           (ex1_pipe_clk),
      .external_en       (1'b0),
      .global_en         (cp0_yy_clk_en),
      .local_en          (ex1_pipe_clk_en),
      .module_en         (cp0_fpu_icg_en),
      .pad_yy_icg_scan_en(pad_yy_icg_scan_en)
  );


  assign ex2_pipe_clk_en = ex2_pipedown;  // Enable EX2 pipe clock

  gated_clk_cell x_ex2_pipe_clk (  // Gated clock cell for EX2 pipeline
      .clk_in            (forever_cpuclk),
      .clk_out           (ex2_pipe_clk),
      .external_en       (1'b0),
      .global_en         (cp0_yy_clk_en),
      .local_en          (ex2_pipe_clk_en),
      .module_en         (cp0_fpu_icg_en),
      .pad_yy_icg_scan_en(pad_yy_icg_scan_en)
  );


  assign expnt_rst_clk_en = ex1_save_op0_gate  // Enable exponent reset clock
      || ex1_pipedown_gate || ex2_pipedown || ex3_pipedown;

  gated_clk_cell x_expnt_rst_clk (  // Gated clock cell for exponent reset
      .clk_in            (forever_cpuclk),
      .clk_out           (expnt_rst_clk),
      .external_en       (1'b0),
      .global_en         (cp0_yy_clk_en),
      .local_en          (expnt_rst_clk_en),
      .module_en         (cp0_fpu_icg_en),
      .pad_yy_icg_scan_en(pad_yy_icg_scan_en)
  );


  // Output WB register
  assign fdsu_yy_wb_freg[4:0] = fdsu_wb_freg[4:0];
  // Output result sign
  assign fdsu_yy_result_sign = fdsu_result_sign;
  // Output operand 0 norm
  assign fdsu_yy_op0_norm = fdsu_op0_norm;
  // Output operand 1 norm
  assign fdsu_yy_op1_norm = fdsu_op1_norm;
  // Output overflow LFN
  assign fdsu_yy_of_rm_lfn = fdsu_of_rm_lfn;
  // Output division
  assign fdsu_yy_div = fdsu_div;
  // Output square root
  assign fdsu_yy_sqrt = fdsu_sqrt;
  // Output rounding mode
  assign fdsu_yy_rm[2:0] = fdsu_rm[2:0];

  // Output exponent reset
  assign fdsu_yy_expnt_rst[9:0] = fdsu_expnt_rst[9:0];
  // Output EX2 exponent
  assign ex2_expnt_adder_op0[9:0] = fdsu_expnt_rst[9:0];

  // Output infinity
  assign fdsu_yy_result_inf = fdsu_result_inf;
  // Output LFN
  assign fdsu_yy_result_lfn = fdsu_result_lfn;
  // Output overflow
  assign fdsu_yy_of = fdsu_of;
  // Output underflow
  assign fdsu_yy_uf = fdsu_uf;
  // Output potential overflow
  assign fdsu_yy_potnt_of = fdsu_potnt_of;
  // Output potential underflow
  assign fdsu_yy_potnt_uf = fdsu_potnt_uf;

  // EX1 pipedown
  assign ex1_pipedown = ctrl_iter_start || ctrl_xx_ex1_warm_up;
  // EX1 pipedown gate
  assign ex1_pipedown_gate = ctrl_iter_start_gate || ctrl_xx_ex1_warm_up;
  // EX2 pipedown
  assign ex2_pipedown = ctrl_srt_itering && srt_last_round || ctrl_xx_ex2_warm_up;
  // EX3 pipedown
  assign ex3_pipedown = ctrl_round || ctrl_xx_ex3_warm_up;


  // SRT state machine on
  assign srt_sm_on = ctrl_srt_itering;

  // FPU EX1 complete
  assign fdsu_fpu_ex1_cmplt = fdsu_ex1_inst_vld;
  // FPU EX1 complete DP
  assign fdsu_fpu_ex1_cmplt_dp = ctrl_xx_ex1_cmplt_dp && idu_fpu_ex1_eu_sel[2];
  // FPU EX1 stall
  assign fdsu_fpu_ex1_stall = ctrl_fdsu_ex1_stall;
  // FRBUS writeback valid
  assign fdsu_frbus_wb_vld = ctrl_result_vld;

  // FPU no operation
  assign fdsu_fpu_no_op = !fdsu_busy;
  // Select operand 1
  assign ex1_op1_sel = ctrl_wfi2;
  // Save operand 0
  assign ex1_save_op0 = ctrl_sm_start && ex1_op0_id && ex1_op1_id_vld;
  // Save operand 0 gate
  assign ex1_save_op0_gate = ctrl_sm_start_gate && ex1_op0_id && ex1_op1_id_vld;


  // Debug info
  assign fdsu_fpu_debug_info[4:0] = {wb_cur_state[1:0], fdsu_cur_state[2:0]};

endmodule
