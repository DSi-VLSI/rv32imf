module rv32imf_int_controller
  import rv32imf_pkg::*;
#(
) (
    input logic clk,   // Clock input
    input logic rst_n, // Asynchronous reset, active low

    input logic [31:0] irq_i,     // Interrupt input vector
    input logic        irq_sec_i, // Secure interrupt input

    output logic       irq_req_ctrl_o,  // Interrupt request to controller
    output logic       irq_sec_ctrl_o,  // Secure interrupt to controller
    output logic [4:0] irq_id_ctrl_o,   // Interrupt ID to controller
    output logic       irq_wu_ctrl_o,   // Interrupt wake-up to controller

    input  logic      [31:0] mie_bypass_i,       // MIE bypass input (for testing)
    output logic      [31:0] mip_o,              // MIP register output
    input  logic             m_ie_i,             // MIE (Machine Interrupt Enable) input
    input  logic             u_ie_i,             // UIE (User Interrupt Enable) input
    input  priv_lvl_t        current_priv_lvl_i  // Current privilege level
);

  // Internal signals
  logic        global_irq_enable;
  logic [31:0] irq_local_qual;
  logic [31:0] irq_q;
  logic        irq_sec_q;

  // Register to store interrupt inputs
  always_ff @(posedge clk, negedge rst_n) begin
    if (rst_n == 1'b0) begin
      irq_q     <= '0;  // Initialize interrupt queue
      irq_sec_q <= 1'b0;  // Initialize secure interrupt
    end else begin
      irq_q <= irq_i & IRQ_MASK;  // Mask irrelevant interrupt bits
      irq_sec_q <= irq_sec_i;  // Store secure interrupt input
    end
  end

  // Assign MIP register (Machine Interrupt Pending)
  assign mip_o = irq_q;

  // Determine locally qualified interrupts (after masking)
  assign irq_local_qual = irq_q & mie_bypass_i;

  // Wake-up signal: any qualified interrupt
  assign irq_wu_ctrl_o = |(irq_i & mie_bypass_i);

  // Global interrupt enable: MIE bit
  assign global_irq_enable = m_ie_i;

  // Interrupt request to the controller: any local IRQ and global enable
  assign irq_req_ctrl_o = (|irq_local_qual) && global_irq_enable;

  // Logic to determine the highest priority interrupt ID
  always_comb begin
    if (irq_local_qual[31]) irq_id_ctrl_o = 5'd31;
    else if (irq_local_qual[30]) irq_id_ctrl_o = 5'd30;
    else if (irq_local_qual[29]) irq_id_ctrl_o = 5'd29;
    else if (irq_local_qual[28]) irq_id_ctrl_o = 5'd28;
    else if (irq_local_qual[27]) irq_id_ctrl_o = 5'd27;
    else if (irq_local_qual[26]) irq_id_ctrl_o = 5'd26;
    else if (irq_local_qual[25]) irq_id_ctrl_o = 5'd25;
    else if (irq_local_qual[24]) irq_id_ctrl_o = 5'd24;
    else if (irq_local_qual[23]) irq_id_ctrl_o = 5'd23;
    else if (irq_local_qual[22]) irq_id_ctrl_o = 5'd22;
    else if (irq_local_qual[21]) irq_id_ctrl_o = 5'd21;
    else if (irq_local_qual[20]) irq_id_ctrl_o = 5'd20;
    else if (irq_local_qual[19]) irq_id_ctrl_o = 5'd19;
    else if (irq_local_qual[18]) irq_id_ctrl_o = 5'd18;
    else if (irq_local_qual[17]) irq_id_ctrl_o = 5'd17;
    else if (irq_local_qual[16]) irq_id_ctrl_o = 5'd16;
    else if (irq_local_qual[15]) irq_id_ctrl_o = 5'd15;
    else if (irq_local_qual[14]) irq_id_ctrl_o = 5'd14;
    else if (irq_local_qual[13]) irq_id_ctrl_o = 5'd13;
    else if (irq_local_qual[12]) irq_id_ctrl_o = 5'd12;
    else if (irq_local_qual[CSR_MEIX_BIT]) irq_id_ctrl_o = CSR_MEIX_BIT;
    else if (irq_local_qual[CSR_MSIX_BIT]) irq_id_ctrl_o = CSR_MSIX_BIT;
    else if (irq_local_qual[CSR_MTIX_BIT]) irq_id_ctrl_o = CSR_MTIX_BIT;
    else if (irq_local_qual[10]) irq_id_ctrl_o = 5'd10;
    else if (irq_local_qual[2]) irq_id_ctrl_o = 5'd2;
    else if (irq_local_qual[6]) irq_id_ctrl_o = 5'd6;
    else if (irq_local_qual[9]) irq_id_ctrl_o = 5'd9;
    else if (irq_local_qual[1]) irq_id_ctrl_o = 5'd1;
    else if (irq_local_qual[5]) irq_id_ctrl_o = 5'd5;
    else if (irq_local_qual[8]) irq_id_ctrl_o = 5'd8;
    else if (irq_local_qual[0]) irq_id_ctrl_o = 5'd0;
    else if (irq_local_qual[4]) irq_id_ctrl_o = 5'd4;
    else irq_id_ctrl_o = CSR_MTIX_BIT;  // Default interrupt ID
  end

  // Output the secure interrupt signal
  assign irq_sec_ctrl_o = irq_sec_q;

endmodule
