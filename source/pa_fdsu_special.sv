module pa_fdsu_special(
  cp0_fpu_xx_dqnan,
  dp_xx_ex1_cnan,
  dp_xx_ex1_id,
  dp_xx_ex1_inf,
  dp_xx_ex1_qnan,
  dp_xx_ex1_snan,
  dp_xx_ex1_zero,
  ex1_div,
  ex1_op0_id,
  ex1_op0_norm,
  ex1_op0_sign,
  ex1_op1_id,
  ex1_op1_norm,
  ex1_result_sign,
  ex1_sqrt,
  ex1_srt_skip,
  fdsu_fpu_ex1_fflags,
  fdsu_fpu_ex1_special_sel,
  fdsu_fpu_ex1_special_sign
);


input          cp0_fpu_xx_dqnan;
input   [2:0]  dp_xx_ex1_cnan;
input   [2:0]  dp_xx_ex1_id;
input   [2:0]  dp_xx_ex1_inf;
input   [2:0]  dp_xx_ex1_qnan;
input   [2:0]  dp_xx_ex1_snan;
input   [2:0]  dp_xx_ex1_zero;
input          ex1_div;
input          ex1_op0_sign;
input          ex1_result_sign;
input          ex1_sqrt;
output         ex1_op0_id;
output         ex1_op0_norm;
output         ex1_op1_id;
output         ex1_op1_norm;
output         ex1_srt_skip;
output  [4:0]  fdsu_fpu_ex1_fflags;
output  [7:0]  fdsu_fpu_ex1_special_sel;
output  [3:0]  fdsu_fpu_ex1_special_sign;


reg            ex1_result_cnan;
reg            ex1_result_qnan_op0;
reg            ex1_result_qnan_op1;


wire           cp0_fpu_xx_dqnan;
wire    [2:0]  dp_xx_ex1_cnan;
wire    [2:0]  dp_xx_ex1_id;
wire    [2:0]  dp_xx_ex1_inf;
wire    [2:0]  dp_xx_ex1_qnan;
wire    [2:0]  dp_xx_ex1_snan;
wire    [2:0]  dp_xx_ex1_zero;
wire           ex1_div;
wire           ex1_div_dz;
wire           ex1_div_nv;
wire           ex1_div_rst_inf;
wire           ex1_div_rst_qnan;
wire           ex1_div_rst_zero;
wire           ex1_dz;
wire    [4:0]  ex1_fflags;
wire           ex1_nv;
wire           ex1_op0_cnan;
wire           ex1_op0_id;
wire           ex1_op0_inf;
wire           ex1_op0_is_qnan;
wire           ex1_op0_is_snan;
wire           ex1_op0_norm;
wire           ex1_op0_qnan;
wire           ex1_op0_sign;
wire           ex1_op0_snan;
wire           ex1_op0_tt_zero;
wire           ex1_op0_zero;
wire           ex1_op1_cnan;
wire           ex1_op1_id;
wire           ex1_op1_inf;
wire           ex1_op1_is_qnan;
wire           ex1_op1_is_snan;
wire           ex1_op1_norm;
wire           ex1_op1_qnan;
wire           ex1_op1_snan;
wire           ex1_op1_tt_zero;
wire           ex1_op1_zero;
wire           ex1_result_inf;
wire           ex1_result_lfn;
wire           ex1_result_qnan;
wire           ex1_result_sign;
wire           ex1_result_zero;
wire           ex1_rst_default_qnan;
wire    [7:0]  ex1_special_sel;
wire    [3:0]  ex1_special_sign;
wire           ex1_sqrt;
wire           ex1_sqrt_nv;
wire           ex1_sqrt_rst_inf;
wire           ex1_sqrt_rst_qnan;
wire           ex1_sqrt_rst_zero;
wire           ex1_srt_skip;
wire    [4:0]  fdsu_fpu_ex1_fflags;
wire    [7:0]  fdsu_fpu_ex1_special_sel;
wire    [3:0]  fdsu_fpu_ex1_special_sign;




assign  ex1_op0_inf                = dp_xx_ex1_inf[0];
assign  ex1_op1_inf                = dp_xx_ex1_inf[1];



assign ex1_op0_zero                = dp_xx_ex1_zero[0];
assign ex1_op1_zero                = dp_xx_ex1_zero[1];



assign ex1_op0_id                  = dp_xx_ex1_id[0];
assign ex1_op1_id                  = dp_xx_ex1_id[1];



assign ex1_op0_cnan                = dp_xx_ex1_cnan[0];
assign ex1_op1_cnan                = dp_xx_ex1_cnan[1];



assign ex1_op0_snan                = dp_xx_ex1_snan[0];
assign ex1_op1_snan                = dp_xx_ex1_snan[1];



assign ex1_op0_qnan                = dp_xx_ex1_qnan[0];
assign ex1_op1_qnan                = dp_xx_ex1_qnan[1];















assign ex1_nv      = ex1_div  && ex1_div_nv  ||
                     ex1_sqrt && ex1_sqrt_nv;

assign ex1_div_nv  = ex1_op0_snan ||
                     ex1_op1_snan ||
                    (ex1_op0_tt_zero && ex1_op1_tt_zero)||
                    (ex1_op0_inf && ex1_op1_inf);
assign ex1_op0_tt_zero = ex1_op0_zero;
assign ex1_op1_tt_zero = ex1_op1_zero;

