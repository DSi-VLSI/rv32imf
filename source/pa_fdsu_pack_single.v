module pa_fdsu_pack_single(
  fdsu_ex4_denorm_to_tiny_frac,
  fdsu_ex4_frac,
  fdsu_ex4_nx,
  fdsu_ex4_potnt_norm,
  fdsu_ex4_result_nor,
  fdsu_frbus_data,
  fdsu_frbus_fflags,
  fdsu_frbus_freg,
  fdsu_yy_expnt_rst,
  fdsu_yy_of,
  fdsu_yy_of_rm_lfn,
  fdsu_yy_potnt_of,
  fdsu_yy_potnt_uf,
  fdsu_yy_result_inf,
  fdsu_yy_result_lfn,
  fdsu_yy_result_sign,
  fdsu_yy_rslt_denorm,
  fdsu_yy_uf,
  fdsu_yy_wb_freg
);


input           fdsu_ex4_denorm_to_tiny_frac;
input   [25:0]  fdsu_ex4_frac;
input           fdsu_ex4_nx;
input   [1 :0]  fdsu_ex4_potnt_norm;
input           fdsu_ex4_result_nor;
input   [9 :0]  fdsu_yy_expnt_rst;
input           fdsu_yy_of;
input           fdsu_yy_of_rm_lfn;
input           fdsu_yy_potnt_of;
input           fdsu_yy_potnt_uf;
input           fdsu_yy_result_inf;
input           fdsu_yy_result_lfn;
input           fdsu_yy_result_sign;
input           fdsu_yy_rslt_denorm;
input           fdsu_yy_uf;
input   [4 :0]  fdsu_yy_wb_freg;
output  [31:0]  fdsu_frbus_data;
output  [4 :0]  fdsu_frbus_fflags;
output  [4 :0]  fdsu_frbus_freg;


reg     [22:0]  ex4_frac_23;
reg     [31:0]  ex4_result;
reg     [22:0]  ex4_single_denorm_frac;
reg     [9 :0]  expnt_add_op1;


wire            ex4_cor_nx;
wire            ex4_cor_uf;
wire            ex4_denorm_potnt_norm;
wire    [31:0]  ex4_denorm_result;
wire    [9 :0]  ex4_expnt_rst;
wire    [4 :0]  ex4_expt;
wire            ex4_final_rst_norm;
wire    [25:0]  ex4_frac;
wire            ex4_of_plus;
wire            ex4_result_inf;
wire            ex4_result_lfn;
wire            ex4_rslt_denorm;
wire    [31:0]  ex4_rst_inf;
wire    [31:0]  ex4_rst_lfn;
wire            ex4_rst_nor;
wire    [31:0]  ex4_rst_norm;
wire            ex4_uf_plus;
wire            fdsu_ex4_denorm_to_tiny_frac;
wire            fdsu_ex4_dz;
wire    [9 :0]  fdsu_ex4_expnt_rst;
wire    [25:0]  fdsu_ex4_frac;
wire            fdsu_ex4_nv;
wire            fdsu_ex4_nx;
wire            fdsu_ex4_of;
wire            fdsu_ex4_of_rst_lfn;
wire    [1 :0]  fdsu_ex4_potnt_norm;
wire            fdsu_ex4_potnt_of;
wire            fdsu_ex4_potnt_uf;
wire            fdsu_ex4_result_inf;
wire            fdsu_ex4_result_lfn;
wire            fdsu_ex4_result_nor;
wire            fdsu_ex4_result_sign;
wire            fdsu_ex4_rslt_denorm;
wire            fdsu_ex4_uf;
wire    [31:0]  fdsu_frbus_data;
wire    [4 :0]  fdsu_frbus_fflags;
wire    [4 :0]  fdsu_frbus_freg;
wire    [9 :0]  fdsu_yy_expnt_rst;
wire            fdsu_yy_of;
wire            fdsu_yy_of_rm_lfn;
wire            fdsu_yy_potnt_of;
wire            fdsu_yy_potnt_uf;
wire            fdsu_yy_result_inf;
wire            fdsu_yy_result_lfn;
wire            fdsu_yy_result_sign;
wire            fdsu_yy_rslt_denorm;
wire            fdsu_yy_uf;
wire    [4 :0]  fdsu_yy_wb_freg;


