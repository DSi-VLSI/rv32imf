// Module for forwarding results from FPU writeback to IDU
module pa_fpu_frbus (
    ctrl_frbus_ex2_wb_req,  // Request from EX2 stage for writeback
    dp_frbus_ex2_data,  // Data from EX2 stage
    dp_frbus_ex2_fflags,  // FPU flags from EX2 stage
    fdsu_frbus_data,  // Data from FDSU
    fdsu_frbus_fflags,  // FPU flags from FDSU
    fdsu_frbus_wb_vld,  // Writeback valid from FDSU
    fpu_idu_fwd_data,  // Forwarded data to IDU
    fpu_idu_fwd_fflags,  // Forwarded FPU flags to IDU
    fpu_idu_fwd_vld  // Forward valid signal to IDU
);

  input ctrl_frbus_ex2_wb_req;  // Input request signal
  input [31:0] dp_frbus_ex2_data;  // Input data from EX2
  input [4 : 0] dp_frbus_ex2_fflags;  // Input flags from EX2
  input [31:0] fdsu_frbus_data;  // Input data from FDSU
  input [4 : 0] fdsu_frbus_fflags;  // Input flags from FDSU
  input fdsu_frbus_wb_vld;  // Input valid from FDSU
  output [31:0] fpu_idu_fwd_data;  // Output forwarded data
  output [4 : 0] fpu_idu_fwd_fflags;  // Output forwarded flags
  output fpu_idu_fwd_vld;  // Output forwarded valid

  reg  [ 31:0] frbus_wb_data;  // Register to hold writeback data
  reg  [4 : 0] frbus_wb_fflags;  // Register to hold writeback flags

  wire         ctrl_frbus_ex2_wb_req;  // Wire for EX2 writeback request
  wire [ 31:0] fdsu_frbus_data;  // Wire for FDSU data
  wire [4 : 0] fdsu_frbus_fflags;  // Wire for FDSU flags
  wire         fdsu_frbus_wb_vld;  // Wire for FDSU writeback valid
  wire [ 31:0] fpu_idu_fwd_data;  // Wire for forwarded data
  wire [4 : 0] fpu_idu_fwd_fflags;  // Wire for forwarded flags
  wire         fpu_idu_fwd_vld;  // Wire for forwarded valid
  wire         frbus_ex2_wb_vld;  // Wire for EX2 writeback valid
  wire         frbus_fdsu_wb_vld;  // Wire for FDSU writeback valid
  wire         frbus_wb_vld;  // Wire for overall writeback valid
  wire [3 : 0] frbus_source_vld;  // Wire to indicate source of writeback

  // Assign the FDSU writeback valid signal
  assign frbus_fdsu_wb_vld = fdsu_frbus_wb_vld;
  // Assign the EX2 writeback valid signal
  assign frbus_ex2_wb_vld = ctrl_frbus_ex2_wb_req;
  // Determine which source is providing the writeback data
  assign frbus_source_vld[3:0] = {1'b0, 1'b0, frbus_ex2_wb_vld, frbus_fdsu_wb_vld};
  // Overall writeback valid if either EX2 or FDSU is valid
  assign frbus_wb_vld = frbus_ex2_wb_vld | frbus_fdsu_wb_vld;

  // Always block to select the writeback data and flags
  always @( frbus_source_vld[3:0] or fdsu_frbus_data[31:0] or
          dp_frbus_ex2_data[31:0] or fdsu_frbus_fflags[4:0] or
          dp_frbus_ex2_fflags[4:0])
begin
    case (frbus_source_vld[3:0])
      4'b0001: begin  // FDSU is the source
        frbus_wb_data[31:0]  = fdsu_frbus_data[31:0];
        frbus_wb_fflags[4:0] = fdsu_frbus_fflags[4:0];
      end
      4'b0010: begin  // EX2 is the source
        frbus_wb_data[31:0]  = dp_frbus_ex2_data[31:0];
        frbus_wb_fflags[4:0] = dp_frbus_ex2_fflags[4:0];
      end
      default: begin  // No valid source
        frbus_wb_data[31:0]  = {31{1'b0}};
        frbus_wb_fflags[4:0] = 5'b0;
      end
    endcase
  end

  // Assign the forwarded valid signal
  assign fpu_idu_fwd_vld         = frbus_wb_vld;
  // Assign the forwarded FPU flags
  assign fpu_idu_fwd_fflags[4:0] = frbus_wb_fflags[4:0];
  // Assign the forwarded data
  assign fpu_idu_fwd_data[31:0]  = frbus_wb_data[31:0];

endmodule
