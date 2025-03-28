module rv32imf_fp_wrapper #(
) (
    input logic clk_i,  // Clock input
    input logic rst_ni, // Asynchronous reset input (active low)

    input  logic apu_req_i,  // APU request input
    output logic apu_gnt_o,  // APU grant output

    input logic [ 2:0][31:0] apu_operands_i,  // APU operands input
    input logic [ 5:0]       apu_op_i,        // APU operation code input
    input logic [14:0]       apu_flags_i,     // APU flags input

    output logic        apu_rvalid_o,  // APU result valid output
    output logic [31:0] apu_rdata_o,   // APU result data output
    output logic [ 4:0] apu_rflags_o   // APU result flags output
);

  import rv32imf_pkg::*;  // Import package from rv32imf
  import fpnew_pkg::*;  // Import package from fpnew

  logic [        fpnew_pkg::OP_BITS-1:0] fpu_op;  // FPU operation code
  logic                                  fpu_op_mod;  // FPU operation modifier
  logic                                  fpu_vec_op;  // FPU vector operation flag

  logic [ fpnew_pkg::FP_FORMAT_BITS-1:0] fpu_dst_fmt;  // FPU destination format
  logic [ fpnew_pkg::FP_FORMAT_BITS-1:0] fpu_src_fmt;  // FPU source format
  logic [fpnew_pkg::INT_FORMAT_BITS-1:0] fpu_int_fmt;  // FPU integer format
  logic [                      C_RM-1:0] fp_rnd_mode;  // Floating-point rounding mode

  assign {fpu_vec_op, fpu_op_mod, fpu_op} = apu_op_i;  // Decode APU operation

  assign {fpu_int_fmt, fpu_src_fmt, fpu_dst_fmt, fp_rnd_mode} = apu_flags_i;  // Decode APU flags

  localparam fpnew_pkg::fpu_features_t FpuFeatures = '{  // Define FPU features
      Width: C_FLEN,  // Floating-point data width
      EnableVectors: C_XFVEC,  // Enable vector floating-point
      EnableNanBox: 1'b0,  // Disable NaN boxing
      FpFmtMask: {C_RVF, C_RVD, C_XF16, C_XF8, C_XF16ALT},  // Supported FP formats
      IntFmtMask: {
        C_XFVEC && C_XF8, C_XFVEC && (C_XF16 || C_XF16ALT), 1'b1, 1'b0
      }  // Supported int formats
  };

  localparam fpnew_pkg::fpu_implementation_t FpuImplementation = '{  // Define FPU implementation
      PipeRegs: '{  // Pipeline register configuration
          '{0, C_LAT_FP64, C_LAT_FP16, C_LAT_FP8, C_LAT_FP16ALT},  // Latencies for FP formats
          '{default: C_LAT_DIVSQRT},  // Default latency for div/sqrt
          '{default: 0},  // Default latency
          '{default: 0}  // Default latency
      },
      UnitTypes: '{  // Functional unit types
          '{default: fpnew_pkg::MERGED},  // Default unit type is merged
          '{default: fpnew_pkg::MERGED},  // Default unit type is merged
          '{default: fpnew_pkg::PARALLEL},  // Default unit type is parallel
          '{default: fpnew_pkg::MERGED}  // Default unit type is merged
      },
      PipeConfig: fpnew_pkg::AFTER  // Pipeline configuration
  };

  fpnew_top #(  // Instantiate the fpnew top module
      .Features      (FpuFeatures),        // Pass FPU features
      .Implementation(FpuImplementation),  // Pass FPU implementation
      .PulpDivsqrt   (1'b0),               // Disable Pulp-style div/sqrt
      .TagType       (logic)               // Tag type for the pipeline
  ) i_fpnew_bulk (
      .clk_i         (clk_i),                                  // Connect clock input
      .rst_ni        (rst_ni),                                 // Connect reset input
      .operands_i    (apu_operands_i),                         // Connect input operands
      .rnd_mode_i    (fpnew_pkg::roundmode_e'(fp_rnd_mode)),   // Connect rounding mode
      .op_i          (fpnew_pkg::operation_e'(fpu_op)),        // Connect operation code
      .op_mod_i      (fpu_op_mod),                             // Connect operation modifier
      .src_fmt_i     (fpnew_pkg::fp_format_e'(fpu_src_fmt)),   // Connect source format
      .dst_fmt_i     (fpnew_pkg::fp_format_e'(fpu_dst_fmt)),   // Connect destination format
      .int_fmt_i     (fpnew_pkg::int_format_e'(fpu_int_fmt)),  // Connect integer format
      .vectorial_op_i(fpu_vec_op),                             // Connect vector operation flag
      .tag_i         (1'b0),                                   // Connect tag input
      .simd_mask_i   (1'b0),                                   // Connect SIMD mask input
      .in_valid_i    (apu_req_i),                              // Connect input valid signal
      .in_ready_o    (apu_gnt_o),                              // Connect input ready signal
      .flush_i       (1'b0),                                   // Connect flush signal
      .result_o      (apu_rdata_o),                            // Connect result output
      .status_o      (apu_rflags_o),                           // Connect status output
      .tag_o         (),                                       // Connect tag output
      .out_valid_o   (apu_rvalid_o),                           // Connect output valid signal
      .out_ready_i   (1'b1),                                   // Connect output ready signal
      .busy_o        ()                                        // Connect busy output
  );

endmodule
