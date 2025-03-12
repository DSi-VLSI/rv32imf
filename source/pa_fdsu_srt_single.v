module pa_fdsu_srt_single(
  cp0_fpu_icg_en,
  cp0_yy_clk_en,
  ex1_divisor,
  ex1_expnt_adder_op1,
  ex1_oper_id_frac,
  ex1_oper_id_frac_f,
  ex1_pipedown,
  ex1_pipedown_gate,
  ex1_remainder,
  ex1_save_op0,
  ex1_save_op0_gate,
  ex2_expnt_adder_op0,
  ex2_of,
  ex2_pipe_clk,
  ex2_pipedown,
  ex2_potnt_of,
  ex2_potnt_uf,
  ex2_result_inf,
  ex2_result_lfn,
  ex2_rslt_denorm,
  ex2_srt_expnt_rst,
  ex2_srt_first_round,
  ex2_uf,
  ex2_uf_srt_skip,
  ex3_frac_final_rst,
  ex3_pipedown,
  fdsu_ex3_id_srt_skip,
  fdsu_ex3_rem_sign,
  fdsu_ex3_rem_zero,
  fdsu_ex3_result_denorm_round_add_num,
  fdsu_ex4_frac,
  fdsu_yy_div,
  fdsu_yy_of_rm_lfn,
  fdsu_yy_op0_norm,
  fdsu_yy_op1_norm,
  fdsu_yy_sqrt,
  forever_cpuclk,
  pad_yy_icg_scan_en,
  srt_remainder_zero,
  srt_sm_on,
  total_qt_rt_30
);


input           cp0_fpu_icg_en;
input           cp0_yy_clk_en;
input   [23:0]  ex1_divisor;
input   [12:0]  ex1_expnt_adder_op1;
input   [51:0]  ex1_oper_id_frac;
input           ex1_pipedown;
input           ex1_pipedown_gate;
input   [31:0]  ex1_remainder;
input           ex1_save_op0;
input           ex1_save_op0_gate;
input   [9 :0]  ex2_expnt_adder_op0;
input           ex2_pipe_clk;
input           ex2_pipedown;
input           ex2_srt_first_round;
input   [25:0]  ex3_frac_final_rst;
input           ex3_pipedown;
input           fdsu_yy_div;
input           fdsu_yy_of_rm_lfn;
input           fdsu_yy_op0_norm;
input           fdsu_yy_op1_norm;
input           fdsu_yy_sqrt;
input           forever_cpuclk;
input           pad_yy_icg_scan_en;
input           srt_sm_on;
output  [51:0]  ex1_oper_id_frac_f;
output          ex2_of;
output          ex2_potnt_of;
output          ex2_potnt_uf;
output          ex2_result_inf;
output          ex2_result_lfn;
output          ex2_rslt_denorm;
output  [9 :0]  ex2_srt_expnt_rst;
output          ex2_uf;
output          ex2_uf_srt_skip;
output          fdsu_ex3_id_srt_skip;
output          fdsu_ex3_rem_sign;
output          fdsu_ex3_rem_zero;
output  [23:0]  fdsu_ex3_result_denorm_round_add_num;
output  [25:0]  fdsu_ex4_frac;
output          srt_remainder_zero;
output  [29:0]  total_qt_rt_30;


reg     [31:0]  cur_rem;
reg     [7 :0]  digit_bound_1;
reg     [7 :0]  digit_bound_2;
reg     [23:0]  ex2_result_denorm_round_add_num;
reg             fdsu_ex3_id_srt_skip;
reg             fdsu_ex3_rem_sign;
reg             fdsu_ex3_rem_zero;
reg     [23:0]  fdsu_ex3_result_denorm_round_add_num;
reg     [29:0]  qt_rt_const_shift_std;
reg     [7 :0]  qtrt_sel_rem;
reg     [31:0]  rem_add1_op1;
reg     [31:0]  rem_add2_op1;
reg     [25:0]  srt_divisor;
reg     [31:0]  srt_remainder;
reg     [29:0]  total_qt_rt_30;
reg     [29:0]  total_qt_rt_30_next;
reg     [29:0]  total_qt_rt_minus_30;
reg     [29:0]  total_qt_rt_minus_30_next;


