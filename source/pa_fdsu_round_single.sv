module pa_fdsu_round_single(
  cp0_fpu_icg_en,
  cp0_yy_clk_en,
  ex3_expnt_adjust_result,
  ex3_frac_final_rst,
  ex3_pipedown,
  ex3_rslt_denorm,
  fdsu_ex3_id_srt_skip,
  fdsu_ex3_rem_sign,
  fdsu_ex3_rem_zero,
  fdsu_ex3_result_denorm_round_add_num,
  fdsu_ex4_denorm_to_tiny_frac,
  fdsu_ex4_nx,
  fdsu_ex4_potnt_norm,
  fdsu_ex4_result_nor,
  fdsu_yy_expnt_rst,
  fdsu_yy_result_inf,
  fdsu_yy_result_lfn,
  fdsu_yy_result_sign,
  fdsu_yy_rm,
  fdsu_yy_rslt_denorm,
  forever_cpuclk,
  pad_yy_icg_scan_en,
  total_qt_rt_30
);


input           cp0_fpu_icg_en;
input           cp0_yy_clk_en;
input           ex3_pipedown;
input           fdsu_ex3_id_srt_skip;
input           fdsu_ex3_rem_sign;
input           fdsu_ex3_rem_zero;
input   [23:0]  fdsu_ex3_result_denorm_round_add_num;
input   [9 :0]  fdsu_yy_expnt_rst;
input           fdsu_yy_result_inf;
input           fdsu_yy_result_lfn;
input           fdsu_yy_result_sign;
input   [2 :0]  fdsu_yy_rm;
input           fdsu_yy_rslt_denorm;
input           forever_cpuclk;
input           pad_yy_icg_scan_en;
input   [29:0]  total_qt_rt_30;
output  [9 :0]  ex3_expnt_adjust_result;
output  [25:0]  ex3_frac_final_rst;
output          ex3_rslt_denorm;
output          fdsu_ex4_denorm_to_tiny_frac;
output          fdsu_ex4_nx;
output  [1 :0]  fdsu_ex4_potnt_norm;
output          fdsu_ex4_result_nor;


reg             denorm_to_tiny_frac;
reg             fdsu_ex4_denorm_to_tiny_frac;
reg             fdsu_ex4_nx;
reg     [1 :0]  fdsu_ex4_potnt_norm;
reg             fdsu_ex4_result_nor;
reg     [25:0]  frac_add1_op1;
reg             frac_add_1;
reg             frac_orig;
reg     [25:0]  frac_sub1_op1;
reg             frac_sub_1;
reg     [27:0]  qt_result_single_denorm_for_round;
reg             single_denorm_lst_frac;


