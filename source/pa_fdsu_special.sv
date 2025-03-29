// Module to handle special cases in the FDSU (Floating-Point Dataflow Special Unit)
module pa_fdsu_special (
    cp0_fpu_xx_dqnan,  // Input: CP0 double/single NaN enable
    dp_xx_ex1_cnan,  // Input: Canonical NaN flags from EX1
    dp_xx_ex1_id,  // Input: Operand ID flags from EX1
    dp_xx_ex1_inf,  // Input: Infinity flags from EX1
    dp_xx_ex1_qnan,  // Input: Quiet NaN flags from EX1
    dp_xx_ex1_snan,  // Input: Signaling NaN flags from EX1
    dp_xx_ex1_zero,  // Input: Zero flags from EX1
    ex1_div,  // Input: Division operation enable
    ex1_op0_id,  // Output: Operand 0 ID flag
    ex1_op0_norm,  // Output: Operand 0 is normalized
    ex1_op0_sign,  // Input: Operand 0 sign
    ex1_op1_id,  // Output: Operand 1 ID flag
    ex1_op1_norm,  // Output: Operand 1 is normalized
    ex1_result_sign,  // Input: Result sign from EX1
    ex1_sqrt,  // Input: Square root operation enable
    ex1_srt_skip,  // Output: Skip SRT division/sqrt
    fdsu_fpu_ex1_fflags,  // Output: FPU exception flags to EX1
    fdsu_fpu_ex1_special_sel,  // Output: Special case selection to EX1
    fdsu_fpu_ex1_special_sign  // Output: Special case sign to EX1
);

  input cp0_fpu_xx_dqnan;  // Input: Double/Single NaN mode from CP0
  input [2:0] dp_xx_ex1_cnan;  // Input: Canonical NaN status from EX1
  input [2:0] dp_xx_ex1_id;  // Input: Operand IDs from EX1
  input [2:0] dp_xx_ex1_inf;  // Input: Infinity status from EX1
  input [2:0] dp_xx_ex1_qnan;  // Input: Quiet NaN status from EX1
  input [2:0] dp_xx_ex1_snan;  // Input: Signaling NaN status from EX1
  input [2:0] dp_xx_ex1_zero;  // Input: Zero status from EX1
  input ex1_div;  // Input: Division operation is active
  input ex1_op0_sign;  // Input: Sign of operand 0
  input ex1_result_sign;  // Input: Sign of the result
  input ex1_sqrt;  // Input: Square root operation is active
  output ex1_op0_id;  // Output: ID of operand 0
  output ex1_op0_norm;  // Output: Operand 0 is normalized
  output ex1_op1_id;  // Output: ID of operand 1
  output ex1_op1_norm;  // Output: Operand 1 is normalized
  output ex1_srt_skip;  // Output: Signal to skip SRT algorithm
  output [4:0] fdsu_fpu_ex1_fflags;  // Output: FPU exception flags
  output [7:0] fdsu_fpu_ex1_special_sel;  // Output: Special selection signals
  output [3:0] fdsu_fpu_ex1_special_sign;  // Output: Special sign signals

  reg        ex1_result_cnan;  // Register for canonical NaN result
  reg        ex1_result_qnan_op0;  // Register for quiet NaN result (op0)
  reg        ex1_result_qnan_op1;  // Register for quiet NaN result (op1)

  wire       cp0_fpu_xx_dqnan;  // Wire for CP0 double/single NaN enable
  wire [2:0] dp_xx_ex1_cnan;  // Wire for canonical NaN flags
  wire [2:0] dp_xx_ex1_id;  // Wire for operand ID flags
  wire [2:0] dp_xx_ex1_inf;  // Wire for infinity flags
  wire [2:0] dp_xx_ex1_qnan;  // Wire for quiet NaN flags
  wire [2:0] dp_xx_ex1_snan;  // Wire for signaling NaN flags
  wire [2:0] dp_xx_ex1_zero;  // Wire for zero flags
  wire       ex1_div;  // Wire for division enable
  wire       ex1_div_dz;  // Wire for division by zero condition
  wire       ex1_div_nv;  // Wire for division invalid operation
  wire       ex1_div_rst_inf;  // Wire for division result infinity
  wire       ex1_div_rst_qnan;  // Wire for division result quiet NaN
  wire       ex1_div_rst_zero;  // Wire for division result zero
  wire       ex1_dz;  // Wire for division by zero exception
  wire [4:0] ex1_fflags;  // Wire for FPU exception flags
  wire       ex1_nv;  // Wire for invalid operation exception
  wire       ex1_op0_cnan;  // Wire for operand 0 canonical NaN
  wire       ex1_op0_id;  // Wire for operand 0 ID
  wire       ex1_op0_inf;  // Wire for operand 0 infinity
  wire       ex1_op0_is_qnan;  // Wire for operand 0 is quiet NaN
  wire       ex1_op0_is_snan;  // Wire for operand 0 is signaling NaN
  wire       ex1_op0_norm;  // Wire for operand 0 normalized
  wire       ex1_op0_qnan;  // Wire for operand 0 quiet NaN
  wire       ex1_op0_sign;  // Wire for operand 0 sign
  wire       ex1_op0_snan;  // Wire for operand 0 signaling NaN
  wire       ex1_op0_tt_zero;  // Wire for operand 0 treated as zero
  wire       ex1_op0_zero;  // Wire for operand 0 zero
  wire       ex1_op1_cnan;  // Wire for operand 1 canonical NaN
  wire       ex1_op1_id;  // Wire for operand 1 ID
  wire       ex1_op1_inf;  // Wire for operand 1 infinity
  wire       ex1_op1_is_qnan;  // Wire for operand 1 is quiet NaN
  wire       ex1_op1_is_snan;  // Wire for operand 1 is signaling NaN
  wire       ex1_op1_norm;  // Wire for operand 1 normalized
  wire       ex1_op1_qnan;  // Wire for operand 1 quiet NaN
  wire       ex1_op1_snan;  // Wire for operand 1 signaling NaN
  wire       ex1_op1_tt_zero;  // Wire for operand 1 treated as zero
  wire       ex1_op1_zero;  // Wire for operand 1 zero
  wire       ex1_result_inf;  // Wire for result infinity
  wire       ex1_result_lfn;  // Wire for result large finite number
  wire       ex1_result_qnan;  // Wire for result quiet NaN
  wire       ex1_result_sign;  // Wire for result sign
  wire       ex1_result_zero;  // Wire for result zero
  wire       ex1_rst_default_qnan;  // Wire for default quiet NaN result
  wire [7:0] ex1_special_sel;  // Wire for special selection signals
  wire [3:0] ex1_special_sign;  // Wire for special sign signals
  wire       ex1_sqrt;  // Wire for square root enable
  wire       ex1_sqrt_nv;  // Wire for square root invalid operation
  wire       ex1_sqrt_rst_inf;  // Wire for square root result infinity
  wire       ex1_sqrt_rst_qnan;  // Wire for square root result quiet NaN
  wire       ex1_sqrt_rst_zero;  // Wire for square root result zero
  wire       ex1_srt_skip;  // Wire to skip SRT algorithm
  wire [4:0] fdsu_fpu_ex1_fflags;  // Wire for FPU exception flags
  wire [7:0] fdsu_fpu_ex1_special_sel;  // Wire for special selection signals
  wire [3:0] fdsu_fpu_ex1_special_sign;  // Wire for special sign signals

  // Assign operand infinity flags
  assign ex1_op0_inf = dp_xx_ex1_inf[0];
  assign ex1_op1_inf = dp_xx_ex1_inf[1];

  // Assign operand zero flags
  assign ex1_op0_zero = dp_xx_ex1_zero[0];
  assign ex1_op1_zero = dp_xx_ex1_zero[1];

  // Assign operand ID flags
  assign ex1_op0_id = dp_xx_ex1_id[0];
  assign ex1_op1_id = dp_xx_ex1_id[1];

  // Assign operand canonical NaN flags
  assign ex1_op0_cnan = dp_xx_ex1_cnan[0];
  assign ex1_op1_cnan = dp_xx_ex1_cnan[1];

  // Assign operand signaling NaN flags
  assign ex1_op0_snan = dp_xx_ex1_snan[0];
  assign ex1_op1_snan = dp_xx_ex1_snan[1];

  // Assign operand quiet NaN flags
  assign ex1_op0_qnan = dp_xx_ex1_qnan[0];
  assign ex1_op1_qnan = dp_xx_ex1_qnan[1];

  // Determine invalid operation exception
  assign ex1_nv = ex1_div && ex1_div_nv || ex1_sqrt && ex1_sqrt_nv;

  // Condition for division invalid operation
  assign ex1_div_nv      = ex1_op0_snan ||
                         ex1_op1_snan ||
                         (ex1_op0_tt_zero && ex1_op1_tt_zero)||
                         (ex1_op0_inf && ex1_op1_inf);
  assign ex1_op0_tt_zero = ex1_op0_zero;  // Treat operand 0 zero as true zero
  assign ex1_op1_tt_zero = ex1_op1_zero;  // Treat operand 1 zero as true zero

  // Condition for square root invalid operation
  assign ex1_sqrt_nv = ex1_op0_snan || ex1_op0_sign && (ex1_op0_norm || ex1_op0_inf);

  // Determine if operand is normalized
  assign ex1_op0_norm    = !ex1_op0_inf && !ex1_op0_zero && !ex1_op0_snan &&
                         !ex1_op0_qnan && !ex1_op0_cnan;
  assign ex1_op1_norm    = !ex1_op1_inf && !ex1_op1_zero && !ex1_op1_snan &&
                         !ex1_op1_qnan && !ex1_op1_cnan;

  // Determine division by zero exception
  assign ex1_dz = ex1_div && ex1_div_dz;
  assign ex1_div_dz = ex1_op1_tt_zero && ex1_op0_norm;

  // Determine result zero
  assign ex1_result_zero = ex1_div_rst_zero && ex1_div || ex1_sqrt_rst_zero && ex1_sqrt;
  assign ex1_div_rst_zero= (ex1_op0_tt_zero && ex1_op1_norm ) ||
                         (!ex1_op0_inf && !ex1_op0_qnan && !ex1_op0_snan &&
                          !ex1_op0_cnan && ex1_op1_inf);
  assign ex1_sqrt_rst_zero = ex1_op0_tt_zero;

  // Determine result quiet NaN
  assign ex1_result_qnan = ex1_div_rst_qnan && ex1_div || ex1_sqrt_rst_qnan && ex1_sqrt || ex1_nv;
  assign ex1_div_rst_qnan = ex1_op0_qnan || ex1_op1_qnan;
  assign ex1_sqrt_rst_qnan = ex1_op0_qnan;

  // Determine default quiet NaN result
  assign ex1_rst_default_qnan = (ex1_div && ex1_op0_zero && ex1_op1_zero) ||
                               (ex1_div && ex1_op0_inf  && ex1_op1_inf)  ||
                               (ex1_sqrt&& ex1_op0_sign && (ex1_op0_norm || ex1_op0_inf));

  // Determine result infinity
  assign ex1_result_inf = ex1_div_rst_inf && ex1_div || ex1_sqrt_rst_inf && ex1_sqrt || ex1_dz;

  assign ex1_div_rst_inf = ex1_op0_inf && !ex1_op1_inf && !ex1_op1_qnan &&
                         !ex1_op1_snan && !ex1_op1_cnan;
  assign ex1_sqrt_rst_inf = ex1_op0_inf && !ex1_op0_sign;

  // Result is never large finite number in these special cases
  assign ex1_result_lfn = 1'b0;

  // Determine if operand is signaling or quiet NaN
  assign ex1_op0_is_snan = ex1_op0_snan;
  assign ex1_op1_is_snan = ex1_op1_snan && ex1_div;
  assign ex1_op0_is_qnan = ex1_op0_qnan;
  assign ex1_op1_is_qnan = ex1_op1_qnan && ex1_div;

  // Determine the type of NaN result based on operand types and CP0 setting
  always @( ex1_op0_is_snan or ex1_op0_cnan or ex1_result_qnan or
          ex1_op0_is_qnan or ex1_rst_default_qnan or cp0_fpu_xx_dqnan or
          ex1_op1_cnan or ex1_op1_is_qnan or ex1_op1_is_snan)