wire    [7 :0]  bound1_cmp_result;
wire            bound1_cmp_sign;
wire    [7 :0]  bound2_cmp_result;
wire            bound2_cmp_sign;
wire    [3 :0]  bound_sel;
wire            cp0_fpu_icg_en;
wire            cp0_yy_clk_en;
wire    [31:0]  cur_doub_rem_1;
wire    [31:0]  cur_doub_rem_2;
wire    [31:0]  cur_rem_1;
wire    [31:0]  cur_rem_2;
wire    [31:0]  div_qt_1_rem_add_op1;
wire    [31:0]  div_qt_2_rem_add_op1;
wire    [31:0]  div_qt_r1_rem_add_op1;
wire    [31:0]  div_qt_r2_rem_add_op1;
wire    [23:0]  ex1_divisor;
wire            ex1_ex2_pipe_clk;
wire            ex1_ex2_pipe_clk_en;
wire    [12:0]  ex1_expnt_adder_op1;
wire    [51:0]  ex1_oper_id_frac;
wire    [51:0]  ex1_oper_id_frac_f;
wire            ex1_pipedown;
wire            ex1_pipedown_gate;
wire    [31:0]  ex1_remainder;
wire            ex1_save_op0;
wire            ex1_save_op0_gate;
wire            ex2_div_of;
wire            ex2_div_uf;
wire    [9 :0]  ex2_expnt_adder_op0;
wire    [9 :0]  ex2_expnt_adder_op1;
wire            ex2_expnt_of;
wire    [9 :0]  ex2_expnt_result;
wire            ex2_expnt_uf;
wire            ex2_id_nor_srt_skip;
wire            ex2_of;
wire            ex2_of_plus;
wire            ex2_pipe_clk;
wire            ex2_pipedown;
wire            ex2_potnt_of;
wire            ex2_potnt_of_pre;
wire            ex2_potnt_uf;
wire            ex2_potnt_uf_pre;
wire            ex2_result_inf;
wire            ex2_result_lfn;
wire            ex2_rslt_denorm;
wire    [9 :0]  ex2_sqrt_expnt_result;
wire    [9 :0]  ex2_srt_expnt_rst;
wire            ex2_srt_first_round;
wire            ex2_uf;
wire            ex2_uf_plus;
wire            ex2_uf_srt_skip;
wire    [25:0]  ex3_frac_final_rst;
wire            ex3_pipedown;
wire            fdsu_ex2_div;
wire    [9 :0]  fdsu_ex2_expnt_rst;
wire            fdsu_ex2_of_rm_lfn;
wire            fdsu_ex2_op0_norm;
wire            fdsu_ex2_op1_norm;
wire            fdsu_ex2_result_lfn;
wire            fdsu_ex2_sqrt;
wire    [25:0]  fdsu_ex4_frac;
wire            fdsu_yy_div;
wire            fdsu_yy_of_rm_lfn;
wire            fdsu_yy_op0_norm;
wire            fdsu_yy_op1_norm;
wire            fdsu_yy_sqrt;
wire            forever_cpuclk;
wire            pad_yy_icg_scan_en;
wire            qt_clk;
wire            qt_clk_en;
wire    [29:0]  qt_rt_const_pre_sel_q1;
wire    [29:0]  qt_rt_const_pre_sel_q2;
wire    [29:0]  qt_rt_const_q1;
wire    [29:0]  qt_rt_const_q2;
wire    [29:0]  qt_rt_const_q3;
wire    [29:0]  qt_rt_const_shift_std_next;
wire    [29:0]  qt_rt_mins_const_pre_sel_q1;
wire    [29:0]  qt_rt_mins_const_pre_sel_q2;
wire            rem_sign;
wire    [31:0]  sqrt_qt_1_rem_add_op1;
wire    [31:0]  sqrt_qt_2_rem_add_op1;
wire    [31:0]  sqrt_qt_r1_rem_add_op1;
wire    [31:0]  sqrt_qt_r2_rem_add_op1;
wire            srt_div_clk;
wire            srt_div_clk_en;
wire    [31:0]  srt_remainder_nxt;
wire    [31:0]  srt_remainder_shift;
wire            srt_remainder_sign;
wire            srt_remainder_zero;
wire            srt_sm_on;
wire    [29:0]  total_qt_rt_pre_sel;


