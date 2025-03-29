// Module to prepare operands for FD/SQRT operations in EX1 stage
module pa_fdsu_prepare (
    dp_xx_ex1_rm,  // Input: Rounding mode from previous stage
    ex1_div,  // Output: Flag indicating division operation
    ex1_divisor,  // Output: Divisor for division operation
    ex1_expnt_adder_op0,  // Output: Operand 0 for exponent adder
    ex1_expnt_adder_op1,  // Output: Operand 1 for exponent adder
    ex1_of_result_lfn,  // Output: Flag for overflow result LFN
    ex1_op0_id,  // Input: ID of operand 0
    ex1_op0_sign,  // Output: Sign of operand 0
    ex1_op1_id,  // Input: ID of operand 1
    ex1_op1_id_vld,  // Output: Valid flag for operand 1 ID
    ex1_op1_sel,  // Input: Select signal for operand 1
    ex1_oper_id_expnt,  // Output: Exponent of selected operand
    ex1_oper_id_expnt_f,  // Input: Fractional exponent of selected operand
    ex1_oper_id_frac,  // Output: Fraction of selected operand
    ex1_oper_id_frac_f,  // Input: Fractional part of selected operand
    ex1_remainder,  // Output: Remainder of division
    ex1_result_sign,  // Output: Sign of the result
    ex1_rm,  // Output: Rounding mode for EX1 stage
    ex1_sqrt,  // Output: Flag indicating square root operation
    fdsu_ex1_sel,  // Input: Select signal for FDSU EX1
    idu_fpu_ex1_func,  // Input: Function code for EX1
    idu_fpu_ex1_srcf0,  // Input: Source operand 0 from IDU
    idu_fpu_ex1_srcf1  // Input: Source operand 1 from IDU
);

  input [2 : 0] dp_xx_ex1_rm;  // Input: Rounding mode from DP
  input ex1_op0_id;  // Input: Operand 0 ID
  input ex1_op1_id;  // Input: Operand 1 ID
  input ex1_op1_sel;  // Input: Operand 1 select
  input [12:0] ex1_oper_id_expnt_f;  // Input: Fractional exponent
  input [51:0] ex1_oper_id_frac_f;  // Input: Fractional part
  input fdsu_ex1_sel;  // Input: FDSU EX1 select
  input [9 : 0] idu_fpu_ex1_func;  // Input: FPU function code
  input [31:0] idu_fpu_ex1_srcf0;  // Input: Source operand 0
  input [31:0] idu_fpu_ex1_srcf1;  // Input: Source operand 1
  output ex1_div;  // Output: Division flag
  output [23:0] ex1_divisor;  // Output: Divisor
  output [12:0] ex1_expnt_adder_op0;  // Output: Exponent adder operand 0
  output [12:0] ex1_expnt_adder_op1;  // Output: Exponent adder operand 1
  output ex1_of_result_lfn;  // Output: Overflow LFN flag
  output ex1_op0_sign;  // Output: Operand 0 sign
  output ex1_op1_id_vld;  // Output: Operand 1 ID valid
  output [12:0] ex1_oper_id_expnt;  // Output: Selected operand exponent
  output [51:0] ex1_oper_id_frac;  // Output: Selected operand fraction
  output [31:0] ex1_remainder;  // Output: Remainder
  output ex1_result_sign;  // Output: Result sign
  output [2 : 0] ex1_rm;  // Output: Rounding mode
  output ex1_sqrt;  // Output: Square root flag

  reg  [ 12:0] ex1_expnt_adder_op1;  // Register for exponent adder operand 1
  reg          ex1_of_result_lfn;  // Register for overflow LFN flag

  wire         div_sign;  // Wire for division sign
  wire [2 : 0] dp_xx_ex1_rm;  // Wire for rounding mode from DP
  wire         ex1_div;  // Wire for division flag
  wire [ 52:0] ex1_div_noid_nor_srt_op0;  // Wire for div op0 without ID, normalized, shifted
  wire [ 52:0] ex1_div_noid_nor_srt_op1;  // Wire for div op1 without ID, normalized, shifted
  wire [ 52:0] ex1_div_nor_srt_op0;  // Wire for div op0 normalized and shifted
  wire [ 52:0] ex1_div_nor_srt_op1;  // Wire for div op1 normalized and shifted
  wire [ 12:0] ex1_div_op0_expnt;  // Wire for division operand 0 exponent
  wire [ 12:0] ex1_div_op1_expnt;  // Wire for division operand 1 exponent
  wire [ 52:0] ex1_div_srt_op0;  // Wire for division operand 0 shifted
  wire [ 52:0] ex1_div_srt_op1;  // Wire for division operand 1 shifted
  wire [ 23:0] ex1_divisor;  // Wire for divisor
  wire         ex1_double;  // Wire for double-precision flag
  wire [ 12:0] ex1_expnt_adder_op0;  // Wire for exponent adder operand 0
  wire         ex1_op0_id;  // Wire for operand 0 ID
  wire         ex1_op0_id_nor;  // Wire for normalized operand 0 ID
  wire         ex1_op0_sign;  // Wire for operand 0 sign
  wire         ex1_op1_id;  // Wire for operand 1 ID
  wire         ex1_op1_id_nor;  // Wire for normalized operand 1 ID
  wire         ex1_op1_id_vld;  // Wire for operand 1 ID valid
  wire         ex1_op1_sel;  // Wire for operand 1 select
  wire         ex1_op1_sign;  // Wire for operand 1 sign
  wire [ 63:0] ex1_oper0;  // Wire for operand 0
  wire [ 51:0] ex1_oper0_frac;  // Wire for operand 0 fraction
  wire [ 12:0] ex1_oper0_id_expnt;  // Wire for operand 0 ID exponent
  wire [ 51:0] ex1_oper0_id_frac;  // Wire for operand 0 ID fraction
  wire [ 63:0] ex1_oper1;  // Wire for operand 1
  wire [ 51:0] ex1_oper1_frac;  // Wire for operand 1 fraction
  wire [ 12:0] ex1_oper1_id_expnt;  // Wire for operand 1 ID exponent
  wire [ 51:0] ex1_oper1_id_frac;  // Wire for operand 1 ID fraction
  wire [ 51:0] ex1_oper_frac;  // Wire for selected operand fraction
  wire [ 12:0] ex1_oper_id_expnt;  // Wire for selected operand exponent
  wire [ 12:0] ex1_oper_id_expnt_f;  // Wire for fractional exponent
  wire [ 51:0] ex1_oper_id_frac;  // Wire for selected operand fraction
  wire [ 51:0] ex1_oper_id_frac_f;  // Wire for fractional part
  wire [ 31:0] ex1_remainder;  // Wire for remainder
  wire         ex1_result_sign;  // Wire for result sign
  wire [2 : 0] ex1_rm;  // Wire for rounding mode
  wire         ex1_single;  // Wire for single-precision flag
  wire         ex1_sqrt;  // Wire for square root flag
  wire         ex1_sqrt_expnt_odd;  // Wire for sqrt exponent odd flag
  wire         ex1_sqrt_op0_expnt_0;  // Wire for sqrt op0 exponent bit 0
  wire [ 12:0] ex1_sqrt_op1_expnt;  // Wire for sqrt operand 1 exponent
  wire [ 52:0] ex1_sqrt_srt_op0;  // Wire for sqrt operand 0 shifted
  wire         fdsu_ex1_sel;  // Wire for FDSU EX1 select
  wire [9 : 0] idu_fpu_ex1_func;  // Wire for FPU function code
  wire [ 31:0] idu_fpu_ex1_srcf0;  // Wire for source operand 0
  wire [ 31:0] idu_fpu_ex1_srcf1;  // Wire for source operand 1
  wire [ 59:0] sqrt_remainder;  // Wire for square root remainder
  wire         sqrt_sign;  // Wire for square root sign

  assign ex1_sqrt            = idu_fpu_ex1_func[0];  // Assign sqrt flag
  assign ex1_div             = idu_fpu_ex1_func[1];  // Assign division flag
  // Select source operand 0 based on fdsu_ex1_sel
  assign ex1_oper0[63:0]     = {32'b0, idu_fpu_ex1_srcf0 & {32{fdsu_ex1_sel}}};
  // Select source operand 1 based on fdsu_ex1_sel
  assign ex1_oper1[63:0]     = {32'b0, idu_fpu_ex1_srcf1 & {32{fdsu_ex1_sel}}};
  assign ex1_double          = 1'b0;  // Double-precision flag (fixed to 0)
  assign ex1_single          = 1'b1;  // Single-precision flag (fixed to 1)

  assign ex1_op0_id_nor      = ex1_op0_id;  // Assign operand 0 ID
  assign ex1_op1_id_nor      = ex1_op1_id;  // Assign operand 1 ID

  // Determine the sign of operand 0 based on precision
  assign ex1_op0_sign        = ex1_double && ex1_oper0[63] || ex1_single && ex1_oper0[31];
  // Determine the sign of operand 1 based on precision
  assign ex1_op1_sign        = ex1_double && ex1_oper1[63] || ex1_single && ex1_oper1[31];
  assign div_sign            = ex1_op0_sign ^ ex1_op1_sign;  // Calculate division sign
  assign sqrt_sign           = ex1_op0_sign;  // Square root sign is same as operand 0
  // Determine the result sign based on operation
  assign ex1_result_sign     = (ex1_div) ? div_sign : sqrt_sign;

  // Select the operand fraction based on ex1_op1_sel
  assign ex1_oper_frac[51:0] = ex1_op1_sel ? ex1_oper1_frac[51:0] : ex1_oper0_frac[51:0];

  // Instantiate the pa_fdsu_ff1 module to find first '1' and shift
  pa_fdsu_ff1 x_frac_expnt (
      .fanc_shift_num(ex1_oper_id_frac[51:0]),   // Output: Shifted fraction
      .frac_bin_val  (ex1_oper_id_expnt[12:0]),  // Output: Exponent
      .frac_num      (ex1_oper_frac[51:0])       // Input: Fraction
  );

  // Select exponent for operand 0 based on ex1_op1_sel
  assign ex1_oper0_id_expnt[12:0] = ex1_op1_sel ? ex1_oper_id_expnt_f[12:0]
                                                : ex1_oper_id_expnt[12:0];
  // Select fraction for operand 0 based on ex1_op1_sel
  assign ex1_oper0_id_frac[51:0] = ex1_op1_sel ? ex1_oper_id_frac_f[51:0] : ex1_oper_id_frac[51:0];
  assign ex1_oper1_id_expnt[12:0] = ex1_oper_id_expnt[12:0];  // Assign exponent for operand 1
  assign ex1_oper1_id_frac[51:0] = ex1_oper_id_frac[51:0];  // Assign fraction for operand 1

  // Extract fraction part of operand 0 based on precision
  assign ex1_oper0_frac[51:0] = {52{ex1_double}} & ex1_oper0[51:0] |
                              {52{ex1_single}} & {ex1_oper0[22:0],29'b0};
  // Extract fraction part of operand 1 based on precision
  assign ex1_oper1_frac[51:0] = {52{ex1_double}} & ex1_oper1[51:0] |
                              {52{ex1_single}} & {ex1_oper1[22:0],29'b0};

  // Extract exponent of operand 0 for division based on precision
  assign ex1_div_op0_expnt[12:0]  = {13{ex1_double}} & {2'b0,ex1_oper0[62:52]} |
                                  {13{ex1_single}} & {5'b0,ex1_oper0[30:23]};
  // Select exponent operand 0 for adder
  assign ex1_expnt_adder_op0[12:0] = ex1_op0_id_nor ? ex1_oper0_id_expnt[12:0]
                                                    : ex1_div_op0_expnt[12:0];

  // Extract exponent of operand 1 for division based on precision
  assign ex1_div_op1_expnt[12:0] = {13{ex1_double}} & {2'b0,ex1_oper1[62:52]} |
                                 {13{ex1_single}} & {5'b0,ex1_oper1[30:23]};
  // Define exponent for square root operation
  assign ex1_sqrt_op1_expnt[12:0] = {13{ex1_double}} & {3'b0,{10{1'b1}}} |
                                  {13{ex1_single}} & {6'b0,{7{1'b1}}};

  // Select exponent operand 1 for adder based on operation
  always @( ex1_oper1_id_expnt[12:0] or ex1_div or ex1_op1_id_nor or
          ex1_sqrt_op1_expnt[12:0] or ex1_sqrt or ex1_div_op1_expnt[12:0])
begin
    case ({
      ex1_div, ex1_sqrt
    })
      2'b10:
      ex1_expnt_adder_op1[12:0] = ex1_op1_id_nor ? ex1_oper1_id_expnt[12:0] :
                                         ex1_div_op1_expnt[12:0]; // For division
      2'b01: ex1_expnt_adder_op1[12:0] = ex1_sqrt_op1_expnt[12:0];  // For square root
      default: ex1_expnt_adder_op1[12:0] = 13'b0;  // Default case
    endcase
  end

  // Extract the least significant bit of exponent 0 for square root
  assign ex1_sqrt_op0_expnt_0 = ex1_op0_id_nor ? ex1_oper_id_expnt[0] : ex1_div_op0_expnt[0];

  // Determine if the exponent for square root is odd
  assign ex1_sqrt_expnt_odd   = !ex1_sqrt_op0_expnt_0;

  assign ex1_rm[2:0]          = dp_xx_ex1_rm[2:0];  // Pass through rounding mode

  // Determine overflow result LFN based on rounding mode and result sign
  always @(ex1_rm[2:0] or ex1_result_sign) begin
    case (ex1_rm[2:0])
      3'b000:  ex1_of_result_lfn = 1'b0;  // Round to nearest even
      3'b001:  ex1_of_result_lfn = 1'b1;  // Round towards positive
      3'b010:  ex1_of_result_lfn = !ex1_result_sign;  // Round towards negative
      3'b011:  ex1_of_result_lfn = ex1_result_sign;  // Round towards zero
      3'b100:  ex1_of_result_lfn = 1'b0;  // Round to nearest away from zero
      default: ex1_of_result_lfn = 1'b0;  // Default case
    endcase
  end

  // Select remainder based on operation
  assign ex1_remainder[31:0] = {32{ex1_div }} & {5'b0,ex1_div_srt_op0[52:28],2'b0} |
                               {32{ex1_sqrt}} & sqrt_remainder[59:28];

  assign ex1_divisor[23:0] = ex1_div_srt_op1[52:29];  // Extract divisor

  assign ex1_div_srt_op0[52:0] = ex1_div_nor_srt_op0[52:0];  // Assign shifted operand 0
  assign ex1_div_srt_op1[52:0] = ex1_div_nor_srt_op1[52:0];  // Assign shifted operand 1

  // Normalize and shift operand 0 for division (without ID)
  assign ex1_div_noid_nor_srt_op0[52:0] = {53{ex1_double}} & {1'b1,ex1_oper0[51:0]} |
                                         {53{ex1_single}} & {1'b1,ex1_oper0[22:0],29'b0};
  // Normalize and shift operand 0 for division (with ID)
  assign ex1_div_nor_srt_op0[52:0]    = ex1_op0_id_nor ? {ex1_oper0_id_frac[51:0],1'b0} :
                                         ex1_div_noid_nor_srt_op0[52:0];

  // Normalize and shift operand 1 for division (without ID)
  assign ex1_div_noid_nor_srt_op1[52:0] = {53{ex1_double}} & {1'b1,ex1_oper1[51:0]} |
                                         {53{ex1_single}} & {1'b1,ex1_oper1[22:0],29'b0};
  // Normalize and shift operand 1 for division (with ID)
  assign ex1_div_nor_srt_op1[52:0]    = ex1_op1_id_nor ? {ex1_oper1_id_frac[51:0],1'b0} :
                                         ex1_div_noid_nor_srt_op1[52:0];

  // Prepare remainder for square root based on exponent parity
  assign sqrt_remainder[59:0]       = (ex1_sqrt_expnt_odd) ? {5'b0,ex1_sqrt_srt_op0[52:0],2'b0} :
                                         {6'b0,ex1_sqrt_srt_op0[52:0],1'b0};

  assign ex1_sqrt_srt_op0[52:0] = ex1_div_srt_op0[52:0];  // Assign shifted operand 0 for sqrt

  assign ex1_op1_id_vld = ex1_op1_id_nor && ex1_div;  // Operand 1 ID is valid for division

endmodule
