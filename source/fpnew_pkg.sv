package fpnew_pkg;

  // Floating-point encoding structure
  typedef struct packed {
    int unsigned exp_bits;
    int unsigned man_bits;
  } fp_encoding_t;

  // Local parameters for floating-point formats
  parameter int unsigned NUM_FP_FORMATS = 5;
  parameter int unsigned FP_FORMAT_BITS = $clog2(NUM_FP_FORMATS);

  // Enumeration for floating-point formats
  typedef enum logic [FP_FORMAT_BITS-1:0] {
    FP32    = 'd0,
    FP64    = 'd1,
    FP16    = 'd2,
    FP8     = 'd3,
    FP16ALT = 'd4
  } fp_format_e;

  // Type definitions for format logic and unsigned values
  typedef logic [0:NUM_FP_FORMATS-1] fmt_logic_t;
  typedef logic [0:NUM_FP_FORMATS-1][31:0] fmt_unsigned_t;

  // Local parameters for packed formats
  parameter fmt_logic_t CPK_FORMATS = 5'b11000;
  parameter int unsigned NUM_INT_FORMATS = 4;
  parameter int unsigned INT_FORMAT_BITS = $clog2(NUM_INT_FORMATS);

  // Enumeration for integer formats
  typedef enum logic [INT_FORMAT_BITS-1:0] {
    INT8,
    INT16,
    INT32,
    INT64
  } int_format_e;

  // Function to get integer width based on format
  function automatic int unsigned int_width(int_format_e ifmt);
    unique case (ifmt)
      INT8:  return 8;
      INT16: return 16;
      INT32: return 32;
      INT64: return 64;
      default: begin
        $fatal(1, "Invalid INT format supplied");
        return INT8;
      end
    endcase
  endfunction

  // Type definition for integer format logic
  typedef logic [0:NUM_INT_FORMATS-1] ifmt_logic_t;

  // Local parameters for operation groups
  parameter int unsigned NUM_OPGROUPS = 4;

  // Enumeration for operation groups
  typedef enum logic [1:0] {
    ADDMUL,
    DIVSQRT,
    NONCOMP,
    CONV
  } opgroup_e;

  // Local parameters for operations
  parameter int unsigned OP_BITS = 4;

  // Enumeration for operations
  typedef enum logic [OP_BITS-1:0] {
    FMADD,
    FNMSUB,
    ADD,
    MUL,
    DIV,
    SQRT,
    SGNJ,
    MINMAX,
    CMP,
    CLASSIFY,
    F2F,
    F2I,
    I2F,
    CPKAB,
    CPKCD
  } operation_e;

  // Enumeration for rounding modes
  typedef enum logic [2:0] {
    RNE = 3'b000,
    RTZ = 3'b001,
    RDN = 3'b010,
    RUP = 3'b011,
    RMM = 3'b100,
    ROD = 3'b101,
    DYN = 3'b111
  } roundmode_e;

  // Structure for status flags
  typedef struct packed {
    logic NV;
    logic DZ;
    logic OF;
    logic UF;
    logic NX;
  } status_t;

  // Structure for floating-point information
  typedef struct packed {
    logic is_normal;
    logic is_subnormal;
    logic is_zero;
    logic is_inf;
    logic is_nan;
    logic is_signalling;
    logic is_quiet;
    logic is_boxed;
  } fp_info_t;

  // Enumeration for class masks
  typedef enum logic [9:0] {
    NEGINF     = 10'b00_0000_0001,
    NEGNORM    = 10'b00_0000_0010,
    NEGSUBNORM = 10'b00_0000_0100,
    NEGZERO    = 10'b00_0000_1000,
    POSZERO    = 10'b00_0001_0000,
    POSSUBNORM = 10'b00_0010_0000,
    POSNORM    = 10'b00_0100_0000,
    POSINF     = 10'b00_1000_0000,
    SNAN       = 10'b01_0000_0000,
    QNAN       = 10'b10_0000_0000
  } classmask_e;

  // Enumeration for pipeline configuration
  typedef enum logic [1:0] {
    BEFORE,
    AFTER,
    INSIDE,
    DISTRIBUTED
  } pipe_config_t;

  // Enumeration for unit types
  typedef enum logic [1:0] {
    DISABLED,
    PARALLEL,
    MERGED
  } unit_type_t;

  // Type definitions for unit types and unsigned values
  typedef unit_type_t [0:NUM_FP_FORMATS-1] fmt_unit_types_t;
  typedef fmt_unit_types_t [0:NUM_OPGROUPS-1] opgrp_fmt_unit_types_t;
  typedef fmt_unsigned_t [0:NUM_OPGROUPS-1] opgrp_fmt_unsigned_t;

  // Structure for FPU features
  typedef struct packed {
    int unsigned Width;
    logic        EnableVectors;
    logic        EnableNanBox;
    fmt_logic_t  FpFmtMask;
    ifmt_logic_t IntFmtMask;
  } fpu_features_t;

  // Local parameters for different FPU configurations
  parameter fpu_features_t RV64D = '{
      Width: 64,
      EnableVectors: 1'b0,
      EnableNanBox: 1'b1,
      FpFmtMask: 5'b11000,
      IntFmtMask: 4'b0011
  };

  parameter fpu_features_t RV32D = '{
      Width: 64,
      EnableVectors: 1'b1,
      EnableNanBox: 1'b1,
      FpFmtMask: 5'b11000,
      IntFmtMask: 4'b0010
  };

  parameter fpu_features_t RV32F = '{
      Width: 32,
      EnableVectors: 1'b0,
      EnableNanBox: 1'b1,
      FpFmtMask: 5'b10000,
      IntFmtMask: 4'b0010
  };

  parameter fpu_features_t RV64D_Xsflt = '{
      Width: 64,
      EnableVectors: 1'b1,
      EnableNanBox: 1'b1,
      FpFmtMask: 5'b11111,
      IntFmtMask: 4'b1111
  };

  parameter fpu_features_t RV32F_Xsflt = '{
      Width: 32,
      EnableVectors: 1'b1,
      EnableNanBox: 1'b1,
      FpFmtMask: 5'b10111,
      IntFmtMask: 4'b1110
  };

  parameter fpu_features_t RV32F_Xf16alt_Xfvec = '{
      Width: 32,
      EnableVectors: 1'b1,
      EnableNanBox: 1'b1,
      FpFmtMask: 5'b10001,
      IntFmtMask: 4'b0110
  };

  // Structure for FPU implementation
  typedef struct packed {
    opgrp_fmt_unsigned_t   PipeRegs;
    opgrp_fmt_unit_types_t UnitTypes;
    pipe_config_t          PipeConfig;
  } fpu_implementation_t;

  // Local parameters for different FPU implementations
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

  // Local parameter for don't care logic
  parameter logic DONT_CARE = 1'b1;

  // Function to get the minimum of two integers
  function automatic int minimum(int a, int b);
    return (a < b) ? a : b;
  endfunction

  // Function to get the maximum of two integers
  function automatic int maximum(int a, int b);
    return (a > b) ? a : b;
  endfunction

  // Function to get the width of a floating-point format
  function automatic int unsigned fp_width(fp_format_e fmt);
    case (fmt)
      FP32:    return 32;
      FP64:    return 64;
      FP16:    return 16;
      FP8:     return 8;
      FP16ALT: return 16;
    endcase
  endfunction

  // Function to get the maximum width of floating-point formats
  function automatic int unsigned max_fp_width(fmt_logic_t cfg);
    automatic int unsigned res = 0;
    for (int unsigned i = 0; i < NUM_FP_FORMATS; i++)
    if (cfg[i]) res = unsigned'(maximum(res, fp_width(fp_format_e'(i))));
    return res;
  endfunction

  // Function to get the minimum width of floating-point formats
  function automatic int unsigned min_fp_width(fmt_logic_t cfg);
    automatic int unsigned res = max_fp_width(cfg);
    for (int unsigned i = 0; i < NUM_FP_FORMATS; i++)
    if (cfg[i]) res = unsigned'(minimum(res, fp_width(fp_format_e'(i))));
    return res;
  endfunction

  // Function to get the exponent bits of a floating-point format
  function automatic int unsigned exp_bits(fp_format_e fmt);
    case (fmt)
      FP32:    return 8;
      FP64:    return 11;
      FP16:    return 5;
      FP8:     return 5;
      FP16ALT: return 8;
    endcase
  endfunction

  // Function to get the mantissa bits of a floating-point format
  function automatic int unsigned man_bits(fp_format_e fmt);
    case (fmt)
      FP32:    return 23;
      FP64:    return 52;
      FP16:    return 10;
      FP8:     return 2;
      FP16ALT: return 7;
    endcase
  endfunction

  // Function to get the bias of a floating-point format
  function automatic int unsigned bias(fp_format_e fmt);
    case (fmt)
      FP32:    return 127;
      FP64:    return 1023;
      FP16:    return 15;
      FP8:     return 15;
      FP16ALT: return 127;
    endcase
  endfunction

  // Function to get the super format of floating-point formats
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

  // Function to get the maximum integer width
  function automatic int unsigned max_int_width(ifmt_logic_t cfg);
    automatic int unsigned res = 0;
    for (int ifmt = 0; ifmt < NUM_INT_FORMATS; ifmt++) begin
      if (cfg[ifmt]) res = maximum(res, int_width(int_format_e'(ifmt)));
    end
    return res;
  endfunction

  // Function to get the operation group of an operation
  function automatic opgroup_e get_opgroup(operation_e op);
    unique case (op)
      FMADD, FNMSUB, ADD, MUL:     return ADDMUL;
      DIV, SQRT:                   return DIVSQRT;
      SGNJ, MINMAX, CMP, CLASSIFY: return NONCOMP;
      F2F, F2I, I2F, CPKAB, CPKCD: return CONV;
      default:                     return NONCOMP;
    endcase
  endfunction

  // Function to get the number of operands for an operation group
  function automatic int unsigned num_operands(opgroup_e grp);
    unique case (grp)
      ADDMUL:  return 3;
      DIVSQRT: return 2;
      NONCOMP: return 2;
      CONV:    return 3;
      default: return 0;
    endcase
  endfunction

  // Function to get the number of lanes for a format
  function automatic int unsigned num_lanes(int unsigned width, fp_format_e fmt, logic vec);
    return vec ? width / fp_width(fmt) : 1;
  endfunction

  // Function to get the maximum number of lanes for formats
  function automatic int unsigned max_num_lanes(int unsigned width, fmt_logic_t cfg, logic vec);
    return vec ? width / min_fp_width(cfg) : 1;
  endfunction

  // Function to get the lane formats for a given lane number
  function automatic fmt_logic_t get_lane_formats(int unsigned width, fmt_logic_t cfg,
                                                  int unsigned lane_no);
    automatic fmt_logic_t res;
    for (int unsigned fmt = 0; fmt < NUM_FP_FORMATS; fmt++)
    res[fmt] = cfg[fmt] & (width / fp_width(fp_format_e'(fmt)) > lane_no);
    return res;
  endfunction

  // Function to get the lane integer formats for a given lane number
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

  // Function to get the conversion lane formats for a given lane number
  function automatic fmt_logic_t get_conv_lane_formats(int unsigned width, fmt_logic_t cfg,
                                                       int unsigned lane_no);
    automatic fmt_logic_t res;
    for (int unsigned fmt = 0; fmt < NUM_FP_FORMATS; fmt++)
    res[fmt] = cfg[fmt] &&
        ((width / fp_width(fp_format_e'(fmt)) > lane_no) || (CPK_FORMATS[fmt] && (lane_no < 2)));
    return res;
  endfunction

  // Function to get the conversion lane integer formats for a given lane number
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

  // Function to check if any multi-format is enabled
  function automatic logic any_enabled_multi(fmt_unit_types_t types, fmt_logic_t cfg);
    for (int unsigned i = 0; i < NUM_FP_FORMATS; i++) if (cfg[i] && types[i] == MERGED) return 1'b1;
    return 1'b0;
  endfunction

  // Function to check if the first enabled multi-format is the given format
  function automatic logic is_first_enabled_multi(fp_format_e fmt, fmt_unit_types_t types,
                                                  fmt_logic_t cfg);
    for (int unsigned i = 0; i < NUM_FP_FORMATS; i++) begin
      if (cfg[i] && types[i] == MERGED) return (fp_format_e'(i) == fmt);
    end
    return 1'b0;
  endfunction

  // Function to get the first enabled multi-format
  function automatic fp_format_e get_first_enabled_multi(fmt_unit_types_t types, fmt_logic_t cfg);
    for (int unsigned i = 0; i < NUM_FP_FORMATS; i++)
    if (cfg[i] && types[i] == MERGED) return fp_format_e'(i);
    return fp_format_e'(0);
  endfunction

  // Function to get the number of registers for multi-formats
  function automatic int unsigned get_num_regs_multi(fmt_unsigned_t regs, fmt_unit_types_t types,
                                                     fmt_logic_t cfg);
    automatic int unsigned res = 0;
    for (int unsigned i = 0; i < NUM_FP_FORMATS; i++) begin
      if (cfg[i] && types[i] == MERGED) res = maximum(res, regs[i]);
    end
    return res;
  endfunction

endpackage
