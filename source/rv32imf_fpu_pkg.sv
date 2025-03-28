// Package definition for the RV32IMF FPU related definitions
package rv32imf_fpu_pkg;

  // Parameter defining the number of supported floating-point formats
  parameter int unsigned NUM_FP_FORMATS = 5;

  // Parameter defining the number of bits required to represent FP formats
  parameter int unsigned FP_FORMAT_BITS = $clog2(NUM_FP_FORMATS);

  // Typedef for the floating-point format enumeration
  typedef enum logic [FP_FORMAT_BITS-1:0] {
    // Floating-point format: Single-precision (32-bit)
    FP32    = 'd0,
    // Floating-point format: Double-precision (64-bit)
    FP64    = 'd1,
    // Floating-point format: Half-precision (16-bit)
    FP16    = 'd2,
    // Floating-point format: Quarter-precision (8-bit)
    FP8     = 'd3,
    // Floating-point format: Alternative half-precision (16-bit)
    FP16ALT = 'd4
  } fp_format_e;

  // Parameter defining the number of supported integer formats
  parameter int unsigned NUM_INT_FORMATS = 4;

  // Parameter defining the number of bits required to represent integer formats
  parameter int unsigned INT_FORMAT_BITS = $clog2(NUM_INT_FORMATS);

  // Typedef for the integer format enumeration
  typedef enum logic [INT_FORMAT_BITS-1:0] {
    // Integer format: 8-bit integer
    INT8,
    // Integer format: 16-bit integer
    INT16,
    // Integer format: 32-bit integer
    INT32,
    // Integer format: 64-bit integer
    INT64
  } int_format_e;

  // Parameter defining the number of bits for the operation code
  parameter int unsigned OP_BITS = 4;

  // Typedef for the floating-point operation enumeration
  typedef enum logic [OP_BITS-1:0] {
    // Floating-point operation: Fused multiply-add
    FMADD,
    // Floating-point operation: Fused negate multiply-subtract
    FNMSUB,
    // Floating-point operation: Addition
    ADD,
    // Floating-point operation: Multiplication
    MUL,
    // Floating-point operation: Division
    DIV,
    // Floating-point operation: Square root
    SQRT,
    // Floating-point operation: Sign-inject
    SGNJ,
    // Floating-point operation: Minimum or maximum
    MINMAX,
    // Floating-point operation: Comparison
    CMP,
    // Floating-point operation: Classify
    CLASSIFY,
    // Floating-point operation: Float-to-float conversion
    F2F,
    // Floating-point operation: Float-to-integer conversion
    F2I,
    // Floating-point operation: Integer-to-float conversion
    I2F,
    // Floating-point operation: Complex pack AB
    CPKAB,
    // Floating-point operation: Complex pack CD
    CPKCD
  } operation_e;

endpackage
