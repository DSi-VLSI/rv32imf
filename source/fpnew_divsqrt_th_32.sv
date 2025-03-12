`include "common_cells/registers.svh"

module fpnew_divsqrt_th_32 #(


  parameter int unsigned             NumPipeRegs = 0,
  parameter fpnew_pkg::pipe_config_t PipeConfig  = fpnew_pkg::BEFORE,
  parameter type                     TagType     = logic,
  parameter type                     AuxType     = logic,

  localparam int unsigned WIDTH       = 32,
  localparam int unsigned NUM_FORMATS = fpnew_pkg::NUM_FP_FORMATS,
  localparam int unsigned ExtRegEnaWidth = NumPipeRegs == 0 ? 1 : NumPipeRegs
) (
  input  logic                        clk_i,
  input  logic                        rst_ni,

  input  logic [1:0][WIDTH-1:0]       operands_i,
  input  logic [NUM_FORMATS-1:0][1:0] is_boxed_i,
  input  fpnew_pkg::roundmode_e       rnd_mode_i,
  input  fpnew_pkg::operation_e       op_i,
  input  TagType                      tag_i,
  input  logic                        mask_i,
  input  AuxType                      aux_i,

  input  logic                        in_valid_i,
  output logic                        in_ready_o,
  input  logic                        flush_i,

  output logic [WIDTH-1:0]            result_o,
  output fpnew_pkg::status_t          status_o,
  output logic                        extension_bit_o,
  output TagType                      tag_o,
  output logic                        mask_o,
  output AuxType                      aux_o,

  output logic                        out_valid_o,
  input  logic                        out_ready_i,

  output logic                        busy_o,

  input  logic [ExtRegEnaWidth-1:0]   reg_ena_i
);





  localparam NUM_INP_REGS = (PipeConfig == fpnew_pkg::BEFORE)
                            ? NumPipeRegs
                            : (PipeConfig == fpnew_pkg::DISTRIBUTED
                               ? (NumPipeRegs / 2)
                               : 0);
  localparam NUM_OUT_REGS = (PipeConfig == fpnew_pkg::AFTER || PipeConfig == fpnew_pkg::INSIDE)
                            ? NumPipeRegs
                            : (PipeConfig == fpnew_pkg::DISTRIBUTED
                               ? ((NumPipeRegs + 1) / 2)
                               : 0);





  logic [1:0][WIDTH-1:0] operands_q;
  fpnew_pkg::roundmode_e rnd_mode_q;
  fpnew_pkg::operation_e op_q;
  logic                  in_valid_q;


  logic                  [0:NUM_INP_REGS][1:0][WIDTH-1:0]       inp_pipe_operands_q;
  fpnew_pkg::roundmode_e [0:NUM_INP_REGS]                       inp_pipe_rnd_mode_q;
  fpnew_pkg::operation_e [0:NUM_INP_REGS]                       inp_pipe_op_q;
  TagType                [0:NUM_INP_REGS]                       inp_pipe_tag_q;
  logic                  [0:NUM_INP_REGS]                       inp_pipe_mask_q;
  AuxType                [0:NUM_INP_REGS]                       inp_pipe_aux_q;
  logic                  [0:NUM_INP_REGS]                       inp_pipe_valid_q;

  logic [0:NUM_INP_REGS] inp_pipe_ready;


  assign inp_pipe_operands_q[0] = operands_i;
  assign inp_pipe_rnd_mode_q[0] = rnd_mode_i;
  assign inp_pipe_op_q[0]       = op_i;
  assign inp_pipe_tag_q[0]      = tag_i;
  assign inp_pipe_mask_q[0]     = mask_i;
  assign inp_pipe_aux_q[0]      = aux_i;
  assign inp_pipe_valid_q[0]    = in_valid_i;

  assign in_ready_o = inp_pipe_ready[0];

  for (genvar i = 0; i < NUM_INP_REGS; i++) begin : gen_input_pipeline

    logic reg_ena;



    assign inp_pipe_ready[i] = inp_pipe_ready[i+1] | ~inp_pipe_valid_q[i+1];

    `FFLARNC(inp_pipe_valid_q[i+1], inp_pipe_valid_q[i], inp_pipe_ready[i], flush_i, 1'b0, clk_i, rst_ni)

    assign reg_ena = (inp_pipe_ready[i] & inp_pipe_valid_q[i]) | reg_ena_i[i];

    `FFL(inp_pipe_operands_q[i+1], inp_pipe_operands_q[i], reg_ena, '0)
    `FFL(inp_pipe_rnd_mode_q[i+1], inp_pipe_rnd_mode_q[i], reg_ena, fpnew_pkg::RNE)
    `FFL(inp_pipe_op_q[i+1],       inp_pipe_op_q[i],       reg_ena, fpnew_pkg::FMADD)
    `FFL(inp_pipe_tag_q[i+1],      inp_pipe_tag_q[i],      reg_ena, TagType'('0))
    `FFL(inp_pipe_mask_q[i+1],     inp_pipe_mask_q[i],     reg_ena, '0)
    `FFL(inp_pipe_aux_q[i+1],      inp_pipe_aux_q[i],      reg_ena, AuxType'('0))
  end

  assign operands_q = inp_pipe_operands_q[NUM_INP_REGS];
  assign rnd_mode_q = inp_pipe_rnd_mode_q[NUM_INP_REGS];
  assign op_q       = inp_pipe_op_q[NUM_INP_REGS];
  assign in_valid_q = inp_pipe_valid_q[NUM_INP_REGS];




  logic in_ready;
  logic div_op, sqrt_op;
  logic unit_ready_q, unit_done;
  logic op_starting;
  logic out_valid, out_ready;
  logic hold_result;
  logic data_is_held;
  logic unit_busy;

  typedef enum logic [1:0] {IDLE, BUSY, HOLD} fsm_state_e;
  fsm_state_e state_q, state_d;


  assign div_op   = in_valid_q & (op_q == fpnew_pkg::DIV) & in_ready & ~flush_i;
  assign sqrt_op  = in_valid_q & (op_q == fpnew_pkg::SQRT) & in_ready & ~flush_i;
  assign op_starting = div_op | sqrt_op;

  logic fdsu_fpu_ex1_stall, fdsu_fpu_ex1_stall_q;
  logic div_op_d, div_op_q;
  logic sqrt_op_d, sqrt_op_q;

  assign div_op_d  = (fdsu_fpu_ex1_stall) ? div_op  : 1'b0;
  assign sqrt_op_d = (fdsu_fpu_ex1_stall) ? sqrt_op : 1'b0;

  `FFL(fdsu_fpu_ex1_stall_q, fdsu_fpu_ex1_stall, 1'b1, '0)
  `FFL(div_op_q, div_op_d, 1'b1, '0)
  `FFL(sqrt_op_q, sqrt_op_d, 1'b1, '0)


  always_comb begin : flag_fsm

    in_ready     = 1'b0;
    out_valid    = 1'b0;
    hold_result  = 1'b0;
    data_is_held = 1'b0;
    unit_busy    = 1'b0;
    state_d      = state_q;
    inp_pipe_ready[NUM_INP_REGS] = unit_ready_q;

    unique case (state_q)

      IDLE: begin

        in_ready = unit_ready_q;
        if (in_valid_q && unit_ready_q) begin
          inp_pipe_ready[NUM_INP_REGS] = unit_ready_q && !fdsu_fpu_ex1_stall;
          state_d = BUSY;
        end
      end

      BUSY: begin
        inp_pipe_ready[NUM_INP_REGS] = fdsu_fpu_ex1_stall_q;
        unit_busy = 1'b1;

        if (unit_done) begin
          out_valid = 1'b1;

          if (out_ready) begin
            state_d = IDLE;
            if (in_valid_q && unit_ready_q) begin
              in_ready = 1'b1;
              state_d  = BUSY;
            end

          end else begin
            hold_result = 1'b1;
            state_d     = HOLD;
          end
        end
      end

      HOLD: begin
        unit_busy    = 1'b1;
        data_is_held = 1'b1;
        out_valid    = 1'b1;

        if (out_ready) begin
          state_d = IDLE;
          if (in_valid_q && unit_ready_q) begin
            in_ready = 1'b1;
            state_d  = BUSY;
          end
        end
      end

      default: state_d = IDLE;
    endcase


    if (flush_i) begin
      unit_busy = 1'b0;
      out_valid = 1'b0;
      state_d   = IDLE;
    end
  end


  `FF(state_q, state_d, IDLE)


  TagType result_tag_q;
  AuxType result_aux_q;
  logic   result_mask_q;


  `FFL(result_tag_q,  inp_pipe_tag_q[NUM_INP_REGS],  op_starting, '0)
  `FFL(result_mask_q, inp_pipe_mask_q[NUM_INP_REGS], op_starting, '0)
  `FFL(result_aux_q,  inp_pipe_aux_q[NUM_INP_REGS],  op_starting, '0)




  logic [WIDTH-1:0]   unit_result, held_result_q;
  fpnew_pkg::status_t unit_status, held_status_q;


  logic        ctrl_fdsu_ex1_sel;
  logic        fdsu_fpu_ex1_cmplt;
  logic  [4:0] fdsu_fpu_ex1_fflags;
  logic  [7:0] fdsu_fpu_ex1_special_sel;
  logic  [3:0] fdsu_fpu_ex1_special_sign;
  logic        fdsu_fpu_no_op;
  logic  [2:0] idu_fpu_ex1_eu_sel;
  logic [31:0] fdsu_frbus_data;
  logic  [4:0] fdsu_frbus_fflags;
  logic        fdsu_frbus_wb_vld;


  logic [31:0] dp_frbus_ex2_data;
  logic  [4:0] dp_frbus_ex2_fflags;
  logic  [2:0] dp_xx_ex1_cnan;
  logic  [2:0] dp_xx_ex1_id;
  logic  [2:0] dp_xx_ex1_inf;
  logic  [2:0] dp_xx_ex1_norm;
  logic  [2:0] dp_xx_ex1_qnan;
  logic  [2:0] dp_xx_ex1_snan;
  logic  [2:0] dp_xx_ex1_zero;
  logic        ex2_inst_wb;
  logic        ex2_inst_wb_vld_d, ex2_inst_wb_vld_q;


  logic [31:0] fpu_idu_fwd_data;
  logic  [4:0] fpu_idu_fwd_fflags;
  logic        fpu_idu_fwd_vld;

  logic unit_ready_d;


  always_comb begin
    if(op_starting && unit_ready_q) begin
      if(ex2_inst_wb && ex2_inst_wb_vld_q) begin
        unit_ready_d = 1'b1;
      end else begin
        unit_ready_d = 1'b0;
      end
    end else if(fpu_idu_fwd_vld | flush_i) begin
      unit_ready_d = 1'b1;
    end else begin
      unit_ready_d = unit_ready_q;
    end
  end

  `FFL(unit_ready_q, unit_ready_d, 1'b1, 1'b1)


  always_comb begin
    ctrl_fdsu_ex1_sel = 1'b0;
    idu_fpu_ex1_eu_sel = 3'h0;
    if (op_starting) begin
      ctrl_fdsu_ex1_sel = 1'b1;
      idu_fpu_ex1_eu_sel = 3'h4;
    end else if (fdsu_fpu_ex1_stall_q) begin
      ctrl_fdsu_ex1_sel = 1'b1;
      idu_fpu_ex1_eu_sel = 3'h4;
    end else begin
      ctrl_fdsu_ex1_sel = 1'b0;
      idu_fpu_ex1_eu_sel = 3'h0;
    end
  end

  pa_fdsu_top i_divsqrt_thead (
   .cp0_fpu_icg_en                ( 1'b0               ),
   .cp0_fpu_xx_dqnan              ( 1'b0               ),
   .cp0_yy_clk_en                 ( 1'b1               ),
   .cpurst_b                      ( rst_ni             ),
   .ctrl_fdsu_ex1_sel             ( ctrl_fdsu_ex1_sel  ),
   .ctrl_xx_ex1_cmplt_dp          ( ctrl_fdsu_ex1_sel  ),
   .ctrl_xx_ex1_inst_vld          ( ctrl_fdsu_ex1_sel  ),
   .ctrl_xx_ex1_stall             ( fdsu_fpu_ex1_stall ),
   .ctrl_xx_ex1_warm_up           ( 1'b0               ),
   .ctrl_xx_ex2_warm_up           ( 1'b0               ),
   .ctrl_xx_ex3_warm_up           ( 1'b0               ),
   .dp_xx_ex1_cnan                ( dp_xx_ex1_cnan     ),
   .dp_xx_ex1_id                  ( dp_xx_ex1_id       ),
   .dp_xx_ex1_inf                 ( dp_xx_ex1_inf      ),
   .dp_xx_ex1_qnan                ( dp_xx_ex1_qnan     ),
   .dp_xx_ex1_rm                  ( rnd_mode_q         ),
   .dp_xx_ex1_snan                ( dp_xx_ex1_snan     ),
   .dp_xx_ex1_zero                ( dp_xx_ex1_zero     ),
   .fdsu_fpu_debug_info           (                    ),
   .fdsu_fpu_ex1_cmplt            ( fdsu_fpu_ex1_cmplt ),
   .fdsu_fpu_ex1_cmplt_dp         (                    ),
   .fdsu_fpu_ex1_fflags           ( fdsu_fpu_ex1_fflags       ),
   .fdsu_fpu_ex1_special_sel      ( fdsu_fpu_ex1_special_sel  ),
   .fdsu_fpu_ex1_special_sign     ( fdsu_fpu_ex1_special_sign ),
   .fdsu_fpu_ex1_stall            ( fdsu_fpu_ex1_stall        ),
   .fdsu_fpu_no_op                ( fdsu_fpu_no_op            ),
   .fdsu_frbus_data               ( fdsu_frbus_data           ),
   .fdsu_frbus_fflags             ( fdsu_frbus_fflags         ),
   .fdsu_frbus_freg               (                           ),
   .fdsu_frbus_wb_vld             ( fdsu_frbus_wb_vld         ),
   .forever_cpuclk                ( clk_i                     ),
   .frbus_fdsu_wb_grant           ( fdsu_frbus_wb_vld         ),
   .idu_fpu_ex1_dst_freg          ( 5'h0f                     ),
   .idu_fpu_ex1_eu_sel            ( idu_fpu_ex1_eu_sel        ),
   .idu_fpu_ex1_func              ( {8'b0, div_op | div_op_q, sqrt_op | sqrt_op_q} ),
   .idu_fpu_ex1_srcf0             ( operands_q[0][31:0]       ),
   .idu_fpu_ex1_srcf1             ( operands_q[1][31:0]       ),
   .pad_yy_icg_scan_en            ( 1'b0                      ),
   .rtu_xx_ex1_cancel             ( 1'b0                      ),
   .rtu_xx_ex2_cancel             ( 1'b0                      ),
   .rtu_yy_xx_async_flush         ( flush_i                   ),
   .rtu_yy_xx_flush               ( 1'b0                      )
  );

  pa_fpu_dp  x_pa_fpu_dp (
    .cp0_fpu_icg_en              ( 1'b0                       ),
    .cp0_fpu_xx_rm               ( rnd_mode_q                 ),
    .cp0_yy_clk_en               ( 1'b1                       ),
    .ctrl_xx_ex1_inst_vld        ( ctrl_fdsu_ex1_sel          ),
    .ctrl_xx_ex1_stall           ( 1'b0                       ),
    .ctrl_xx_ex1_warm_up         ( 1'b0                       ),
    .dp_frbus_ex2_data           ( dp_frbus_ex2_data          ),
    .dp_frbus_ex2_fflags         ( dp_frbus_ex2_fflags        ),
    .dp_xx_ex1_cnan              ( dp_xx_ex1_cnan             ),
    .dp_xx_ex1_id                ( dp_xx_ex1_id               ),
    .dp_xx_ex1_inf               ( dp_xx_ex1_inf              ),
    .dp_xx_ex1_norm              ( dp_xx_ex1_norm             ),
    .dp_xx_ex1_qnan              ( dp_xx_ex1_qnan             ),
    .dp_xx_ex1_snan              ( dp_xx_ex1_snan             ),
    .dp_xx_ex1_zero              ( dp_xx_ex1_zero             ),
    .ex2_inst_wb                 ( ex2_inst_wb                ),
    .fdsu_fpu_ex1_fflags         ( fdsu_fpu_ex1_fflags        ),
    .fdsu_fpu_ex1_special_sel    ( fdsu_fpu_ex1_special_sel   ),
    .fdsu_fpu_ex1_special_sign   ( fdsu_fpu_ex1_special_sign  ),
    .forever_cpuclk              ( clk_i                      ),
    .idu_fpu_ex1_eu_sel          ( idu_fpu_ex1_eu_sel         ),
    .idu_fpu_ex1_func            ( {8'b0, div_op, sqrt_op}    ),
    .idu_fpu_ex1_gateclk_vld     ( fdsu_fpu_ex1_cmplt         ),
    .idu_fpu_ex1_rm              ( rnd_mode_q                 ),
    .idu_fpu_ex1_srcf0           ( operands_q[0][31:0]        ),
    .idu_fpu_ex1_srcf1           ( operands_q[1][31:0]        ),
    .idu_fpu_ex1_srcf2           ( '0                         ),
    .pad_yy_icg_scan_en          ( 1'b0                       )
  );

  assign ex2_inst_wb_vld_d = ctrl_fdsu_ex1_sel;
  `FF(ex2_inst_wb_vld_q, ex2_inst_wb_vld_d, '0)

  pa_fpu_frbus x_pa_fpu_frbus (
    .ctrl_frbus_ex2_wb_req     ( ex2_inst_wb & ex2_inst_wb_vld_q ),
    .dp_frbus_ex2_data         ( dp_frbus_ex2_data   ),
    .dp_frbus_ex2_fflags       ( dp_frbus_ex2_fflags ),
    .fdsu_frbus_data           ( fdsu_frbus_data     ),
    .fdsu_frbus_fflags         ( fdsu_frbus_fflags   ),
    .fdsu_frbus_wb_vld         ( fdsu_frbus_wb_vld   ),
    .fpu_idu_fwd_data          ( fpu_idu_fwd_data    ),
    .fpu_idu_fwd_fflags        ( fpu_idu_fwd_fflags  ),
    .fpu_idu_fwd_vld           ( fpu_idu_fwd_vld     )
  );

  always_comb begin
    unit_result[31:0] = fpu_idu_fwd_data[31:0];
    unit_status[4:0]  = fpu_idu_fwd_fflags[4:0];
    unit_done         = fpu_idu_fwd_vld;
  end


  `FFLNR(held_result_q, unit_result, hold_result, clk_i)
  `FFLNR(held_status_q, unit_status, hold_result, clk_i)




  logic [WIDTH-1:0]   result_d;
  fpnew_pkg::status_t status_d;

  assign result_d = data_is_held ? held_result_q : unit_result;
  assign status_d = data_is_held ? held_status_q : unit_status;





  logic               [0:NUM_OUT_REGS][WIDTH-1:0] out_pipe_result_q;
  fpnew_pkg::status_t [0:NUM_OUT_REGS]            out_pipe_status_q;
  TagType             [0:NUM_OUT_REGS]            out_pipe_tag_q;
  AuxType             [0:NUM_OUT_REGS]            out_pipe_aux_q;
  logic               [0:NUM_OUT_REGS]            out_pipe_mask_q;
  logic               [0:NUM_OUT_REGS]            out_pipe_valid_q;

  logic [0:NUM_OUT_REGS] out_pipe_ready;


  assign out_pipe_result_q[0] = result_d;
  assign out_pipe_status_q[0] = status_d;
  assign out_pipe_tag_q[0]    = result_tag_q;
  assign out_pipe_mask_q[0]   = result_mask_q;
  assign out_pipe_aux_q[0]    = result_aux_q;
  assign out_pipe_valid_q[0]  = out_valid;

  assign out_ready = out_pipe_ready[0];

  for (genvar i = 0; i < NUM_OUT_REGS; i++) begin : gen_output_pipeline

    logic reg_ena;



    assign out_pipe_ready[i] = out_pipe_ready[i+1] | ~out_pipe_valid_q[i+1];

    `FFLARNC(out_pipe_valid_q[i+1], out_pipe_valid_q[i], out_pipe_ready[i], flush_i, 1'b0, clk_i, rst_ni)

    assign reg_ena = (out_pipe_ready[i] & out_pipe_valid_q[i]) | reg_ena_i[NUM_INP_REGS + i];

    `FFL(out_pipe_result_q[i+1], out_pipe_result_q[i], reg_ena, '0)
    `FFL(out_pipe_status_q[i+1], out_pipe_status_q[i], reg_ena, '0)
    `FFL(out_pipe_tag_q[i+1],    out_pipe_tag_q[i],    reg_ena, TagType'('0))
    `FFL(out_pipe_mask_q[i+1],   out_pipe_mask_q[i],   reg_ena, '0)
    `FFL(out_pipe_aux_q[i+1],    out_pipe_aux_q[i],    reg_ena, AuxType'('0))
  end

  assign out_pipe_ready[NUM_OUT_REGS] = out_ready_i;

  assign result_o        = out_pipe_result_q[NUM_OUT_REGS];
  assign status_o        = out_pipe_status_q[NUM_OUT_REGS];
  assign extension_bit_o = 1'b1;
  assign tag_o           = out_pipe_tag_q[NUM_OUT_REGS];
  assign mask_o          = out_pipe_mask_q[NUM_OUT_REGS];
  assign aux_o           = out_pipe_aux_q[NUM_OUT_REGS];
  assign out_valid_o     = out_pipe_valid_q[NUM_OUT_REGS];
  assign busy_o          = (| {inp_pipe_valid_q, unit_busy, out_pipe_valid_q});
endmodule