assign fdsu_ex4_result_sign     = fdsu_yy_result_sign;
assign fdsu_ex4_of_rst_lfn      = fdsu_yy_of_rm_lfn;
assign fdsu_ex4_result_inf      = fdsu_yy_result_inf;
assign fdsu_ex4_result_lfn      = fdsu_yy_result_lfn;
assign fdsu_ex4_of              = fdsu_yy_of;
assign fdsu_ex4_uf              = fdsu_yy_uf;
assign fdsu_ex4_potnt_of        = fdsu_yy_potnt_of;
assign fdsu_ex4_potnt_uf        = fdsu_yy_potnt_uf;
assign fdsu_ex4_nv              = 1'b0;
assign fdsu_ex4_dz              = 1'b0;
assign fdsu_ex4_expnt_rst[9:0] = fdsu_yy_expnt_rst[9:0];
assign fdsu_ex4_rslt_denorm     = fdsu_yy_rslt_denorm;

assign ex4_frac[25:0] = fdsu_ex4_frac[25:0];


always @( ex4_frac[25:24])
begin
casez(ex4_frac[25:24])
  2'b00   : expnt_add_op1[9:0] = 10'h1ff;
  2'b01   : expnt_add_op1[9:0] = 10'h0;
  2'b1?   : expnt_add_op1[9:0] = 10'h1;
  default : expnt_add_op1[9:0] = 10'b0;
endcase

end
assign ex4_expnt_rst[9:0] = fdsu_ex4_expnt_rst[9:0] +
                             expnt_add_op1[9:0];






always @( fdsu_ex4_expnt_rst[9:0]
       or fdsu_ex4_denorm_to_tiny_frac
       or ex4_frac[25:1])
begin
case(fdsu_ex4_expnt_rst[9:0])
  10'h1:   ex4_single_denorm_frac[22:0] = {      ex4_frac[23:1]};
  10'h0:   ex4_single_denorm_frac[22:0] = {      ex4_frac[24:2]};
  10'h3ff:ex4_single_denorm_frac[22:0] = {      ex4_frac[25:3]};
  10'h3fe:ex4_single_denorm_frac[22:0] = {1'b0, ex4_frac[25:4]};
  10'h3fd:ex4_single_denorm_frac[22:0] = {2'b0, ex4_frac[25:5]};
  10'h3fc:ex4_single_denorm_frac[22:0] = {3'b0, ex4_frac[25:6]};
  10'h3fb:ex4_single_denorm_frac[22:0] = {4'b0, ex4_frac[25:7]};
  10'h3fa:ex4_single_denorm_frac[22:0] = {5'b0, ex4_frac[25:8]};
  10'h3f9:ex4_single_denorm_frac[22:0] = {6'b0, ex4_frac[25:9]};
  10'h3f8:ex4_single_denorm_frac[22:0] = {7'b0, ex4_frac[25:10]};
  10'h3f7:ex4_single_denorm_frac[22:0] = {8'b0, ex4_frac[25:11]};
  10'h3f6:ex4_single_denorm_frac[22:0] = {9'b0, ex4_frac[25:12]};
  10'h3f5:ex4_single_denorm_frac[22:0] = {10'b0,ex4_frac[25:13]};
  10'h3f4:ex4_single_denorm_frac[22:0] = {11'b0,ex4_frac[25:14]};
  10'h3f3:ex4_single_denorm_frac[22:0] = {12'b0,ex4_frac[25:15]};
  10'h3f2:ex4_single_denorm_frac[22:0] = {13'b0,ex4_frac[25:16]};
  10'h3f1:ex4_single_denorm_frac[22:0] = {14'b0,ex4_frac[25:17]};
  10'h3f0:ex4_single_denorm_frac[22:0] = {15'b0,ex4_frac[25:18]};
  10'h3ef:ex4_single_denorm_frac[22:0] = {16'b0,ex4_frac[25:19]};
  10'h3ee:ex4_single_denorm_frac[22:0] = {17'b0,ex4_frac[25:20]};
  10'h3ed:ex4_single_denorm_frac[22:0] = {18'b0,ex4_frac[25:21]};
  10'h3ec:ex4_single_denorm_frac[22:0] = {19'b0,ex4_frac[25:22]};
  10'h3eb:ex4_single_denorm_frac[22:0] = {20'b0,ex4_frac[25:23]};
  10'h3ea:ex4_single_denorm_frac[22:0] = {21'b0,ex4_frac[25:24]};
  default :ex4_single_denorm_frac[22:0] = fdsu_ex4_denorm_to_tiny_frac ? 23'b1 : 23'b0;