wire            cp0_fpu_icg_en;
wire            cp0_yy_clk_en;
wire            ex3_denorm_eq;
wire            ex3_denorm_gr;
wire            ex3_denorm_lst_frac;
wire            ex3_denorm_nx;
wire            ex3_denorm_plus;
wire            ex3_denorm_potnt_norm;
wire            ex3_denorm_zero;
wire    [9 :0]  ex3_expnt_adjst;
wire    [9 :0]  ex3_expnt_adjust_result;
wire    [25:0]  ex3_frac_final_rst;
wire            ex3_nx;
wire            ex3_pipe_clk;
wire            ex3_pipe_clk_en;
wire            ex3_pipedown;
wire    [1 :0]  ex3_potnt_norm;
wire            ex3_qt_eq;
wire            ex3_qt_gr;
wire            ex3_qt_sing_lo3_not0;
wire            ex3_qt_sing_lo4_not0;
wire            ex3_qt_zero;
wire            ex3_rslt_denorm;
wire            ex3_rst_eq_1;
wire            ex3_rst_nor;
wire            ex3_single_denorm_eq;
wire            ex3_single_denorm_gr;
wire            ex3_single_denorm_zero;
wire            ex3_single_low_not_zero;
wire    [9 :0]  fdsu_ex3_expnt_rst;
wire            fdsu_ex3_id_srt_skip;
wire            fdsu_ex3_rem_sign;
wire            fdsu_ex3_rem_zero;
wire    [23:0]  fdsu_ex3_result_denorm_round_add_num;
wire            fdsu_ex3_result_inf;
wire            fdsu_ex3_result_lfn;
wire            fdsu_ex3_result_sign;
wire    [2 :0]  fdsu_ex3_rm;
wire            fdsu_ex3_rslt_denorm;
wire    [9 :0]  fdsu_yy_expnt_rst;
wire            fdsu_yy_result_inf;
wire            fdsu_yy_result_lfn;
wire            fdsu_yy_result_sign;
wire    [2 :0]  fdsu_yy_rm;
wire            fdsu_yy_rslt_denorm;
wire            forever_cpuclk;
wire    [25:0]  frac_add1_op1_with_denorm;
wire    [25:0]  frac_add1_rst;
wire            frac_denorm_rdn_add_1;
wire            frac_denorm_rdn_sub_1;
wire            frac_denorm_rmm_add_1;
wire            frac_denorm_rne_add_1;
wire            frac_denorm_rtz_sub_1;
wire            frac_denorm_rup_add_1;
wire            frac_denorm_rup_sub_1;
wire    [25:0]  frac_final_rst;
wire            frac_rdn_add_1;
wire            frac_rdn_sub_1;
wire            frac_rmm_add_1;
wire            frac_rne_add_1;
wire            frac_rtz_sub_1;
wire            frac_rup_add_1;
wire            frac_rup_sub_1;
wire    [25:0]  frac_sub1_op1_with_denorm;
wire    [25:0]  frac_sub1_rst;
wire            pad_yy_icg_scan_en;
wire    [29:0]  total_qt_rt_30;


assign fdsu_ex3_result_sign     = fdsu_yy_result_sign;
assign fdsu_ex3_expnt_rst[9:0]  = fdsu_yy_expnt_rst[9:0];
assign fdsu_ex3_result_inf      = fdsu_yy_result_inf;
assign fdsu_ex3_result_lfn      = fdsu_yy_result_lfn;
assign fdsu_ex3_rm[2:0]         = fdsu_yy_rm[2:0];
assign fdsu_ex3_rslt_denorm     = fdsu_yy_rslt_denorm;









assign ex3_qt_sing_lo4_not0 = |total_qt_rt_30[3:0];
assign ex3_qt_sing_lo3_not0 = |total_qt_rt_30[2:0];

assign ex3_qt_gr          = (total_qt_rt_30[28])
                            ?  total_qt_rt_30[4] && ex3_qt_sing_lo4_not0
                            :  total_qt_rt_30[3] && ex3_qt_sing_lo3_not0;


assign ex3_qt_eq          = (total_qt_rt_30[28])
                            ?  total_qt_rt_30[4] && !ex3_qt_sing_lo4_not0
                            :  total_qt_rt_30[3] && !ex3_qt_sing_lo3_not0;

assign ex3_qt_zero        = (total_qt_rt_30[28])
                            ? ~|total_qt_rt_30[4:0]
                            : ~|total_qt_rt_30[3:0];

assign ex3_rst_eq_1    = total_qt_rt_30[28] && ~|total_qt_rt_30[27:5];



