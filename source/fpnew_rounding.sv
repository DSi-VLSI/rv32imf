module fpnew_rounding #(
  parameter int unsigned AbsWidth=2
) (

  input logic [AbsWidth-1:0]   abs_value_i,
  input logic                  sign_i,

  input logic [1:0]            round_sticky_bits_i,
  input fpnew_pkg::roundmode_e rnd_mode_i,
  input logic                  effective_subtraction_i,

  output logic [AbsWidth-1:0]  abs_rounded_o,
  output logic                 sign_o,

  output logic                 exact_zero_o
);

  logic round_up;











  always_comb begin : rounding_decision
    unique case (rnd_mode_i)
      fpnew_pkg::RNE:
        unique case (round_sticky_bits_i)
          2'b00,
          2'b01: round_up = 1'b0;
          2'b10: round_up = abs_value_i[0];
          2'b11: round_up = 1'b1;
          default: round_up = fpnew_pkg::DONT_CARE;
        endcase
      fpnew_pkg::RTZ: round_up = 1'b0;
      fpnew_pkg::RDN: round_up = (| round_sticky_bits_i) ? sign_i  : 1'b0;
      fpnew_pkg::RUP: round_up = (| round_sticky_bits_i) ? ~sign_i : 1'b0;
      fpnew_pkg::RMM: round_up = round_sticky_bits_i[1];
      fpnew_pkg::ROD: round_up = ~abs_value_i[0] & (| round_sticky_bits_i);
      default: round_up = fpnew_pkg::DONT_CARE;
    endcase
  end


  assign abs_rounded_o = abs_value_i + round_up;


  assign exact_zero_o = (abs_value_i == '0) && (round_sticky_bits_i == '0);



  assign sign_o = (exact_zero_o && effective_subtraction_i)
                  ? (rnd_mode_i == fpnew_pkg::RDN)
                  : sign_i;

endmodule