assign fdsu_ex2_div             = fdsu_yy_div;
assign fdsu_ex2_sqrt            = fdsu_yy_sqrt;
assign fdsu_ex2_op0_norm        = fdsu_yy_op0_norm;
assign fdsu_ex2_op1_norm        = fdsu_yy_op1_norm;
assign fdsu_ex2_of_rm_lfn       = fdsu_yy_of_rm_lfn;
assign fdsu_ex2_result_lfn      = 1'b0;





assign ex2_expnt_result[9:0] =  ex2_expnt_adder_op0[9:0] -
                                 ex2_expnt_adder_op1[9:0];




assign ex2_sqrt_expnt_result[9:0] = {ex2_expnt_result[9],
                                      ex2_expnt_result[9:1]};

assign ex2_srt_expnt_rst[9:0] = (fdsu_ex2_sqrt)
                               ? ex2_sqrt_expnt_result[9:0]
                               : ex2_expnt_result[9:0];

assign fdsu_ex2_expnt_rst[9:0] = ex2_srt_expnt_rst[9:0];







assign ex2_expnt_of = ~fdsu_ex2_expnt_rst[9] && (fdsu_ex2_expnt_rst[8]
                                                      || (fdsu_ex2_expnt_rst[7]  &&
                                                          |fdsu_ex2_expnt_rst[6:0]));

assign ex2_potnt_of_pre = ~fdsu_ex2_expnt_rst[9]  &&
                           ~fdsu_ex2_expnt_rst[8]  &&
                            fdsu_ex2_expnt_rst[7]  &&
                          ~|fdsu_ex2_expnt_rst[6:0];
assign ex2_potnt_of      = ex2_potnt_of_pre &&
                           fdsu_ex2_op0_norm &&
                           fdsu_ex2_op1_norm &&
                           fdsu_ex2_div;


