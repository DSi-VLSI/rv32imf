package rv32imf_fpu_pkg;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // Floating-Point Formats
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Number of supported floating-point formats
  parameter int unsigned NUM_FP_FORMATS = 5;
  // Number of bits required to represent all floating-point formats
  parameter int unsigned FP_FORMAT_BITS = $clog2(NUM_FP_FORMATS);

  // Enumeration of supported floating-point formats
  typedef enum logic [FP_FORMAT_BITS-1:0] {
    FP32    = 'd0,  // Single-precision floating-point (32 bits)
    FP64    = 'd1,  // Double-precision floating-point (64 bits)
    FP16    = 'd2,  // Half-precision floating-point (16 bits)
    FP8     = 'd3,  // 8-bit floating-point (non-standard)
    FP16ALT = 'd4   // Alternative 16-bit floating-point format (non-standard)
  } fp_format_e;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // Integer Formats
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Number of supported integer formats
  parameter int unsigned NUM_INT_FORMATS = 4;
  // Number of bits required to represent all integer formats
  parameter int unsigned INT_FORMAT_BITS = $clog2(NUM_INT_FORMATS);

  // Enumeration of supported integer formats
  typedef enum logic [INT_FORMAT_BITS-1:0] {
    INT8,   // 8-bit integer
    INT16,  // 16-bit integer
    INT32,  // 32-bit integer
    INT64   // 64-bit integer
  } int_format_e;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // Floating-Point Operations
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Number of bits required to represent all supported FPU operations
  parameter int unsigned OP_BITS = 4;

  // Enumeration of supported floating-point operations
  typedef enum logic [OP_BITS-1:0] {
    FMADD,     // Fused Multiply-Add
    FNMSUB,    // Fused Negative Multiply-Subtract
    ADD,       // Addition
    MUL,       // Multiplication
    DIV,       // Division
    SQRT,      // Square Root
    SGNJ,      // Sign-injection operations (SGNJ, SGNJN, SGNJX)
    MINMAX,    // Minimum and Maximum operations (MIN, MAX)
    CMP,       // Comparison operations (EQ, NE, LT, LE, GT, GE)
    CLASSIFY,  // Classify floating-point number
    F2F,       // Floating-point to floating-point conversion
    F2I,       // Floating-point to integer conversion
    I2F,       // Integer to floating-point conversion
    CPKAB,     // Complex Pack AB (non-standard)
    CPKCD      // Complex Pack CD (non-standard)
  } operation_e;

endpackage