assign ex3_denorm_plus       = !total_qt_rt_30[28] && (fdsu_ex3_expnt_rst[9:0] == 10'h382);
assign ex3_denorm_potnt_norm = total_qt_rt_30[28] && (fdsu_ex3_expnt_rst[9:0] == 10'h381);
assign ex3_rslt_denorm            = ex3_denorm_plus || fdsu_ex3_rslt_denorm;





always @( total_qt_rt_30[28:0]
       or fdsu_ex3_expnt_rst[9:0])
begin
case(fdsu_ex3_expnt_rst[9:0])
  10'h382:begin qt_result_single_denorm_for_round[27:0] = {total_qt_rt_30[4:0],23'b0};
                single_denorm_lst_frac =  total_qt_rt_30[5];
			 		end
  10'h381:begin qt_result_single_denorm_for_round[27:0] = {total_qt_rt_30[5:0],22'b0};
                single_denorm_lst_frac =  total_qt_rt_30[6];
			 		end
  10'h380:begin qt_result_single_denorm_for_round[27:0] = {total_qt_rt_30[6:0],21'b0};
                single_denorm_lst_frac =  total_qt_rt_30[7];
			 		end
  10'h37f:begin qt_result_single_denorm_for_round[27:0] = {total_qt_rt_30[7:0],20'b0};
                single_denorm_lst_frac =  total_qt_rt_30[8];
			 		end
  10'h37e:begin qt_result_single_denorm_for_round[27:0] = {total_qt_rt_30[8:0],19'b0};
                single_denorm_lst_frac =  total_qt_rt_30[9];
			 		end
  10'h37d:begin qt_result_single_denorm_for_round[27:0] = {total_qt_rt_30[9:0],18'b0};
                single_denorm_lst_frac =  total_qt_rt_30[10];
			 		end
  10'h37c:begin qt_result_single_denorm_for_round[27:0] = {total_qt_rt_30[10:0],17'b0};
                single_denorm_lst_frac =  total_qt_rt_30[11];
			 		end
  10'h37b:begin qt_result_single_denorm_for_round[27:0] = {total_qt_rt_30[11:0],16'b0};
                single_denorm_lst_frac =  total_qt_rt_30[12];
			 		end
  10'h37a:begin qt_result_single_denorm_for_round[27:0] = {total_qt_rt_30[12:0],15'b0};
                single_denorm_lst_frac =  total_qt_rt_30[13];
			 		end
  10'h379:begin qt_result_single_denorm_for_round[27:0] = {total_qt_rt_30[13:0],14'b0};
                single_denorm_lst_frac =  total_qt_rt_30[14];
			 		end
  10'h378:begin qt_result_single_denorm_for_round[27:0] = {total_qt_rt_30[14:0],13'b0};
                single_denorm_lst_frac =  total_qt_rt_30[15];
			 		end
  10'h377:begin qt_result_single_denorm_for_round[27:0] = {total_qt_rt_30[15:0],12'b0};
                single_denorm_lst_frac =  total_qt_rt_30[16];
			 		end
  10'h376:begin qt_result_single_denorm_for_round[27:0] = {total_qt_rt_30[16:0],11'b0};
                single_denorm_lst_frac =  total_qt_rt_30[17];
			 		end
  10'h375:begin qt_result_single_denorm_for_round[27:0] = {total_qt_rt_30[17:0],10'b0};
                single_denorm_lst_frac =  total_qt_rt_30[18];
			 		end
  10'h374:begin qt_result_single_denorm_for_round[27:0] = {total_qt_rt_30[18:0],9'b0};
                single_denorm_lst_frac =  total_qt_rt_30[19];
			 		end
  10'h373:begin qt_result_single_denorm_for_round[27:0] = {total_qt_rt_30[19:0],8'b0};
                single_denorm_lst_frac =  total_qt_rt_30[20];
			 		end
  10'h372:begin qt_result_single_denorm_for_round[27:0] = {total_qt_rt_30[20:0],7'b0};
                single_denorm_lst_frac =  total_qt_rt_30[21];
			 		end
  10'h371:begin qt_result_single_denorm_for_round[27:0] = {total_qt_rt_30[21:0],6'b0};
                single_denorm_lst_frac =  total_qt_rt_30[22];
			 		end
  10'h370:begin qt_result_single_denorm_for_round[27:0] = {total_qt_rt_30[22:0],5'b0};
                single_denorm_lst_frac =  total_qt_rt_30[23];
			 		end
  10'h36f:begin qt_result_single_denorm_for_round[27:0] = {total_qt_rt_30[23:0],4'b0};
                single_denorm_lst_frac =  total_qt_rt_30[24];
			 		end
  10'h36e:begin qt_result_single_denorm_for_round[27:0] = {total_qt_rt_30[24:0],3'b0};
                single_denorm_lst_frac =  total_qt_rt_30[25];
			 		end
  10'h36d:begin qt_result_single_denorm_for_round[27:0] = {total_qt_rt_30[25:0],2'b0};
                single_denorm_lst_frac =  total_qt_rt_30[26];
			 		end
  10'h36c:begin qt_result_single_denorm_for_round[27:0] = {total_qt_rt_30[26:0],1'b0};
                single_denorm_lst_frac =  total_qt_rt_30[27];
			 		end
  10'h36b: begin qt_result_single_denorm_for_round[27:0] = {total_qt_rt_30[27:0]};
                 single_denorm_lst_frac = total_qt_rt_30[28] ;
						end
  default:  begin qt_result_single_denorm_for_round[27:0] = {total_qt_rt_30[28:1]};
                 single_denorm_lst_frac = 1'b0;
						end
