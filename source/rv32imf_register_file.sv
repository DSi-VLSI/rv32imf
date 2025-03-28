// Module definition for the register file
module rv32imf_register_file #(
    // Parameter for the address width of the register file (default is 5, allowing 32 registers)
    parameter int ADDR_WIDTH = 5,
    // Parameter for the data width of the registers (default is 32 bits for RV32)
    parameter int DATA_WIDTH = 32
) (
    // Input clock signal
    input logic clk,
    // Input reset signal (active low)
    input logic rst_n,

    // Input address for read port A
    input  logic [ADDR_WIDTH-1:0] raddr_a_i,
    // Output data for read port A
    output logic [DATA_WIDTH-1:0] rdata_a_o,

    // Input address for read port B
    input  logic [ADDR_WIDTH-1:0] raddr_b_i,
    // Output data for read port B
    output logic [DATA_WIDTH-1:0] rdata_b_o,

    // Input address for read port C
    input  logic [ADDR_WIDTH-1:0] raddr_c_i,
    // Output data for read port C
    output logic [DATA_WIDTH-1:0] rdata_c_o,

    // Input address for write port A
    input logic [ADDR_WIDTH-1:0] waddr_a_i,
    // Input data for write port A
    input logic [DATA_WIDTH-1:0] wdata_a_i,
    // Input write enable signal for write port A
    input logic                  we_a_i,

    // Input address for write port B
    input logic [ADDR_WIDTH-1:0] waddr_b_i,
    // Input data for write port B
    input logic [DATA_WIDTH-1:0] wdata_b_i,
    // Input write enable signal for write port B
    input logic                  we_b_i
);

  // Local parameter to calculate the number of integer registers (assuming bit 5 distinguishes FP)
  localparam int NumWords = 2 ** (ADDR_WIDTH - 1);

  // Local parameter to calculate the number of floating-point registers (assuming bit 5 distinguishes FP)
  localparam int NumFPWords = 2 ** (ADDR_WIDTH - 1);

  // Local parameter for the total number of addressable locations
  localparam int NumTotalWords = (NumWords + NumFPWords);

  // Memory array to store integer registers. Indexed by [register number][bit number]
  logic [NumWords-1:0][DATA_WIDTH-1:0] mem;

  // Memory array to store floating-point registers
  logic [NumFPWords-1:0][DATA_WIDTH-1:0] mem_fp;

  // Internal signals to hold the write addresses
  logic [ADDR_WIDTH-1:0] waddr_a;
  logic [ADDR_WIDTH-1:0] waddr_b;

  // One-hot decoded write enable signals for write port A
  logic [NumTotalWords-1:0] we_a_dec;
  // One-hot decoded write enable signals for write port B
  logic [NumTotalWords-1:0] we_b_dec;

  // Read port A logic: If the most significant bit of the address is set, read from FP registers, else from integer registers.
  assign rdata_a_o = raddr_a_i[ADDR_WIDTH-1] ? mem_fp[raddr_a_i[ADDR_WIDTH-2:0]]
                                             : mem[raddr_a_i[ADDR_WIDTH-2:0]];
  // Read port B logic: Similar to read port A.
  assign rdata_b_o = raddr_b_i[ADDR_WIDTH-1] ? mem_fp[raddr_b_i[ADDR_WIDTH-2:0]]
                                             : mem[raddr_b_i[ADDR_WIDTH-2:0]];
  // Read port C logic: Similar to read port A.
  assign rdata_c_o = raddr_c_i[ADDR_WIDTH-1] ? mem_fp[raddr_c_i[ADDR_WIDTH-2:0]]
                                             : mem[raddr_c_i[ADDR_WIDTH-2:0]];

  // Assign input write addresses to internal signals
  assign waddr_a = waddr_a_i;
  assign waddr_b = waddr_b_i;

  // Generate block to decode the write enable signals into a one-hot format
  for (genvar gidx = 0; gidx < NumTotalWords; gidx++) begin : gen_we_decoder
    // If the write address A matches the current index, and write enable A is asserted, set the corresponding bit in we_a_dec
    assign we_a_dec[gidx] = (waddr_a == gidx) ? we_a_i : 1'b0;
    // If the write address B matches the current index, and write enable B is asserted, set the corresponding bit in we_b_dec
    assign we_b_dec[gidx] = (waddr_b == gidx) ? we_b_i : 1'b0;
  end

  // Asynchronous reset sets the value of integer register x0 to zero
  always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
      mem[0] <= 32'b0;  // Reset register x0 to 0
    end else begin
      mem[0] <= 32'b0;  // Keep register x0 at 0 (convention for RISC-V)
    end
  end

  // Generate block for the integer register file (excluding x0, which is always zero)
  for (genvar i = 1; i < NumWords; i++) begin : gen_rf
    // Sequential logic for each integer register
    always_ff @(posedge clk, negedge rst_n) begin : register_write_behavioral
      if (rst_n == 1'b0) begin
        mem[i] <= 32'b0;  // Reset all integer registers to 0
      end else begin
        // Write to the register if write enable B is asserted for this register
        if (we_b_dec[i] == 1'b1) mem[i] <= wdata_b_i;
        // Else, write to the register if write enable A is asserted for this register
        else if (we_a_dec[i] == 1'b1) mem[i] <= wdata_a_i;
        // If neither write enable is asserted, the register retains its value
      end
    end
  end

  // Generate block for the floating-point register file
  for (genvar l = 0; l < NumFPWords; l++) begin : gen_fpu_regs
    // Sequential logic for each floating-point register
    always_ff @(posedge clk, negedge rst_n) begin : fp_regs
      if (rst_n == 1'b0) mem_fp[l] <= '0;  // Reset all floating-point registers to 0
      // Write to the FP register if write enable B is asserted for this FP register
      else if (we_b_dec[l+NumWords] == 1'b1) mem_fp[l] <= wdata_b_i;
      // Else, write to the FP register if write enable A is asserted for this FP register
      else if (we_a_dec[l+NumWords] == 1'b1) mem_fp[l] <= wdata_a_i;
      // If neither write enable is asserted, the register retains its value
    end
  end

endmodule
