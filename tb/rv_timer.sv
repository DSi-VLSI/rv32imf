module rv_timer (
    input logic clk_i,   // Clock input
    input logic rst_n_i, // Asynchronous reset, active low

    input  logic        obi_req_i,     // OBI request
    input  logic [31:0] obi_addr_i,    // OBI address
    input  logic        obi_we_i,      // OBI write enable
    input  logic [31:0] obi_wdata_i,   // OBI write data
    input  logic [ 3:0] obi_be_i,      // OBI byte enable
    output logic        obi_gnt_o,     // OBI grant
    output logic        obi_rvalid_o,  // OBI valid (renamed from obi_rdy_o)
    output logic [31:0] obi_rdata_o,   // OBI read data

    output logic timer_irq_o  // Timer interrupt output
);

  // Timer Registers (Memory-Mapped)
  localparam logic [31:0] TimerLoadAddr = 32'h00;  // Offset 0x00
  localparam logic [31:0] TimerCtrlAddr = 32'h04;  // Offset 0x04
  localparam logic [31:0] TimerValueAddr = 32'h08;  // Offset 0x08
  localparam logic [31:0] TimerIntClrAddr = 32'h04;  // Offset 0x04

  // Control Register Bits
  localparam logic TimerEnableBit = 0;

  // Internal Signals
  logic [31:0] timer_load;  // Timer load value
  logic [31:0] timer_count;  // Current timer count
  logic        timer_enable;  // Timer enable flag
  logic        timer_irq;  // Internal interrupt signal
  logic        obi_rdy;  // OBI ready signal
  logic [31:0] obi_rdata;  // OBI read data
  logic        int_clr;

  // OBI Interface Logic
  assign obi_rvalid_o = obi_rdy;  // Renamed signal
  assign obi_rdata_o = obi_rdata;
  assign timer_irq_o = timer_irq;
  assign obi_gnt_o    = 1'b1;     // Always grant for simplicity

  // Timer Counter
  always_ff @(posedge clk_i or negedge rst_n_i) begin
    if (~rst_n_i) begin
      timer_count <= 32'h0;
    end else if (timer_enable) begin
      timer_count <= timer_count + 1'b1;
    end
  end

  // Timer Interrupt Logic
  always_ff @(posedge clk_i or negedge rst_n_i) begin
    if (~rst_n_i) begin
      timer_irq <= 1'b0;
    end else if (timer_enable) begin
      if (timer_count == timer_load) begin
        timer_irq <= 1'b1;
      end else if (int_clr) begin  // Clear interrupt when TimerIntClrAddr is written
        timer_irq <= 1'b0;
      end
    end
  end

  // OBI Read/Write Logic
  always_ff @(posedge clk_i or negedge rst_n_i) begin
    if (~rst_n_i) begin
      obi_rdy <= 1'b0;
      obi_rdata <= 32'h0;
      timer_load <= 32'h0;
      timer_enable <= 1'b0;
      int_clr <= 1'b0;
    end else begin
      obi_rdy <= 1'b0;
      int_clr <= 1'b0;  // Default

      if (obi_req_i) begin
        obi_rdy <= 1'b1;  // Always ready for single-cycle access

        if (obi_we_i) begin  // Write operation
          case (obi_addr_i)
            TimerLoadAddr: timer_load <= obi_wdata_i;
            TimerCtrlAddr: begin
              timer_enable <= obi_wdata_i[TimerEnableBit];
              int_clr <= 1'b0;  //no clear here
            end
            TimerIntClrAddr: int_clr <= 1'b1;  // writing to this address clears the interrupt
            default: ;  // Ignore writes to invalid addresses
          endcase
        end else begin  // Read operation
          case (obi_addr_i)
            TimerLoadAddr:  obi_rdata <= timer_load;
            TimerValueAddr: obi_rdata <= timer_count;
            TimerCtrlAddr:  obi_rdata <= {31'b0, timer_enable};
            default:        obi_rdata <= 32'h0;  // Return 0 for invalid addresses
          endcase
        end
      end
    end
  end

endmodule