endcase

end

assign ex3_single_denorm_eq      = qt_result_single_denorm_for_round[27]
                                   &&  !ex3_single_low_not_zero;
assign ex3_single_low_not_zero   = |qt_result_single_denorm_for_round[26:0];
assign ex3_single_denorm_gr      = qt_result_single_denorm_for_round[27]
                                   &&  ex3_single_low_not_zero;
assign ex3_single_denorm_zero    = !qt_result_single_denorm_for_round[27]
                                   && !ex3_single_low_not_zero;


assign ex3_denorm_eq             = ex3_single_denorm_eq;
assign ex3_denorm_gr             = ex3_single_denorm_gr;
assign ex3_denorm_zero           = ex3_single_denorm_zero;
assign ex3_denorm_lst_frac       = single_denorm_lst_frac;






















assign frac_rne_add_1 = ex3_qt_gr ||
                       (ex3_qt_eq && !fdsu_ex3_rem_sign);
assign frac_rtz_sub_1 = ex3_qt_zero && fdsu_ex3_rem_sign;
assign frac_rup_add_1 = !fdsu_ex3_result_sign &&
                       (!ex3_qt_zero ||
                       (!fdsu_ex3_rem_sign && !fdsu_ex3_rem_zero));
assign frac_rup_sub_1 = fdsu_ex3_result_sign &&
                       (ex3_qt_zero && fdsu_ex3_rem_sign);
assign frac_rdn_add_1 = fdsu_ex3_result_sign &&
                       (!ex3_qt_zero ||
                       (!fdsu_ex3_rem_sign && !fdsu_ex3_rem_zero));
assign frac_rdn_sub_1 = !fdsu_ex3_result_sign &&
                       (ex3_qt_zero && fdsu_ex3_rem_sign);
assign frac_rmm_add_1 = ex3_qt_gr ||
                       (ex3_qt_eq && !fdsu_ex3_rem_sign);

assign frac_denorm_rne_add_1 = ex3_denorm_gr ||
                               (ex3_denorm_eq &&
                               ((fdsu_ex3_rem_zero &&
                                ex3_denorm_lst_frac) ||
                               (!fdsu_ex3_rem_zero &&
                                !fdsu_ex3_rem_sign)));
assign frac_denorm_rtz_sub_1 = ex3_denorm_zero && fdsu_ex3_rem_sign;
assign frac_denorm_rup_add_1 = !fdsu_ex3_result_sign &&
                               (!ex3_denorm_zero ||
                               (!fdsu_ex3_rem_sign && !fdsu_ex3_rem_zero));
assign frac_denorm_rup_sub_1 = fdsu_ex3_result_sign &&
                       (ex3_denorm_zero && fdsu_ex3_rem_sign);
assign frac_denorm_rdn_add_1 = fdsu_ex3_result_sign &&
                       (!ex3_denorm_zero ||
                       (!fdsu_ex3_rem_sign && !fdsu_ex3_rem_zero));
assign frac_denorm_rdn_sub_1 = !fdsu_ex3_result_sign &&
                       (ex3_denorm_zero && fdsu_ex3_rem_sign);
