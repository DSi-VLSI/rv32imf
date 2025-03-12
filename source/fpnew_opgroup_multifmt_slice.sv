`include "common_cells/registers.svh"

module fpnew_opgroup_multifmt_slice #(
  parameter fpnew_pkg::opgroup_e     OpGroup       = fpnew_pkg::CONV,
  parameter int unsigned             Width         = 64,

  parameter fpnew_pkg::fmt_logic_t   FpFmtConfig   = '1,
  parameter fpnew_pkg::ifmt_logic_t  IntFmtConfig  = '1,
  parameter logic                    EnableVectors = 1'b1,
  parameter logic                    PulpDivsqrt   = 1'b1,
  parameter int unsigned             NumPipeRegs   = 0,
  parameter fpnew_pkg::pipe_config_t PipeConfig    = fpnew_pkg::BEFORE,
  parameter logic                    ExtRegEna     = 1'b0,
  parameter type                     TagType       = logic,

  localparam int unsigned NUM_OPERANDS = fpnew_pkg::num_operands(OpGroup),
  localparam int unsigned NUM_FORMATS  = fpnew_pkg::NUM_FP_FORMATS,
  localparam int unsigned NUM_SIMD_LANES = fpnew_pkg::max_num_lanes(Width, FpFmtConfig, EnableVectors),
  localparam type         MaskType     = logic [NUM_SIMD_LANES-1:0],
  localparam int unsigned ExtRegEnaWidth = NumPipeRegs == 0 ? 1 : NumPipeRegs
) (
  input logic                                     clk_i,
  input logic                                     rst_ni,

  input logic [NUM_OPERANDS-1:0][Width-1:0]       operands_i,
  input logic [NUM_FORMATS-1:0][NUM_OPERANDS-1:0] is_boxed_i,
  input fpnew_pkg::roundmode_e                    rnd_mode_i,
  input fpnew_pkg::operation_e                    op_i,
  input logic                                     op_mod_i,
  input fpnew_pkg::fp_format_e                    src_fmt_i,
  input fpnew_pkg::fp_format_e                    dst_fmt_i,
  input fpnew_pkg::int_format_e                   int_fmt_i,
  input logic                                     vectorial_op_i,
  input TagType                                   tag_i,
  input MaskType                                  simd_mask_i,

  input  logic                                    in_valid_i,
  output logic                                    in_ready_o,
  input  logic                                    flush_i,

  output logic [Width-1:0]                        result_o,
  output fpnew_pkg::status_t                      status_o,
  output logic                                    extension_bit_o,
  output TagType                                  tag_o,

  output logic                                    out_valid_o,
  input  logic                                    out_ready_i,

  output logic                                    busy_o,

  input  logic [ExtRegEnaWidth-1:0]               reg_ena_i
);

  if ((OpGroup == fpnew_pkg::DIVSQRT) && !PulpDivsqrt &&
      !((FpFmtConfig[0] == 1) && (FpFmtConfig[1:NUM_FORMATS-1] == '0))) begin
    $fatal(1, "T-Head-based DivSqrt unit supported only in FP32-only configurations. \
Set PulpDivsqrt to 1 not to use the PULP DivSqrt unit \
or set Features.FpFmtMask to support only FP32");
  end

  localparam int unsigned MAX_FP_WIDTH   = fpnew_pkg::max_fp_width(FpFmtConfig);
  localparam int unsigned MAX_INT_WIDTH  = fpnew_pkg::max_int_width(IntFmtConfig);
  localparam int unsigned NUM_LANES = fpnew_pkg::max_num_lanes(Width, FpFmtConfig, 1'b1);
  localparam int unsigned NUM_INT_FORMATS = fpnew_pkg::NUM_INT_FORMATS;

  localparam int unsigned FMT_BITS =
      fpnew_pkg::maximum($clog2(NUM_FORMATS), $clog2(NUM_INT_FORMATS));
  localparam int unsigned AUX_BITS = FMT_BITS + 2;

  logic [NUM_LANES-1:0] lane_in_ready, lane_out_valid, divsqrt_done, divsqrt_ready;
  logic                 vectorial_op;
  logic [FMT_BITS-1:0]  dst_fmt;
  logic [AUX_BITS-1:0]  aux_data;


  logic       dst_fmt_is_int, dst_is_cpk;
  logic [1:0] dst_vec_op;
  logic [2:0] target_aux_d;
  logic       is_up_cast, is_down_cast;

  logic [NUM_FORMATS-1:0][Width-1:0]     fmt_slice_result;
  logic [NUM_INT_FORMATS-1:0][Width-1:0] ifmt_slice_result;

  logic [Width-1:0] conv_target_d, conv_target_q;

  fpnew_pkg::status_t [NUM_LANES-1:0]   lane_status;
  logic   [NUM_LANES-1:0]               lane_ext_bit;
  TagType [NUM_LANES-1:0]               lane_tags;
  logic   [NUM_LANES-1:0]               lane_masks;
  logic   [NUM_LANES-1:0][AUX_BITS-1:0] lane_aux;
  logic   [NUM_LANES-1:0]               lane_busy;

  logic                result_is_vector;
  logic [FMT_BITS-1:0] result_fmt;
  logic                result_fmt_is_int, result_is_cpk;
  logic [1:0]          result_vec_op;

  logic simd_synch_rdy, simd_synch_done;




  assign in_ready_o   = lane_in_ready[0];
  assign vectorial_op = vectorial_op_i & EnableVectors;


  assign dst_fmt_is_int = (OpGroup == fpnew_pkg::CONV) & (op_i == fpnew_pkg::F2I);
  assign dst_is_cpk     = (OpGroup == fpnew_pkg::CONV) & (op_i == fpnew_pkg::CPKAB ||
                                                          op_i == fpnew_pkg::CPKCD);
  assign dst_vec_op     = (OpGroup == fpnew_pkg::CONV) & {(op_i == fpnew_pkg::CPKCD), op_mod_i};

  assign is_up_cast   = (fpnew_pkg::fp_width(dst_fmt_i) > fpnew_pkg::fp_width(src_fmt_i));
  assign is_down_cast = (fpnew_pkg::fp_width(dst_fmt_i) < fpnew_pkg::fp_width(src_fmt_i));


  assign dst_fmt    = dst_fmt_is_int ? int_fmt_i : dst_fmt_i;


  assign aux_data      = {dst_fmt_is_int, vectorial_op, dst_fmt};
  assign target_aux_d  = {dst_vec_op, dst_is_cpk};


  if (OpGroup == fpnew_pkg::CONV) begin : conv_target
    assign conv_target_d = dst_is_cpk ? operands_i[2] : operands_i[1];
  end else begin : not_conv_target
    assign conv_target_d = '0;
  end


  logic [NUM_FORMATS-1:0]      is_boxed_1op;
  logic [NUM_FORMATS-1:0][1:0] is_boxed_2op;

  always_comb begin : boxed_2op
    for (int fmt = 0; fmt < NUM_FORMATS; fmt++) begin
      is_boxed_1op[fmt] = is_boxed_i[fmt][0];
      is_boxed_2op[fmt] = is_boxed_i[fmt][1:0];
    end
  end




  for (genvar lane = 0; lane < int'(NUM_LANES); lane++) begin : gen_num_lanes
    localparam int unsigned LANE = unsigned'(lane);

    localparam fpnew_pkg::fmt_logic_t ACTIVE_FORMATS =
        fpnew_pkg::get_lane_formats(Width, FpFmtConfig, LANE);
    localparam fpnew_pkg::ifmt_logic_t ACTIVE_INT_FORMATS =
        fpnew_pkg::get_lane_int_formats(Width, FpFmtConfig, IntFmtConfig, LANE);
    localparam int unsigned MAX_WIDTH = fpnew_pkg::max_fp_width(ACTIVE_FORMATS);


    localparam fpnew_pkg::fmt_logic_t CONV_FORMATS =
        fpnew_pkg::get_conv_lane_formats(Width, FpFmtConfig, LANE);
    localparam fpnew_pkg::ifmt_logic_t CONV_INT_FORMATS =
        fpnew_pkg::get_conv_lane_int_formats(Width, FpFmtConfig, IntFmtConfig, LANE);
    localparam int unsigned CONV_WIDTH = fpnew_pkg::max_fp_width(CONV_FORMATS);


    localparam fpnew_pkg::fmt_logic_t LANE_FORMATS = (OpGroup == fpnew_pkg::CONV)
                                                     ? CONV_FORMATS : ACTIVE_FORMATS;
    localparam int unsigned LANE_WIDTH = (OpGroup == fpnew_pkg::CONV) ? CONV_WIDTH : MAX_WIDTH;

    logic [LANE_WIDTH-1:0] local_result;


    if ((lane == 0) || EnableVectors) begin : active_lane
      logic in_valid, out_valid, out_ready;

      logic [NUM_OPERANDS-1:0][LANE_WIDTH-1:0] local_operands;
      logic [LANE_WIDTH-1:0]                   op_result;
      fpnew_pkg::status_t                      op_status;

      assign in_valid = in_valid_i & ((lane == 0) | vectorial_op);


      always_comb begin : prepare_input
        for (int unsigned i = 0; i < NUM_OPERANDS; i++) begin
          if (i == 2) begin
            local_operands[i] = operands_i[i] >> LANE*fpnew_pkg::fp_width(dst_fmt_i);
          end else begin
            local_operands[i] = operands_i[i] >> LANE*fpnew_pkg::fp_width(src_fmt_i);
          end
        end


        if (OpGroup == fpnew_pkg::CONV) begin

          if (op_i == fpnew_pkg::I2F) begin
            local_operands[0] = operands_i[0] >> LANE*fpnew_pkg::int_width(int_fmt_i);

          end else if (op_i == fpnew_pkg::F2F) begin
            if (vectorial_op && op_mod_i && is_up_cast) begin
              local_operands[0] = operands_i[0] >> LANE*fpnew_pkg::fp_width(src_fmt_i) +
                                                   MAX_FP_WIDTH/2;
            end

          end else if (dst_is_cpk) begin
            if (lane == 1) begin
              local_operands[0] = operands_i[1][LANE_WIDTH-1:0];
            end
          end
        end
      end


      if (OpGroup == fpnew_pkg::ADDMUL) begin : lane_instance
        fpnew_fma_multi #(
          .FpFmtConfig ( LANE_FORMATS         ),
          .NumPipeRegs ( NumPipeRegs          ),
          .PipeConfig  ( PipeConfig           ),
          .TagType     ( TagType              ),
          .AuxType     ( logic [AUX_BITS-1:0] )
        ) i_fpnew_fma_multi (
          .clk_i,
          .rst_ni,
          .operands_i      ( local_operands  ),
          .is_boxed_i,
          .rnd_mode_i,
          .op_i,
          .op_mod_i,
          .src_fmt_i,
          .dst_fmt_i,
          .tag_i,
          .mask_i          ( simd_mask_i[lane]   ),
          .aux_i           ( aux_data            ),
          .in_valid_i      ( in_valid            ),
          .in_ready_o      ( lane_in_ready[lane] ),
          .flush_i,
          .result_o        ( op_result           ),
          .status_o        ( op_status           ),
          .extension_bit_o ( lane_ext_bit[lane]  ),
          .tag_o           ( lane_tags[lane]     ),
          .mask_o          ( lane_masks[lane]    ),
          .aux_o           ( lane_aux[lane]      ),
          .out_valid_o     ( out_valid           ),
          .out_ready_i     ( out_ready           ),
          .busy_o          ( lane_busy[lane]     ),
          .reg_ena_i
        );

      end else if (OpGroup == fpnew_pkg::DIVSQRT) begin : lane_instance
        if (!PulpDivsqrt && LANE_FORMATS[0] && (LANE_FORMATS[1:fpnew_pkg::NUM_FP_FORMATS-1] == '0)) begin

          fpnew_divsqrt_th_32 #(
            .NumPipeRegs ( NumPipeRegs          ),
            .PipeConfig  ( PipeConfig           ),
            .TagType     ( TagType              ),
            .AuxType     ( logic [AUX_BITS-1:0] )
          ) i_fpnew_divsqrt_multi_th (
            .clk_i,
            .rst_ni,
            .operands_i      ( local_operands[1:0] ),
            .is_boxed_i      ( is_boxed_2op        ),
            .rnd_mode_i,
            .op_i,
            .tag_i,
            .mask_i          ( simd_mask_i[lane]   ),
            .aux_i           ( aux_data            ),
            .in_valid_i      ( in_valid            ),
            .in_ready_o      ( lane_in_ready[lane] ),
            .flush_i,
            .result_o        ( op_result           ),
            .status_o        ( op_status           ),
            .extension_bit_o ( lane_ext_bit[lane]  ),
            .tag_o           ( lane_tags[lane]     ),
            .mask_o          ( lane_masks[lane]    ),
            .aux_o           ( lane_aux[lane]      ),
            .out_valid_o     ( out_valid           ),
            .out_ready_i     ( out_ready           ),
            .busy_o          ( lane_busy[lane]     ),
            .reg_ena_i
          );
        end else begin
          fpnew_divsqrt_multi #(
            .FpFmtConfig ( LANE_FORMATS         ),
            .NumPipeRegs ( NumPipeRegs          ),
            .PipeConfig  ( PipeConfig           ),
            .TagType     ( TagType              ),
            .AuxType     ( logic [AUX_BITS-1:0] )
          ) i_fpnew_divsqrt_multi (
            .clk_i,
            .rst_ni,
            .operands_i       ( local_operands[1:0] ),
            .is_boxed_i       ( is_boxed_2op        ),
            .rnd_mode_i,
            .op_i,
            .dst_fmt_i,
            .tag_i,
            .mask_i           ( simd_mask_i[lane]   ),
            .aux_i            ( aux_data            ),
            .vectorial_op_i   ( vectorial_op        ),
            .in_valid_i       ( in_valid            ),
            .in_ready_o       ( lane_in_ready[lane] ),
            .divsqrt_done_o   ( divsqrt_done[lane]  ),
            .simd_synch_done_i( simd_synch_done     ),
            .divsqrt_ready_o  ( divsqrt_ready[lane] ),
            .simd_synch_rdy_i ( simd_synch_rdy      ),
            .flush_i,
            .result_o         ( op_result           ),
            .status_o         ( op_status           ),
            .extension_bit_o  ( lane_ext_bit[lane]  ),
            .tag_o            ( lane_tags[lane]     ),
            .mask_o           ( lane_masks[lane]    ),
            .aux_o            ( lane_aux[lane]      ),
            .out_valid_o      ( out_valid           ),
            .out_ready_i      ( out_ready           ),
            .busy_o           ( lane_busy[lane]     ),
            .reg_ena_i
          );
        end
      end else if (OpGroup == fpnew_pkg::NONCOMP) begin : lane_instance

      end else if (OpGroup == fpnew_pkg::CONV) begin : lane_instance
        fpnew_cast_multi #(
          .FpFmtConfig  ( LANE_FORMATS         ),
          .IntFmtConfig ( CONV_INT_FORMATS     ),
          .NumPipeRegs  ( NumPipeRegs          ),
          .PipeConfig   ( PipeConfig           ),
          .TagType      ( TagType              ),
          .AuxType      ( logic [AUX_BITS-1:0] )
        ) i_fpnew_cast_multi (
          .clk_i,
          .rst_ni,
          .operands_i      ( local_operands[0]   ),
          .is_boxed_i      ( is_boxed_1op        ),
          .rnd_mode_i,
          .op_i,
          .op_mod_i,
          .src_fmt_i,
          .dst_fmt_i,
          .int_fmt_i,
          .tag_i,
          .mask_i          ( simd_mask_i[lane]   ),
          .aux_i           ( aux_data            ),
          .in_valid_i      ( in_valid            ),
          .in_ready_o      ( lane_in_ready[lane] ),
          .flush_i,
          .result_o        ( op_result           ),
          .status_o        ( op_status           ),
          .extension_bit_o ( lane_ext_bit[lane]  ),
          .tag_o           ( lane_tags[lane]     ),
          .mask_o          ( lane_masks[lane]    ),
          .aux_o           ( lane_aux[lane]      ),
          .out_valid_o     ( out_valid           ),
          .out_ready_i     ( out_ready           ),
          .busy_o          ( lane_busy[lane]     ),
          .reg_ena_i
        );
      end


      assign out_ready            = out_ready_i & ((lane == 0) | result_is_vector);
      assign lane_out_valid[lane] = out_valid & ((lane == 0) | result_is_vector);


      assign local_result      = (lane_out_valid[lane] | ExtRegEna) ? op_result : '{default: lane_ext_bit[0]};
      assign lane_status[lane] = (lane_out_valid[lane] | ExtRegEna) ? op_status : '0;


    end else begin : inactive_lane
      assign lane_out_valid[lane] = 1'b0;
      assign lane_in_ready[lane]  = 1'b0;
      assign lane_aux[lane]       = 1'b0;
      assign lane_masks[lane]     = 1'b1;
      assign lane_tags[lane]      = 1'b0;
      assign divsqrt_done[lane]   = 1'b0;
      assign divsqrt_ready[lane]  = 1'b0;
      assign lane_ext_bit[lane]   = 1'b1;
      assign local_result         = {(LANE_WIDTH){lane_ext_bit[0]}};
      assign lane_status[lane]    = '0;
      assign lane_busy[lane]      = 1'b0;
    end


    for (genvar fmt = 0; fmt < NUM_FORMATS; fmt++) begin : pack_fp_result

      localparam int unsigned FP_WIDTH = fpnew_pkg::fp_width(fpnew_pkg::fp_format_e'(fmt));

      if (ACTIVE_FORMATS[fmt]) begin
        assign fmt_slice_result[fmt][(LANE+1)*FP_WIDTH-1:LANE*FP_WIDTH] =
            local_result[FP_WIDTH-1:0];
      end else if ((LANE+1)*FP_WIDTH <= Width) begin
        assign fmt_slice_result[fmt][(LANE+1)*FP_WIDTH-1:LANE*FP_WIDTH] =
            '{default: lane_ext_bit[LANE]};
      end else if (LANE*FP_WIDTH < Width) begin
        assign fmt_slice_result[fmt][Width-1:LANE*FP_WIDTH] =
            '{default: lane_ext_bit[LANE]};
      end
    end


    if (OpGroup == fpnew_pkg::CONV) begin : int_results_enabled
      for (genvar ifmt = 0; ifmt < NUM_INT_FORMATS; ifmt++) begin : pack_int_result

        localparam int unsigned INT_WIDTH = fpnew_pkg::int_width(fpnew_pkg::int_format_e'(ifmt));
        if (ACTIVE_INT_FORMATS[ifmt]) begin
          assign ifmt_slice_result[ifmt][(LANE+1)*INT_WIDTH-1:LANE*INT_WIDTH] =
            local_result[INT_WIDTH-1:0];
        end else if ((LANE+1)*INT_WIDTH <= Width) begin
          assign ifmt_slice_result[ifmt][(LANE+1)*INT_WIDTH-1:LANE*INT_WIDTH] = '0;
        end else if (LANE*INT_WIDTH < Width) begin
          assign ifmt_slice_result[ifmt][Width-1:LANE*INT_WIDTH] = '0;
        end
      end
    end
  end


  for (genvar fmt = 0; fmt < NUM_FORMATS; fmt++) begin : extend_fp_result

    localparam int unsigned FP_WIDTH = fpnew_pkg::fp_width(fpnew_pkg::fp_format_e'(fmt));
    if (NUM_LANES*FP_WIDTH < Width)
      assign fmt_slice_result[fmt][Width-1:NUM_LANES*FP_WIDTH] = '{default: lane_ext_bit[0]};
  end

  for (genvar ifmt = 0; ifmt < NUM_INT_FORMATS; ifmt++) begin : extend_or_mute_int_result

    if (OpGroup != fpnew_pkg::CONV) begin : mute_int_result
      assign ifmt_slice_result[ifmt] = '0;


    end else begin : extend_int_result

      localparam int unsigned INT_WIDTH = fpnew_pkg::int_width(fpnew_pkg::int_format_e'(ifmt));
      if (NUM_LANES*INT_WIDTH < Width)
        assign ifmt_slice_result[ifmt][Width-1:NUM_LANES*INT_WIDTH] = '0;
    end
  end


  if (OpGroup == fpnew_pkg::CONV) begin : target_regs

    logic [0:NumPipeRegs][Width-1:0] byp_pipe_target_q;
    logic [0:NumPipeRegs][2:0]       byp_pipe_aux_q;
    logic [0:NumPipeRegs]            byp_pipe_valid_q;

    logic [0:NumPipeRegs] byp_pipe_ready;


    assign byp_pipe_target_q[0]  = conv_target_d;
    assign byp_pipe_aux_q[0]     = target_aux_d;
    assign byp_pipe_valid_q[0]   = in_valid_i & vectorial_op;

    for (genvar i = 0; i < NumPipeRegs; i++) begin : gen_bypass_pipeline

      logic reg_ena;



      assign byp_pipe_ready[i] = byp_pipe_ready[i+1] | ~byp_pipe_valid_q[i+1];

      `FFLARNC(byp_pipe_valid_q[i+1], byp_pipe_valid_q[i], byp_pipe_ready[i], flush_i, 1'b0, clk_i, rst_ni)

      assign reg_ena = (byp_pipe_ready[i] & byp_pipe_valid_q[i]) | reg_ena_i[i];

      `FFL(byp_pipe_target_q[i+1],  byp_pipe_target_q[i],  reg_ena, '0)
      `FFL(byp_pipe_aux_q[i+1],     byp_pipe_aux_q[i],     reg_ena, '0)
    end

    assign byp_pipe_ready[NumPipeRegs] = out_ready_i & result_is_vector;

    assign conv_target_q = byp_pipe_target_q[NumPipeRegs];


    assign {result_vec_op, result_is_cpk} = byp_pipe_aux_q[NumPipeRegs];
  end else begin : no_conv
    assign {result_vec_op, result_is_cpk} = '0;
    assign conv_target_q = '0;
  end

  if (PulpDivsqrt) begin

    assign simd_synch_rdy  = EnableVectors ? &divsqrt_ready : divsqrt_ready[0];
    assign simd_synch_done = EnableVectors ? &divsqrt_done  : divsqrt_done[0];
  end else begin

    assign simd_synch_rdy  = '0;
    assign simd_synch_done = '0;
  end




  assign {result_fmt_is_int, result_is_vector, result_fmt} = lane_aux[0];

  assign result_o = result_fmt_is_int
                    ? ifmt_slice_result[result_fmt]
                    : fmt_slice_result[result_fmt];

  assign extension_bit_o = lane_ext_bit[0];
  assign tag_o           = lane_tags[0];
  assign busy_o          = (| lane_busy);

  assign out_valid_o     = lane_out_valid[0];


  always_comb begin : output_processing

    automatic fpnew_pkg::status_t temp_status;
    temp_status = '0;
    for (int i = 0; i < int'(NUM_LANES); i++)
      temp_status |= lane_status[i] & {5{lane_masks[i]}};
    status_o = temp_status;
  end

endmodule
