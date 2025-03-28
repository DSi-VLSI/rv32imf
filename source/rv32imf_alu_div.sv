module rv32imf_alu_div #(
    parameter int C_WIDTH = 32,
    parameter int C_LOG_WIDTH = 6
) (
    input logic Clk_CI,
    input logic Rst_RBI,

    input logic [    C_WIDTH-1:0] OpA_DI,       // Operand A input
    input logic [    C_WIDTH-1:0] OpB_DI,       // Operand B input
    input logic [C_LOG_WIDTH-1:0] OpBShift_DI,  // Operand B shift amount input
    input logic                   OpBIsZero_SI, // Operand B is zero input

    input logic       OpBSign_SI,  // Operand B sign input
    input logic [1:0] OpCode_SI,   // Operation code input

    input logic InVld_SI,  // Input valid signal

    input  logic               OutRdy_SI,  // Output ready signal
    output logic               OutVld_SO,  // Output valid signal
    output logic [C_WIDTH-1:0] Res_DO      // Result output
);

  // Internal registers
  logic [C_WIDTH-1:0] ResReg_DP, ResReg_DN;
  logic [C_WIDTH-1:0] ResReg_DP_rev;
  logic [C_WIDTH-1:0] AReg_DP, AReg_DN;
  logic [C_WIDTH-1:0] BReg_DP, BReg_DN;

  // Control signals for registers
  logic RemSel_SN, RemSel_SP;
  logic CompInv_SN, CompInv_SP;
  logic ResInv_SN, ResInv_SP;

  // Internal data path signals
  logic [C_WIDTH-1:0] AddMux_D;
  logic [C_WIDTH-1:0] AddOut_D;
  logic [C_WIDTH-1:0] AddTmp_D;
  logic [C_WIDTH-1:0] BMux_D;
  logic [C_WIDTH-1:0] OutMux_D;

  // Counter signals
  logic [C_LOG_WIDTH-1:0] Cnt_DP, Cnt_DN;
  logic CntZero_S;

  // Control signals
  logic ARegEn_S, BRegEn_S, ResRegEn_S, ABComp_S, PmSel_S, LoadEn_S;

  // FSM state definition
  typedef enum logic [1:0] {
    IDLE,
    DIVIDE,
    FINISH
  } state_t;
  state_t State_SN, State_SP;

  //  --- Datapath Logic ---

  // Select addition or subtraction for division
  assign PmSel_S  = LoadEn_S & ~(OpCode_SI[0] & (OpA_DI[$high(OpA_DI)] ^ OpBSign_SI));

  // Multiplexer for the adder input
  assign AddMux_D = (LoadEn_S) ? OpA_DI : BReg_DP;

  // Multiplexer for the B register input
  assign BMux_D   = (LoadEn_S) ? OpB_DI : {CompInv_SP, (BReg_DP[$high(BReg_DP):1])};

  // Bit reversal for the result register
  genvar index;
  generate
    for (index = 0; index < C_WIDTH; index++) begin : gen_bit_swapping
      assign ResReg_DP_rev[index] = ResReg_DP[C_WIDTH-1-index];
    end
  endgenerate

  // Output multiplexer to select remainder or quotient
  assign OutMux_D = (RemSel_SP) ? AReg_DP : ResReg_DP_rev;

  // Result output with sign correction
  assign Res_DO = (ResInv_SP) ? -$signed(OutMux_D) : OutMux_D;

  // Comparator for A and B registers
  assign ABComp_S   = ((AReg_DP == BReg_DP) | ((AReg_DP > BReg_DP) ^ CompInv_SP))
              & ((|AReg_DP) | OpBIsZero_SI);

  // Temporary value for addition/subtraction
  assign AddTmp_D = (LoadEn_S) ? 0 : AReg_DP;
  // Adder output
  assign AddOut_D = (PmSel_S) ? AddTmp_D + AddMux_D : AddTmp_D - $signed(AddMux_D);

  //  --- Control Logic ---

  // Counter decrement logic
  assign Cnt_DN = (LoadEn_S) ? OpBShift_DI : (~CntZero_S) ? Cnt_DP - 1 : Cnt_DP;

  // Counter zero detection
  assign CntZero_S = ~(|Cnt_DP);

  //  --- Finite State Machine ---

  always_comb begin : p_fsm

    State_SN   = State_SP;

    OutVld_SO  = 1'b0;

    LoadEn_S   = 1'b0;

    ARegEn_S   = 1'b0;
    BRegEn_S   = 1'b0;
    ResRegEn_S = 1'b0;

    case (State_SP)

      IDLE: begin
        OutVld_SO = 1'b1;  // Output is valid in IDLE state

        // Start division when input is valid
        if (InVld_SI) begin
          OutVld_SO = 1'b0;
          ARegEn_S  = 1'b1;  // Enable A register load
          BRegEn_S  = 1'b1;  // Enable B register load
          LoadEn_S  = 1'b1;  // Enable initial load
          State_SN  = DIVIDE;  // Go to DIVIDE state
        end
      end

      DIVIDE: begin
        ARegEn_S   = ABComp_S;  // Enable A register if A >= B
        BRegEn_S   = 1'b1;  // Always enable B register
        ResRegEn_S = 1'b1;  // Always enable result register

        // Go to FINISH state when the counter is zero
        if (CntZero_S) begin
          State_SN = FINISH;
        end
      end

      FINISH: begin
        OutVld_SO = 1'b1;  // Output is valid in FINISH state

        // Go back to IDLE when output is ready
        if (OutRdy_SI) begin
          State_SN = IDLE;
        end
      end

      default: begin
        // Default case - should not happen
      end

    endcase
  end

  //  --- Control Register Updates ---

  // Remainder selection update
  assign RemSel_SN = (LoadEn_S) ? OpCode_SI[1] : RemSel_SP;
  // Comparator inversion update
  assign CompInv_SN = (LoadEn_S) ? OpBSign_SI : CompInv_SP;
  // Result inversion update
  assign ResInv_SN = (LoadEn_S) ? (~OpBIsZero_SI | OpCode_SI[1]) & OpCode_SI[0] & (OpA_DI[$high(
      OpA_DI
  )] ^ OpBSign_SI) : ResInv_SP;

  // A register update
  assign AReg_DN = (ARegEn_S) ? AddOut_D : AReg_DP;
  // B register update
  assign BReg_DN = (BRegEn_S) ? BMux_D : BReg_DP;
  // Result register update
  assign ResReg_DN = (LoadEn_S) ? '0 : (ResRegEn_S) ? {ABComp_S, ResReg_DP[$high(
      ResReg_DP
  ):1]} : ResReg_DP;

  // Register update on clock edge or reset
  always_ff @(posedge Clk_CI or negedge Rst_RBI) begin : p_regs
    if (~Rst_RBI) begin
      State_SP   <= IDLE;
      AReg_DP    <= '0;
      BReg_DP    <= '0;
      ResReg_DP  <= '0;
      Cnt_DP     <= '0;
      RemSel_SP  <= 1'b0;
      CompInv_SP <= 1'b0;
      ResInv_SP  <= 1'b0;
    end else begin
      State_SP   <= State_SN;
      AReg_DP    <= AReg_DN;
      BReg_DP    <= BReg_DN;
      ResReg_DP  <= ResReg_DN;
      Cnt_DP     <= Cnt_DN;
      RemSel_SP  <= RemSel_SN;
      CompInv_SP <= CompInv_SN;
      ResInv_SP  <= ResInv_SN;
    end
  end

endmodule
