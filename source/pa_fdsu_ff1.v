module pa_fdsu_ff1(
  fanc_shift_num,
  frac_bin_val,
  frac_num
);


input   [51:0]  frac_num;
output  [51:0]  fanc_shift_num;
output  [12:0]  frac_bin_val;


reg     [51:0]  fanc_shift_num;
reg     [12:0]  frac_bin_val;


wire    [51:0]  frac_num;



always @( frac_num[51:0])
begin
casez(frac_num[51:0])
  52'b1???????????????????????????????????????????????????: frac_bin_val[12:0] = 13'h0;
  52'b01??????????????????????????????????????????????????: frac_bin_val[12:0] = 13'h1fff;
  52'b001?????????????????????????????????????????????????: frac_bin_val[12:0] = 13'h1ffe;
  52'b0001????????????????????????????????????????????????: frac_bin_val[12:0] = 13'h1ffd;
  52'b00001???????????????????????????????????????????????: frac_bin_val[12:0] = 13'h1ffc;
  52'b000001??????????????????????????????????????????????: frac_bin_val[12:0] = 13'h1ffb;
  52'b0000001?????????????????????????????????????????????: frac_bin_val[12:0] = 13'h1ffa;
  52'b00000001????????????????????????????????????????????: frac_bin_val[12:0] = 13'h1ff9;
  52'b000000001???????????????????????????????????????????: frac_bin_val[12:0] = 13'h1ff8;
  52'b0000000001??????????????????????????????????????????: frac_bin_val[12:0] = 13'h1ff7;
  52'b00000000001?????????????????????????????????????????: frac_bin_val[12:0] = 13'h1ff6;
  52'b000000000001????????????????????????????????????????: frac_bin_val[12:0] = 13'h1ff5;
  52'b0000000000001???????????????????????????????????????: frac_bin_val[12:0] = 13'h1ff4;
  52'b00000000000001??????????????????????????????????????: frac_bin_val[12:0] = 13'h1ff3;
  52'b000000000000001?????????????????????????????????????: frac_bin_val[12:0] = 13'h1ff2;
  52'b0000000000000001????????????????????????????????????: frac_bin_val[12:0] = 13'h1ff1;
  52'b00000000000000001???????????????????????????????????: frac_bin_val[12:0] = 13'h1ff0;
  52'b000000000000000001??????????????????????????????????: frac_bin_val[12:0] = 13'h1fef;
  52'b0000000000000000001?????????????????????????????????: frac_bin_val[12:0] = 13'h1fee;
  52'b00000000000000000001????????????????????????????????: frac_bin_val[12:0] = 13'h1fed;
  52'b000000000000000000001???????????????????????????????: frac_bin_val[12:0] = 13'h1fec;
  52'b0000000000000000000001??????????????????????????????: frac_bin_val[12:0] = 13'h1feb;
  52'b00000000000000000000001?????????????????????????????: frac_bin_val[12:0] = 13'h1fea;
  52'b000000000000000000000001????????????????????????????: frac_bin_val[12:0] = 13'h1fe9;
  52'b0000000000000000000000001???????????????????????????: frac_bin_val[12:0] = 13'h1fe8;
  52'b00000000000000000000000001??????????????????????????: frac_bin_val[12:0] = 13'h1fe7;
  52'b000000000000000000000000001?????????????????????????: frac_bin_val[12:0] = 13'h1fe6;
  52'b0000000000000000000000000001????????????????????????: frac_bin_val[12:0] = 13'h1fe5;
  52'b00000000000000000000000000001???????????????????????: frac_bin_val[12:0] = 13'h1fe4;
  52'b000000000000000000000000000001??????????????????????: frac_bin_val[12:0] = 13'h1fe3;
  52'b0000000000000000000000000000001?????????????????????: frac_bin_val[12:0] = 13'h1fe2;
  52'b00000000000000000000000000000001????????????????????: frac_bin_val[12:0] = 13'h1fe1;
  52'b000000000000000000000000000000001???????????????????: frac_bin_val[12:0] = 13'h1fe0;
  52'b0000000000000000000000000000000001??????????????????: frac_bin_val[12:0] = 13'h1fdf;
  52'b00000000000000000000000000000000001?????????????????: frac_bin_val[12:0] = 13'h1fde;
  52'b000000000000000000000000000000000001????????????????: frac_bin_val[12:0] = 13'h1fdd;
  52'b0000000000000000000000000000000000001???????????????: frac_bin_val[12:0] = 13'h1fdc;
  52'b00000000000000000000000000000000000001??????????????: frac_bin_val[12:0] = 13'h1fdb;
  52'b000000000000000000000000000000000000001?????????????: frac_bin_val[12:0] = 13'h1fda;
  52'b0000000000000000000000000000000000000001????????????: frac_bin_val[12:0] = 13'h1fd9;
  52'b00000000000000000000000000000000000000001???????????: frac_bin_val[12:0] = 13'h1fd8;
  52'b000000000000000000000000000000000000000001??????????: frac_bin_val[12:0] = 13'h1fd7;
  52'b0000000000000000000000000000000000000000001?????????: frac_bin_val[12:0] = 13'h1fd6;
  52'b00000000000000000000000000000000000000000001????????: frac_bin_val[12:0] = 13'h1fd5;
  52'b000000000000000000000000000000000000000000001???????: frac_bin_val[12:0] = 13'h1fd4;
  52'b0000000000000000000000000000000000000000000001??????: frac_bin_val[12:0] = 13'h1fd3;
  52'b00000000000000000000000000000000000000000000001?????: frac_bin_val[12:0] = 13'h1fd2;
  52'b000000000000000000000000000000000000000000000001????: frac_bin_val[12:0] = 13'h1fd1;
  52'b0000000000000000000000000000000000000000000000001???: frac_bin_val[12:0] = 13'h1fd0;
  52'b00000000000000000000000000000000000000000000000001??: frac_bin_val[12:0] = 13'h1fcf;
  52'b000000000000000000000000000000000000000000000000001?: frac_bin_val[12:0] = 13'h1fce;
  52'b0000000000000000000000000000000000000000000000000001: frac_bin_val[12:0] = 13'h1fcd;
  52'b0000000000000000000000000000000000000000000000000000: frac_bin_val[12:0] = 13'h1fcc;
  default                                                 : frac_bin_val[12:0] = 13'h000;
