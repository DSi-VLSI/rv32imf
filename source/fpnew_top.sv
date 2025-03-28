module fpnew_top #(
    // FPU features parameter
    parameter fpnew_pkg::fpu_features_t       Features       = fpnew_pkg::RV64D_XSFLT,
    // FPU implementation parameter
    parameter fpnew_pkg::fpu_implementation_t Implementation = fpnew_pkg::DEFAULT_NOREGS,

    parameter logic        PulpDivsqrt    = 1'b1,   // Enable Pulp-style division and square root
    parameter type         TagType        = logic,  // Data type for tags
    parameter int unsigned TrueSIMDClass  = 0,      // Parameter for true SIMD class
    parameter int unsigned EnableSIMDMask = 0,      // Enable SIMD mask functionality

    localparam int unsigned NumLanes = fpnew_pkg::max_num_lanes(  // Calculate number of lanes
        Features.Width, Features.FpFmtMask, Features.EnableVectors
    ),
    localparam type MaskType = logic [NumLanes-1:0],  // Define mask type based on number of lanes
    localparam int unsigned WIDTH = Features.Width,  // Local parameter for data width
    localparam int unsigned NumOperands = 3  // Local parameter for number of operands
) (
    input logic clk_i,  // Clock input
    input logic rst_ni, // Asynchronous reset input (active low)

    input logic [NumOperands-1:0][WIDTH-1:0] operands_i,  // Input operands
    input fpnew_pkg::roundmode_e rnd_mode_i,  // Rounding mode input
    input fpnew_pkg::operation_e op_i,  // Operation code input
    input logic op_mod_i,  // Operation modifier input
    input fpnew_pkg::fp_format_e src_fmt_i,  // Source format input
    input fpnew_pkg::fp_format_e dst_fmt_i,  // Destination format input
    input fpnew_pkg::int_format_e int_fmt_i,  // Integer format input
    input logic vectorial_op_i,  // Vectorial operation flag
    input TagType tag_i,  // Tag input
    input MaskType simd_mask_i,  // SIMD mask input

    input  logic in_valid_i,  // Input valid signal
    output logic in_ready_o,  // Input ready signal
    input  logic flush_i,     // Flush signal

    output logic               [WIDTH-1:0] result_o,  // Result output
    output fpnew_pkg::status_t             status_o,  // Status output
    output TagType                         tag_o,     // Tag output

    output logic out_valid_o,  // Output valid signal
    input  logic out_ready_i,  // Output ready signal

    output logic busy_o  // Busy signal
);

  // Number of operation groups
  localparam int unsigned NumOpgroups = fpnew_pkg::NUM_OPGROUPS;
  // Number of floating-point formats
  localparam int unsigned NumFormats = fpnew_pkg::NUM_FP_FORMATS;

  typedef struct packed {  // Define output structure
    logic [WIDTH-1:0]   result;  // Result data
    fpnew_pkg::status_t status;  // Status flags
    TagType             tag;     // Tag
  } output_t;

  logic [NumOpgroups-1:0] opgrp_in_ready, opgrp_out_valid, opgrp_out_ready, opgrp_ext, opgrp_busy;
  output_t [NumOpgroups-1:0] opgrp_outputs;

  logic [NumFormats-1:0][NumOperands-1:0] is_boxed;

  assign in_ready_o = in_valid_i & opgrp_in_ready[fpnew_pkg::get_opgroup(
          op_i
      )];  // Input ready logic

  for (
      genvar fmt = 0; fmt < int'(NumFormats); fmt++
  ) begin : gen_nanbox_check  // Check for NaN boxing
    localparam int unsigned FpWidth = fpnew_pkg::fp_width(
        fpnew_pkg::fp_format_e'(fmt)
    );  // Get FP width

    // Check if NaN boxing is enabled
    if (Features.EnableNanBox && (FpWidth < WIDTH)) begin : g_check
      for (
          genvar op = 0; op < int'(NumOperands); op++
      ) begin : g_operands  // Iterate through operands
        assign is_boxed[fmt][op] = (!vectorial_op_i) ?  // Check if operand is NaN boxed
            operands_i[op][WIDTH-1:FpWidth] == '1 : 1'b1;
      end
    end else begin : g_no_check
      assign is_boxed[fmt] = '1;  // If no NaN boxing, all are boxed
    end
  end

  MaskType simd_mask;  // Declare SIMD mask
  assign simd_mask = simd_mask_i | ~{NumLanes{logic'(EnableSIMDMask)}};  // Apply SIMD mask

  for (
      genvar opgrp = 0; opgrp < int'(NumOpgroups); opgrp++
  ) begin : gen_operation_groups  // Iterate through op groups
    localparam int unsigned NumOps = fpnew_pkg::num_operands(
        fpnew_pkg::opgroup_e'(opgrp)
    );  // Get num operands

    logic in_valid;
    logic [NumFormats-1:0][NumOps-1:0] input_boxed;

    assign in_valid = in_valid_i & (fpnew_pkg::get_opgroup(
            op_i
        ) == fpnew_pkg::opgroup_e'(opgrp));  // Input valid for group

    always_comb begin : slice_inputs  // Slice inputs for each format
      for (int unsigned fmt = 0; fmt < NumFormats; fmt++)
      input_boxed[fmt] = is_boxed[fmt][NumOps-1:0];
    end

    fpnew_opgroup_block #(  // Instantiate operation group block
        .OpGroup      (fpnew_pkg::opgroup_e'(opgrp)),     // Operation group
        .Width        (WIDTH),                            // Data width
        .EnableVectors(Features.EnableVectors),           // Enable vectors
        .PulpDivsqrt  (PulpDivsqrt),                      // Pulp-style div/sqrt
        .FpFmtMask    (Features.FpFmtMask),               // FP format mask
        .IntFmtMask   (Features.IntFmtMask),              // Integer format mask
        .FmtPipeRegs  (Implementation.PipeRegs[opgrp]),   // Pipe registers
        .FmtUnitTypes (Implementation.UnitTypes[opgrp]),  // Unit types
        .PipeConfig   (Implementation.PipeConfig),        // Pipeline config
        .TagType      (TagType),                          // Tag type
        .TrueSIMDClass(TrueSIMDClass)                     // True SIMD class
    ) i_opgroup_block (
        .clk_i,
        .rst_ni,
        .operands_i     (operands_i[NumOps-1:0]),       // Input operands
        .is_boxed_i     (input_boxed),                  // Input boxed flags
        .rnd_mode_i,  // Rounding mode
        .op_i,  // Operation code
        .op_mod_i,  // Operation modifier
        .src_fmt_i,  // Source format
        .dst_fmt_i,  // Destination format
        .int_fmt_i,  // Integer format
        .vectorial_op_i,  // Vectorial operation
        .tag_i,  // Tag input
        .simd_mask_i    (simd_mask),                    // SIMD mask
        .in_valid_i     (in_valid),                     // Input valid
        .in_ready_o     (opgrp_in_ready[opgrp]),        // Input ready
        .flush_i,  // Flush
        .result_o       (opgrp_outputs[opgrp].result),  // Result output
        .status_o       (opgrp_outputs[opgrp].status),  // Status output
        .extension_bit_o(opgrp_ext[opgrp]),             // Extension bit output
        .tag_o          (opgrp_outputs[opgrp].tag),     // Tag output
        .out_valid_o    (opgrp_out_valid[opgrp]),       // Output valid
        .out_ready_i    (opgrp_out_ready[opgrp]),       // Output ready
        .busy_o         (opgrp_busy[opgrp])             // Busy output
    );
  end

  output_t arbiter_output;  // Declare arbiter output

  rr_arb_tree #(  // Instantiate round-robin arbiter
      .NumIn    (NumOpgroups),  // Number of inputs
      .DataType (output_t),     // Data type
      .AxiVldRdy(1'b1)          // Use AXI valid/ready
  ) i_arbiter (
      .clk_i,
      .rst_ni,
      .flush_i,
      .rr_i  ('0),               // Round-robin input
      .req_i (opgrp_out_valid),  // Request inputs
      .gnt_o (opgrp_out_ready),  // Grant outputs
      .data_i(opgrp_outputs),    // Data inputs
      .gnt_i (out_ready_i),      // Grant input
      .req_o (out_valid_o),      // Request output
      .data_o(arbiter_output),   // Data output
      .idx_o ()                  // Index output
  );

  assign result_o = arbiter_output.result;  // Assign result output
  assign status_o = arbiter_output.status;  // Assign status output
  assign tag_o    = arbiter_output.tag;  // Assign tag output

  assign busy_o   = (|opgrp_busy);  // Assign busy output
endmodule
