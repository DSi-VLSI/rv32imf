module rv32imf_aligner (
    input logic clk,
    input logic rst_n,

    input  logic fetch_valid_i,
    output logic aligner_ready_o,

    input logic if_valid_i,

    input  logic [31:0] fetch_rdata_i,
    output logic [31:0] instr_aligned_o,
    output logic        instr_valid_o,

    input logic [31:0] branch_addr_i,
    input logic        branch_i,

    input logic [31:0] hwlp_addr_i,

    output logic [31:0] pc_o
);

  typedef enum logic [2:0] {
    ALIGNED32,
    MISALIGNED32,
    MISALIGNED16,
    BRANCH_MISALIGNED,
    WAIT_VALID_BRANCH
  } state_t;
  state_t state, next_state;

  logic [15:0] r_instr_h;
  logic [31:0] hwlp_addr_q;
  logic [31:0] pc_q, pc_n;
  logic update_state;
  logic [31:0] pc_plus4, pc_plus2;
  logic aligner_ready_q, hwlp_update_pc_q;

  assign pc_o     = pc_q;

  assign pc_plus2 = pc_q + 2;
  assign pc_plus4 = pc_q + 4;

  always_ff @(posedge clk or negedge rst_n) begin : proc_SEQ_FSM
    if (~rst_n) begin
      state            <= ALIGNED32;
      r_instr_h        <= '0;
      hwlp_addr_q      <= '0;
      pc_q             <= '0;
      aligner_ready_q  <= 1'b0;
      hwlp_update_pc_q <= 1'b0;
    end else begin
      if (update_state) begin
        pc_q             <= pc_n;
        state            <= next_state;
        r_instr_h        <= fetch_rdata_i[31:16];
        aligner_ready_q  <= aligner_ready_o;
        hwlp_update_pc_q <= 1'b0;
      end
    end
  end

  always_comb begin


    pc_n            = pc_q;
    instr_valid_o   = fetch_valid_i;
    instr_aligned_o = fetch_rdata_i;
    aligner_ready_o = 1'b1;
    update_state    = 1'b0;
    next_state      = state;


    case (state)
      ALIGNED32: begin
        if (fetch_rdata_i[1:0] == 2'b11) begin
          next_state      = ALIGNED32;
          pc_n            = pc_plus4;
          instr_aligned_o = fetch_rdata_i;

          update_state    = fetch_valid_i & if_valid_i;
          if (hwlp_update_pc_q) pc_n = hwlp_addr_q;
        end else begin
          next_state      = MISALIGNED32;
          pc_n            = pc_plus2;
          instr_aligned_o = fetch_rdata_i;

          update_state    = fetch_valid_i & if_valid_i;
        end
      end


      MISALIGNED32: begin
        if (r_instr_h[1:0] == 2'b11) begin
          next_state      = MISALIGNED32;
          pc_n            = pc_plus4;
          instr_aligned_o = {fetch_rdata_i[15:0], r_instr_h[15:0]};

          update_state    = fetch_valid_i & if_valid_i;
        end else begin
          instr_aligned_o = {fetch_rdata_i[31:16], r_instr_h[15:0]};
          next_state = MISALIGNED16;
          instr_valid_o = 1'b1;
          pc_n = pc_plus2;


          aligner_ready_o = !fetch_valid_i;

          update_state = if_valid_i;
        end
      end


      MISALIGNED16: begin

        instr_valid_o = !aligner_ready_q || fetch_valid_i;
        if (fetch_rdata_i[1:0] == 2'b11) begin
          next_state      = ALIGNED32;
          pc_n            = pc_plus4;
          instr_aligned_o = fetch_rdata_i;

          update_state    = (!aligner_ready_q | fetch_valid_i) & if_valid_i;
        end else begin
          next_state = MISALIGNED32;
          pc_n = pc_plus2;
          instr_aligned_o = fetch_rdata_i;

          update_state = (!aligner_ready_q | fetch_valid_i) & if_valid_i;
        end
      end


      BRANCH_MISALIGNED: begin

        if (fetch_rdata_i[17:16] == 2'b11) begin
          next_state      = MISALIGNED32;
          instr_valid_o   = 1'b0;
          pc_n            = pc_q;
          instr_aligned_o = fetch_rdata_i;

          update_state    = fetch_valid_i & if_valid_i;
        end else begin
          next_state = ALIGNED32;
          pc_n = pc_plus2;
          instr_aligned_o = {fetch_rdata_i[31:16], fetch_rdata_i[31:16]};

          update_state = fetch_valid_i & if_valid_i;
        end
      end

    endcase



    if (branch_i) begin
      update_state = 1'b1;
      pc_n         = branch_addr_i;
      next_state   = branch_addr_i[1] ? BRANCH_MISALIGNED : ALIGNED32;
    end

  end

endmodule