endcase

end


always @( frac_num[51:0])
begin
casez(frac_num[51:0])
  52'b1???????????????????????????????????????????????????: fanc_shift_num[51:0] = frac_num[51:0];
  52'b01??????????????????????????????????????????????????: fanc_shift_num[51:0] = {frac_num[50:0],1'b0};
  52'b001?????????????????????????????????????????????????: fanc_shift_num[51:0] = {frac_num[49:0],2'b0};
  52'b0001????????????????????????????????????????????????: fanc_shift_num[51:0] = {frac_num[48:0],3'b0};
  52'b00001???????????????????????????????????????????????: fanc_shift_num[51:0] = {frac_num[47:0],4'b0};
  52'b000001??????????????????????????????????????????????: fanc_shift_num[51:0] = {frac_num[46:0],5'b0};
  52'b0000001?????????????????????????????????????????????: fanc_shift_num[51:0] = {frac_num[45:0],6'b0};
  52'b00000001????????????????????????????????????????????: fanc_shift_num[51:0] = {frac_num[44:0],7'b0};
  52'b000000001???????????????????????????????????????????: fanc_shift_num[51:0] = {frac_num[43:0],8'b0};
  52'b0000000001??????????????????????????????????????????: fanc_shift_num[51:0] = {frac_num[42:0],9'b0};
  52'b00000000001?????????????????????????????????????????: fanc_shift_num[51:0] = {frac_num[41:0],10'b0};
  52'b000000000001????????????????????????????????????????: fanc_shift_num[51:0] = {frac_num[40:0],11'b0};
  52'b0000000000001???????????????????????????????????????: fanc_shift_num[51:0] = {frac_num[39:0],12'b0};
  52'b00000000000001??????????????????????????????????????: fanc_shift_num[51:0] = {frac_num[38:0],13'b0};
  52'b000000000000001?????????????????????????????????????: fanc_shift_num[51:0] = {frac_num[37:0],14'b0};
  52'b0000000000000001????????????????????????????????????: fanc_shift_num[51:0] = {frac_num[36:0],15'b0};
  52'b00000000000000001???????????????????????????????????: fanc_shift_num[51:0] = {frac_num[35:0],16'b0};
  52'b000000000000000001??????????????????????????????????: fanc_shift_num[51:0] = {frac_num[34:0],17'b0};
  52'b0000000000000000001?????????????????????????????????: fanc_shift_num[51:0] = {frac_num[33:0],18'b0};
  52'b00000000000000000001????????????????????????????????: fanc_shift_num[51:0] = {frac_num[32:0],19'b0};
  52'b000000000000000000001???????????????????????????????: fanc_shift_num[51:0] = {frac_num[31:0],20'b0};
  52'b0000000000000000000001??????????????????????????????: fanc_shift_num[51:0] = {frac_num[30:0],21'b0};
  52'b00000000000000000000001?????????????????????????????: fanc_shift_num[51:0] = {frac_num[29:0],22'b0};
  52'b000000000000000000000001????????????????????????????: fanc_shift_num[51:0] = {frac_num[28:0],23'b0};
  52'b0000000000000000000000001???????????????????????????: fanc_shift_num[51:0] = {frac_num[27:0],24'b0};
  52'b00000000000000000000000001??????????????????????????: fanc_shift_num[51:0] = {frac_num[26:0],25'b0};
  52'b000000000000000000000000001?????????????????????????: fanc_shift_num[51:0] = {frac_num[25:0],26'b0};
  52'b0000000000000000000000000001????????????????????????: fanc_shift_num[51:0] = {frac_num[24:0],27'b0};
  52'b00000000000000000000000000001???????????????????????: fanc_shift_num[51:0] = {frac_num[23:0],28'b0};
  52'b000000000000000000000000000001??????????????????????: fanc_shift_num[51:0] = {frac_num[22:0],29'b0};
  52'b0000000000000000000000000000001?????????????????????: fanc_shift_num[51:0] = {frac_num[21:0],30'b0};
  52'b00000000000000000000000000000001????????????????????: fanc_shift_num[51:0] = {frac_num[20:0],31'b0};
  52'b000000000000000000000000000000001???????????????????: fanc_shift_num[51:0] = {frac_num[19:0],32'b0};
  52'b0000000000000000000000000000000001??????????????????: fanc_shift_num[51:0] = {frac_num[18:0],33'b0};
  52'b00000000000000000000000000000000001?????????????????: fanc_shift_num[51:0] = {frac_num[17:0],34'b0};
  52'b000000000000000000000000000000000001????????????????: fanc_shift_num[51:0] = {frac_num[16:0],35'b0};
  52'b0000000000000000000000000000000000001???????????????: fanc_shift_num[51:0] = {frac_num[15:0],36'b0};
  52'b00000000000000000000000000000000000001??????????????: fanc_shift_num[51:0] = {frac_num[14:0],37'b0};
  52'b000000000000000000000000000000000000001?????????????: fanc_shift_num[51:0] = {frac_num[13:0],38'b0};
  52'b0000000000000000000000000000000000000001????????????: fanc_shift_num[51:0] = {frac_num[12:0],39'b0};
  52'b00000000000000000000000000000000000000001???????????: fanc_shift_num[51:0] = {frac_num[11:0],40'b0};
  52'b000000000000000000000000000000000000000001??????????: fanc_shift_num[51:0] = {frac_num[10:0],41'b0};
  52'b0000000000000000000000000000000000000000001?????????: fanc_shift_num[51:0] = {frac_num[9:0],42'b0};
  52'b00000000000000000000000000000000000000000001????????: fanc_shift_num[51:0] = {frac_num[8:0],43'b0};
  52'b000000000000000000000000000000000000000000001???????: fanc_shift_num[51:0] = {frac_num[7:0],44'b0};
  52'b0000000000000000000000000000000000000000000001??????: fanc_shift_num[51:0] = {frac_num[6:0],45'b0};
  52'b00000000000000000000000000000000000000000000001?????: fanc_shift_num[51:0] = {frac_num[5:0],46'b0};
  52'b000000000000000000000000000000000000000000000001????: fanc_shift_num[51:0] = {frac_num[4:0],47'b0};
  52'b0000000000000000000000000000000000000000000000001???: fanc_shift_num[51:0] = {frac_num[3:0],48'b0};
  52'b00000000000000000000000000000000000000000000000001??: fanc_shift_num[51:0] = {frac_num[2:0],49'b0};
  52'b000000000000000000000000000000000000000000000000001?: fanc_shift_num[51:0] = {frac_num[1:0],50'b0};
  52'b0000000000000000000000000000000000000000000000000001: fanc_shift_num[51:0] = {frac_num[0:0],51'b0};
  52'b0000000000000000000000000000000000000000000000000000: fanc_shift_num[51:0] = {52'b0};
  default                                                 : fanc_shift_num[51:0] = {52'b0};
endcase

end


endmodule