endcase

end

assign ex4_denorm_potnt_norm    = (fdsu_ex4_potnt_norm[1] && ex4_frac[24]) ||
                                  (fdsu_ex4_potnt_norm[0] && ex4_frac[25]) ;
assign ex4_rslt_denorm          = fdsu_ex4_rslt_denorm && !ex4_denorm_potnt_norm;
assign ex4_denorm_result[31:0]  = {fdsu_ex4_result_sign,
                                        8'h0,ex4_single_denorm_frac[22:0]};



assign ex4_rst_nor = fdsu_ex4_result_nor;
assign ex4_of_plus = fdsu_ex4_potnt_of  &&
                     (|ex4_frac[25:24])  &&
                     ex4_rst_nor;
assign ex4_uf_plus = fdsu_ex4_potnt_uf  &&
                     (~|ex4_frac[25:24]) &&
                     ex4_rst_nor;

assign ex4_result_lfn = (ex4_of_plus &&  fdsu_ex4_of_rst_lfn) ||
                        fdsu_ex4_result_lfn;
assign ex4_result_inf = (ex4_of_plus && !fdsu_ex4_of_rst_lfn) ||
                        fdsu_ex4_result_inf;


assign ex4_rst_lfn[31:0]      = {fdsu_ex4_result_sign,8'hfe,{23{1'b1}}};

assign ex4_rst_inf[31:0]  = {fdsu_ex4_result_sign,8'hff,23'b0};


always @( ex4_frac[25:0])
begin
casez(ex4_frac[25:24])
  2'b00   : ex4_frac_23[22:0]  = ex4_frac[22:0];
  2'b01   : ex4_frac_23[22:0]  = ex4_frac[23:1];
  2'b1?   : ex4_frac_23[22:0]  = ex4_frac[24:2];
  default : ex4_frac_23[22:0]  = 23'b0;
endcase

end
assign ex4_rst_norm[31:0] = {fdsu_ex4_result_sign,
                                  ex4_expnt_rst[7:0],
                                  ex4_frac_23[22:0]};
assign ex4_cor_uf            = (fdsu_ex4_uf || ex4_denorm_potnt_norm || ex4_uf_plus)
                               && fdsu_ex4_nx;
assign ex4_cor_nx            =  fdsu_ex4_nx
                                || fdsu_ex4_of
                                || ex4_of_plus;

assign ex4_expt[4:0]           = {
                                  fdsu_ex4_nv,
                                  fdsu_ex4_dz,
                                  fdsu_ex4_of | ex4_of_plus,
                                  ex4_cor_uf,
                                  ex4_cor_nx};

assign ex4_final_rst_norm      = !ex4_result_inf        &&
                                 !ex4_result_lfn        &&
                                 !ex4_rslt_denorm;

always @( ex4_denorm_result[31:0]
       or ex4_result_lfn
       or ex4_result_inf
       or ex4_final_rst_norm
       or ex4_rst_norm[31:0]
       or ex4_rst_lfn[31:0]
       or ex4_rst_inf[31:0]
       or ex4_rslt_denorm)
begin
case({ex4_rslt_denorm,
      ex4_result_inf,
      ex4_result_lfn,
      ex4_final_rst_norm})
  4'b1000 : ex4_result[31:0]  = ex4_denorm_result[31:0];
  4'b0100 : ex4_result[31:0]  = ex4_rst_inf[31:0];
  4'b0010 : ex4_result[31:0]  = ex4_rst_lfn[31:0];
  4'b0001 : ex4_result[31:0]  = ex4_rst_norm[31:0];
  default   : ex4_result[31:0]  = 32'b0;
endcase

end




assign fdsu_frbus_freg[4:0]   = fdsu_yy_wb_freg[4:0];
assign fdsu_frbus_data[31:0]  = ex4_result[31:0];
assign fdsu_frbus_fflags[4:0] = ex4_expt[4:0];


endmodule



