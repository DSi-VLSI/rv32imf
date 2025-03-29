// Module to pack the result into single-precision format
module pa_fdsu_pack_single (
    fdsu_ex4_denorm_to_tiny_frac,  // Input: Denorm to tiny fraction flag
    fdsu_ex4_frac,  // Input: Fraction from EX4 stage
    fdsu_ex4_nx,  // Input: Nearest representable value flag
    fdsu_ex4_potnt_norm,  // Input: Potential normalization shift
    fdsu_ex4_result_nor,  // Input: Result is normal
    fdsu_frbus_data,  // Output: Floating-point result data
    fdsu_frbus_fflags,  // Output: Floating-point status flags
    fdsu_frbus_freg,  // Output: Floating-point register destination
    fdsu_yy_expnt_rst,  // Input: Reset exponent value
    fdsu_yy_of,  // Input: Overflow flag
    fdsu_yy_of_rm_lfn,  // Input: Overflow result is LFN
    fdsu_yy_potnt_of,  // Input: Potential overflow
    fdsu_yy_potnt_uf,  // Input: Potential underflow
    fdsu_yy_result_inf,  // Input: Result is infinity
    fdsu_yy_result_lfn,  // Input: Result is LFN
    fdsu_yy_result_sign,  // Input: Sign of the result
    fdsu_yy_rslt_denorm,  // Input: Result is denormalized
    fdsu_yy_uf,  // Input: Underflow flag
    fdsu_yy_wb_freg  // Input: Writeback register number
);

  input fdsu_ex4_denorm_to_tiny_frac;  // Input: Denorm to tiny frac
  input [25:0] fdsu_ex4_frac;  // Input: Fraction from EX4
  input fdsu_ex4_nx;  // Input: Nearest representable
  input [1 : 0] fdsu_ex4_potnt_norm;  // Input: Potential normalization
  input fdsu_ex4_result_nor;  // Input: Result is normal
  input [9 : 0] fdsu_yy_expnt_rst;  // Input: Reset exponent
  input fdsu_yy_of;  // Input: Overflow
  input fdsu_yy_of_rm_lfn;  // Input: Overflow is LFN
  input fdsu_yy_potnt_of;  // Input: Potential overflow
  input fdsu_yy_potnt_uf;  // Input: Potential underflow
  input fdsu_yy_result_inf;  // Input: Result is infinity
  input fdsu_yy_result_lfn;  // Input: Result is LFN
  input fdsu_yy_result_sign;  // Input: Result sign
  input fdsu_yy_rslt_denorm;  // Input: Result is denorm
  input fdsu_yy_uf;  // Input: Underflow
  input [4 : 0] fdsu_yy_wb_freg;  // Input: Writeback register
  output [31:0] fdsu_frbus_data;  // Output: Result data
  output [4 : 0] fdsu_frbus_fflags;  // Output: Status flags
  output [4 : 0] fdsu_frbus_freg;  // Output: Destination register

  reg  [ 22:0] ex4_frac_23;  // Register for fraction (23 bits)
  reg  [ 31:0] ex4_result;  // Register for final result
  reg  [ 22:0] ex4_single_denorm_frac;  // Register for denorm fraction
  reg  [9 : 0] expnt_add_op1;  // Register for exponent addition

  wire         ex4_cor_nx;  // Wire for corrected NX flag
  wire         ex4_cor_uf;  // Wire for corrected UF flag
  wire         ex4_denorm_potnt_norm;  // Wire for denorm potential norm
  wire [ 31:0] ex4_denorm_result;  // Wire for denorm result
  wire [9 : 0] ex4_expnt_rst;  // Wire for reset exponent
  wire [4 : 0] ex4_expt;  // Wire for exception flags
  wire         ex4_final_rst_norm;  // Wire for final reset normal
  wire [ 25:0] ex4_frac;  // Wire for fraction
  wire         ex4_of_plus;  // Wire for overflow plus
  wire         ex4_result_inf;  // Wire for result is infinity
  wire         ex4_result_lfn;  // Wire for result is LFN
  wire         ex4_rslt_denorm;  // Wire for result is denorm
  wire [ 31:0] ex4_rst_inf;  // Wire for infinity result
  wire [ 31:0] ex4_rst_lfn;  // Wire for LFN result
  wire         ex4_rst_nor;  // Wire for reset normal
  wire [ 31:0] ex4_rst_norm;  // Wire for normal result
  wire         ex4_uf_plus;  // Wire for underflow plus
  wire         fdsu_ex4_denorm_to_tiny_frac;  // Wire for denorm to tiny frac
  wire         fdsu_ex4_dz;  // Wire for divide by zero flag
  wire [9 : 0] fdsu_ex4_expnt_rst;  // Wire for reset exponent
  wire [ 25:0] fdsu_ex4_frac;  // Wire for fraction from EX4
  wire         fdsu_ex4_nv;  // Wire for invalid operation flag
  wire         fdsu_ex4_nx;  // Wire for nearest representable
  wire         fdsu_ex4_of;  // Wire for overflow
  wire         fdsu_ex4_of_rst_lfn;  // Wire for overflow is LFN
  wire [1 : 0] fdsu_ex4_potnt_norm;  // Wire for potential normalization
  wire         fdsu_ex4_potnt_of;  // Wire for potential overflow
  wire         fdsu_ex4_potnt_uf;  // Wire for potential underflow
  wire         fdsu_ex4_result_inf;  // Wire for result is infinity
  wire         fdsu_ex4_result_lfn;  // Wire for result is LFN
  wire         fdsu_ex4_result_nor;  // Wire for result is normal
  wire         fdsu_ex4_result_sign;  // Wire for result sign
  wire         fdsu_ex4_rslt_denorm;  // Wire for result is denorm
  wire         fdsu_ex4_uf;  // Wire for underflow
  wire [ 31:0] fdsu_frbus_data;  // Wire for result data
  wire [4 : 0] fdsu_frbus_fflags;  // Wire for status flags
  wire [4 : 0] fdsu_frbus_freg;  // Wire for destination register
  wire [9 : 0] fdsu_yy_expnt_rst;  // Wire for reset exponent
  wire         fdsu_yy_of;  // Wire for overflow
  wire         fdsu_yy_of_rm_lfn;  // Wire for overflow is LFN
  wire         fdsu_yy_potnt_of;  // Wire for potential overflow
  wire         fdsu_yy_potnt_uf;  // Wire for potential underflow
  wire         fdsu_yy_result_inf;  // Wire for result is infinity
  wire         fdsu_yy_result_lfn;  // Wire for result is LFN
  wire         fdsu_yy_result_sign;  // Wire for result sign
  wire         fdsu_yy_rslt_denorm;  // Wire for result is denorm
  wire         fdsu_yy_uf;  // Wire for underflow
  wire [4 : 0] fdsu_yy_wb_freg;  // Wire for writeback register

  assign fdsu_ex4_result_sign    = fdsu_yy_result_sign;  // Assign result sign
  assign fdsu_ex4_of_rst_lfn     = fdsu_yy_of_rm_lfn;  // Assign overflow is LFN
  assign fdsu_ex4_result_inf     = fdsu_yy_result_inf;  // Assign result is infinity
  assign fdsu_ex4_result_lfn     = fdsu_yy_result_lfn;  // Assign result is LFN
  assign fdsu_ex4_of             = fdsu_yy_of;  // Assign overflow
  assign fdsu_ex4_uf             = fdsu_yy_uf;  // Assign underflow
  assign fdsu_ex4_potnt_of       = fdsu_yy_potnt_of;  // Assign potential overflow
  assign fdsu_ex4_potnt_uf       = fdsu_yy_potnt_uf;  // Assign potential underflow
  assign fdsu_ex4_nv             = 1'b0;  // Assign invalid operation (fixed to 0)
  assign fdsu_ex4_dz             = 1'b0;  // Assign divide by zero (fixed to 0)
  assign fdsu_ex4_expnt_rst[9:0] = fdsu_yy_expnt_rst[9:0];  // Assign reset exponent
  assign fdsu_ex4_rslt_denorm    = fdsu_yy_rslt_denorm;  // Assign result is denorm

  assign ex4_frac[25:0]          = fdsu_ex4_frac[25:0];  // Assign fraction

  // Determine the exponent adjustment based on fraction bits
  always @(ex4_frac[25:24]) begin
    casez (ex4_frac[25:24])
      2'b00:   expnt_add_op1[9:0] = 10'h1ff;  // Adjust for subnormal
      2'b01:   expnt_add_op1[9:0] = 10'h0;  // No adjustment
      2'b1?:   expnt_add_op1[9:0] = 10'h1;  // Adjust for normalization
      default: expnt_add_op1[9:0] = 10'b0;  // Default case
    endcase
  end
  // Calculate the final reset exponent value
  assign ex4_expnt_rst[9:0] = fdsu_ex4_expnt_rst[9:0] + expnt_add_op1[9:0];

  // Handle denormalized numbers by shifting the fraction
  always @(fdsu_ex4_expnt_rst[9:0] or fdsu_ex4_denorm_to_tiny_frac or ex4_frac[25:1]) begin
    case (fdsu_ex4_expnt_rst[9:0])
      10'h1: ex4_single_denorm_frac[22:0] = {ex4_frac[23:1]};
      10'h0: ex4_single_denorm_frac[22:0] = {ex4_frac[24:2]};
      10'h3ff: ex4_single_denorm_frac[22:0] = {ex4_frac[25:3]};
      10'h3fe: ex4_single_denorm_frac[22:0] = {1'b0, ex4_frac[25:4]};
      10'h3fd: ex4_single_denorm_frac[22:0] = {2'b0, ex4_frac[25:5]};
      10'h3fc: ex4_single_denorm_frac[22:0] = {3'b0, ex4_frac[25:6]};
      10'h3fb: ex4_single_denorm_frac[22:0] = {4'b0, ex4_frac[25:7]};
      10'h3fa: ex4_single_denorm_frac[22:0] = {5'b0, ex4_frac[25:8]};
      10'h3f9: ex4_single_denorm_frac[22:0] = {6'b0, ex4_frac[25:9]};
      10'h3f8: ex4_single_denorm_frac[22:0] = {7'b0, ex4_frac[25:10]};
      10'h3f7: ex4_single_denorm_frac[22:0] = {8'b0, ex4_frac[25:11]};
      10'h3f6: ex4_single_denorm_frac[22:0] = {9'b0, ex4_frac[25:12]};
      10'h3f5: ex4_single_denorm_frac[22:0] = {10'b0, ex4_frac[25:13]};
      10'h3f4: ex4_single_denorm_frac[22:0] = {11'b0, ex4_frac[25:14]};
      10'h3f3: ex4_single_denorm_frac[22:0] = {12'b0, ex4_frac[25:15]};
      10'h3f2: ex4_single_denorm_frac[22:0] = {13'b0, ex4_frac[25:16]};
      10'h3f1: ex4_single_denorm_frac[22:0] = {14'b0, ex4_frac[25:17]};
      10'h3f0: ex4_single_denorm_frac[22:0] = {15'b0, ex4_frac[25:18]};
      10'h3ef: ex4_single_denorm_frac[22:0] = {16'b0, ex4_frac[25:19]};
      10'h3ee: ex4_single_denorm_frac[22:0] = {17'b0, ex4_frac[25:20]};
      10'h3ed: ex4_single_denorm_frac[22:0] = {18'b0, ex4_frac[25:21]};
      10'h3ec: ex4_single_denorm_frac[22:0] = {19'b0, ex4_frac[25:22]};
      10'h3eb: ex4_single_denorm_frac[22:0] = {20'b0, ex4_frac[25:23]};
      10'h3ea: ex4_single_denorm_frac[22:0] = {21'b0, ex4_frac[25:24]};
      default:
      ex4_single_denorm_frac[22:0] = fdsu_ex4_denorm_to_tiny_frac ? 23'd1 : 23'b0;  // Tiny denorm
    endcase
  end

  // Check for potential normalization of denormalized numbers
  assign ex4_denorm_potnt_norm = (fdsu_ex4_potnt_norm[1] && ex4_frac[24]) ||
                               (fdsu_ex4_potnt_norm[0] && ex4_frac[25]) ;
  // Determine if the result should be denormalized
  assign ex4_rslt_denorm = fdsu_ex4_rslt_denorm && !ex4_denorm_potnt_norm;
  // Construct the denormalized result
  assign ex4_denorm_result[31:0] = {fdsu_ex4_result_sign, 8'h0, ex4_single_denorm_frac[22:0]};

  assign ex4_rst_nor = fdsu_ex4_result_nor;  // Assign normal result flag
  // Check for overflow with potential overflow and normalization
  assign ex4_of_plus = fdsu_ex4_potnt_of && (|ex4_frac[25:24]) && ex4_rst_nor;
  // Check for underflow with potential underflow and normalization
  assign ex4_uf_plus = fdsu_ex4_potnt_uf && (~|ex4_frac[25:24]) && ex4_rst_nor;

  // Determine if the result is LFN
  assign ex4_result_lfn = (ex4_of_plus && fdsu_ex4_of_rst_lfn) || fdsu_ex4_result_lfn;
  // Determine if the result is infinity
  assign ex4_result_inf = (ex4_of_plus && !fdsu_ex4_of_rst_lfn) || fdsu_ex4_result_inf;

  // Define the LFN result value
  assign ex4_rst_lfn[31:0] = {fdsu_ex4_result_sign, 8'hfe, {23{1'b1}}};

  // Define the infinity result value
  assign ex4_rst_inf[31:0] = {fdsu_ex4_result_sign, 8'hff, 23'b0};

  // Select the fraction bits based on the leading bits
  always @(ex4_frac[25:0]) begin
    casez (ex4_frac[25:24])
      2'b00:   ex4_frac_23[22:0] = ex4_frac[22:0];  // Fraction bits 22-0
      2'b01:   ex4_frac_23[22:0] = ex4_frac[23:1];  // Fraction bits 23-1
      2'b1?:   ex4_frac_23[22:0] = ex4_frac[24:2];  // Fraction bits 24-2
      default: ex4_frac_23[22:0] = 23'b0;  // Default to zero
    endcase
  end
  // Construct the normal result
  assign ex4_rst_norm[31:0] = {fdsu_ex4_result_sign, ex4_expnt_rst[7:0], ex4_frac_23[22:0]};
  // Determine the corrected underflow flag
  assign ex4_cor_uf = (fdsu_ex4_uf || ex4_denorm_potnt_norm || ex4_uf_plus) && fdsu_ex4_nx;
  // Determine the corrected nearest representable value flag
  assign ex4_cor_nx = fdsu_ex4_nx || fdsu_ex4_of || ex4_of_plus;

  // Combine all exception flags
  assign ex4_expt[4:0] = {
    fdsu_ex4_nv, fdsu_ex4_dz, fdsu_ex4_of | ex4_of_plus, ex4_cor_uf, ex4_cor_nx
  };

  // Determine if the final result should be normal
  assign ex4_final_rst_norm = !ex4_result_inf && !ex4_result_lfn && !ex4_rslt_denorm;

  // Select the final result based on different conditions
  always @( ex4_denorm_result[31:0] or ex4_result_lfn or ex4_result_inf or
          ex4_final_rst_norm or ex4_rst_norm[31:0] or ex4_rst_lfn[31:0] or
          ex4_rst_inf[31:0] or ex4_rslt_denorm)
begin
    case ({
      ex4_rslt_denorm, ex4_result_inf, ex4_result_lfn, ex4_final_rst_norm
    })
      4'b1000: ex4_result[31:0] = ex4_denorm_result[31:0];  // Denormalized
      4'b0100: ex4_result[31:0] = ex4_rst_inf[31:0];  // Infinity
      4'b0010: ex4_result[31:0] = ex4_rst_lfn[31:0];  // LFN
      4'b0001: ex4_result[31:0] = ex4_rst_norm[31:0];  // Normal
      default: ex4_result[31:0] = 32'b0;  // Default to zero
    endcase
  end

  assign fdsu_frbus_freg[4:0]   = fdsu_yy_wb_freg[4:0];  // Assign writeback register
  assign fdsu_frbus_data[31:0]  = ex4_result[31:0];  // Assign result data
  assign fdsu_frbus_fflags[4:0] = ex4_expt[4:0];  // Assign status flags

endmodule
