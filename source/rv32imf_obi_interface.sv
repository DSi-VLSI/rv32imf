


module rv32imf_obi_interface #(
    parameter int TRANS_STABLE = 0
) (
    input logic clk,
    input logic rst_n,


    input logic trans_valid_i,
    output logic trans_ready_o,
    input logic [31:0] trans_addr_i,
    input logic trans_we_i,
    input logic [3:0] trans_be_i,
    input logic [31:0] trans_wdata_i,
    input logic [5:0] trans_atop_i,


    output logic resp_valid_o,
    output logic [31:0] resp_rdata_o,
    output logic resp_err_o,


    output logic        obi_req_o,
    input  logic        obi_gnt_i,
    output logic [31:0] obi_addr_o,
    output logic        obi_we_o,
    output logic [ 3:0] obi_be_o,
    output logic [31:0] obi_wdata_o,
    output logic [ 5:0] obi_atop_o,
    input  logic [31:0] obi_rdata_i,
    input  logic        obi_rvalid_i,
    input  logic        obi_err_i
);


  typedef enum logic {
    TRANSPARENT,
    REGISTERED
  } state_t;
  state_t state_q, next_state;


  assign resp_valid_o = obi_rvalid_i;
  assign resp_rdata_o = obi_rdata_i;
  assign resp_err_o   = obi_err_i;

  generate
    if (TRANS_STABLE) begin : gen_trans_stable


      assign obi_req_o     = trans_valid_i;
      assign obi_addr_o    = trans_addr_i;
      assign obi_we_o      = trans_we_i;
      assign obi_be_o      = trans_be_i;
      assign obi_wdata_o   = trans_wdata_i;
      assign obi_atop_o    = trans_atop_i;

      assign trans_ready_o = obi_gnt_i;

      assign state_q       = TRANSPARENT;
      assign next_state    = TRANSPARENT;

    end else begin : gen_no_trans_stable


      logic [31:0] obi_addr_q;
      logic        obi_we_q;
      logic [ 3:0] obi_be_q;
      logic [31:0] obi_wdata_q;
      logic [ 5:0] obi_atop_q;


      always_comb begin
        next_state = state_q;

        case (state_q)
          default: begin
            if (obi_req_o && !obi_gnt_i) begin
              next_state = REGISTERED;
            end
          end

          REGISTERED: begin
            if (obi_gnt_i) begin
              next_state = TRANSPARENT;
            end
          end

        endcase
      end


      always_comb begin
        if (state_q == TRANSPARENT) begin
          obi_req_o   = trans_valid_i;
          obi_addr_o  = trans_addr_i;
          obi_we_o    = trans_we_i;
          obi_be_o    = trans_be_i;
          obi_wdata_o = trans_wdata_i;
          obi_atop_o  = trans_atop_i;
        end else begin
          obi_req_o   = 1'b1;
          obi_addr_o  = obi_addr_q;
          obi_we_o    = obi_we_q;
          obi_be_o    = obi_be_q;
          obi_wdata_o = obi_wdata_q;
          obi_atop_o  = obi_atop_q;
        end
      end


      always_ff @(posedge clk, negedge rst_n) begin
        if (rst_n == 1'b0) begin
          state_q     <= TRANSPARENT;
          obi_addr_q  <= 32'b0;
          obi_we_q    <= 1'b0;
          obi_be_q    <= 4'b0;
          obi_wdata_q <= 32'b0;
          obi_atop_q  <= 6'b0;
        end else begin
          state_q <= next_state;
          if ((state_q == TRANSPARENT) && (next_state == REGISTERED)) begin
            obi_addr_q  <= obi_addr_o;
            obi_we_q    <= obi_we_o;
            obi_be_q    <= obi_be_o;
            obi_wdata_q <= obi_wdata_o;
            obi_atop_q  <= obi_atop_o;
          end
        end
      end


      assign trans_ready_o = (state_q == TRANSPARENT);

    end
  endgenerate

endmodule
