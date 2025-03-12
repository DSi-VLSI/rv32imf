


module rv32imf_prefetch_controller #(
    parameter int DEPTH           = 4,
    parameter int FIFO_ADDR_DEPTH = (DEPTH > 1) ? $clog2(DEPTH) : 1
) (
    input logic clk,
    input logic rst_n,

    input  logic        req_i,
    input  logic        branch_i,
    input  logic [31:0] branch_addr_i,
    output logic        busy_o,

    input logic [31:0] hwlp_target_i,

    output logic        trans_valid_o,
    input  logic        trans_ready_i,
    output logic [31:0] trans_addr_o,

    input logic resp_valid_i,

    input  logic fetch_ready_i,
    output logic fetch_valid_o,

    output logic                     fifo_push_o,
    output logic                     fifo_pop_o,
    output logic                     fifo_flush_o,
    input  logic [FIFO_ADDR_DEPTH:0] fifo_cnt_i,
    input  logic                     fifo_empty_i
);

  import rv32imf_pkg::*;

  prefetch_state_e state_q, next_state;

  logic [FIFO_ADDR_DEPTH:0] cnt_q;
  logic [FIFO_ADDR_DEPTH:0] next_cnt;
  logic                     count_up;
  logic                     count_down;

  logic [FIFO_ADDR_DEPTH:0] flush_cnt_q;
  logic [FIFO_ADDR_DEPTH:0] next_flush_cnt;

  logic [31:0] trans_addr_q, trans_addr_incr;
  logic [             31:0] aligned_branch_addr;

  logic                     fifo_valid;
  logic [FIFO_ADDR_DEPTH:0] fifo_cnt_masked;


  assign busy_o = (cnt_q != 3'b000) || trans_valid_o;


  assign fetch_valid_o = (fifo_valid || resp_valid_i) && !(branch_i || (flush_cnt_q > 0));


  assign aligned_branch_addr = {branch_addr_i[31:2], 2'b00};


  assign trans_addr_incr = {trans_addr_q[31:2], 2'b00} + 32'd4;

  assign trans_valid_o = req_i && (fifo_cnt_masked + cnt_q < DEPTH);

  assign fifo_cnt_masked = (branch_i) ? '0 : fifo_cnt_i;

  always_comb begin
    next_state   = state_q;
    trans_addr_o = trans_addr_q;

    case (state_q)
      default: begin
        if (branch_i) begin
          trans_addr_o = aligned_branch_addr;
        end else begin
          trans_addr_o = trans_addr_incr;
        end
        if ((branch_i) && !(trans_valid_o && trans_ready_i)) begin
          next_state = BRANCH_WAIT;
        end
      end

      BRANCH_WAIT: begin
        trans_addr_o = branch_i ? aligned_branch_addr : trans_addr_q;
        if (trans_valid_o && trans_ready_i) begin
          next_state = IDLE;
        end
      end
    endcase
  end


  assign fifo_valid = !fifo_empty_i;
  assign fifo_push_o = resp_valid_i &&
                      (fifo_valid || !fetch_ready_i) && !(branch_i || (flush_cnt_q > 0));
  assign fifo_pop_o = fifo_valid && fetch_ready_i;


  assign count_up = trans_valid_o && trans_ready_i;
  assign count_down = resp_valid_i;

  always_comb begin
    case ({
      count_up, count_down
    })
      2'b01:   next_cnt = cnt_q - 1'b1;
      2'b10:   next_cnt = cnt_q + 1'b1;
      default: next_cnt = cnt_q;
    endcase
  end

  assign fifo_flush_o = branch_i;

  always_comb begin
    next_flush_cnt = flush_cnt_q;
    if (branch_i) begin
      next_flush_cnt = cnt_q;
      if (resp_valid_i && (cnt_q > 0)) begin
        next_flush_cnt = cnt_q - 1'b1;
      end
    end else if (resp_valid_i && (flush_cnt_q > 0)) begin
      next_flush_cnt = flush_cnt_q - 1'b1;
    end
  end

  always_ff @(posedge clk, negedge rst_n) begin
    if (rst_n == 1'b0) begin
      state_q      <= IDLE;
      cnt_q        <= '0;
      flush_cnt_q  <= '0;
      trans_addr_q <= '0;
    end else begin
      state_q     <= next_state;
      cnt_q       <= next_cnt;
      flush_cnt_q <= next_flush_cnt;
      if (branch_i || (trans_valid_o && trans_ready_i)) begin
        trans_addr_q <= trans_addr_o;
      end
    end
  end

endmodule
