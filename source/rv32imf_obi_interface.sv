// Module definition for the OBI (On-chip Bus Interface) interface
module rv32imf_obi_interface #(
    // Parameter to indicate if the transaction signals should be stable until grant
    parameter int TRANS_STABLE = 0
) (
    // Input clock signal
    input logic clk,
    // Input reset signal (active low)
    input logic rst_n,

    // Input signal indicating a valid transaction request from the internal component
    input logic trans_valid_i,
    // Output signal indicating the interface is ready to accept a transaction
    output logic trans_ready_o,
    // Input signal providing the address for the transaction
    input logic [31:0] trans_addr_i,
    // Input signal indicating if the transaction is a write operation
    input logic trans_we_i,
    // Input signal providing the byte enable mask for the transaction
    input logic [3:0] trans_be_i,
    // Input signal providing the write data for the transaction
    input logic [31:0] trans_wdata_i,
    // Input signal providing the atomic operation type (if any)
    input logic [5:0] trans_atop_i,

    // Output signal indicating a valid response from the OBI
    output logic resp_valid_o,
    // Output signal providing the read data from the OBI response
    output logic [31:0] resp_rdata_o,
    // Output signal indicating an error in the OBI response
    output logic resp_err_o,

    // Output signal indicating a request to the OBI
    output logic        obi_req_o,
    // Input signal indicating the OBI has granted the request
    input  logic        obi_gnt_i,
    // Output signal providing the address to the OBI
    output logic [31:0] obi_addr_o,
    // Output signal indicating if the OBI transaction is a write operation
    output logic        obi_we_o,
    // Output signal providing the byte enable mask to the OBI
    output logic [ 3:0] obi_be_o,
    // Output signal providing the write data to the OBI
    output logic [31:0] obi_wdata_o,
    // Output signal providing the atomic operation type to the OBI
    output logic [ 5:0] obi_atop_o,
    // Input signal providing the read data from the OBI
    input  logic [31:0] obi_rdata_i,
    // Input signal indicating a valid read response from the OBI
    input  logic        obi_rvalid_i,
    // Input signal indicating an error in the OBI response
    input  logic        obi_err_i
);

  // Define the states for the interface's state machine
  typedef enum logic {
    // State where the interface is transparently passing through transactions
    TRANSPARENT,
    // State where the transaction request is registered waiting for grant
    REGISTERED
  } state_t;
  // State registers for the interface's state machine
  state_t state_q, next_state;

  // Assign the OBI response signals directly to the output
  assign resp_valid_o = obi_rvalid_i;
  assign resp_rdata_o = obi_rdata_i;
  assign resp_err_o   = obi_err_i;

  // Generate block to handle the TRANS_STABLE parameter
  generate
    // If TRANS_STABLE is set (non-zero)
    if (TRANS_STABLE) begin : gen_trans_stable
      // Directly connect the internal transaction signals to the OBI request signals
      assign obi_req_o     = trans_valid_i;
      assign obi_addr_o    = trans_addr_i;
      assign obi_we_o      = trans_we_i;
      assign obi_be_o      = trans_be_i;
      assign obi_wdata_o   = trans_wdata_i;
      assign obi_atop_o    = trans_atop_i;

      // The interface is ready to accept a new transaction when the OBI grants the current one
      assign trans_ready_o = obi_gnt_i;

      // The state is always transparent in this mode
      assign state_q       = TRANSPARENT;
      assign next_state    = TRANSPARENT;

    end else begin : gen_no_trans_stable
      // Internal registers to hold the OBI request signals when TRANS_STABLE is not set
      logic [31:0] obi_addr_q;
      logic        obi_we_q;
      logic [ 3:0] obi_be_q;
      logic [31:0] obi_wdata_q;
      logic [ 5:0] obi_atop_q;

      // Combinational logic for the next state of the interface
      always_comb begin
        next_state = state_q;

        case (state_q)
          default: begin  // TRANSPARENT state
            // If a transaction is requested but not yet granted, move to REGISTERED state
            if (obi_req_o && !obi_gnt_i) begin
              next_state = REGISTERED;
            end
          end

          REGISTERED: begin
            // Once the OBI grants the request, go back to the TRANSPARENT state
            if (obi_gnt_i) begin
              next_state = TRANSPARENT;
            end
          end

        endcase
      end

      // Combinational logic to drive the OBI request signals
      always_comb begin
        // In the TRANSPARENT state, directly pass through the internal transaction signals
        if (state_q == TRANSPARENT) begin
          obi_req_o   = trans_valid_i;
          obi_addr_o  = trans_addr_i;
          obi_we_o    = trans_we_i;
          obi_be_o    = trans_be_i;
          obi_wdata_o = trans_wdata_i;
          obi_atop_o  = trans_atop_i;
        end else begin  // In the REGISTERED state, drive the registered values
          obi_req_o   = 1'b1; // Keep the request asserted
          obi_addr_o  = obi_addr_q;
          obi_we_o    = obi_we_q;
          obi_be_o    = obi_be_q;
          obi_wdata_o = obi_wdata_q;
          obi_atop_o  = obi_atop_q;
        end
      end

      // Sequential block to update the state and registered OBI request signals
      always_ff @(posedge clk, negedge rst_n) begin
        if (rst_n == 1'b0) begin
          state_q   <= TRANSPARENT;
          obi_addr_q  <= 32'b0;
          obi_we_q    <= 1'b0;
          obi_be_q    <= 4'b0;
          obi_wdata_q <= 32'b0;
          obi_atop_q  <= 6'b0;
        end else begin
          state_q <= next_state;
          // When transitioning from TRANSPARENT to REGISTERED, latch the transaction signals
          if ((state_q == TRANSPARENT) && (next_state == REGISTERED)) begin
            obi_addr_q  <= obi_addr_o;
            obi_we_q    <= obi_we_o;
            obi_be_q    <= obi_be_o;
            obi_wdata_q <= obi_wdata_o;
            obi_atop_q  <= obi_atop_o;
          end
        end
      end

      // The interface is ready to accept a new transaction only in the TRANSPARENT state
      assign trans_ready_o = (state_q == TRANSPARENT);

    end
  endgenerate

endmodule