assign ex1_sqrt_nv = ex1_op0_snan ||
                     ex1_op0_sign &&
                    (ex1_op0_norm ||
                     ex1_op0_inf );


assign ex1_op0_norm = !ex1_op0_inf && !ex1_op0_zero && !ex1_op0_snan && !ex1_op0_qnan && !ex1_op0_cnan;
assign ex1_op1_norm = !ex1_op1_inf && !ex1_op1_zero && !ex1_op1_snan && !ex1_op1_qnan && !ex1_op1_cnan;



















assign ex1_dz      = ex1_div && ex1_div_dz;
assign ex1_div_dz  = ex1_op1_tt_zero && ex1_op0_norm;








assign ex1_result_zero   = ex1_div_rst_zero  && ex1_div  ||
                           ex1_sqrt_rst_zero && ex1_sqrt;
assign ex1_div_rst_zero  = (ex1_op0_tt_zero && ex1_op1_norm ) ||

                           (!ex1_op0_inf && !ex1_op0_qnan && !ex1_op0_snan && !ex1_op0_cnan && ex1_op1_inf);
assign ex1_sqrt_rst_zero = ex1_op0_tt_zero;







assign ex1_result_qnan   = ex1_div_rst_qnan  && ex1_div  ||
                           ex1_sqrt_rst_qnan && ex1_sqrt ||
                           ex1_nv;
assign ex1_div_rst_qnan  = ex1_op0_qnan ||
                           ex1_op1_qnan;
assign ex1_sqrt_rst_qnan = ex1_op0_qnan;



assign ex1_rst_default_qnan = (ex1_div && ex1_op0_zero && ex1_op1_zero) ||
                              (ex1_div && ex1_op0_inf  && ex1_op1_inf)  ||
                              (ex1_sqrt&& ex1_op0_sign && (ex1_op0_norm || ex1_op0_inf));








assign ex1_result_inf    = ex1_div_rst_inf  && ex1_div  ||
                           ex1_sqrt_rst_inf && ex1_sqrt ||
                           ex1_dz ;

assign ex1_div_rst_inf   = ex1_op0_inf && !ex1_op1_inf && !ex1_op1_qnan && !ex1_op1_snan && !ex1_op1_cnan;
assign ex1_sqrt_rst_inf  = ex1_op0_inf && !ex1_op0_sign;



assign ex1_result_lfn = 1'b0;


assign ex1_op0_is_snan      = ex1_op0_snan;
assign ex1_op1_is_snan      = ex1_op1_snan && ex1_div;
assign ex1_op0_is_qnan      = ex1_op0_qnan;
assign ex1_op1_is_qnan      = ex1_op1_qnan && ex1_div;


always @( ex1_op0_is_snan
       or ex1_op0_cnan
       or ex1_result_qnan
       or ex1_op0_is_qnan
       or ex1_rst_default_qnan
       or cp0_fpu_xx_dqnan
       or ex1_op1_cnan
       or ex1_op1_is_qnan
       or ex1_op1_is_snan)
begin
if(ex1_rst_default_qnan)
begin
  ex1_result_qnan_op0  = 1'b0;
  ex1_result_qnan_op1  = 1'b0;
  ex1_result_cnan      = ex1_result_qnan;
end
else if(ex1_op0_is_snan && cp0_fpu_xx_dqnan)
begin
  ex1_result_qnan_op0  = ex1_result_qnan;
  ex1_result_qnan_op1  = 1'b0;
  ex1_result_cnan      = 1'b0;
end
else if(ex1_op1_is_snan && cp0_fpu_xx_dqnan)
begin
  ex1_result_qnan_op0  = 1'b0;
  ex1_result_qnan_op1  = ex1_result_qnan;
  ex1_result_cnan      = 1'b0;
end
else if(ex1_op0_is_qnan && cp0_fpu_xx_dqnan)
begin
  ex1_result_qnan_op0  = ex1_result_qnan && !ex1_op0_cnan;
  ex1_result_qnan_op1  = 1'b0;
  ex1_result_cnan      = ex1_result_qnan &&  ex1_op0_cnan;
end
else if(ex1_op1_is_qnan && cp0_fpu_xx_dqnan)
begin
  ex1_result_qnan_op0  = 1'b0;
  ex1_result_qnan_op1  = ex1_result_qnan && !ex1_op1_cnan;
  ex1_result_cnan      = ex1_result_qnan &&  ex1_op1_cnan;
end
else
begin
  ex1_result_qnan_op0  = 1'b0;
  ex1_result_qnan_op1  = 1'b0;
  ex1_result_cnan      = ex1_result_qnan;
end

end



assign ex1_srt_skip = ex1_result_zero ||
                      ex1_result_qnan ||
                      ex1_result_lfn  ||
                      ex1_result_inf;


assign ex1_fflags[4:0] = {ex1_nv, ex1_dz, 3'b0};


assign ex1_special_sel[7:0] = {1'b0, ex1_result_qnan_op1, ex1_result_qnan_op0,
                               ex1_result_cnan, ex1_result_lfn, ex1_result_inf,
                               ex1_result_zero, 1'b0};


assign ex1_special_sign[3:0] = {ex1_result_sign, ex1_result_sign, ex1_result_sign, 1'b0};




assign fdsu_fpu_ex1_fflags[4:0]       = ex1_fflags[4:0];
assign fdsu_fpu_ex1_special_sel[7:0]  = ex1_special_sel[7:0];
assign fdsu_fpu_ex1_special_sign[3:0] = ex1_special_sign[3:0];





endmodule



