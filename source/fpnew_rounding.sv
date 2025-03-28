module fpnew_rounding #(
    // Parameter for the width of the absolute value.
    parameter int unsigned AbsWidth = 2
) (

    // Input port for the absolute value to be rounded.
    input logic [AbsWidth-1:0] abs_value_i,
    // Input port for the sign bit.
    input logic sign_i,

    // Input port for the round and sticky bits.
    input logic [1:0] round_sticky_bits_i,
    // Input port for the rounding mode.
    input fpnew_pkg::roundmode_e rnd_mode_i,
    // Input port indicating if the operation was an effective subtraction.
    input logic effective_subtraction_i,

    // Output port for the rounded absolute value.
    output logic [AbsWidth-1:0] abs_rounded_o,
    // Output port for the sign of the rounded result.
    output logic sign_o,

    // Output port indicating if the result is exactly zero.
    output logic exact_zero_o
);

  // Internal logic signal to determine if rounding up is needed.
  logic round_up;

  // Combinational block to determine if rounding up is necessary.
  always_comb begin : rounding_decision
    unique case (rnd_mode_i)
      // Round to nearest even.
      fpnew_pkg::RNE:
      unique case (round_sticky_bits_i)
        // No rounding needed.
        2'b00, 2'b01: round_up = 1'b0;
        // Round up if the last bit is 1.
        2'b10: round_up = abs_value_i[0];
        // Round up.
        2'b11: round_up = 1'b1;
        default: round_up = fpnew_pkg::DONT_CARE;
      endcase
      // Round towards zero.
      fpnew_pkg::RTZ: round_up = 1'b0;
      // Round towards negative infinity.
      fpnew_pkg::RDN: round_up = (|round_sticky_bits_i) ? sign_i : 1'b0;
      // Round towards positive infinity.
      fpnew_pkg::RUP: round_up = (|round_sticky_bits_i) ? ~sign_i : 1'b0;
      // Round to nearest away from zero (magnitude).
      fpnew_pkg::RMM: round_up = round_sticky_bits_i[1];
      // Round towards odd.
      fpnew_pkg::ROD: round_up = ~abs_value_i[0] & (|round_sticky_bits_i);
      default: round_up = fpnew_pkg::DONT_CARE;
    endcase
  end

  // Assign the rounded absolute value.
  assign abs_rounded_o = abs_value_i + round_up;

  // Determine if the result is exactly zero.
  assign exact_zero_o = (abs_value_i == '0) && (round_sticky_bits_i == '0);

  // Determine the sign of the rounded result, handling negative zero.
  assign sign_o = (exact_zero_o && effective_subtraction_i)
                    ? (rnd_mode_i == fpnew_pkg::RDN)
                    : sign_i;

endmodule
