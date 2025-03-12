


module rv32imf_int_controller
  import rv32imf_pkg::*;
#(
) (
    input logic clk,
    input logic rst_n,

    input logic [31:0] irq_i,
    input logic        irq_sec_i,

    output logic       irq_req_ctrl_o,
    output logic       irq_sec_ctrl_o,
    output logic [4:0] irq_id_ctrl_o,
    output logic       irq_wu_ctrl_o,

    input  logic      [31:0] mie_bypass_i,
    output logic      [31:0] mip_o,
    input  logic             m_ie_i,
    input  logic             u_ie_i,
    input  priv_lvl_t        current_priv_lvl_i
);


  logic        global_irq_enable;
  logic [31:0] irq_local_qual;
  logic [31:0] irq_q;
  logic        irq_sec_q;


  always_ff @(posedge clk, negedge rst_n) begin
    if (rst_n == 1'b0) begin
      irq_q     <= '0;
      irq_sec_q <= 1'b0;
    end else begin
      irq_q     <= irq_i & IRQ_MASK;
      irq_sec_q <= irq_sec_i;
    end
  end


  assign mip_o = irq_q;
  assign irq_local_qual = irq_q & mie_bypass_i;
  assign irq_wu_ctrl_o = |(irq_i & mie_bypass_i);
  assign global_irq_enable = m_ie_i;
  assign irq_req_ctrl_o = (|irq_local_qual) && global_irq_enable;


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
    else irq_id_ctrl_o = CSR_MTIX_BIT;
  end


  assign irq_sec_ctrl_o = irq_sec_q;

endmodule
