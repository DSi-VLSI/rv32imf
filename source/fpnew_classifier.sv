module fpnew_classifier #(
    // Parameter for the floating-point format.
    parameter fpnew_pkg::fp_format_e FpFormat = fpnew_pkg::fp_format_e'(0),
    // Parameter for the number of operands.
    parameter int unsigned NumOperands = 1,

    // Local parameter for the width of the floating-point number.
    localparam int unsigned WIDTH = fpnew_pkg::fp_width(FpFormat)
) (
    // Input port for the operands.
    input logic [NumOperands-1:0][WIDTH-1:0] operands_i,
    // Input port indicating if the operand is a valid boxed value.
    input logic [NumOperands-1:0] is_boxed_i,
    // Output port providing classification information for each operand.
    output fpnew_pkg::fp_info_t [NumOperands-1:0] info_o
);

  // Local parameter for the number of exponent bits.
  localparam int unsigned ExpBits = fpnew_pkg::exp_bits(FpFormat);
  // Local parameter for the number of mantissa bits.
  localparam int unsigned ManBits = fpnew_pkg::man_bits(FpFormat);


  // Define a struct to represent the floating-point number format.
  typedef struct packed {
    logic sign;
    logic [ExpBits-1:0] exponent;
    logic [ManBits-1:0] mantissa;
  } fp_t;


  // Generate block to handle each operand.
  for (genvar op = 0; op < int'(NumOperands); op++) begin : gen_num_values

    // Declare a local variable to hold the current operand value.
    fp_t  value;
    // Declare a local variable to hold the boxed status of the operand.
    logic is_boxed;
    // Declare a local variable to indicate if the operand is normal.
    logic is_normal;
    // Declare a local variable to indicate if the operand is infinity.
    logic is_inf;
    // Declare a local variable to indicate if the operand is NaN.
    logic is_nan;
    // Declare a local variable to indicate if the operand is signalling NaN.
    logic is_signalling;
    // Declare a local variable to indicate if the operand is quiet NaN.
    logic is_quiet;
    // Declare a local variable to indicate if the operand is zero.
    logic is_zero;
    // Declare a local variable to indicate if the operand is subnormal.
    logic is_subnormal;




    // Combinational block to classify the input operand.
    always_comb begin : classify_input
      // Assign the current operand value.
      value = operands_i[op];
      // Assign the boxed status of the current operand.
      is_boxed = is_boxed_i[op];
      // Check if the operand is a normal number.
      is_normal = is_boxed && (value.exponent != '0) && (value.exponent != '1);
      // Check if the operand is zero.
      is_zero = is_boxed && (value.exponent == '0) && (value.mantissa == '0);
      // Check if the operand is a subnormal number.
      is_subnormal = is_boxed && (value.exponent == '0) && !is_zero;
      // Check if the operand is infinity.
      is_inf = is_boxed && ((value.exponent == '1) && (value.mantissa == '0));
      // Check if the operand is NaN.
      is_nan = !is_boxed || ((value.exponent == '1) && (value.mantissa != '0));
      // Check if the operand is a signalling NaN.
      is_signalling = is_boxed && is_nan && (value.mantissa[ManBits-1] == 1'b0);
      // Check if the operand is a quiet NaN.
      is_quiet = is_nan && !is_signalling;

      // Assign the classification information to the output port.
      info_o[op].is_normal = is_normal;
      info_o[op].is_subnormal = is_subnormal;
      info_o[op].is_zero = is_zero;
      info_o[op].is_inf = is_inf;
      info_o[op].is_nan = is_nan;
      info_o[op].is_signalling = is_signalling;
      info_o[op].is_quiet = is_quiet;
      info_o[op].is_boxed = is_boxed;
    end
  end
endmodule