assign ex2_expnt_uf = fdsu_ex2_expnt_rst[9] &&(fdsu_ex2_expnt_rst[8:0] <= 9'h181);

assign ex2_potnt_uf_pre = &fdsu_ex2_expnt_rst[9:7]   &&
                          ~|fdsu_ex2_expnt_rst[6:2]   &&
                            fdsu_ex2_expnt_rst[1]     &&
                           !fdsu_ex2_expnt_rst[0];
assign ex2_potnt_uf      = (ex2_potnt_uf_pre &&
                            fdsu_ex2_op0_norm &&
                            fdsu_ex2_op1_norm &&
                            fdsu_ex2_div)     ||
                           (ex2_potnt_uf_pre   &&
                            fdsu_ex2_op0_norm);






assign ex2_of      = ex2_of_plus;
assign ex2_of_plus = ex2_div_of  && fdsu_ex2_div;
assign ex2_div_of  = fdsu_ex2_op0_norm &&
                     fdsu_ex2_op1_norm &&
                     ex2_expnt_of;






assign ex2_uf      = ex2_uf_plus;
assign ex2_uf_plus = ex2_div_uf  && fdsu_ex2_div;
assign ex2_div_uf  = fdsu_ex2_op0_norm &&
                     fdsu_ex2_op1_norm &&
                     ex2_expnt_uf;
assign ex2_id_nor_srt_skip =  fdsu_ex2_expnt_rst[9]
                                     && (fdsu_ex2_expnt_rst[8:0]<9'h16a);
assign ex2_uf_srt_skip            = ex2_id_nor_srt_skip;
assign ex2_rslt_denorm            = ex2_uf;


always @( fdsu_ex2_expnt_rst[9:0])
begin
case(fdsu_ex2_expnt_rst[9:0])
  10'h382:ex2_result_denorm_round_add_num[23:0] = 24'h1;
  10'h381:ex2_result_denorm_round_add_num[23:0] = 24'h2;
  10'h380:ex2_result_denorm_round_add_num[23:0] = 24'h4;
  10'h37f:ex2_result_denorm_round_add_num[23:0] = 24'h8;
  10'h37e:ex2_result_denorm_round_add_num[23:0] = 24'h10;
  10'h37d:ex2_result_denorm_round_add_num[23:0] = 24'h20;
  10'h37c:ex2_result_denorm_round_add_num[23:0] = 24'h40;
  10'h37b:ex2_result_denorm_round_add_num[23:0] = 24'h80;
  10'h37a:ex2_result_denorm_round_add_num[23:0] = 24'h100;
  10'h379:ex2_result_denorm_round_add_num[23:0] = 24'h200;
  10'h378:ex2_result_denorm_round_add_num[23:0] = 24'h400;
  10'h377:ex2_result_denorm_round_add_num[23:0] = 24'h800;
  10'h376:ex2_result_denorm_round_add_num[23:0] = 24'h1000;
  10'h375:ex2_result_denorm_round_add_num[23:0] = 24'h2000;
  10'h374:ex2_result_denorm_round_add_num[23:0] = 24'h4000;
  10'h373:ex2_result_denorm_round_add_num[23:0] = 24'h8000;
  10'h372:ex2_result_denorm_round_add_num[23:0] = 24'h10000;
  10'h371:ex2_result_denorm_round_add_num[23:0] = 24'h20000;
  10'h370:ex2_result_denorm_round_add_num[23:0] = 24'h40000;
  10'h36f:ex2_result_denorm_round_add_num[23:0] = 24'h80000;
  10'h36e:ex2_result_denorm_round_add_num[23:0] = 24'h100000;
  10'h36d:ex2_result_denorm_round_add_num[23:0] = 24'h200000;
  10'h36c:ex2_result_denorm_round_add_num[23:0] = 24'h400000;
  10'h36b:ex2_result_denorm_round_add_num[23:0] = 24'h800000;
  default: ex2_result_denorm_round_add_num[23:0] = 24'h0;
endcase

end


assign ex2_result_inf  = ex2_of_plus && !fdsu_ex2_of_rm_lfn;
assign ex2_result_lfn  = fdsu_ex2_result_lfn ||
                         ex2_of_plus &&  fdsu_ex2_of_rm_lfn;




always @(posedge ex1_ex2_pipe_clk)
begin
  if(ex1_pipedown)
  begin
    fdsu_ex3_result_denorm_round_add_num[23:0]
                              <= {14'b0, ex1_expnt_adder_op1[9:0]};
  end
  else if(ex2_pipedown)
  begin
    fdsu_ex3_result_denorm_round_add_num[23:0]
                              <= ex2_result_denorm_round_add_num[23:0];
  end
  else
  begin
    fdsu_ex3_result_denorm_round_add_num[23:0]
                              <= fdsu_ex3_result_denorm_round_add_num[23:0];
  end
end
assign ex2_expnt_adder_op1 = fdsu_ex3_result_denorm_round_add_num[9:0];


assign ex1_ex2_pipe_clk_en = ex1_pipedown_gate || ex2_pipedown;

gated_clk_cell  x_ex1_ex2_pipe_clk (
  .clk_in              (forever_cpuclk     ),
  .clk_out             (ex1_ex2_pipe_clk   ),
  .external_en         (1'b0               ),
  .global_en           (cp0_yy_clk_en      ),
  .local_en            (ex1_ex2_pipe_clk_en),
  .module_en           (cp0_fpu_icg_en     ),
  .pad_yy_icg_scan_en  (pad_yy_icg_scan_en )
);








always @(posedge ex2_pipe_clk)
begin
  if(ex2_pipedown)
  begin
    fdsu_ex3_rem_sign        <= srt_remainder_sign;
    fdsu_ex3_rem_zero        <= srt_remainder_zero;
    fdsu_ex3_id_srt_skip     <= ex2_id_nor_srt_skip;
  end
  else
  begin
    fdsu_ex3_rem_sign        <= fdsu_ex3_rem_sign;
    fdsu_ex3_rem_zero        <= fdsu_ex3_rem_zero;
    fdsu_ex3_id_srt_skip    <=  fdsu_ex3_id_srt_skip;
  end
end























always @(posedge qt_clk)
begin
  if (ex1_pipedown)
    srt_remainder[31:0] <= ex1_remainder[31:0];
  else if (srt_sm_on)
    srt_remainder[31:0] <= srt_remainder_nxt[31:0];
  else
    srt_remainder[31:0] <= srt_remainder[31:0];
end




gated_clk_cell  x_srt_div_clk (
  .clk_in             (forever_cpuclk    ),
  .clk_out            (srt_div_clk       ),
  .external_en        (1'b0              ),
  .global_en          (cp0_yy_clk_en     ),
  .local_en           (srt_div_clk_en    ),
  .module_en          (cp0_fpu_icg_en    ),
  .pad_yy_icg_scan_en (pad_yy_icg_scan_en)
);








assign srt_div_clk_en = ex1_pipedown_gate
                     || ex1_save_op0_gate
                     || ex3_pipedown;


always @(posedge srt_div_clk)
begin
  if (ex1_save_op0)
    srt_divisor[25:0] <= {3'b0, {ex1_oper_id_frac[51:29]}};
  else if (ex1_pipedown)
    srt_divisor[25:0] <= {2'b0, ex1_divisor[23:0]};
  else if (ex3_pipedown)
    srt_divisor[25:0] <= ex3_frac_final_rst[25:0];
  else
    srt_divisor[25:0] <= srt_divisor[25:0];
end
assign ex1_oper_id_frac_f[51:0] = {srt_divisor[22:0], 29'b0};

assign fdsu_ex4_frac[25:0] = srt_divisor[25:0];














assign bound_sel[3:0] = (fdsu_ex2_div)
                      ? srt_divisor[23:20]
                      : (ex2_srt_first_round)
                        ? 4'b1010
                        : total_qt_rt_30[28:25];





always @( bound_sel[3:0])
begin
case(bound_sel[3:0])
4'b0000:
   begin
     digit_bound_1[7:0] = 8'b11110100;
     digit_bound_2[7:0] = 8'b11010001;
   end
4'b1000:
   begin
     digit_bound_1[7:0] = 8'b11111001;
     digit_bound_2[7:0] = 8'b11100111;
   end
4'b1001:
   begin
     digit_bound_1[7:0] = 8'b11111001;
     digit_bound_2[7:0] = 8'b11100100;
   end
4'b1010:
   begin
     digit_bound_1[7:0] = 8'b11111000;
     digit_bound_2[7:0] = 8'b11100001;
   end
4'b1011:
   begin
     digit_bound_1[7:0] = 8'b11110111;
     digit_bound_2[7:0] = 8'b11011111;
   end
4'b1100:
   begin
     digit_bound_1[7:0] = 8'b11110111;
     digit_bound_2[7:0] = 8'b11011100;
   end
4'b1101:
   begin
     digit_bound_1[7:0] = 8'b11110110;
     digit_bound_2[7:0] = 8'b11011001;
   end
4'b1110:
   begin
     digit_bound_1[7:0] = 8'b11110101;
     digit_bound_2[7:0] = 8'b11010111;
   end
4'b1111:
   begin
     digit_bound_1[7:0] = 8'b11110100;
     digit_bound_2[7:0] = 8'b11010001;
   end
default:
   begin
     digit_bound_1[7:0] = 8'b11111001;
     digit_bound_2[7:0] = 8'b11100111;
   end
endcase

end


assign bound1_cmp_result[7:0] = qtrt_sel_rem[7:0] + digit_bound_1[7:0];
assign bound2_cmp_result[7:0] = qtrt_sel_rem[7:0] + digit_bound_2[7:0];
assign bound1_cmp_sign        = bound1_cmp_result[7];
assign bound2_cmp_sign        = bound2_cmp_result[7];
assign rem_sign               = srt_remainder[29];












always @( ex2_srt_first_round
       or fdsu_ex2_sqrt
       or srt_remainder[29:21])
begin
if(ex2_srt_first_round && fdsu_ex2_sqrt)
  qtrt_sel_rem[7:0] = {srt_remainder[29],   srt_remainder[27:21]};
else
  qtrt_sel_rem[7:0] =  srt_remainder[29] ? ~srt_remainder[29:22]
                                         :  srt_remainder[29:22];

end






gated_clk_cell  x_qt_clk (
  .clk_in             (forever_cpuclk    ),
  .clk_out            (qt_clk            ),
  .external_en        (1'b0              ),
  .global_en          (cp0_yy_clk_en     ),
  .local_en           (qt_clk_en         ),
  .module_en          (cp0_fpu_icg_en    ),
  .pad_yy_icg_scan_en (pad_yy_icg_scan_en)
);








assign qt_clk_en = srt_sm_on ||
                   ex1_pipedown_gate;







always @(posedge qt_clk)
begin
  if(ex1_pipedown)
  begin
    qt_rt_const_shift_std[29:0] <= {1'b0,1'b1,28'b0};
    total_qt_rt_30[29:0]        <= 30'b0;
    total_qt_rt_minus_30[29:0]  <= 30'b0;
  end
  else if(srt_sm_on)
  begin
    qt_rt_const_shift_std[29:0] <= qt_rt_const_shift_std_next[29:0];
    total_qt_rt_30[29:0]        <= total_qt_rt_30_next[29:0];
    total_qt_rt_minus_30[29:0]  <= total_qt_rt_minus_30_next[29:0];
  end
  else
  begin
    qt_rt_const_shift_std[29:0] <= qt_rt_const_shift_std[29:0];
    total_qt_rt_30[29:0]        <= total_qt_rt_30[29:0];
    total_qt_rt_minus_30[29:0]  <= total_qt_rt_minus_30[29:0];
  end
end



assign qt_rt_const_q1[29:0] =  qt_rt_const_shift_std[29:0];
assign qt_rt_const_q2[29:0] = {qt_rt_const_shift_std[28:0],1'b0};
assign qt_rt_const_q3[29:0] =  qt_rt_const_q1[29:0] |
                               qt_rt_const_q2[29:0];

assign qt_rt_const_shift_std_next[29:0] = {2'b0, qt_rt_const_shift_std[29:2]};














assign total_qt_rt_pre_sel[29:0]         = (rem_sign) ?
                                           total_qt_rt_minus_30[29:0] :
                                           total_qt_rt_30[29:0];

assign qt_rt_const_pre_sel_q2[29:0]      = qt_rt_const_q2[29:0];
assign qt_rt_mins_const_pre_sel_q2[29:0] = qt_rt_const_q1[29:0];

assign qt_rt_const_pre_sel_q1[29:0]      = (rem_sign) ?
                                           qt_rt_const_q3[29:0] :
                                           qt_rt_const_q1[29:0];
assign qt_rt_mins_const_pre_sel_q1[29:0] = (rem_sign) ?
                                           qt_rt_const_q2[29:0] :
                                           30'b0;



always @( qt_rt_const_q3[29:0]
       or qt_rt_mins_const_pre_sel_q1[29:0]
       or bound1_cmp_sign
       or total_qt_rt_30[29:0]
       or qt_rt_mins_const_pre_sel_q2[29:0]
       or total_qt_rt_minus_30[29:0]
       or bound2_cmp_sign
       or qt_rt_const_pre_sel_q2[29:0]
       or qt_rt_const_pre_sel_q1[29:0]
       or total_qt_rt_pre_sel[29:0])
begin
casez({bound1_cmp_sign,bound2_cmp_sign})
  2'b00:
  begin
    total_qt_rt_30_next[29:0]       = total_qt_rt_pre_sel[29:0] |
                                      qt_rt_const_pre_sel_q2[29:0];
    total_qt_rt_minus_30_next[29:0] = total_qt_rt_pre_sel[29:0] |
                                      qt_rt_mins_const_pre_sel_q2[29:0];
  end
  2'b01:
  begin
    total_qt_rt_30_next[29:0]       = total_qt_rt_pre_sel[29:0] |
                                      qt_rt_const_pre_sel_q1[29:0];
    total_qt_rt_minus_30_next[29:0] = total_qt_rt_pre_sel[29:0] |
                                      qt_rt_mins_const_pre_sel_q1[29:0];
  end
  2'b1?:
  begin
    total_qt_rt_30_next[29:0]       = total_qt_rt_30[29:0];
    total_qt_rt_minus_30_next[29:0] = total_qt_rt_minus_30[29:0] |
                                      qt_rt_const_q3[29:0];
  end
  default:
  begin
    total_qt_rt_30_next[29:0]       = 30'b0;
    total_qt_rt_minus_30_next[29:0] = 30'b0;
  end
endcase

end






assign div_qt_1_rem_add_op1[31:0]   = ~{3'b0,srt_divisor[23:0],5'b0};

assign div_qt_2_rem_add_op1[31:0]   = ~{2'b0,srt_divisor[23:0],6'b0};

assign div_qt_r1_rem_add_op1[31:0]  =  {3'b0,srt_divisor[23:0],5'b0};

assign div_qt_r2_rem_add_op1[31:0]  =  {2'b0,srt_divisor[23:0],6'b0};



assign sqrt_qt_1_rem_add_op1[31:0]  = ~({2'b0,total_qt_rt_30[29:0]} |
                                        {3'b0,qt_rt_const_q1[29:1]});

assign sqrt_qt_2_rem_add_op1[31:0]  = ~({1'b0,total_qt_rt_30[29:0],1'b0} |
                                        {1'b0,qt_rt_const_q1[29:0],1'b0});

assign sqrt_qt_r1_rem_add_op1[31:0] =   {2'b0,total_qt_rt_minus_30[29:0]} |
                                        {1'b0,qt_rt_const_q1[29:0],1'b0}  |
                                        {2'b0,qt_rt_const_q1[29:0]}       |
                                        {3'b0,qt_rt_const_q1[29:1]};

assign sqrt_qt_r2_rem_add_op1[31:0] =   {1'b0,
                                         total_qt_rt_minus_30[29:0],1'b0} |
                                        {qt_rt_const_q1[29:0],2'b0}       |
                                        {1'b0,qt_rt_const_q1[29:0],1'b0};


always @( div_qt_2_rem_add_op1[31:0]
       or sqrt_qt_r2_rem_add_op1[31:0]
       or sqrt_qt_r1_rem_add_op1[31:0]
       or rem_sign
       or div_qt_r2_rem_add_op1[31:0]
       or div_qt_1_rem_add_op1[31:0]
       or sqrt_qt_2_rem_add_op1[31:0]
       or fdsu_ex2_sqrt
       or div_qt_r1_rem_add_op1[31:0]
       or sqrt_qt_1_rem_add_op1[31:0])
begin
case({rem_sign,fdsu_ex2_sqrt})
  2'b01:
  begin
        rem_add1_op1[31:0] = sqrt_qt_1_rem_add_op1[31:0];
        rem_add2_op1[31:0] = sqrt_qt_2_rem_add_op1[31:0];
  end
  2'b00:
  begin
        rem_add1_op1[31:0] = div_qt_1_rem_add_op1[31:0];
        rem_add2_op1[31:0] = div_qt_2_rem_add_op1[31:0];
  end
  2'b11:
  begin
        rem_add1_op1[31:0] = sqrt_qt_r1_rem_add_op1[31:0];
        rem_add2_op1[31:0] = sqrt_qt_r2_rem_add_op1[31:0];
  end
  2'b10:
  begin
        rem_add1_op1[31:0] = div_qt_r1_rem_add_op1[31:0];
        rem_add2_op1[31:0] = div_qt_r2_rem_add_op1[31:0];
  end
  default :
  begin
        rem_add1_op1[31:0] = 32'b0;
        rem_add2_op1[31:0] = 32'b0;
  end
  endcase

end
assign srt_remainder_shift[31:0] = {srt_remainder[31],
                                    srt_remainder[28:0],2'b0};

assign cur_doub_rem_1[31:0]      = srt_remainder_shift[31:0] +
                                   rem_add1_op1[31:0]    +
                                   {31'b0, ~rem_sign};
assign cur_doub_rem_2[31:0]      = srt_remainder_shift[31:0] +
                                   rem_add2_op1[31:0]    +
                                   {31'b0, ~rem_sign};
assign cur_rem_1[31:0]           = cur_doub_rem_1[31:0];
assign cur_rem_2[31:0]           = cur_doub_rem_2[31:0];


always @( cur_rem_2[31:0]
       or bound1_cmp_sign
       or srt_remainder_shift[31:0]
       or bound2_cmp_sign
       or cur_rem_1[31:0])
begin
case({bound1_cmp_sign,bound2_cmp_sign})
  2'b00:   cur_rem[31:0]         = cur_rem_2[31:0];
  2'b01:   cur_rem[31:0]         = cur_rem_1[31:0];
  default: cur_rem[31:0]         = srt_remainder_shift[31:0];
endcase

end
assign srt_remainder_nxt[31:0]   = cur_rem[31:0];


assign srt_remainder_zero        = ~|srt_remainder[31:0];

assign srt_remainder_sign        =   srt_remainder[31];



endmodule