assign frac_denorm_rmm_add_1 = ex3_denorm_gr ||
                       (ex3_denorm_eq && !fdsu_ex3_rem_sign);



always @( fdsu_ex3_rm[2:0]
       or frac_denorm_rdn_add_1
       or frac_rne_add_1
       or frac_denorm_rdn_sub_1
       or fdsu_ex3_result_sign
       or frac_rup_add_1
       or frac_denorm_rup_sub_1
       or frac_rdn_sub_1
       or frac_rtz_sub_1
       or frac_rdn_add_1
       or fdsu_ex3_id_srt_skip
       or frac_denorm_rtz_sub_1
       or ex3_rslt_denorm
       or frac_rup_sub_1
       or frac_denorm_rmm_add_1
       or frac_denorm_rup_add_1
       or frac_denorm_rne_add_1
       or frac_rmm_add_1)
begin
case(fdsu_ex3_rm[2:0])
  3'b000:
  begin
    frac_add_1          =  ex3_rslt_denorm ? frac_denorm_rne_add_1 : frac_rne_add_1;
    frac_sub_1          =  1'b0;
    frac_orig           =  ex3_rslt_denorm ? !frac_denorm_rne_add_1 : !frac_rne_add_1;
    denorm_to_tiny_frac =  fdsu_ex3_id_srt_skip ? 1'b0 : frac_denorm_rne_add_1;
  end
  3'b001:
  begin
    frac_add_1           =  1'b0;
    frac_sub_1           =  ex3_rslt_denorm ? frac_denorm_rtz_sub_1 : frac_rtz_sub_1;
    frac_orig            =  ex3_rslt_denorm ? !frac_denorm_rtz_sub_1 : !frac_rtz_sub_1;
    denorm_to_tiny_frac  = 1'b0;
  end
  3'b010:
  begin
    frac_add_1          =  ex3_rslt_denorm ? frac_denorm_rdn_add_1 : frac_rdn_add_1;
    frac_sub_1          =  ex3_rslt_denorm ? frac_denorm_rdn_sub_1 : frac_rdn_sub_1;
    frac_orig           =  ex3_rslt_denorm ? !frac_denorm_rdn_add_1 && !frac_denorm_rdn_sub_1
                                           : !frac_rdn_add_1 && !frac_rdn_sub_1;
    denorm_to_tiny_frac = fdsu_ex3_id_srt_skip ? fdsu_ex3_result_sign
                                                : frac_denorm_rdn_add_1;
  end
  3'b011:
  begin
    frac_add_1          =  ex3_rslt_denorm ? frac_denorm_rup_add_1 : frac_rup_add_1;
    frac_sub_1          =  ex3_rslt_denorm ? frac_denorm_rup_sub_1 : frac_rup_sub_1;
    frac_orig           =  ex3_rslt_denorm ? !frac_denorm_rup_add_1 && !frac_denorm_rup_sub_1
                                           : !frac_rup_add_1 && !frac_rup_sub_1;
    denorm_to_tiny_frac = fdsu_ex3_id_srt_skip ? !fdsu_ex3_result_sign
                                                : frac_denorm_rup_add_1;
  end
  3'b100:
  begin
    frac_add_1          = ex3_rslt_denorm ? frac_denorm_rmm_add_1 : frac_rmm_add_1;
    frac_sub_1          = 1'b0;
    frac_orig           = ex3_rslt_denorm ? !frac_denorm_rmm_add_1 : !frac_rmm_add_1;
    denorm_to_tiny_frac = fdsu_ex3_id_srt_skip ? 1'b0 : frac_denorm_rmm_add_1;
  end
  default:
  begin
    frac_add_1          = 1'b0;
    frac_sub_1          = 1'b0;
    frac_orig           = 1'b0;
    denorm_to_tiny_frac = 1'b0;
  end
endcase

end


