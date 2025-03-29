// Module for single-precision SRT division and square root unit
module pa_fdsu_srt_single (
    cp0_fpu_icg_en,  // Input: Clock gating enable from CP0
    cp0_yy_clk_en,  // Input: Clock enable from CP0
    ex1_divisor,  // Input: Divisor from EX1 stage
    ex1_expnt_adder_op1,  // Input: Exponent operand 1 from EX1
    ex1_oper_id_frac,  // Input: Operand fraction from EX1
    ex1_oper_id_frac_f,  // Output: Formatted operand fraction for EX1
    ex1_pipedown,  // Input: Pipedown signal from EX1
    ex1_pipedown_gate,  // Input: Pipedown gate signal from EX1
    ex1_remainder,  // Input: Remainder from EX1
    ex1_save_op0,  // Input: Save operand 0 signal from EX1
    ex1_save_op0_gate,  // Input: Save operand 0 gate from EX1
    ex2_expnt_adder_op0,  // Input: Exponent operand 0 from EX2
    ex2_of,  // Output: Overflow flag for EX2
    ex2_pipe_clk,  // Input: Clock for EX2 stage
    ex2_pipedown,  // Input: Pipedown signal from EX2
    ex2_potnt_of,  // Output: Potential overflow flag for EX2
    ex2_potnt_uf,  // Output: Potential underflow flag for EX2
    ex2_result_inf,  // Output: Result infinity flag for EX2
    ex2_result_lfn,  // Output: Result large finite number flag for EX2
    ex2_rslt_denorm,  // Output: Result denorm flag for EX2
    ex2_srt_expnt_rst,  // Output: SRT exponent result for EX2
    ex2_srt_first_round,  // Input: First round flag for SRT in EX2
    ex2_uf,  // Output: Underflow flag for EX2
    ex2_uf_srt_skip,  // Output: Underflow skip flag for SRT in EX2
    ex3_frac_final_rst,  // Input: Final fraction reset from EX3
    ex3_pipedown,  // Input: Pipedown signal from EX3
    fdsu_ex3_id_srt_skip,  // Output: SRT skip flag for EX3 (ID)
    fdsu_ex3_rem_sign,  // Output: Remainder sign for EX3
    fdsu_ex3_rem_zero,  // Output: Remainder zero flag for EX3
    fdsu_ex3_result_denorm_round_add_num,  // Output: Denorm round add num for EX3
    fdsu_ex4_frac,  // Input: Fraction from EX4 stage
    fdsu_yy_div,  // Input: Division operation flag
    fdsu_yy_of_rm_lfn,  // Input: Overflow/LFN with rounding mode flag
    fdsu_yy_op0_norm,  // Input: Operand 0 normalized flag
    fdsu_yy_op1_norm,  // Input: Operand 1 normalized flag
    fdsu_yy_sqrt,  // Input: Square root operation flag
    forever_cpuclk,  // Input: System clock
    pad_yy_icg_scan_en,  // Input: Scan enable for clock gating
    srt_remainder_zero,  // Output: SRT remainder zero flag
    srt_sm_on,  // Input: SRT state machine on flag
    total_qt_rt_30  // Output: Total quotient/remainder bits (30)
);

  input cp0_fpu_icg_en;  // Input: Clock gate enable
  input cp0_yy_clk_en;  // Input: System clock enable
  input [23:0] ex1_divisor;  // Input: Divisor
  input [12:0] ex1_expnt_adder_op1;  // Input: Exponent operand 1
  input [51:0] ex1_oper_id_frac;  // Input: Operand fraction
  input ex1_pipedown;  // Input: EX1 pipedown
  input ex1_pipedown_gate;  // Input: EX1 pipedown gate
  input [31:0] ex1_remainder;  // Input: Remainder
  input ex1_save_op0;  // Input: Save operand 0
  input ex1_save_op0_gate;  // Input: Save operand 0 gate
  input [9 : 0] ex2_expnt_adder_op0;  // Input: Exponent operand 0
  input ex2_pipe_clk;  // Input: EX2 clock
  input ex2_pipedown;  // Input: EX2 pipedown
  input ex2_srt_first_round;  // Input: EX2 SRT first round
  input [25:0] ex3_frac_final_rst;  // Input: EX3 fraction reset
  input ex3_pipedown;  // Input: EX3 pipedown
  input fdsu_yy_div;  // Input: Division flag
  input fdsu_yy_of_rm_lfn;  // Input: OF/LFN flag
  input fdsu_yy_op0_norm;  // Input: Operand 0 norm flag
  input fdsu_yy_op1_norm;  // Input: Operand 1 norm flag
  input fdsu_yy_sqrt;  // Input: Square root flag
  input forever_cpuclk;  // Input: Forever clock
  input pad_yy_icg_scan_en;  // Input: ICG scan enable
  input srt_sm_on;  // Input: SRT state machine on
  output [51:0] ex1_oper_id_frac_f;  // Output: Formatted operand fraction
  output ex2_of;  // Output: Overflow
  output ex2_potnt_of;  // Output: Potential overflow
  output ex2_potnt_uf;  // Output: Potential underflow
  output ex2_result_inf;  // Output: Result infinity
  output ex2_result_lfn;  // Output: Result LFN
  output ex2_rslt_denorm;  // Output: Result denorm
  output [9 : 0] ex2_srt_expnt_rst;  // Output: SRT exponent result
  output ex2_uf;  // Output: Underflow
  output ex2_uf_srt_skip;  // Output: Underflow SRT skip
  output fdsu_ex3_id_srt_skip;  // Output: EX3 ID SRT skip
  output fdsu_ex3_rem_sign;  // Output: EX3 remainder sign
  output fdsu_ex3_rem_zero;  // Output: EX3 remainder zero
  output [23:0] fdsu_ex3_result_denorm_round_add_num;  // Output: EX3 denorm add num
  output [25:0] fdsu_ex4_frac;  // Output: EX4 fraction
  output srt_remainder_zero;  // Output: SRT remainder zero
  output [29:0] total_qt_rt_30;  // Output: Total quotient/remainder

  reg  [ 31:0] cur_rem;  // Register for current remainder
  reg  [7 : 0] digit_bound_1;  // Register for digit bound 1
  reg  [7 : 0] digit_bound_2;  // Register for digit bound 2
  reg  [ 23:0] ex2_result_denorm_round_add_num;  // Register for denorm round add num
  reg          fdsu_ex3_id_srt_skip;  // Register for EX3 ID SRT skip
  reg          fdsu_ex3_rem_sign;  // Register for EX3 remainder sign
  reg          fdsu_ex3_rem_zero;  // Register for EX3 remainder zero
  reg  [ 23:0] fdsu_ex3_result_denorm_round_add_num;  // Register for EX3 denorm add num
  reg  [ 29:0] qt_rt_const_shift_std;  // Register for quotient/remainder shift
  reg  [7 : 0] qtrt_sel_rem;  // Register for selected remainder bits
  reg  [ 31:0] rem_add1_op1;  // Register for remainder add operand 1
  reg  [ 31:0] rem_add2_op1;  // Register for remainder add operand 2
  reg  [ 25:0] srt_divisor;  // Register for SRT divisor
  reg  [ 31:0] srt_remainder;  // Register for SRT remainder
  reg  [ 29:0] total_qt_rt_30;  // Register for total quotient/remainder
  reg  [ 29:0] total_qt_rt_30_next;  // Register for next total quotient/remainder
  reg  [ 29:0] total_qt_rt_minus_30;  // Register for total quotient/remainder minus
  reg  [ 29:0] total_qt_rt_minus_30_next;  // Register for next total quotient/remainder minus

  wire [7 : 0] bound1_cmp_result;  // Wire for bound 1 compare result
  wire         bound1_cmp_sign;  // Wire for bound 1 compare sign
  wire [7 : 0] bound2_cmp_result;  // Wire for bound 2 compare result
  wire         bound2_cmp_sign;  // Wire for bound 2 compare sign
  wire [3 : 0] bound_sel;  // Wire for bound select
  wire         cp0_fpu_icg_en;  // Wire for clock gate enable
  wire         cp0_yy_clk_en;  // Wire for system clock enable
  wire [ 31:0] cur_doub_rem_1;  // Wire for current doubled remainder 1
  wire [ 31:0] cur_doub_rem_2;  // Wire for current doubled remainder 2
  wire [ 31:0] cur_rem_1;  // Wire for current remainder 1
  wire [ 31:0] cur_rem_2;  // Wire for current remainder 2
  wire [ 31:0] div_qt_1_rem_add_op1;  // Wire for division quotient 1 add op1
  wire [ 31:0] div_qt_2_rem_add_op1;  // Wire for division quotient 2 add op1
  wire [ 31:0] div_qt_r1_rem_add_op1;  // Wire for division remainder 1 add op1
  wire [ 31:0] div_qt_r2_rem_add_op1;  // Wire for division remainder 2 add op1
  wire [ 23:0] ex1_divisor;  // Wire for divisor
  wire         ex1_ex2_pipe_clk;  // Wire for EX1-EX2 pipe clock
  wire         ex1_ex2_pipe_clk_en;  // Wire for EX1-EX2 pipe clock enable
  wire [ 12:0] ex1_expnt_adder_op1;  // Wire for exponent operand 1
  wire [ 51:0] ex1_oper_id_frac;  // Wire for operand fraction
  wire [ 51:0] ex1_oper_id_frac_f;  // Wire for formatted operand fraction
  wire         ex1_pipedown;  // Wire for EX1 pipedown
  wire         ex1_pipedown_gate;  // Wire for EX1 pipedown gate
  wire [ 31:0] ex1_remainder;  // Wire for remainder
  wire         ex1_save_op0;  // Wire for save operand 0
  wire         ex1_save_op0_gate;  // Wire for save operand 0 gate
  wire         ex2_div_of;  // Wire for EX2 division overflow
  wire         ex2_div_uf;  // Wire for EX2 division underflow
  wire [9 : 0] ex2_expnt_adder_op0;  // Wire for exponent operand 0
  wire [9 : 0] ex2_expnt_adder_op1;  // Wire for exponent operand 1
  wire         ex2_expnt_of;  // Wire for EX2 exponent overflow
  wire [9 : 0] ex2_expnt_result;  // Wire for exponent result
  wire         ex2_expnt_uf;  // Wire for EX2 exponent underflow
  wire         ex2_id_nor_srt_skip;  // Wire for EX2 ID/norm SRT skip
  wire         ex2_of;  // Wire for overflow
  wire         ex2_of_plus;  // Wire for overflow plus
  wire         ex2_pipe_clk;  // Wire for EX2 clock
  wire         ex2_pipedown;  // Wire for EX2 pipedown
  wire         ex2_potnt_of;  // Wire for potential overflow
  wire         ex2_potnt_of_pre;  // Wire for potential overflow pre
  wire         ex2_potnt_uf;  // Wire for potential underflow
  wire         ex2_potnt_uf_pre;  // Wire for potential underflow pre
  wire         ex2_result_inf;  // Wire for result infinity
  wire         ex2_result_lfn;  // Wire for result LFN
  wire         ex2_rslt_denorm;  // Wire for result denorm
  wire [9 : 0] ex2_sqrt_expnt_result;  // Wire for square root exponent result
  wire [9 : 0] ex2_srt_expnt_rst;  // Wire for SRT exponent reset
  wire         ex2_srt_first_round;  // Wire for EX2 SRT first round
  wire         ex2_uf;  // Wire for underflow
  wire         ex2_uf_plus;  // Wire for underflow plus
  wire         ex2_uf_srt_skip;  // Wire for underflow SRT skip
  wire [ 25:0] ex3_frac_final_rst;  // Wire for EX3 final fraction reset
  wire         ex3_pipedown;  // Wire for EX3 pipedown
  wire         fdsu_ex2_div;  // Wire for EX2 division flag
  wire [9 : 0] fdsu_ex2_expnt_rst;  // Wire for EX2 exponent reset
  wire         fdsu_ex2_of_rm_lfn;  // Wire for EX2 OF/LFN flag
  wire         fdsu_ex2_op0_norm;  // Wire for EX2 operand 0 norm
  wire         fdsu_ex2_op1_norm;  // Wire for EX2 operand 1 norm
  wire         fdsu_ex2_result_lfn;  // Wire for EX2 result LFN
  wire         fdsu_ex2_sqrt;  // Wire for EX2 square root flag
  wire [ 25:0] fdsu_ex4_frac;  // Wire for EX4 fraction
  wire         fdsu_yy_div;  // Wire for division flag
  wire         fdsu_yy_of_rm_lfn;  // Wire for OF/LFN flag
  wire         fdsu_yy_op0_norm;  // Wire for operand 0 norm flag
  wire         fdsu_yy_op1_norm;  // Wire for operand 1 norm flag
  wire         fdsu_yy_sqrt;  // Wire for square root flag
  wire         forever_cpuclk;  // Wire for forever clock
  wire         pad_yy_icg_scan_en;  // Wire for ICG scan enable
  wire         qt_clk;  // Wire for quotient clock
  wire         qt_clk_en;  // Wire for quotient clock enable
  wire [ 29:0] qt_rt_const_pre_sel_q1;  // Wire for QR constant pre-select q1
  wire [ 29:0] qt_rt_const_pre_sel_q2;  // Wire for QR constant pre-select q2
  wire [ 29:0] qt_rt_const_q1;  // Wire for QR constant q1
  wire [ 29:0] qt_rt_const_q2;  // Wire for QR constant q2
  wire [ 29:0] qt_rt_const_q3;  // Wire for QR constant q3
  wire [ 29:0] qt_rt_const_shift_std_next;  // Wire for QR shift next
  wire [ 29:0] qt_rt_mins_const_pre_sel_q1;  // Wire for QR minus pre-select q1
  wire [ 29:0] qt_rt_mins_const_pre_sel_q2;  // Wire for QR minus pre-select q2
  wire         rem_sign;  // Wire for remainder sign
  wire [ 31:0] sqrt_qt_1_rem_add_op1;  // Wire for sqrt quotient 1 add op1
  wire [ 31:0] sqrt_qt_2_rem_add_op1;  // Wire for sqrt quotient 2 add op1
  wire [ 31:0] sqrt_qt_r1_rem_add_op1;  // Wire for sqrt remainder 1 add op1
  wire [ 31:0] sqrt_qt_r2_rem_add_op1;  // Wire for sqrt remainder 2 add op1
  wire         srt_div_clk;  // Wire for SRT division clock
  wire         srt_div_clk_en;  // Wire for SRT division clock enable
  wire [ 31:0] srt_remainder_nxt;  // Wire for next SRT remainder
  wire [ 31:0] srt_remainder_shift;  // Wire for shifted SRT remainder
  wire         srt_remainder_sign;  // Wire for SRT remainder sign
  wire         srt_remainder_zero;  // Wire for SRT remainder zero
  wire         srt_sm_on;  // Wire for SRT state machine on
  wire [ 29:0] total_qt_rt_pre_sel;  // Wire for total QR pre-select

  // Assign signals for division and square root flags
  assign fdsu_ex2_div = fdsu_yy_div;
  assign fdsu_ex2_sqrt = fdsu_yy_sqrt;
  assign fdsu_ex2_op0_norm = fdsu_yy_op0_norm;
  assign fdsu_ex2_op1_norm = fdsu_yy_op1_norm;
  assign fdsu_ex2_of_rm_lfn = fdsu_yy_of_rm_lfn;
  assign fdsu_ex2_result_lfn = 1'b0;

  // Calculate the exponent result after SRT operation
  assign ex2_expnt_result[9:0] = ex2_expnt_adder_op0[9:0] - ex2_expnt_adder_op1[9:0];

  // Adjust exponent for square root operation
  assign ex2_sqrt_expnt_result[9:0] = {ex2_expnt_result[9], ex2_expnt_result[9:1]};

  // Select the exponent result based on operation type (div or sqrt)
  assign ex2_srt_expnt_rst[9:0] = (fdsu_ex2_sqrt)
                               ? ex2_sqrt_expnt_result[9:0]
                               : ex2_expnt_result[9:0];

  // Assign the SRT exponent result to the next stage
  assign fdsu_ex2_expnt_rst[9:0] = ex2_srt_expnt_rst[9:0];

  // Detect exponent overflow
  assign ex2_expnt_of = ~fdsu_ex2_expnt_rst[9] && (fdsu_ex2_expnt_rst[8] ||
                      (fdsu_ex2_expnt_rst[7] && |fdsu_ex2_expnt_rst[6:0]));

  // Detect potential exponent overflow
  assign ex2_potnt_of_pre = ~fdsu_ex2_expnt_rst[9] &&
                          ~fdsu_ex2_expnt_rst[8] &&
                           fdsu_ex2_expnt_rst[7] &&
                          ~|fdsu_ex2_expnt_rst[6:0];
  // Final potential overflow condition
  assign ex2_potnt_of = ex2_potnt_of_pre && fdsu_ex2_op0_norm && fdsu_ex2_op1_norm && fdsu_ex2_div;

  // Detect exponent underflow
  assign ex2_expnt_uf = fdsu_ex2_expnt_rst[9] && (fdsu_ex2_expnt_rst[8:0] <= 9'h181);

  // Detect potential exponent underflow
  assign ex2_potnt_uf_pre = &fdsu_ex2_expnt_rst[9:7] &&
                          ~|fdsu_ex2_expnt_rst[6:2] &&
                           fdsu_ex2_expnt_rst[1]   &&
                          !fdsu_ex2_expnt_rst[0];
  // Final potential underflow condition
  assign ex2_potnt_uf     = (ex2_potnt_uf_pre &&
                          fdsu_ex2_op0_norm &&
                          fdsu_ex2_op1_norm &&
                          fdsu_ex2_div) ||
                         (ex2_potnt_uf_pre &&
                          fdsu_ex2_op0_norm);

  // Assign overflow flag
  assign ex2_of = ex2_of_plus;
  assign ex2_of_plus = ex2_div_of && fdsu_ex2_div;
  assign ex2_div_of = fdsu_ex2_op0_norm && fdsu_ex2_op1_norm && ex2_expnt_of;

  // Assign underflow flag
  assign ex2_uf = ex2_uf_plus;
  assign ex2_uf_plus = ex2_div_uf && fdsu_ex2_div;
  assign ex2_div_uf = fdsu_ex2_op0_norm && fdsu_ex2_op1_norm && ex2_expnt_uf;
  // Detect underflow condition for SRT skip
  assign ex2_id_nor_srt_skip = fdsu_ex2_expnt_rst[9] && (fdsu_ex2_expnt_rst[8:0] < 9'h16a);
  // Assign underflow SRT skip flag
  assign ex2_uf_srt_skip = ex2_id_nor_srt_skip;
  // Assign result denorm flag
  assign ex2_rslt_denorm = ex2_uf;

  // Determine the amount to add for denormalized numbers during rounding
  always @(fdsu_ex2_expnt_rst[9:0]) begin
    case (fdsu_ex2_expnt_rst[9:0])
      10'h382: ex2_result_denorm_round_add_num[23:0] = 24'h1;
      10'h381: ex2_result_denorm_round_add_num[23:0] = 24'h2;
      10'h380: ex2_result_denorm_round_add_num[23:0] = 24'h4;
      10'h37f: ex2_result_denorm_round_add_num[23:0] = 24'h8;
      10'h37e: ex2_result_denorm_round_add_num[23:0] = 24'h10;
      10'h37d: ex2_result_denorm_round_add_num[23:0] = 24'h20;
      10'h37c: ex2_result_denorm_round_add_num[23:0] = 24'h40;
      10'h37b: ex2_result_denorm_round_add_num[23:0] = 24'h80;
      10'h37a: ex2_result_denorm_round_add_num[23:0] = 24'h100;
      10'h379: ex2_result_denorm_round_add_num[23:0] = 24'h200;
      10'h378: ex2_result_denorm_round_add_num[23:0] = 24'h400;
      10'h377: ex2_result_denorm_round_add_num[23:0] = 24'h800;
      10'h376: ex2_result_denorm_round_add_num[23:0] = 24'h1000;
      10'h375: ex2_result_denorm_round_add_num[23:0] = 24'h2000;
      10'h374: ex2_result_denorm_round_add_num[23:0] = 24'h4000;
      10'h373: ex2_result_denorm_round_add_num[23:0] = 24'h8000;
      10'h372: ex2_result_denorm_round_add_num[23:0] = 24'h10000;
      10'h371: ex2_result_denorm_round_add_num[23:0] = 24'h20000;
      10'h370: ex2_result_denorm_round_add_num[23:0] = 24'h40000;
      10'h36f: ex2_result_denorm_round_add_num[23:0] = 24'h80000;
      10'h36e: ex2_result_denorm_round_add_num[23:0] = 24'h100000;
      10'h36d: ex2_result_denorm_round_add_num[23:0] = 24'h200000;
      10'h36c: ex2_result_denorm_round_add_num[23:0] = 24'h400000;
      10'h36b: ex2_result_denorm_round_add_num[23:0] = 24'h800000;
      default: ex2_result_denorm_round_add_num[23:0] = 24'h0;
    endcase
  end

  // Assign result infinity flag
  assign ex2_result_inf = ex2_of_plus && !fdsu_ex2_of_rm_lfn;
  // Assign result large finite number flag
  assign ex2_result_lfn = fdsu_ex2_result_lfn || ex2_of_plus && fdsu_ex2_of_rm_lfn;

  // Pipeline the denorm rounding add number
  always @(posedge ex1_ex2_pipe_clk) begin
    if (ex1_pipedown)
      fdsu_ex3_result_denorm_round_add_num[23:0] <= {14'b0, ex1_expnt_adder_op1[9:0]};
    else if (ex2_pipedown)
      fdsu_ex3_result_denorm_round_add_num[23:0] <= ex2_result_denorm_round_add_num[23:0];
    else fdsu_ex3_result_denorm_round_add_num[23:0] <= fdsu_ex3_result_denorm_round_add_num[23:0];
  end
  // Assign exponent operand 1 for the next stage
  assign ex2_expnt_adder_op1 = fdsu_ex3_result_denorm_round_add_num[9:0];

  // Enable signal for the EX1-EX2 pipeline clock
  assign ex1_ex2_pipe_clk_en = ex1_pipedown_gate || ex2_pipedown;

  // Instantiate gated clock cell for EX1-EX2 pipeline
  gated_clk_cell x_ex1_ex2_pipe_clk (
      .clk_in            (forever_cpuclk),
      .clk_out           (ex1_ex2_pipe_clk),
      .external_en       (1'b0),
      .global_en         (cp0_yy_clk_en),
      .local_en          (ex1_ex2_pipe_clk_en),
      .module_en         (cp0_fpu_icg_en),
      .pad_yy_icg_scan_en(pad_yy_icg_scan_en)
  );

  // Pipeline the remainder sign, zero flag, and SRT skip flag
  always @(posedge ex2_pipe_clk) begin
    if (ex2_pipedown) begin
      fdsu_ex3_rem_sign <= srt_remainder_sign;
      fdsu_ex3_rem_zero <= srt_remainder_zero;
      fdsu_ex3_id_srt_skip <= ex2_id_nor_srt_skip;
    end else begin
      fdsu_ex3_rem_sign <= fdsu_ex3_rem_sign;
      fdsu_ex3_rem_zero <= fdsu_ex3_rem_zero;
      fdsu_ex3_id_srt_skip <= fdsu_ex3_id_srt_skip;
    end
  end

  // Register for the SRT remainder
  always @(posedge qt_clk) begin
    if (ex1_pipedown) srt_remainder[31:0] <= ex1_remainder[31:0];
    else if (srt_sm_on) srt_remainder[31:0] <= srt_remainder_nxt[31:0];
    else srt_remainder[31:0] <= srt_remainder[31:0];
  end

  // Instantiate gated clock cell for SRT division
  gated_clk_cell x_srt_div_clk (
      .clk_in            (forever_cpuclk),
      .clk_out           (srt_div_clk),
      .external_en       (1'b0),
      .global_en         (cp0_yy_clk_en),
      .local_en          (srt_div_clk_en),
      .module_en         (cp0_fpu_icg_en),
      .pad_yy_icg_scan_en(pad_yy_icg_scan_en)
  );

  // Enable signal for SRT division clock
  assign srt_div_clk_en = ex1_pipedown_gate || ex1_save_op0_gate || ex3_pipedown;

  // Register for the SRT divisor
  always @(posedge srt_div_clk) begin
    if (ex1_save_op0) srt_divisor[25:0] <= {3'b0, {ex1_oper_id_frac[51:29]}};
    else if (ex1_pipedown) srt_divisor[25:0] <= {2'b0, ex1_divisor[23:0]};
    else if (ex3_pipedown) srt_divisor[25:0] <= ex3_frac_final_rst[25:0];
    else srt_divisor[25:0] <= srt_divisor[25:0];
  end
  // Format the operand fraction for the next stage
  assign ex1_oper_id_frac_f[51:0] = {srt_divisor[22:0], 29'b0};
  // Assign the SRT divisor to the output for the next stage
  assign fdsu_ex4_frac[25:0] = srt_divisor[25:0];

  // Select the digit bounds based on the divisor and quotient/remainder
  assign bound_sel[3:0] = (fdsu_ex2_div)
                        ? srt_divisor[23:20]
                        : (ex2_srt_first_round)
                          ? 4'b1010
                          : total_qt_rt_30[28:25];

  // Determine the digit bounds for SRT algorithm
  always @(bound_sel[3:0]) begin
    case (bound_sel[3:0])
      4'b0000: begin
        digit_bound_1[7:0] = 8'b11110100;
        digit_bound_2[7:0] = 8'b11010001;
      end
      4'b1000: begin
        digit_bound_1[7:0] = 8'b11111001;
        digit_bound_2[7:0] = 8'b11100111;
      end
      4'b1001: begin
        digit_bound_1[7:0] = 8'b11111001;
        digit_bound_2[7:0] = 8'b11100100;
      end
      4'b1010: begin
        digit_bound_1[7:0] = 8'b11111000;
        digit_bound_2[7:0] = 8'b11100001;
      end
      4'b1011: begin
        digit_bound_1[7:0] = 8'b11110111;
        digit_bound_2[7:0] = 8'b11011111;
      end
      4'b1100: begin
        digit_bound_1[7:0] = 8'b11110111;
        digit_bound_2[7:0] = 8'b11011100;
      end
      4'b1101: begin
        digit_bound_1[7:0] = 8'b11110110;
        digit_bound_2[7:0] = 8'b11011001;
      end
      4'b1110: begin
        digit_bound_1[7:0] = 8'b11110101;
        digit_bound_2[7:0] = 8'b11010111;
      end
      4'b1111: begin
        digit_bound_1[7:0] = 8'b11110100;
        digit_bound_2[7:0] = 8'b11010001;
      end
      default: begin
        digit_bound_1[7:0] = 8'b11111001;
        digit_bound_2[7:0] = 8'b11100111;
      end
    endcase
  end

  // Compare selected remainder bits with digit bounds
  assign bound1_cmp_result[7:0] = qtrt_sel_rem[7:0] + digit_bound_1[7:0];
  assign bound2_cmp_result[7:0] = qtrt_sel_rem[7:0] + digit_bound_2[7:0];
  assign bound1_cmp_sign        = bound1_cmp_result[7];
  assign bound2_cmp_sign        = bound2_cmp_result[7];
  // Assign the sign of the remainder
  assign rem_sign               = srt_remainder[29];

  // Select relevant bits of the remainder for comparison
  always @(ex2_srt_first_round or fdsu_ex2_sqrt or srt_remainder[29:21]) begin
    if (ex2_srt_first_round && fdsu_ex2_sqrt)
      qtrt_sel_rem[7:0] = {srt_remainder[29], srt_remainder[27:21]};
    else qtrt_sel_rem[7:0] = srt_remainder[29] ? ~srt_remainder[29:22] : srt_remainder[29:22];
  end

  // Instantiate gated clock cell for quotient/remainder logic
  gated_clk_cell x_qt_clk (
      .clk_in            (forever_cpuclk),
      .clk_out           (qt_clk),
      .external_en       (1'b0),
      .global_en         (cp0_yy_clk_en),
      .local_en          (qt_clk_en),
      .module_en         (cp0_fpu_icg_en),
      .pad_yy_icg_scan_en(pad_yy_icg_scan_en)
  );

  // Enable signal for quotient/remainder clock
  assign qt_clk_en = srt_sm_on || ex1_pipedown_gate;

  // Register for quotient/remainder constants and total value
  always @(posedge qt_clk) begin
    if (ex1_pipedown) begin
      qt_rt_const_shift_std[29:0] <= {1'b0, 1'b1, 28'b0};
      total_qt_rt_30[29:0]        <= 30'b0;
      total_qt_rt_minus_30[29:0]  <= 30'b0;
    end else if (srt_sm_on) begin
      qt_rt_const_shift_std[29:0] <= qt_rt_const_shift_std_next[29:0];
      total_qt_rt_30[29:0]        <= total_qt_rt_30_next[29:0];
      total_qt_rt_minus_30[29:0]  <= total_qt_rt_minus_30_next[29:0];
    end else begin
      qt_rt_const_shift_std[29:0] <= qt_rt_const_shift_std[29:0];
      total_qt_rt_30[29:0]        <= total_qt_rt_30[29:0];
      total_qt_rt_minus_30[29:0]  <= total_qt_rt_minus_30[29:0];
    end
  end

  // Define constants for quotient/remainder calculation
  assign qt_rt_const_q1[29:0] = qt_rt_const_shift_std[29:0];
  assign qt_rt_const_q2[29:0] = {qt_rt_const_shift_std[28:0], 1'b0};
  assign qt_rt_const_q3[29:0] = qt_rt_const_q1[29:0] | qt_rt_const_q2[29:0];

  // Shift the constant for the next iteration
  assign qt_rt_const_shift_std_next[29:0] = {2'b0, qt_rt_const_shift_std[29:2]};

  // Select the appropriate total quotient/remainder based on remainder sign
  assign total_qt_rt_pre_sel[29:0] = (rem_sign) ? total_qt_rt_minus_30[29:0]
                                                : total_qt_rt_30[29:0];

  // Define pre-selected constants for quotient/remainder update
  assign qt_rt_const_pre_sel_q2[29:0] = qt_rt_const_q2[29:0];
  assign qt_rt_mins_const_pre_sel_q2[29:0] = qt_rt_const_q1[29:0];

  // Define pre-selected constants for quotient/remainder update based on remainder sign
  assign qt_rt_const_pre_sel_q1[29:0] = (rem_sign) ? qt_rt_const_q3[29:0] : qt_rt_const_q1[29:0];
  assign qt_rt_mins_const_pre_sel_q1[29:0] = (rem_sign) ? qt_rt_const_q2[29:0] : 30'b0;

  // Update the total quotient/remainder based on comparison with bounds
  always @( qt_rt_const_q3[29:0] or qt_rt_mins_const_pre_sel_q1[29:0] or
          bound1_cmp_sign or total_qt_rt_30[29:0] or
          qt_rt_mins_const_pre_sel_q2[29:0] or total_qt_rt_minus_30[29:0] or
          bound2_cmp_sign or qt_rt_const_pre_sel_q2[29:0] or
          qt_rt_const_pre_sel_q1[29:0] or total_qt_rt_pre_sel[29:0])
begin
    casez ({
      bound1_cmp_sign, bound2_cmp_sign
    })
      2'b00: begin
        total_qt_rt_30_next[29:0] = total_qt_rt_pre_sel[29:0] | qt_rt_const_pre_sel_q2[29:0];
        total_qt_rt_minus_30_next[29:0] = total_qt_rt_pre_sel[29:0]
        | qt_rt_mins_const_pre_sel_q2[29:0];
      end
      2'b01: begin
        total_qt_rt_30_next[29:0] = total_qt_rt_pre_sel[29:0] | qt_rt_const_pre_sel_q1[29:0];
        total_qt_rt_minus_30_next[29:0] = total_qt_rt_pre_sel[29:0]
        | qt_rt_mins_const_pre_sel_q1[29:0];
      end
      2'b1?: begin
        total_qt_rt_30_next[29:0]    = total_qt_rt_30[29:0];
        total_qt_rt_minus_30_next[29:0] = total_qt_rt_minus_30[29:0] | qt_rt_const_q3[29:0];
      end
      default: begin
        total_qt_rt_30_next[29:0]    = 30'b0;
        total_qt_rt_minus_30_next[29:0] = 30'b0;
      end
    endcase
  end

  // Define operands for remainder addition in division
  assign div_qt_1_rem_add_op1[31:0] = ~{3'b0, srt_divisor[23:0], 5'b0};
  assign div_qt_2_rem_add_op1[31:0] = ~{2'b0, srt_divisor[23:0], 6'b0};
  assign div_qt_r1_rem_add_op1[31:0] = {3'b0, srt_divisor[23:0], 5'b0};
  assign div_qt_r2_rem_add_op1[31:0] = {2'b0, srt_divisor[23:0], 6'b0};

  // Define operands for remainder addition in square root
  assign sqrt_qt_1_rem_add_op1[31:0] = ~({2'b0, total_qt_rt_30[29:0]} |
                                       {3'b0, qt_rt_const_q1[29:1]});
  assign sqrt_qt_2_rem_add_op1[31:0] = ~({1'b0, total_qt_rt_30[29:0], 1'b0} |
                                       {1'b0, qt_rt_const_q1[29:0], 1'b0});
  assign sqrt_qt_r1_rem_add_op1[31:0] =  {2'b0, total_qt_rt_minus_30[29:0]} |
                                       {1'b0, qt_rt_const_q1[29:0], 1'b0} |
                                       {2'b0, qt_rt_const_q1[29:0]} |
                                       {3'b0, qt_rt_const_q1[29:1]};
  assign sqrt_qt_r2_rem_add_op1[31:0] =  {1'b0,
                                       total_qt_rt_minus_30[29:0], 1'b0} |
                                       {qt_rt_const_q1[29:0], 2'b0} |
                                       {1'b0, qt_rt_const_q1[29:0], 1'b0};

  // Select the operands for remainder addition based on operation type and remainder sign
  always @( div_qt_2_rem_add_op1[31:0] or sqrt_qt_r2_rem_add_op1[31:0] or
          sqrt_qt_r1_rem_add_op1[31:0] or rem_sign or
          div_qt_r2_rem_add_op1[31:0] or div_qt_1_rem_add_op1[31:0] or
          sqrt_qt_2_rem_add_op1[31:0] or fdsu_ex2_sqrt or
          div_qt_r1_rem_add_op1[31:0] or sqrt_qt_1_rem_add_op1[31:0])
begin
    case ({
      rem_sign, fdsu_ex2_sqrt
    })
      2'b01: begin
        rem_add1_op1[31:0] = sqrt_qt_1_rem_add_op1[31:0];
        rem_add2_op1[31:0] = sqrt_qt_2_rem_add_op1[31:0];
      end
      2'b00: begin
        rem_add1_op1[31:0] = div_qt_1_rem_add_op1[31:0];
        rem_add2_op1[31:0] = div_qt_2_rem_add_op1[31:0];
      end
      2'b11: begin
        rem_add1_op1[31:0] = sqrt_qt_r1_rem_add_op1[31:0];
        rem_add2_op1[31:0] = sqrt_qt_r2_rem_add_op1[31:0];
      end
      2'b10: begin
        rem_add1_op1[31:0] = div_qt_r1_rem_add_op1[31:0];
        rem_add2_op1[31:0] = div_qt_r2_rem_add_op1[31:0];
      end
      default: begin
        rem_add1_op1[31:0] = 32'b0;
        rem_add2_op1[31:0] = 32'b0;
      end
    endcase
  end
  // Shift the remainder for the next iteration
  assign srt_remainder_shift[31:0] = {srt_remainder[31], srt_remainder[28:0], 2'b0};

  // Calculate the next remainder values
  assign cur_doub_rem_1[31:0] = srt_remainder_shift[31:0]
    + rem_add1_op1[31:0] + {31'b0, ~rem_sign};
  assign cur_doub_rem_2[31:0] = srt_remainder_shift[31:0]
    + rem_add2_op1[31:0] + {31'b0, ~rem_sign};
  assign cur_rem_1[31:0] = cur_doub_rem_1[31:0];
  assign cur_rem_2[31:0] = cur_doub_rem_2[31:0];

  // Select the next remainder based on comparison with bounds
  always @( cur_rem_2[31:0] or bound1_cmp_sign or srt_remainder_shift[31:0] or
          bound2_cmp_sign or cur_rem_1[31:0])
begin
    case ({
      bound1_cmp_sign, bound2_cmp_sign
    })
      2'b00:   cur_rem[31:0] = cur_rem_2[31:0];
      2'b01:   cur_rem[31:0] = cur_rem_1[31:0];
      default: cur_rem[31:0] = srt_remainder_shift[31:0];
    endcase
  end
  // Assign the next remainder value
  assign srt_remainder_nxt[31:0] = cur_rem[31:0];

  // Check if the remainder is zero
  assign srt_remainder_zero      = ~|srt_remainder[31:0];
  // Assign the sign of the remainder
  assign srt_remainder_sign      = srt_remainder[31];

endmodule
