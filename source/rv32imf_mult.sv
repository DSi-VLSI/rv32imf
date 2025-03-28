module rv32imf_mult
  import rv32imf_pkg::*;
(
    input logic clk,   // Clock signal
    input logic rst_n, // Active-low reset signal

    input logic        enable_i,   // Enable signal for the multiplier
    input mul_opcode_e operator_i, // Multiplier operation code

    input logic       short_subword_i,  // Indicates short subword operation
    input logic [1:0] short_signed_i,   // Indicates signedness for short ops

    input logic [31:0] op_a_i,  // Operand A (32-bit)
    input logic [31:0] op_b_i,  // Operand B (32-bit)
    input logic [31:0] op_c_i,  // Operand C (32-bit)

    input logic [4:0] imm_i,  // Immediate value (5-bit)

    input logic [ 1:0] dot_signed_i,  // Signedness for dot product ops
    input logic [31:0] dot_op_a_i,    // Operand A for dot product
    input logic [31:0] dot_op_b_i,    // Operand B for dot product
    input logic [31:0] dot_op_c_i,    // Operand C for dot product
    input logic        is_clpx_i,     // Complex instruction indicator
    input logic [ 1:0] clpx_shift_i,  // Shift value for complex instruction
    input logic        clpx_img_i,    // Image indicator for complex instruction

    output logic [31:0] result_o,  // Result of the multiplication

    output logic multicycle_o,   // Indicates a multi-cycle operation
    output logic mulh_active_o,  // Indicates MULH operation is active
    output logic ready_o,        // Indicates the multiplier is ready
    input  logic ex_ready_i      // External ready signal
);

  logic [16:0] short_op_a;  // Internal signal for short operand A
  logic [16:0] short_op_b;  // Internal signal for short operand B
  logic [32:0] short_op_c;  // Internal signal for short operand C
  logic [33:0] short_mul;  // Internal signal for short multiplication result
  logic [33:0] short_mac;  // Internal signal for short multiply-accumulate
  logic [31:0] short_round, short_round_tmp;  // Rounding signals for short ops
  logic [33:0] short_result;  // Internal signal for short operation result

  logic        short_mac_msb1;  // MSB bit of short MAC (bit 33)
  logic        short_mac_msb0;  // Second MSB bit of short MAC (bit 32)

  logic [ 4:0] short_imm;  // Internal signal for short immediate
  logic [ 1:0] short_subword;  // Internal signal for short subword
  logic [ 1:0] short_signed;  // Internal signal for short signedness
  logic        short_shift_arith;  // Arithmetic shift for short ops
  logic [ 4:0] mulh_imm;  // Immediate for MULH operation
  logic [ 1:0] mulh_subword;  // Subword for MULH operation
  logic [ 1:0] mulh_signed;  // Signedness for MULH operation
  logic        mulh_shift_arith;  // Arithmetic shift for MULH
  logic        mulh_carry_q;  // Carry bit for MULH operation
  logic        mulh_save;  // Save signal for MULH operation
  logic        mulh_clearcarry;  // Clear carry signal for MULH
  logic        mulh_ready;  // Ready signal for MULH

  mult_state_e mulh_CS, mulh_NS;  // Current and next state for MULH FSM

  // Calculate rounding constant
  assign short_round_tmp = (32'h00000001) << imm_i;
  // Rounding for MUL_IR
  assign short_round = (operator_i == MUL_IR) ? {1'b0, short_round_tmp[31:1]} : '0;

  // Select lower/upper half of op_a
  assign short_op_a[15:0] = short_subword[0] ? op_a_i[31:16] : op_a_i[15:0];
  // Select lower/upper half of op_b
  assign short_op_b[15:0] = short_subword[1] ? op_b_i[31:16] : op_b_i[15:0];

  // Sign extension for short_op_a
  assign short_op_a[16] = short_signed[0] & short_op_a[15];
  // Sign extension for short_op_b
  assign short_op_b[16] = short_signed[1] & short_op_b[15];

  // Operand C for short MAC, with MULH carry
  assign short_op_c = mulh_active_o ? $signed({mulh_carry_q, op_c_i}) : $signed(op_c_i);

  // Perform signed multiplication of short operands
  assign short_mul = $signed(short_op_a) * $signed(short_op_b);
  // Perform signed MAC operation
  assign short_mac = $signed(short_op_c) + $signed(short_mul) + $signed(short_round);

  // Shift and sign-extend the short MAC result
  assign short_result = $signed(
      {short_shift_arith & short_mac_msb1, short_shift_arith & short_mac_msb0, short_mac[31:0]}
  ) >>> short_imm;

  // Select immediate based on MULH activity
  assign short_imm = mulh_active_o ? mulh_imm : imm_i;
  // Select subword based on MULH activity
  assign short_subword = mulh_active_o ? mulh_subword : {2{short_subword_i}};
  // Select signedness based on MULH activity
  assign short_signed = mulh_active_o ? mulh_signed : short_signed_i;
  // Select shift type based on MULH
  assign short_shift_arith = mulh_active_o ? mulh_shift_arith : short_signed_i[0];

  // Select MSB based on MULH activity
  assign short_mac_msb1 = mulh_active_o ? short_mac[33] : short_mac[31];
  // Select second MSB based on MULH activity
  assign short_mac_msb0 = mulh_active_o ? short_mac[32] : short_mac[31];

  always_comb begin
    mulh_NS          = mulh_CS;  // Default next state is current state
    mulh_imm         = 5'd0;  // Default MULH immediate value
    mulh_subword     = 2'b00;  // Default MULH subword value
    mulh_signed      = 2'b00;  // Default MULH signed value
    mulh_shift_arith = 1'b0;  // Default MULH shift type
    mulh_ready       = 1'b0;  // Default MULH ready is low
    mulh_active_o    = 1'b1;  // Default MULH active is high
    mulh_save        = 1'b0;  // Default MULH save is low
    mulh_clearcarry  = 1'b0;  // Default MULH clear carry is low
    multicycle_o     = 1'b0;  // Default is not a multicycle op

    case (mulh_CS)
      default: begin
        mulh_active_o = 1'b0;  // MULH is not active in IDLE
        mulh_ready    = 1'b1;  // Multiplier is ready in IDLE
        mulh_save     = 1'b0;  // Don't save carry in IDLE
        if ((operator_i == MUL_H) && enable_i) begin  // Start MULH if enabled and opcode is MUL_H
          mulh_ready = 1'b0; // Not ready during MULH operation
          mulh_NS    = STEP0; // Go to the first step of MULH
        end
      end

      STEP0: begin
        multicycle_o  = 1'b1;  // MULH is a multicycle operation
        mulh_imm      = 5'd16;  // Shift by 16 bits in STEP0
        mulh_active_o = 1'b1;  // MULH is active

        mulh_save     = 1'b0;  // Don't save carry in STEP0
        mulh_NS       = STEP1;  // Go to the next step
      end

      STEP1: begin
        multicycle_o     = 1'b1;  // Still a multicycle operation

        mulh_signed      = {short_signed_i[1], 1'b0};  // Set signedness for STEP1
        mulh_subword     = 2'b10;  // Select upper half of op_a, lower of op_b
        mulh_save        = 1'b1;  // Save the carry from this step
        mulh_shift_arith = 1'b1;  // Use arithmetic shift
        mulh_NS          = STEP2;  // Go to the next step
      end

      STEP2: begin
        multicycle_o     = 1'b1;  // Still a multicycle operation

        mulh_signed      = {1'b0, short_signed_i[0]};  // Set signedness for STEP2
        mulh_subword     = 2'b01;  // Select lower half of op_a, upper of op_b
        mulh_imm         = 5'd16;  // Shift by 16 bits in STEP2
        mulh_save        = 1'b1;  // Save the carry from this step
        mulh_clearcarry  = 1'b1;  // Clear the carry before saving
        mulh_shift_arith = 1'b1;  // Use arithmetic shift
        mulh_NS          = FINISH;  // Go to the final step
      end

      FINISH: begin
        mulh_signed  = short_signed_i;  // Restore original signedness
        mulh_subword = 2'b11;  // Select both halves (though result is ready)
        mulh_ready   = 1'b1;  // MULH operation is complete
        if (ex_ready_i) mulh_NS = IDLE_MULT;  // Go back to IDLE when external ready
      end
    endcase
  end

  always_ff @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      mulh_CS      <= IDLE_MULT;  // Reset MULH state to IDLE
      mulh_carry_q <= 1'b0;  // Reset MULH carry
    end else begin
      mulh_CS <= mulh_NS;  // Update MULH state

      if (mulh_save) mulh_carry_q <= ~mulh_clearcarry & short_mac[32];  // Save carry if enabled
      else if (ex_ready_i) mulh_carry_q <= 1'b0;  // Clear carry if external ready
    end
  end

  logic [31:0] int_op_a_msu;  // Internal operand A for MUL_MSU32
  logic [31:0] int_op_b_msu;  // Internal operand B for MUL_MSU32
  logic [31:0] int_result;  // Internal result for MUL_MAC/MSU

  logic        int_is_msu;  // Flag indicating MUL_MSU32 operation

  assign int_is_msu = (operator_i == MUL_MSU32);  // Check if the operation is MUL_MSU32

  assign int_op_a_msu = op_a_i ^ {32{int_is_msu}};  // Conditional inversion of op_a for MSU
  assign int_op_b_msu = op_b_i & {32{int_is_msu}};  // Conditional AND of op_b for MSU

  assign int_result = $signed(  // Calculate result for MUL_MAC32 and MUL_MSU32
          op_c_i
      ) + $signed(
          int_op_b_msu
      ) + $signed(
          int_op_a_msu
      ) * $signed(
          op_b_i
      );

  logic [31:0]       dot_char_result;  // Result of dot product of chars
  logic [32:0]       dot_short_result;  // Result of dot product of shorts
  logic [31:0]       accumulator;  // Accumulator for dot product
  logic [15:0]       clpx_shift_result;  // Result after CLPX shift
  logic [ 3:0][ 8:0] dot_char_op_a;  // Operands A for char dot product
  logic [ 3:0][ 8:0] dot_char_op_b;  // Operands B for char dot product
  logic [ 3:0][17:0] dot_char_mul;  // Multiplication results for char dot product

  logic [ 1:0][16:0] dot_short_op_a;  // Operands A for short dot product
  logic [ 1:0][16:0] dot_short_op_b;  // Operands B for short dot product
  logic [ 1:0][33:0] dot_short_mul;  // Multiplication results for short dot product
  logic [16:0]       dot_short_op_a_1_neg;  // Negated upper half of dot_op_a
  logic [31:0]       dot_short_op_b_ext;  // Extended upper half of dot_op_b

  // Extract and sign-extend byte 0 of op_a
  assign dot_char_op_a[0] = {dot_signed_i[1] & dot_op_a_i[7], dot_op_a_i[7:0]};
  // Extract and sign-extend byte 1 of op_a
  assign dot_char_op_a[1] = {dot_signed_i[1] & dot_op_a_i[15], dot_op_a_i[15:8]};
  // Extract and sign-extend byte 2 of op_a
  assign dot_char_op_a[2] = {dot_signed_i[1] & dot_op_a_i[23], dot_op_a_i[23:16]};
  // Extract and sign-extend byte 3 of op_a
  assign dot_char_op_a[3] = {dot_signed_i[1] & dot_op_a_i[31], dot_op_a_i[31:24]};

  // Extract and sign-extend byte 0 of op_b
  assign dot_char_op_b[0] = {dot_signed_i[0] & dot_op_b_i[7], dot_op_b_i[7:0]};
  // Extract and sign-extend byte 1 of op_b
  assign dot_char_op_b[1] = {dot_signed_i[0] & dot_op_b_i[15], dot_op_b_i[15:8]};
  // Extract and sign-extend byte 2 of op_b
  assign dot_char_op_b[2] = {dot_signed_i[0] & dot_op_b_i[23], dot_op_b_i[23:16]};
  // Extract and sign-extend byte 3 of op_b
  assign dot_char_op_b[3] = {dot_signed_i[0] & dot_op_b_i[31], dot_op_b_i[31:24]};

  // Multiply byte 0 of op_a and op_b
  assign dot_char_mul[0] = $signed(dot_char_op_a[0]) * $signed(dot_char_op_b[0]);
  // Multiply byte 1 of op_a and op_b
  assign dot_char_mul[1] = $signed(dot_char_op_a[1]) * $signed(dot_char_op_b[1]);
  // Multiply byte 2 of op_a and op_b
  assign dot_char_mul[2] = $signed(dot_char_op_a[2]) * $signed(dot_char_op_b[2]);
  // Multiply byte 3 of op_a and op_b
  assign dot_char_mul[3] = $signed(dot_char_op_a[3]) * $signed(dot_char_op_b[3]);

  assign dot_char_result = $signed(  // Sum the byte multiplications and add op_c
          dot_char_mul[0]
      ) + $signed(
          dot_char_mul[1]
      ) + $signed(
          dot_char_mul[2]
      ) + $signed(
          dot_char_mul[3]
      ) + $signed(
          dot_op_c_i
      );

  // Extract and sign-extend lower half of op_a
  assign dot_short_op_a[0] = {dot_signed_i[1] & dot_op_a_i[15], dot_op_a_i[15:0]};
  // Extract and sign-extend upper half of op_a
  assign dot_short_op_a[1] = {dot_signed_i[1] & dot_op_a_i[31], dot_op_a_i[31:16]};
  // Conditional negation for CLPX
  assign dot_short_op_a_1_neg = dot_short_op_a[1] ^ {17{(is_clpx_i & ~clpx_img_i)}};

  assign dot_short_op_b[0] = (is_clpx_i & clpx_img_i) ? {  // Select based on CLPX and image
      dot_signed_i[0] & dot_op_b_i[31], dot_op_b_i[31:16]
  } : {
    dot_signed_i[0] & dot_op_b_i[15], dot_op_b_i[15:0]
  };
  assign dot_short_op_b[1] = (is_clpx_i & clpx_img_i) ? {  // Select based on CLPX and image
      dot_signed_i[0] & dot_op_b_i[15], dot_op_b_i[15:0]
  } : {
    dot_signed_i[0] & dot_op_b_i[31], dot_op_b_i[31:16]
  };

  // Multiply lower halves
  assign dot_short_mul[0] = $signed(dot_short_op_a[0]) * $signed(dot_short_op_b[0]);
  // Multiply upper halves (potentially negated)
  assign dot_short_mul[1] = $signed(dot_short_op_a_1_neg) * $signed(dot_short_op_b[1]);

  // Sign-extend upper half of op_b
  assign dot_short_op_b_ext = $signed(dot_short_op_b[1]);
  // Accumulator for CLPX or op_c
  assign accumulator = is_clpx_i ? dot_short_op_b_ext & {32{~clpx_img_i}} : $signed(dot_op_c_i);

  // Sum the short multiplications and accumulator
  assign dot_short_result = $signed(
      dot_short_mul[0][31:0]
  ) + $signed(
      dot_short_mul[1][31:0]
  ) + $signed(
      accumulator
  );
  // Shift the upper 16 bits for CLPX
  assign clpx_shift_result = $signed(dot_short_result[31:15]) >>> clpx_shift_i;

  always_comb begin
    result_o = '0;  // Default result is zero

    unique case (operator_i)
      // Result for MAC/MSU operations
      MUL_MAC32, MUL_MSU32: result_o = int_result[31:0];

      // Result for short multiplication operations
      MUL_I, MUL_IR, MUL_H: result_o = short_result[31:0];

      // Result for byte dot product
      MUL_DOT8: result_o = dot_char_result[31:0];

      MUL_DOT16: begin
        if (is_clpx_i) begin  // Handle complex instruction
          if (clpx_img_i) begin  // Image mode
            result_o[31:16] = clpx_shift_result;  // Upper half is shifted result
            result_o[15:0]  = dot_op_c_i[15:0];  // Lower half is from op_c
          end else begin  // Real mode
            result_o[15:0]  = clpx_shift_result;  // Lower half is shifted result
            result_o[31:16] = dot_op_c_i[31:16];  // Upper half is from op_c
          end
        end else begin  // Standard MUL_DOT16
          result_o = dot_short_result[31:0];  // Result is from short dot product
        end
      end

      default: begin  // Handle other cases (currently empty)

      end
    endcase
  end

  assign ready_o = mulh_ready;  // Multiplier ready signal is tied to MULH ready

endmodule
