// Module to determine the type of a floating-point source operand
module pa_fpu_src_type (
    inst_double,  // Input: Indicates if the instruction is for double precision
    inst_single,  // Input: Indicates if the instruction is for single precision
    src_cnan,  // Output: Indicates if the source is a canonical NaN (single)
    src_id,  // Output: Indicates if the source is an invalid number (single/double)
    src_in,  // Input: The 64-bit source operand
    src_inf,  // Output: Indicates if the source is infinity (single/double)
    src_norm,  // Output: Indicates if the source is a normal number (single/double)
    src_qnan,  // Output: Indicates if the source is a quiet NaN (single/double)
    src_snan,  // Output: Indicates if the source is a signaling NaN (single/double)
    src_zero  // Output: Indicates if the source is zero (single/double)
);

  input inst_double;  // Input: Double precision instruction
  input inst_single;  // Input: Single precision instruction
  input [63:0] src_in;  // Input: Source operand

  output src_cnan;  // Output: Canonical NaN (single)
  output src_id;  // Output: Invalid number
  output src_inf;  // Output: Infinity
  output src_norm;  // Output: Normal number
  output src_qnan;  // Output: Quiet NaN
  output src_snan;  // Output: Signaling NaN
  output src_zero;  // Output: Zero

  wire        inst_double;  // Wire for double precision instruction
  wire        inst_single;  // Wire for single precision instruction
  wire [63:0] src;  // Wire for the source operand
  wire        src_cnan;  // Wire for canonical NaN (single)
  wire        src_expn_max;  // Wire for maximum exponent value
  wire        src_expn_zero;  // Wire for zero exponent value
  wire        src_frac_msb;  // Wire for fraction most significant bit
  wire        src_frac_zero;  // Wire for zero fraction value
  wire        src_id;  // Wire for invalid number
  wire [63:0] src_in;  // Wire for the input source operand
  wire        src_inf;  // Wire for infinity
  wire        src_norm;  // Wire for normal number
  wire        src_qnan;  // Wire for quiet NaN
  wire        src_snan;  // Wire for signaling NaN
  wire        src_zero;  // Wire for zero

  assign src[63:0]     = src_in[63:0];  // Assign input to internal signal

  // Check for canonical NaN (single precision)
  assign src_cnan      = !(&src[63:32]) && inst_single;

  // Check if the exponent is zero (for both single and double precision)
  assign src_expn_zero = !(|src[62:52]) && inst_double || !(|src[30:23]) && inst_single;

  // Check if the exponent is maximum (for both single and double precision)
  assign src_expn_max  = (&src[62:52]) && inst_double || (&src[30:23]) && inst_single;

  // Check if the fraction is zero (for both single and double precision)
  assign src_frac_zero = !(|src[51:0]) && inst_double || !(|src[22:0]) && inst_single;

  // Check the most significant bit of the fraction
  assign src_frac_msb  = src[51] && inst_double || src[22] && inst_single;

  // Check for signaling NaN
  assign src_snan      = src_expn_max && !src_frac_msb && !src_frac_zero && !src_cnan;
  // Check for quiet NaN
  assign src_qnan      = src_expn_max && src_frac_msb || src_cnan;
  // Check for zero
  assign src_zero      = src_expn_zero && src_frac_zero && !src_cnan;
  // Check for invalid number (zero exponent, non-zero fraction)
  assign src_id        = src_expn_zero && !src_frac_zero && !src_cnan;
  // Check for infinity (maximum exponent, zero fraction)
  assign src_inf       = src_expn_max && src_frac_zero && !src_cnan;
  // Check for normal number
  assign src_norm      = !(src_expn_zero && src_frac_zero) && !src_expn_max && !src_cnan;

endmodule
