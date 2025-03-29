// Module for the double-precision floating-point unit pipeline stage
module pa_fpu_dp (
    cp0_fpu_icg_en,  // Input: Clock gating enable from CP0
    cp0_fpu_xx_rm,  // Input: Rounding mode from CP0
    cp0_yy_clk_en,  // Input: Clock enable from CP0
    ctrl_xx_ex1_inst_vld,  // Input: Instruction valid from control unit
    ctrl_xx_ex1_stall,  // Input: Stall signal from control unit
    ctrl_xx_ex1_warm_up,  // Input: Warm-up signal from control unit
    dp_frbus_ex2_data,  // Output: Data to the next pipeline stage
    dp_frbus_ex2_fflags,  // Output: FPU flags to the next stage
    dp_xx_ex1_cnan,  // Output: Canonical NaN flags for sources
    dp_xx_ex1_id,  // Output: Invalid operation flags for sources
    dp_xx_ex1_inf,  // Output: Infinity flags for sources
    dp_xx_ex1_norm,  // Output: Normal number flags for sources
    dp_xx_ex1_qnan,  // Output: Quiet NaN flags for sources
    dp_xx_ex1_snan,  // Output: Signaling NaN flags for sources
    dp_xx_ex1_zero,  // Output: Zero flags for sources
    ex2_inst_wb,  // Output: Instruction needs writeback
    fdsu_fpu_ex1_fflags,  // Input: FPU flags from previous stage
    fdsu_fpu_ex1_special_sel,  // Input: Special select from previous stage
    fdsu_fpu_ex1_special_sign,  // Input: Special sign from previous stage
    forever_cpuclk,  // Input: System clock
    idu_fpu_ex1_eu_sel,  // Input: Execution unit select from IDU
    idu_fpu_ex1_func,  // Input: Function code from IDU
    idu_fpu_ex1_gateclk_vld,  // Input: Gate clock valid from IDU
    idu_fpu_ex1_rm,  // Input: Rounding mode from IDU
    idu_fpu_ex1_srcf0,  // Input: Source operand 0 from IDU
    idu_fpu_ex1_srcf1,  // Input: Source operand 1 from IDU
    idu_fpu_ex1_srcf2,  // Input: Source operand 2 from IDU
    pad_yy_icg_scan_en  // Input: Scan enable for clock gating
);

  input cp0_fpu_icg_en;  // Input: Clock gating enable
  input [2 : 0] cp0_fpu_xx_rm;  // Input: CP0 rounding mode
  input cp0_yy_clk_en;  // Input: CP0 clock enable
  input ctrl_xx_ex1_inst_vld;  // Input: Instruction valid
  input ctrl_xx_ex1_stall;  // Input: Stall signal
  input ctrl_xx_ex1_warm_up;  // Input: Warm-up signal
  input [4 : 0] fdsu_fpu_ex1_fflags;  // Input: FPU flags from EX1
  input [7 : 0] fdsu_fpu_ex1_special_sel;  // Input: Special select from EX1
  input [3 : 0] fdsu_fpu_ex1_special_sign;  // Input: Special sign from EX1
  input forever_cpuclk;  // Input: System clock
  input [2 : 0] idu_fpu_ex1_eu_sel;  // Input: Execution unit select
  input [9 : 0] idu_fpu_ex1_func;  // Input: Function code
  input idu_fpu_ex1_gateclk_vld;  // Input: Gate clock valid
  input [2 : 0] idu_fpu_ex1_rm;  // Input: Rounding mode from IDU
  input [31:0] idu_fpu_ex1_srcf0;  // Input: Source operand 0
  input [31:0] idu_fpu_ex1_srcf1;  // Input: Source operand 1
  input [31:0] idu_fpu_ex1_srcf2;  // Input: Source operand 2
  input pad_yy_icg_scan_en;  // Input: Scan enable for ICG
  output [31:0] dp_frbus_ex2_data;  // Output: Data to EX2
  output [4 : 0] dp_frbus_ex2_fflags;  // Output: FPU flags to EX2
  output [2 : 0] dp_xx_ex1_cnan;  // Output: CNAN flags for EX1
  output [2 : 0] dp_xx_ex1_id;  // Output: ID flags for EX1
  output [2 : 0] dp_xx_ex1_inf;  // Output: INF flags for EX1
  output [2 : 0] dp_xx_ex1_norm;  // Output: NORM flags for EX1
  output [2 : 0] dp_xx_ex1_qnan;  // Output: QNAN flags for EX1
  output [2 : 0] dp_xx_ex1_snan;  // Output: SNAN flags for EX1
  output [2 : 0] dp_xx_ex1_zero;  // Output: ZERO flags for EX1
  output ex2_inst_wb;  // Output: Writeback enable

  reg  [4 : 0] ex1_fflags;  // Register for EX1 FPU flags
  reg  [ 31:0] ex1_special_data;  // Register for EX1 special data
  reg  [8 : 0] ex1_special_sel;  // Register for EX1 special select
  reg  [3 : 0] ex1_special_sign;  // Register for EX1 special sign
  reg  [4 : 0] ex2_fflags;  // Register for EX2 FPU flags
  reg  [ 31:0] ex2_result;  // Register for EX2 result data
  reg  [ 31:0] ex2_special_data;  // Register for EX2 special data
  reg  [6 : 0] ex2_special_sel;  // Register for EX2 special select
  reg  [3 : 0] ex2_special_sign;  // Register for EX2 special sign

  wire         cp0_fpu_icg_en;  // Wire for clock gating enable
  wire [2 : 0] cp0_fpu_xx_rm;  // Wire for CP0 rounding mode
  wire         cp0_yy_clk_en;  // Wire for CP0 clock enable
  wire         ctrl_xx_ex1_inst_vld;  // Wire for instruction valid
  wire         ctrl_xx_ex1_stall;  // Wire for stall signal
  wire         ctrl_xx_ex1_warm_up;  // Wire for warm-up signal
  wire [ 31:0] dp_frbus_ex2_data;  // Wire for data to EX2
  wire [4 : 0] dp_frbus_ex2_fflags;  // Wire for FPU flags to EX2
  wire [2 : 0] dp_xx_ex1_cnan;  // Wire for CNAN flags for EX1
  wire [2 : 0] dp_xx_ex1_id;  // Wire for ID flags for EX1
  wire [2 : 0] dp_xx_ex1_inf;  // Wire for INF flags for EX1
  wire [2 : 0] dp_xx_ex1_norm;  // Wire for NORM flags for EX1
  wire [2 : 0] dp_xx_ex1_qnan;  // Wire for QNAN flags for EX1
  wire [2 : 0] dp_xx_ex1_snan;  // Wire for SNAN flags for EX1
  wire [2 : 0] dp_xx_ex1_zero;  // Wire for ZERO flags for EX1
  wire [2 : 0] ex1_decode_rm;  // Wire for decoded rounding mode
  wire         ex1_double;  // Wire for double precision flag
  wire [2 : 0] ex1_eu_sel;  // Wire for execution unit select
  wire [9 : 0] ex1_func;  // Wire for function code
  wire [2 : 0] ex1_global_rm;  // Wire for global rounding mode
  wire [2 : 0] ex1_rm;  // Wire for effective rounding mode
  wire         ex1_single;  // Wire for single precision flag
  wire [ 31:0] ex1_special_data_final;  // Wire for final special data
  wire [ 63:0] ex1_src0;  // Wire for source operand 0
  wire [ 63:0] ex1_src1;  // Wire for source operand 1
  wire [ 63:0] ex1_src2;  // Wire for source operand 2
  wire         ex1_src2_vld;  // Wire for source operand 2 valid
  wire [2 : 0] ex1_src_cnan;  // Wire for CNAN flags for sources
  wire [2 : 0] ex1_src_id;  // Wire for ID flags for sources
  wire [2 : 0] ex1_src_inf;  // Wire for INF flags for sources
  wire [2 : 0] ex1_src_norm;  // Wire for NORM flags for sources
  wire [2 : 0] ex1_src_qnan;  // Wire for QNAN flags for sources
  wire [2 : 0] ex1_src_snan;  // Wire for SNAN flags for sources
  wire [2 : 0] ex1_src_zero;  // Wire for ZERO flags for sources
  wire         ex2_data_clk;  // Wire for clock for EX2 data
  wire         ex2_data_clk_en;  // Wire for enable for EX2 data clock
  wire         ex2_inst_wb;  // Wire for writeback enable
  wire [4 : 0] fdsu_fpu_ex1_fflags;  // Wire for FPU flags from EX1
  wire [7 : 0] fdsu_fpu_ex1_special_sel;  // Wire for special select from EX1
  wire [3 : 0] fdsu_fpu_ex1_special_sign;  // Wire for special sign from EX1
  wire         forever_cpuclk;  // Wire for system clock
  wire [2 : 0] idu_fpu_ex1_eu_sel;  // Wire for execution unit select
  wire [9 : 0] idu_fpu_ex1_func;  // Wire for function code
  wire         idu_fpu_ex1_gateclk_vld;  // Wire for gate clock valid
  wire [2 : 0] idu_fpu_ex1_rm;  // Wire for rounding mode from IDU
  wire [ 31:0] idu_fpu_ex1_srcf0;  // Wire for source operand 0
  wire [ 31:0] idu_fpu_ex1_srcf1;  // Wire for source operand 1
  wire [ 31:0] idu_fpu_ex1_srcf2;  // Wire for source operand 2
  wire         pad_yy_icg_scan_en;  // Wire for scan enable for ICG

  parameter int DOUBLE_WIDTH = 64;  // Parameter for double-precision width
  parameter int SINGLE_WIDTH = 32;  // Parameter for single-precision width
  parameter int FUNC_WIDTH = 10;  // Parameter for function code width

  // Assign the execution unit select signal
  assign ex1_eu_sel[2:0] = idu_fpu_ex1_eu_sel[2:0];
  // Assign the function code
  assign ex1_func[FUNC_WIDTH-1:0] = idu_fpu_ex1_func[FUNC_WIDTH-1:0];
  // Assign the global rounding mode from CP0
  assign ex1_global_rm[2:0] = cp0_fpu_xx_rm[2:0];
  // Assign the rounding mode from the instruction decode stage
  assign ex1_decode_rm[2:0] = idu_fpu_ex1_rm[2:0];

  // Select the effective rounding mode: use decode RM if not default, else global RM
  assign ex1_rm[2:0] = (ex1_decode_rm[2:0] == 3'b111) ? ex1_global_rm[2:0] : ex1_decode_rm[2:0];

  // Determine if the third source operand is valid
  assign ex1_src2_vld = idu_fpu_ex1_eu_sel[1] && ex1_func[0];

  // Extend single-precision sources to double-precision format (with sign extension)
  assign ex1_src0[DOUBLE_WIDTH-1:0] = {{SINGLE_WIDTH{1'b1}}, idu_fpu_ex1_srcf0[SINGLE_WIDTH-1:0]};
  assign ex1_src1[DOUBLE_WIDTH-1:0] = {{SINGLE_WIDTH{1'b1}}, idu_fpu_ex1_srcf1[SINGLE_WIDTH-1:0]};
  assign ex1_src2[DOUBLE_WIDTH-1:0]  = ex1_src2_vld ?
                                     { {SINGLE_WIDTH{1'b1}}, idu_fpu_ex1_srcf2[SINGLE_WIDTH-1:0]} :
                                     { {SINGLE_WIDTH{1'b1}}, {SINGLE_WIDTH{1'b0}} };

  // Indicate that the current operation is treated as single-precision for source type detection
  assign ex1_double = 1'b0;
  assign ex1_single = 1'b1;

  // Instantiate the source type detection module for source operand 0
  pa_fpu_src_type x_pa_fpu_ex1_srcf0_type (
      .inst_double(ex1_double),
      .inst_single(ex1_single),
      .src_cnan   (ex1_src_cnan[0]),
      .src_id     (ex1_src_id[0]),
      .src_in     (ex1_src0),
      .src_inf    (ex1_src_inf[0]),
      .src_norm   (ex1_src_norm[0]),
      .src_qnan   (ex1_src_qnan[0]),
      .src_snan   (ex1_src_snan[0]),
      .src_zero   (ex1_src_zero[0])
  );

  // Instantiate the source type detection module for source operand 1
  pa_fpu_src_type x_pa_fpu_ex1_srcf1_type (
      .inst_double(ex1_double),
      .inst_single(ex1_single),
      .src_cnan   (ex1_src_cnan[1]),
      .src_id     (ex1_src_id[1]),
      .src_in     (ex1_src1),
      .src_inf    (ex1_src_inf[1]),
      .src_norm   (ex1_src_norm[1]),
      .src_qnan   (ex1_src_qnan[1]),
      .src_snan   (ex1_src_snan[1]),
      .src_zero   (ex1_src_zero[1])
  );

  // Instantiate the source type detection module for source operand 2
  pa_fpu_src_type x_pa_fpu_ex1_srcf2_type (
      .inst_double(ex1_double),
      .inst_single(ex1_single),
      .src_cnan   (ex1_src_cnan[2]),
      .src_id     (ex1_src_id[2]),
      .src_in     (ex1_src2),
      .src_inf    (ex1_src_inf[2]),
      .src_norm   (ex1_src_norm[2]),
      .src_qnan   (ex1_src_qnan[2]),
      .src_snan   (ex1_src_snan[2]),
      .src_zero   (ex1_src_zero[2])
  );

  // Assign the source type flags to the output ports
  assign dp_xx_ex1_cnan[2:0] = ex1_src_cnan[2:0];
  assign dp_xx_ex1_snan[2:0] = ex1_src_snan[2:0];
  assign dp_xx_ex1_qnan[2:0] = ex1_src_qnan[2:0];
  assign dp_xx_ex1_norm[2:0] = ex1_src_norm[2:0];
  assign dp_xx_ex1_zero[2:0] = ex1_src_zero[2:0];
  assign dp_xx_ex1_inf[2:0]  = ex1_src_inf[2:0];
  assign dp_xx_ex1_id[2:0]   = ex1_src_id[2:0];

  // Capture the special select and flags based on the execution unit select
  always @( fdsu_fpu_ex1_special_sign[3:0] or fdsu_fpu_ex1_fflags[4:0] or
          ex1_eu_sel[2:0] or fdsu_fpu_ex1_special_sel[7:0])
begin
    case (ex1_eu_sel[2:0])
      3'b100: begin  // If execution unit is for special operations
        ex1_fflags[4:0]       = fdsu_fpu_ex1_fflags[4:0];
        ex1_special_sel[8:0]  = {1'b0, fdsu_fpu_ex1_special_sel[7:0]};
        ex1_special_sign[3:0] = fdsu_fpu_ex1_special_sign[3:0];
      end
      default: begin  // Otherwise, set to default values
        ex1_fflags[4:0]       = {5{1'b0}};
        ex1_special_sel[8:0]  = {9{1'b0}};
        ex1_special_sign[3:0] = {4{1'b0}};
      end
    endcase
  end

  // Select the special data based on the special select signal
  always @(ex1_special_sel[8:5] or ex1_src0[31:0] or ex1_src1[31:0] or ex1_src2[31:0]) begin
    case (ex1_special_sel[8:5])
      4'b0001: ex1_special_data[SINGLE_WIDTH-1:0] = ex1_src0[SINGLE_WIDTH-1:0];
      4'b0010: ex1_special_data[SINGLE_WIDTH-1:0] = ex1_src1[SINGLE_WIDTH-1:0];
      4'b0100: ex1_special_data[SINGLE_WIDTH-1:0] = ex1_src2[SINGLE_WIDTH-1:0];
      default: ex1_special_data[SINGLE_WIDTH-1:0] = ex1_src2[SINGLE_WIDTH-1:0];
    endcase
  end

  // Assign the selected special data
  assign ex1_special_data_final[SINGLE_WIDTH-1:0] = ex1_special_data[SINGLE_WIDTH-1:0];

  // Enable the clock for the EX2 stage data registers
  assign ex2_data_clk_en = idu_fpu_ex1_gateclk_vld || ctrl_xx_ex1_warm_up;

  // Instantiate a gated clock cell for the EX2 stage data
  gated_clk_cell x_fpu_data_ex2_gated_clk (
      .clk_in            (forever_cpuclk),
      .clk_out           (ex2_data_clk),
      .external_en       (1'b0),
      .global_en         (cp0_yy_clk_en),
      .local_en          (ex2_data_clk_en),
      .module_en         (cp0_fpu_icg_en),
      .pad_yy_icg_scan_en(pad_yy_icg_scan_en)
  );

  // Register the control and special signals for the next pipeline stage (EX2)
  always @(posedge ex2_data_clk) begin
    if (ctrl_xx_ex1_inst_vld && !ctrl_xx_ex1_stall || ctrl_xx_ex1_warm_up) begin
      ex2_fflags[4:0] <= ex1_fflags[4:0];
      ex2_special_sign[3:0] <= ex1_special_sign[3:0];
      ex2_special_sel[6:0] <= {ex1_special_sel[8], |ex1_special_sel[7:5], ex1_special_sel[4:0]};
      ex2_special_data[SINGLE_WIDTH-1:0] <= ex1_special_data_final[SINGLE_WIDTH-1:0];
    end
  end

  // Determine if the instruction needs a writeback based on the special select
  assign ex2_inst_wb = (|ex2_special_sel[6:0]);

  // Generate the result data for special operations based on the select signal
  always @(ex2_special_sel[6:0] or ex2_special_data[31:0] or ex2_special_sign[3:0]) begin
    case (ex2_special_sel[6:0])
      7'b0000_001:
      ex2_result[SINGLE_WIDTH-1:0] = {ex2_special_sign[0], ex2_special_data[SINGLE_WIDTH-2:0]};
      7'b0000_010: ex2_result[SINGLE_WIDTH-1:0] = {ex2_special_sign[1], {31{1'b0}}};
      7'b0000_100: ex2_result[SINGLE_WIDTH-1:0] = {ex2_special_sign[2], {8{1'b1}}, {23{1'b0}}};
      7'b0001_000:
      ex2_result[SINGLE_WIDTH-1:0] = {ex2_special_sign[3], {7{1'b1}}, 1'b0, {23{1'b1}}};
      7'b0010_000: ex2_result[SINGLE_WIDTH-1:0] = {1'b0, {8{1'b1}}, 1'b1, {22{1'b0}}};
      7'b0100_000:
      ex2_result[SINGLE_WIDTH-1:0] = {
        ex2_special_data[31], {8{1'b1}}, 1'b1, ex2_special_data[21:0]
      };
      7'b1000_000: ex2_result[SINGLE_WIDTH-1:0] = ex2_special_data[SINGLE_WIDTH-1:0];
      default: ex2_result[SINGLE_WIDTH-1:0] = {SINGLE_WIDTH{1'b0}};
    endcase
  end

  // Assign the result data and FPU flags to the output ports
  assign dp_frbus_ex2_data[SINGLE_WIDTH-1:0] = ex2_result[SINGLE_WIDTH-1:0];
  assign dp_frbus_ex2_fflags[4:0] = ex2_fflags[4:0];

endmodule