always @( total_qt_rt_30[28])
begin
case(total_qt_rt_30[28])
  1'b0:
  begin
    frac_add1_op1[25:0] = {2'b0,24'b1};
    frac_sub1_op1[25:0] = {2'b11,{24{1'b1}}};
  end
  1'b1:
  begin
    frac_add1_op1[25:0] = {25'b1,1'b0};
    frac_sub1_op1[25:0] = {{25{1'b1}},1'b0};
  end
  default:
  begin
    frac_add1_op1[25:0] = 26'b0;
    frac_sub1_op1[25:0] = 26'b0;
  end
endcase

end








assign frac_add1_rst[25:0]             = {1'b0,total_qt_rt_30[28:4]} +
                                         frac_add1_op1_with_denorm[25:0];
assign frac_add1_op1_with_denorm[25:0] = ex3_rslt_denorm ?
                                  {1'b0,fdsu_ex3_result_denorm_round_add_num[23:0],1'b0} :
                                  frac_add1_op1[25:0];
assign frac_sub1_rst[25:0]             = (ex3_rst_eq_1)
                                       ? {3'b0,{23{1'b1}}}
                                       : {1'b0,total_qt_rt_30[28:4]} +
                                         frac_sub1_op1_with_denorm[25:0] + {25'b0, ex3_rslt_denorm};
assign frac_sub1_op1_with_denorm[25:0] = ex3_rslt_denorm ?
                                ~{1'b0,fdsu_ex3_result_denorm_round_add_num[23:0],1'b0} :
                                frac_sub1_op1[25:0];
assign frac_final_rst[25:0]           = (frac_add1_rst[25:0]         & {26{frac_add_1}}) |
                                        (frac_sub1_rst[25:0]         & {26{frac_sub_1}}) |
                                        ({1'b0,total_qt_rt_30[28:4]} & {26{frac_orig}});






assign ex3_rst_nor = !fdsu_ex3_result_inf  &&
                     !fdsu_ex3_result_lfn;
assign ex3_nx      = ex3_rst_nor &&
                    (!ex3_qt_zero || !fdsu_ex3_rem_zero || ex3_denorm_nx);
assign ex3_denorm_nx = ex3_rslt_denorm && (!ex3_denorm_zero ||  !fdsu_ex3_rem_zero);


assign ex3_expnt_adjst[9:0] = 10'h7f;

assign ex3_expnt_adjust_result[9:0] = fdsu_ex3_expnt_rst[9:0] +
                                       ex3_expnt_adjst[9:0];


assign ex3_potnt_norm[1:0]    = {ex3_denorm_plus,ex3_denorm_potnt_norm};



gated_clk_cell  x_ex3_pipe_clk (
  .clk_in             (forever_cpuclk    ),
  .clk_out            (ex3_pipe_clk      ),
  .external_en        (1'b0              ),
  .global_en          (cp0_yy_clk_en     ),
  .local_en           (ex3_pipe_clk_en   ),
  .module_en          (cp0_fpu_icg_en    ),
  .pad_yy_icg_scan_en (pad_yy_icg_scan_en)
);








assign ex3_pipe_clk_en = ex3_pipedown;

always @(posedge ex3_pipe_clk)
begin
  if(ex3_pipedown)
  begin
    fdsu_ex4_result_nor      <= ex3_rst_nor;
    fdsu_ex4_nx              <= ex3_nx;
    fdsu_ex4_denorm_to_tiny_frac
                              <= denorm_to_tiny_frac;
    fdsu_ex4_potnt_norm[1:0] <= ex3_potnt_norm[1:0];
  end
  else
  begin
    fdsu_ex4_result_nor      <= fdsu_ex4_result_nor;
    fdsu_ex4_nx              <= fdsu_ex4_nx;
    fdsu_ex4_denorm_to_tiny_frac
                              <= fdsu_ex4_denorm_to_tiny_frac;
    fdsu_ex4_potnt_norm[1:0] <= fdsu_ex4_potnt_norm[1:0];
  end
end


assign ex3_frac_final_rst[25:0] = frac_final_rst[25:0];







endmodule