begin
    if (ex1_rst_default_qnan) begin
      ex1_result_qnan_op0 = 1'b0;
      ex1_result_qnan_op1 = 1'b0;
      ex1_result_cnan = ex1_result_qnan;
    end else if (ex1_op0_is_snan && cp0_fpu_xx_dqnan) begin
      ex1_result_qnan_op0 = ex1_result_qnan;
      ex1_result_qnan_op1 = 1'b0;
      ex1_result_cnan = 1'b0;
    end else if (ex1_op1_is_snan && cp0_fpu_xx_dqnan) begin
      ex1_result_qnan_op0 = 1'b0;
      ex1_result_qnan_op1 = ex1_result_qnan;
      ex1_result_cnan = 1'b0;
    end else if (ex1_op0_is_qnan && cp0_fpu_xx_dqnan) begin
      ex1_result_qnan_op0 = ex1_result_qnan && !ex1_op0_cnan;
      ex1_result_qnan_op1 = 1'b0;
      ex1_result_cnan = ex1_result_qnan && ex1_op0_cnan;
    end else if (ex1_op1_is_qnan && cp0_fpu_xx_dqnan) begin
      ex1_result_qnan_op0 = 1'b0;
      ex1_result_qnan_op1 = ex1_result_qnan && !ex1_op1_cnan;
      ex1_result_cnan = ex1_result_qnan && ex1_op1_cnan;
    end else begin
      ex1_result_qnan_op0 = 1'b0;
      ex1_result_qnan_op1 = 1'b0;
      ex1_result_cnan = ex1_result_qnan;
    end
  end

  // Determine if SRT algorithm should be skipped
  assign ex1_srt_skip = ex1_result_zero || ex1_result_qnan || ex1_result_lfn || ex1_result_inf;

  // Combine exception flags
  assign ex1_fflags[4:0] = {ex1_nv, ex1_dz, 3'b0};

  // Select special case result type
  assign ex1_special_sel[7:0] = {
    1'b0,
    ex1_result_qnan_op1,
    ex1_result_qnan_op0,
    ex1_result_cnan,
    ex1_result_lfn,
    ex1_result_inf,
    ex1_result_zero,
    1'b0
  };

  // Determine special case result sign
  assign ex1_special_sign[3:0] = {ex1_result_sign, ex1_result_sign, ex1_result_sign, 1'b0};

  // Output the calculated flags and special selections
  assign fdsu_fpu_ex1_fflags[4:0] = ex1_fflags[4:0];
  assign fdsu_fpu_ex1_special_sel[7:0] = ex1_special_sel[7:0];
  assign fdsu_fpu_ex1_special_sign[3:0] = ex1_special_sign[3:0];

endmodule
