package fpnew_pkg;

  // Structure to represent the exponent and mantissa bit widths for a floating-point format
  typedef struct packed {
    int unsigned exp_bits;  // Number of exponent bits
    int unsigned man_bits;  // Number of mantissa bits
  } fp_encoding_t;

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

  // Type representing a bitmask for enabling/disabling floating-point formats
  typedef logic [0:NUM_FP_FORMATS-1] fmt_logic_t;
  // Type representing an array of 32-bit unsigned values, indexed by floating-point format
  typedef logic [0:NUM_FP_FORMATS-1][31:0] fmt_unsigned_t;

  // Parameter indicating which floating-point formats are used for complex pack operations
  parameter fmt_logic_t CPK_FORMATS = 5'b11000;  // FP32 and FP64 are used for CPK

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

  // Function to get the bit width of a given integer format
  function automatic int unsigned int_width(int_format_e ifmt);
    unique case (ifmt)
      INT8:  return 8;
      INT16: return 16;
      INT32: return 32;
      INT64: return 64;
      default: begin
        $fatal(1, "Invalid INT format supplied");
        return INT8;  // Default return to satisfy function type
      end
    endcase
  endfunction

  // Type representing a bitmask for enabling/disabling integer formats
  typedef logic [0:NUM_INT_FORMATS-1] ifmt_logic_t;

  // Number of operation groups
  parameter int unsigned NUM_OPGROUPS = 4;

  // Enumeration of operation groups
  typedef enum logic [1:0] {
    ADDMUL,  // Addition and Multiplication operations
    DIVSQRT,  // Division and Square Root operations
    NONCOMP,  // Non-computational operations (e.g., sign injection, min/max, compare, classify)
    CONV  // Conversion operations (e.g., float-to-float, float-to-int, int-to-float, complex pack)
  } opgroup_e;

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

  // Enumeration of supported rounding modes
  typedef enum logic [2:0] {
    RNE = 3'b000,  // Round to Nearest Even
    RTZ = 3'b001,  // Round Towards Zero
    RDN = 3'b010,  // Round Down (towards negative infinity)
    RUP = 3'b011,  // Round Up (towards positive infinity)
    RMM = 3'b100,  // Round to Nearest Max Magnitude (non-standard)
    ROD = 3'b101,  // Round to Odd (non-standard)
    DYN = 3'b111   // Dynamic rounding mode
  } roundmode_e;

  // Structure to represent the floating-point status flags (exceptions)
  typedef struct packed {
    logic NV;  // Invalid Operation
    logic DZ;  // Divide by Zero
    logic OF;  // Overflow
    logic UF;  // Underflow
    logic NX;  // Inexact
  } status_t;

  // Structure to hold various properties of a floating-point number
  typedef struct packed {
    logic is_normal;      // Number is a normal floating-point number
    logic is_subnormal;   // Number is a subnormal (denormal) floating-point number
    logic is_zero;        // Number is zero
    logic is_inf;         // Number is infinity
    logic is_nan;         // Number is Not-a-Number
    logic is_signalling;  // NaN is a signalling NaN
    logic is_quiet;       // NaN is a quiet NaN
    logic is_boxed;       // Number is in a special "boxed" format (implementation-specific)
  } fp_info_t;

  // Enumeration representing the bitmask for the classify instruction result
  typedef enum logic [9:0] {
    NEGINF     = 10'b00_0000_0001,  // Negative Infinity
    NEGNORM    = 10'b00_0000_0010,  // Negative Normal
    NEGSUBNORM = 10'b00_0000_0100,  // Negative Subnormal
    NEGZERO    = 10'b00_0000_1000,  // Negative Zero
    POSZERO    = 10'b00_0001_0000,  // Positive Zero
    POSSUBNORM = 10'b00_0010_0000,  // Positive Subnormal
    POSNORM    = 10'b00_0100_0000,  // Positive Normal
    POSINF     = 10'b00_1000_0000,  // Positive Infinity
    SNAN       = 10'b01_0000_0000,  // Signalling NaN
    QNAN       = 10'b10_0000_0000   // Quiet NaN
  } classmask_e;

  // Enumeration for different pipeline configurations
  typedef enum logic [1:0] {
    BEFORE,      // Operation performed before a certain stage
    AFTER,       // Operation performed after a certain stage
    INSIDE,      // Operation performed within a certain stage
    DISTRIBUTED  // Operation is distributed across multiple stages
  } pipe_config_t;

  // Enumeration for different types of functional units
  typedef enum logic [1:0] {
    DISABLED,  // Functional unit is disabled for this format/operation group
    PARALLEL,  // Dedicated functional unit for this format/operation group
    MERGED  // Functional unit handles multiple formats/operation groups
  } unit_type_t;

  // Type representing an array of unit types for each floating-point format
  typedef unit_type_t [0:NUM_FP_FORMATS-1] fmt_unit_types_t;
  // Type representing an array of format-specific unit types for each operation group
  typedef fmt_unit_types_t [0:NUM_OPGROUPS-1] opgrp_fmt_unit_types_t;
  // Type representing an array of format-specific unsigned values for each operation group
  typedef fmt_unsigned_t [0:NUM_OPGROUPS-1] opgrp_fmt_unsigned_t;

  // Structure to define the features supported by a specific FPU configuration
  typedef struct packed {
    int unsigned Width;          // Data path width of the FPU
    logic        EnableVectors;  // Flag indicating if vector operations are enabled
    logic        EnableNanBox;   // Flag indicating if NaN boxing is enabled
    fmt_logic_t  FpFmtMask;      // Bitmask indicating supported floating-point formats
    ifmt_logic_t IntFmtMask;     // Bitmask indicating supported integer formats
  } fpu_features_t;

  // Feature configuration for RV64D
  parameter fpu_features_t RV64D = '{
      Width: 64,
      EnableVectors: 1'b0,
      EnableNanBox: 1'b1,
      FpFmtMask: 5'b11000,  // FP32, FP64
      IntFmtMask: 4'b0011  // INT32, INT64
  };

  // Feature configuration for RV32D
  parameter fpu_features_t RV32D = '{
      Width: 64,
      EnableVectors: 1'b1,
      EnableNanBox: 1'b1,
      FpFmtMask: 5'b11000,  // FP32, FP64
      IntFmtMask: 4'b0010  // INT32
  };

  // Feature configuration for RV32F
  parameter fpu_features_t RV32F = '{
      Width: 32,
      EnableVectors: 1'b0,
      EnableNanBox: 1'b1,
      FpFmtMask: 5'b10000,  // FP32
      IntFmtMask: 4'b0010  // INT32
  };

  // Feature configuration for RV64D with extended single-precision floating-point
  parameter fpu_features_t RV64D_XSFLT = '{
      Width: 64,
      EnableVectors: 1'b1,
      EnableNanBox: 1'b1,
      FpFmtMask: 5'b11111,  // FP32, FP64, FP16, FP8, FP16ALT
      IntFmtMask: 4'b1111  // INT8, INT16, INT32, INT64
  };

  // Feature configuration for RV32F with extended single-precision floating-point
  parameter fpu_features_t RV32F_XSFLT = '{
      Width: 32,
      EnableVectors: 1'b1,
      EnableNanBox: 1'b1,
      FpFmtMask: 5'b10111,  // FP32, FP16, FP8, FP16ALT
      IntFmtMask: 4'b1110  // INT16, INT32, INT64
  };

  // Feature configuration for RV32F with alternative half-precision floating-point and vector support
  parameter fpu_features_t RV32F_XF16ALT_XFVEC = '{
      Width: 32,
      EnableVectors: 1'b1,
      EnableNanBox: 1'b1,
      FpFmtMask: 5'b10001,  // FP32, FP16ALT
      IntFmtMask: 4'b0110  // INT16, INT32
  };

  // Structure to define the implementation details of the FPU
  typedef struct packed {
    // Number of pipeline registers for each operation group and format
    opgrp_fmt_unsigned_t PipeRegs;
    // Type of functional unit used for each operation group and format
    opgrp_fmt_unit_types_t UnitTypes;
    // Overall pipeline configuration
    pipe_config_t PipeConfig;
  } fpu_implementation_t;

  // Implementation with no pipeline registers
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

  // Implementation based on the Snitch architecture
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

  // Don't care logic value
  parameter logic DONT_CARE = 1'b1;

  // Function to return the minimum of two integers
  function automatic int minimum(int a, int b);
    return (a < b) ? a : b;
  endfunction

  // Function to return the maximum of two integers
  function automatic int maximum(int a, int b);
    return (a > b) ? a : b;
  endfunction

  // Function to get the bit width of a given floating-point format
  function automatic int unsigned fp_width(fp_format_e fmt);
    case (fmt)
      default: return 32;
      FP64:    return 64;
      FP16:    return 16;
      FP8:     return 8;
      FP16ALT: return 16;
    endcase
  endfunction

  // Function to get the maximum bit width among the enabled floating-point formats
  function automatic int unsigned max_fp_width(fmt_logic_t cfg);
    automatic int unsigned res = 0;
    for (int unsigned i = 0; i < NUM_FP_FORMATS; i++)
    if (cfg[i]) res = unsigned'(maximum(res, fp_width(fp_format_e'(i))));
    return res;
  endfunction

  // Function to get the minimum bit width among the enabled floating-point formats
  function automatic int unsigned min_fp_width(fmt_logic_t cfg);
    automatic int unsigned res = max_fp_width(cfg);
    for (int unsigned i = 0; i < NUM_FP_FORMATS; i++)
    if (cfg[i]) res = unsigned'(minimum(res, fp_width(fp_format_e'(i))));
    return res;
  endfunction

  // Function to get the number of exponent bits for a given floating-point format
  function automatic int unsigned exp_bits(fp_format_e fmt);
    case (fmt)
      default: return 8;
      FP64:    return 11;
      FP16:    return 5;
      FP8:     return 5;
      FP16ALT: return 8;
    endcase
  endfunction

  // Function to get the number of mantissa bits for a given floating-point format
  function automatic int unsigned man_bits(fp_format_e fmt);
    case (fmt)
      default: return 23;
      FP64:    return 52;
      FP16:    return 10;
      FP8:     return 2;
      FP16ALT: return 7;
    endcase
  endfunction

  // Function to get the bias value for a given floating-point format
  function automatic int unsigned bias(fp_format_e fmt);
    case (fmt)
      default: return 127;
      FP64:    return 1023;
      FP16:    return 15;
      FP8:     return 15;
      FP16ALT: return 127;
    endcase
  endfunction

  // Function to determine the "super format" encoding (maximum exponent and mantissa bits)
  // among the enabled floating-point formats
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

  // Function to get the maximum bit width among the enabled integer formats
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

  // Function to calculate the number of lanes for a given width, format, and vector enable
  function automatic int unsigned num_lanes(int unsigned width, fp_format_e fmt, logic vec);
    return vec ? width / fp_width(fmt) : 1;
  endfunction

  // Function to calculate the maximum number of lanes for a given width, enabled formats, and vector enable
  function automatic int unsigned max_num_lanes(int unsigned width, fmt_logic_t cfg, logic vec);
    return vec ? width / min_fp_width(cfg) : 1;
  endfunction

  // Function to get the bitmask of floating-point formats supported by a specific lane
  function automatic fmt_logic_t get_lane_formats(int unsigned width, fmt_logic_t cfg,
                                                  int unsigned lane_no);
    automatic fmt_logic_t res;
    for (int unsigned fmt = 0; fmt < NUM_FP_FORMATS; fmt++)
    res[fmt] = cfg[fmt] & (width / fp_width(fp_format_e'(fmt)) > lane_no);
    return res;
  endfunction

  // Function to get the bitmask of integer formats supported by a specific lane (based on FP format width)
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

  // Function to get the bitmask of floating-point formats supported by a specific lane for conversion operations
  // Includes special handling for complex pack formats which might span multiple lanes
  function automatic fmt_logic_t get_conv_lane_formats(int unsigned width, fmt_logic_t cfg,
                                                       int unsigned lane_no);
    automatic fmt_logic_t res;
    for (int unsigned fmt = 0; fmt < NUM_FP_FORMATS; fmt++)
    res[fmt] = cfg[fmt] &&
        ((width / fp_width(fp_format_e'(fmt)) > lane_no) || (CPK_FORMATS[fmt] && (lane_no < 2)));
    return res;
  endfunction

  // Function to get the bitmask of integer formats supported by a specific lane for conversion operations
  // Considers the floating-point formats supported by the lane and the complex pack formats
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

  // Function to check if any of the enabled floating-point formats use a merged functional unit
  function automatic logic any_enabled_multi(fmt_unit_types_t types, fmt_logic_t cfg);
    for (int unsigned i = 0; i < NUM_FP_FORMATS; i++) begin
      if (cfg[i] && types[i] == MERGED) return 1'b1;
    end
    return 1'b0;
  endfunction

  // Function to check if the given floating-point format is the first enabled format using a merged unit
  function automatic logic is_first_enabled_multi(fp_format_e fmt, fmt_unit_types_t types,
                                                  fmt_logic_t cfg);
    for (int unsigned i = 0; i < NUM_FP_FORMATS; i++) begin
      if (cfg[i] && types[i] == MERGED) return (fp_format_e'(i) == fmt);
    end
    return 1'b0;
  endfunction

  // Function to get the first enabled floating-point format that uses a merged functional unit
  function automatic fp_format_e get_first_enabled_multi(fmt_unit_types_t types, fmt_logic_t cfg);
    for (int unsigned i = 0; i < NUM_FP_FORMATS; i++)
    if (cfg[i] && types[i] == MERGED) return fp_format_e'(i);
    return fp_format_e'(0);
  endfunction

  // Function to get the maximum number of registers required by any enabled format using a merged unit
  function automatic int unsigned get_num_regs_multi(fmt_unsigned_t regs, fmt_unit_types_t types,
                                                     fmt_logic_t cfg);
    automatic int unsigned res = 0;
    for (int unsigned i = 0; i < NUM_FP_FORMATS; i++) begin
      if (cfg[i] && types[i] == MERGED) res = maximum(res, regs[i]);
    end
    return res;
  endfunction

endpackage
