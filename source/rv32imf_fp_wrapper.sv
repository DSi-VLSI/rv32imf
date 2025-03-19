module rv32imf_fp_wrapper
  import rv32imf_apu_core_pkg::*;
#(
) (

    input logic clk_i,
    input logic rst_ni,


    input  logic apu_req_i,
    output logic apu_gnt_o,


    input logic [   APU_NARGS_CPU-1:0][31:0] apu_operands_i,
    input logic [     APU_WOP_CPU-1:0]       apu_op_i,
    input logic [APU_NDSFLAGS_CPU-1:0]       apu_flags_i,


    output logic                        apu_rvalid_o,
    output logic [                31:0] apu_rdata_o,
    output logic [APU_NUSFLAGS_CPU-1:0] apu_rflags_o
);


  import rv32imf_pkg::*;
  import fpnew_pkg::*;

  logic [        fpnew_pkg::OP_BITS-1:0] fpu_op;
  logic                                  fpu_op_mod;
  logic                                  fpu_vec_op;

  logic [ fpnew_pkg::FP_FORMAT_BITS-1:0] fpu_dst_fmt;
  logic [ fpnew_pkg::FP_FORMAT_BITS-1:0] fpu_src_fmt;
  logic [fpnew_pkg::INT_FORMAT_BITS-1:0] fpu_int_fmt;
  logic [                      C_RM-1:0] fp_rnd_mode;




  assign {fpu_vec_op, fpu_op_mod, fpu_op}                     = apu_op_i;

  assign {fpu_int_fmt, fpu_src_fmt, fpu_dst_fmt, fp_rnd_mode} = apu_flags_i;







  localparam fpnew_pkg::fpu_features_t FPU_FEATURES = '{
      Width: C_FLEN,
      EnableVectors: C_XFVEC,
      EnableNanBox: 1'b0,
      FpFmtMask: {C_RVF, C_RVD, C_XF16, C_XF8, C_XF16ALT},
      IntFmtMask: {C_XFVEC && C_XF8, C_XFVEC && (C_XF16 || C_XF16ALT), 1'b1, 1'b0}
  };


  localparam fpnew_pkg::fpu_implementation_t FPU_IMPLEMENTATION = '{
      PipeRegs: '{
          '{0, C_LAT_FP64, C_LAT_FP16, C_LAT_FP8, C_LAT_FP16ALT},
          '{default: C_LAT_DIVSQRT},
          '{default: 0},
          '{default: 0}
      },
      UnitTypes: '{
          '{default: fpnew_pkg::MERGED},
          '{default: fpnew_pkg::MERGED},
          '{default: fpnew_pkg::PARALLEL},
          '{default: fpnew_pkg::MERGED}
      },
      PipeConfig: fpnew_pkg::AFTER
  };





  fpnew_top #(
      .Features      (FPU_FEATURES),
      .Implementation(FPU_IMPLEMENTATION),
      .PulpDivsqrt   (1'b0),
      .TagType       (logic)
  ) i_fpnew_bulk (
      .clk_i         (clk_i),
      .rst_ni        (rst_ni),
      .operands_i    (apu_operands_i),
      .rnd_mode_i    (fpnew_pkg::roundmode_e'(fp_rnd_mode)),
      .op_i          (fpnew_pkg::operation_e'(fpu_op)),
      .op_mod_i      (fpu_op_mod),
      .src_fmt_i     (fpnew_pkg::fp_format_e'(fpu_src_fmt)),
      .dst_fmt_i     (fpnew_pkg::fp_format_e'(fpu_dst_fmt)),
      .int_fmt_i     (fpnew_pkg::int_format_e'(fpu_int_fmt)),
      .vectorial_op_i(fpu_vec_op),
      .tag_i         (1'b0),
      .simd_mask_i   (1'b0),
      .in_valid_i    (apu_req_i),
      .in_ready_o    (apu_gnt_o),
      .flush_i       (1'b0),
      .result_o      (apu_rdata_o),
      .status_o      (apu_rflags_o),
      .tag_o         (),
      .out_valid_o   (apu_rvalid_o),
      .out_ready_i   (1'b1),
      .busy_o        ()
  );

endmodule

