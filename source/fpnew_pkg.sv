// Package definition for the new floating-point unit related definitions
package fpnew_pkg;

  // Typedef for a packed structure representing floating-point encoding
  typedef struct packed {
    // Number of exponent bits for a floating-point format
    int unsigned exp_bits;
    // Number of mantissa bits for a floating-point format
    int unsigned man_bits;
  } fp_encoding_t;

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

  // Typedef for a logic vector representing a set of FP format enables
  typedef logic [0:NUM_FP_FORMATS-1] fmt_logic_t;

  // Typedef for a 2D logic vector to store unsigned values per FP format
  typedef logic [0:NUM_FP_FORMATS-1][31:0] fmt_unsigned_t;

  // Parameter defining the formats that support complex packing operations
  parameter fmt_logic_t CPK_FORMATS = 5'b11000;

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

  // Function to get the width of a given integer format
  function automatic int unsigned int_width(int_format_e ifmt);
    unique case (ifmt)
      // Return 8 for INT8 format
      INT8:  return 8;
      // Return 16 for INT16 format
      INT16: return 16;
      // Return 32 for INT32 format
      INT32: return 32;
      // Return 64 for INT64 format
      INT64: return 64;
      default: begin
        // Fatal error for invalid integer format
        $fatal(1, "Invalid INT format supplied");
        // Default return value (should not be reached)
        return INT8;
      end
    endcase
  endfunction

  // Typedef for a logic vector representing a set of integer format enables
  typedef logic [0:NUM_INT_FORMATS-1] ifmt_logic_t;

  // Parameter defining the number of operation groups
  parameter int unsigned NUM_OPGROUPS = 4;

  // Typedef for the operation group enumeration
  typedef enum logic [1:0] {
    // Operation group: Addition and Multiplication
    ADDMUL,
    // Operation group: Division and Square Root
    DIVSQRT,
    // Operation group: Non-computational operations
    NONCOMP,
    // Operation group: Conversion operations
    CONV
  } opgroup_e;

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

  // Typedef for the rounding mode enumeration
  typedef enum logic [2:0] {
    // Rounding mode: Round to nearest even
    RNE = 3'b000,
    // Rounding mode: Round towards zero
    RTZ = 3'b001,
    // Rounding mode: Round towards negative infinity
    RDN = 3'b010,
    // Rounding mode: Round towards positive infinity
    RUP = 3'b011,
    // Rounding mode: Round to nearest away from zero (Mag)
    RMM = 3'b100,
    // Rounding mode: Round towards odd
    ROD = 3'b101,
    // Rounding mode: Dynamic rounding mode (from FPU control register)
    DYN = 3'b111
  } roundmode_e;

  // Typedef for a packed structure representing floating-point status flags
  typedef struct packed {
    // Invalid operation flag
    logic NV;
    // Division by zero flag
    logic DZ;
    // Overflow flag
    logic OF;
    // Underflow flag
    logic UF;
    // Inexact flag
    logic NX;
  } status_t;

  // Typedef for a packed structure representing floating-point information
  typedef struct packed {
    // Flag indicating if the number is normal
    logic is_normal;
    // Flag indicating if the number is subnormal
    logic is_subnormal;
    // Flag indicating if the number is zero
    logic is_zero;
    // Flag indicating if the number is infinity
    logic is_inf;
    // Flag indicating if the number is NaN (Not a Number)
    logic is_nan;
    // Flag indicating if the number is a signalling NaN
    logic is_signalling;
    // Flag indicating if the number is a quiet NaN
    logic is_quiet;
    // Flag indicating if the number is boxed (implementation-specific)
    logic is_boxed;
  } fp_info_t;

  // Typedef for the class mask enumeration used for classification
  typedef enum logic [9:0] {
    // Negative infinity
    NEGINF     = 10'b00_0000_0001,
    // Negative normal number
    NEGNORM    = 10'b00_0000_0010,
    // Negative subnormal number
    NEGSUBNORM = 10'b00_0000_0100,
    // Negative zero
    NEGZERO    = 10'b00_0000_1000,
    // Positive zero
    POSZERO    = 10'b00_0001_0000,
    // Positive subnormal number
    POSSUBNORM = 10'b00_0010_0000,
    // Positive normal number
    POSNORM    = 10'b00_0100_0000,
    // Positive infinity
    POSINF     = 10'b00_1000_0000,
    // Signalling NaN
    SNAN       = 10'b01_0000_0000,
    // Quiet NaN
    QNAN       = 10'b10_0000_0000
  } classmask_e;

  // Typedef for the pipeline configuration enumeration
  typedef enum logic [1:0] {
    // Pipeline configuration: Before a certain stage
    BEFORE,
    // Pipeline configuration: After a certain stage
    AFTER,
    // Pipeline configuration: Inside a certain stage
    INSIDE,
    // Pipeline configuration: Distributed across stages
    DISTRIBUTED
  } pipe_config_t;

  // Typedef for the unit type enumeration
  typedef enum logic [1:0] {
    // Unit type: Disabled
    DISABLED,
    // Unit type: Parallel execution
    PARALLEL,
    // Unit type: Merged functionality
    MERGED
  } unit_type_t;

  // Typedef for an array of unit types per floating-point format
  typedef unit_type_t [0:NUM_FP_FORMATS-1] fmt_unit_types_t;

  // Typedef for an array of fmt_unit_types_t per operation group
  typedef fmt_unit_types_t [0:NUM_OPGROUPS-1] opgrp_fmt_unit_types_t;

  // Typedef for an array of fmt_unsigned_t per operation group
  typedef fmt_unsigned_t [0:NUM_OPGROUPS-1] opgrp_fmt_unsigned_t;

  // Typedef for a packed structure representing FPU features
  typedef struct packed {
    // Width of the FPU in bits
    int unsigned Width;
    // Flag indicating if vector operations are enabled
    logic        EnableVectors;
    // Flag indicating if NaN boxing is enabled
    logic        EnableNanBox;
    // Mask of supported floating-point formats
    fmt_logic_t  FpFmtMask;
    // Mask of supported integer formats
    ifmt_logic_t IntFmtMask;
  } fpu_features_t;

  // Parameter defining FPU features for RV64D configuration
  parameter fpu_features_t RV64D = '{
      Width: 64,
      EnableVectors: 1'b0,
      EnableNanBox: 1'b1,
      FpFmtMask: 5'b11000,
      IntFmtMask: 4'b0011
  };

  // Parameter defining FPU features for RV32D configuration
  parameter fpu_features_t RV32D = '{
      Width: 64,
      EnableVectors: 1'b1,
      EnableNanBox: 1'b1,
      FpFmtMask: 5'b11000,
      IntFmtMask: 4'b0010
  };

  // Parameter defining FPU features for RV32F configuration
  parameter fpu_features_t RV32F = '{
      Width: 32,
      EnableVectors: 1'b0,
      EnableNanBox: 1'b1,
      FpFmtMask: 5'b10000,
      IntFmtMask: 4'b0010
  };

  // Parameter defining FPU features for RV64D with XSFLT extension
  parameter fpu_features_t RV64D_XSFLT = '{
      Width: 64,
      EnableVectors: 1'b1,
      EnableNanBox: 1'b1,
      FpFmtMask: 5'b11111,
      IntFmtMask: 4'b1111
  };

  // Parameter defining FPU features for RV32F with XSFLT extension
  parameter fpu_features_t RV32F_XSFLT = '{
      Width: 32,
      EnableVectors: 1'b1,
      EnableNanBox: 1'b1,
      FpFmtMask: 5'b10111,
      IntFmtMask: 4'b1110
  };

  // Parameter defining FPU features for RV32F with XF16ALT and XFVEC extensions
  parameter fpu_features_t RV32F_XF16ALT_XFVEC = '{
      Width: 32,
      EnableVectors: 1'b1,
      EnableNanBox: 1'b1,
      FpFmtMask: 5'b10001,
      IntFmtMask: 4'b0110
  };

  // Typedef for a packed structure representing FPU implementation details
  typedef struct packed {
    // Array to store number of pipeline registers per format and opgroup
    opgrp_fmt_unsigned_t PipeRegs;
    // Array to store unit types per format and opgroup
    opgrp_fmt_unit_types_t UnitTypes;
    // Configuration of the pipeline
    pipe_config_t PipeConfig;
  } fpu_implementation_t;

  // Parameter defining default FPU implementation with no pipeline registers
  parameter fpu_implementation_t DEFAULT_NOREGS = '{
      PipeRegs: '{default: 0},
      UnitTypes: '{
          '{default: PARALLEL},
          '{default: MERGED},
          '{default: PARALLEL},
          '{default: MERGED}
      },
      PipeConfig: BEFORE
  };

  // Parameter defining default FPU implementation based on Snitch core
  parameter fpu_implementation_t DEFAULT_SNITCH = '{
      PipeRegs: '{default: 1},
      UnitTypes: '{
          '{default: PARALLEL},
          '{default: DISABLED},
          '{default: PARALLEL},
          '{default: MERGED}
      },
      PipeConfig: BEFORE
  };

  // Parameter defining a don't care logic value
  parameter logic DONT_CARE = 1'b1;

  // Function to return the minimum of two integers
  function automatic int minimum(int a, int b);
    return (a < b) ? a : b;
  endfunction

  // Function to return the maximum of two integers
  function automatic int maximum(int a, int b);
    return (a > b) ? a : b;
  endfunction

  // Function to get the width of a given floating-point format
  function automatic int unsigned fp_width(fp_format_e fmt);
    case (fmt)
      default: return 32;
      FP64:    return 64;
      FP16:    return 16;
      FP8:     return 8;
      FP16ALT: return 16;
    endcase
  endfunction

  // Function to get the maximum width among enabled FP formats in a configuration
  function automatic int unsigned max_fp_width(fmt_logic_t cfg);
    automatic int unsigned res = 0;
    for (int unsigned i = 0; i < NUM_FP_FORMATS; i++)
    if (cfg[i]) res = unsigned'(maximum(res, fp_width(fp_format_e'(i))));
    return res;
  endfunction

  // Function to get the minimum width among enabled FP formats in a configuration
  function automatic int unsigned min_fp_width(fmt_logic_t cfg);
    automatic int unsigned res = max_fp_width(cfg);
    for (int unsigned i = 0; i < NUM_FP_FORMATS; i++)
    if (cfg[i]) res = unsigned'(minimum(res, fp_width(fp_format_e'(i))));
    return res;
  endfunction

  // Function to get the number of exponent bits for a given FP format
  function automatic int unsigned exp_bits(fp_format_e fmt);
    case (fmt)
      default: return 8;
      FP64:    return 11;
      FP16:    return 5;
      FP8:     return 5;
      FP16ALT: return 8;
    endcase
  endfunction

  // Function to get the number of mantissa bits for a given FP format
  function automatic int unsigned man_bits(fp_format_e fmt);
    case (fmt)
      default: return 23;
      FP64:    return 52;
      FP16:    return 10;
      FP8:     return 2;
      FP16ALT: return 7;
    endcase
  endfunction

  // Function to get the bias value for a given FP format
  function automatic int unsigned bias(fp_format_e fmt);
    case (fmt)
      default: return 127;
      FP64:    return 1023;
      FP16:    return 15;
      FP8:     return 15;
      FP16ALT: return 127;
    endcase
  endfunction

  // Function to determine the super-format encoding based on a format configuration
  function automatic fp_encoding_t super_format(fmt_logic_t cfg);
    automatic fp_encoding_t res;
    res = '0;
    for (int unsigned fmt = 0; fmt < NUM_FP_FORMATS; fmt++)
    if (cfg[fmt]) begin
      res.exp_bits = unsigned'(maximum(res.exp_bits, exp_bits(fp_format_e'(fmt))));
      res.man_bits = unsigned'(maximum(res.man_bits, man_bits(fp_format_e'(fmt))));
    end
    return res;
  endfunction

  // Function to get the maximum width among enabled integer formats
  function automatic int unsigned max_int_width(ifmt_logic_t cfg);
    automatic int unsigned res = 0;
    for (int ifmt = 0; ifmt < NUM_INT_FORMATS; ifmt++) begin
      if (cfg[ifmt]) res = maximum(res, int_width(int_format_e'(ifmt)));
    end
    return res;
  endfunction

  // Function to get the operation group for a given operation
  function automatic opgroup_e get_opgroup(operation_e op);
    unique case (op)
      FMADD, FNMSUB, ADD, MUL:     return ADDMUL;
      DIV, SQRT:                   return DIVSQRT;
      SGNJ, MINMAX, CMP, CLASSIFY: return NONCOMP;
      F2F, F2I, I2F, CPKAB, CPKCD: return CONV;
      default:                     return NONCOMP;
    endcase
  endfunction

  // Function to get the number of operands for a given operation group
  function automatic int unsigned num_operands(opgroup_e grp);
    unique case (grp)
      ADDMUL:  return 3;
      DIVSQRT: return 2;
      NONCOMP: return 2;
      CONV:    return 3;
      default: return 0;
    endcase
  endfunction

  // Function to get the number of lanes for a given width, format, and vector enable
  function automatic int unsigned num_lanes(int unsigned width, fp_format_e fmt, logic vec);
    return vec ? width / fp_width(fmt) : 1;
  endfunction

  // Function to get the maximum number of lanes for a given width and format configuration
  function automatic int unsigned max_num_lanes(int unsigned width, fmt_logic_t cfg, logic vec);
    return vec ? width / min_fp_width(cfg) : 1;
  endfunction

  // Function to get the enabled FP formats for a specific lane in a vector operation
  function automatic fmt_logic_t get_lane_formats(int unsigned width, fmt_logic_t cfg,
                                                  int unsigned lane_no);
    automatic fmt_logic_t res;
    for (int unsigned fmt = 0; fmt < NUM_FP_FORMATS; fmt++)
    res[fmt] = cfg[fmt] & (width / fp_width(fp_format_e'(fmt)) > lane_no);
    return res;
  endfunction

  // Function to get the enabled integer formats for a specific lane in a vector operation
  function automatic ifmt_logic_t get_lane_int_formats(int unsigned width, fmt_logic_t cfg,
                                                       ifmt_logic_t icfg, int unsigned lane_no);
    automatic ifmt_logic_t res;
    automatic fmt_logic_t  lanefmts;
    res = '0;
    lanefmts = get_lane_formats(width, cfg, lane_no);
    for (int unsigned ifmt = 0; ifmt < NUM_INT_FORMATS; ifmt++)
    for (int unsigned fmt = 0; fmt < NUM_FP_FORMATS; fmt++)
    if ((fp_width(fp_format_e'(fmt)) == int_width(int_format_e'(ifmt))))
      res[ifmt] |= icfg[ifmt] && lanefmts[fmt];
    return res;
  endfunction

  // Function to get the enabled FP formats for a specific lane in conversion operations
  function automatic fmt_logic_t get_conv_lane_formats(int unsigned width, fmt_logic_t cfg,
                                                       int unsigned lane_no);
    automatic fmt_logic_t res;
    for (int unsigned fmt = 0; fmt < NUM_FP_FORMATS; fmt++)
    res[fmt] = cfg[fmt] &&
        ((width / fp_width(fp_format_e'(fmt)) > lane_no) || (CPK_FORMATS[fmt] && (lane_no < 2)));
    return res;
  endfunction

  // Function to get the enabled integer formats for a specific lane in conversion operations
  function automatic ifmt_logic_t get_conv_lane_int_formats(
      int unsigned width, fmt_logic_t cfg, ifmt_logic_t icfg, int unsigned lane_no);
    automatic ifmt_logic_t res;
    automatic fmt_logic_t  lanefmts;
    res = '0;
    lanefmts = get_conv_lane_formats(width, cfg, lane_no);
    for (int unsigned ifmt = 0; ifmt < NUM_INT_FORMATS; ifmt++)
    for (int unsigned fmt = 0; fmt < NUM_FP_FORMATS; fmt++)
    res[ifmt] |= icfg[ifmt] && lanefmts[fmt] && (fp_width(
        fp_format_e'(fmt)
    ) == int_width(
        int_format_e'(ifmt)
    ));
    return res;
  endfunction

  // Function to check if any multi-cycle unit is enabled for the given formats
  function automatic logic any_enabled_multi(fmt_unit_types_t types, fmt_logic_t cfg);
    for (int unsigned i = 0; i < NUM_FP_FORMATS; i++) begin
      if (cfg[i] && types[i] == MERGED) return 1'b1;
    end
    return 1'b0;
  endfunction

  // Function to check if the given format is the first enabled multi-cycle unit
  function automatic logic is_first_enabled_multi(fp_format_e fmt, fmt_unit_types_t types,
                                                  fmt_logic_t cfg);
    for (int unsigned i = 0; i < NUM_FP_FORMATS; i++) begin
      if (cfg[i] && types[i] == MERGED) return (fp_format_e'(i) == fmt);
    end
    return 1'b0;
  endfunction

  // Function to get the first enabled multi-cycle unit format
  function automatic fp_format_e get_first_enabled_multi(fmt_unit_types_t types, fmt_logic_t cfg);
    for (int unsigned i = 0; i < NUM_FP_FORMATS; i++)
    if (cfg[i] && types[i] == MERGED) return fp_format_e'(i);
    return fp_format_e'(0);
  endfunction

  // Function to get the number of registers for the first enabled multi-cycle unit
  function automatic int unsigned get_num_regs_multi(fmt_unsigned_t regs, fmt_unit_types_t types,
                                                     fmt_logic_t cfg);
    automatic int unsigned res = 0;
    for (int unsigned i = 0; i < NUM_FP_FORMATS; i++) begin
      if (cfg[i] && types[i] == MERGED) res = maximum(res, regs[i]);
    end
    return res;
  endfunction

endpackage
