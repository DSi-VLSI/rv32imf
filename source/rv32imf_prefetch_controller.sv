// Module definition for the prefetch controller
module rv32imf_prefetch_controller #(
    // Parameter defining the depth of the prefetch FIFO
    parameter int DEPTH           = 4,
    // Parameter defining the address depth for the prefetch FIFO counter
    parameter int FIFO_ADDR_DEPTH = (DEPTH > 1) ? $clog2(DEPTH) : 1
) (
    // Input clock signal
    input logic clk,
    // Input reset signal (active low)
    input logic rst_n,

    // Input signal indicating a new fetch request
    input  logic        req_i,
    // Input signal indicating a branch instruction has occurred
    input  logic        branch_i,
    // Input signal providing the target address of the branch
    input  logic [31:0] branch_addr_i,
    // Output signal indicating if the prefetch controller is busy
    output logic        busy_o,

    // Input signal for a hardware loop prefetch target address (not currently used in logic)
    input logic [31:0] hwlp_target_i,

    // Output signal indicating the prefetch transaction is valid
    output logic        trans_valid_o,
    // Input signal indicating the prefetch transaction is ready to be accepted
    input  logic        trans_ready_i,
    // Output signal providing the address for the prefetch transaction
    output logic [31:0] trans_addr_o,

    // Input signal indicating a prefetch response has been received
    input logic resp_valid_i,

    // Input signal indicating the instruction fetch unit is ready for a new instruction
    input  logic fetch_ready_i,
    // Output signal indicating a prefetched instruction is valid and ready for fetch
    output logic fetch_valid_o,

    // Output signal to push data into the prefetch FIFO
    output logic                     fifo_push_o,
    // Output signal to pop data from the prefetch FIFO
    output logic                     fifo_pop_o,
    // Output signal to flush the prefetch FIFO
    output logic                     fifo_flush_o,
    // Input signal providing the current count of the prefetch FIFO
    input  logic [FIFO_ADDR_DEPTH:0] fifo_cnt_i,
    // Input signal indicating if the prefetch FIFO is empty
    input  logic                     fifo_empty_i
);

  // Import definitions from the rv32imf package
  import rv32imf_pkg::*;

  // State type for the prefetch controller's state machine
  typedef enum logic [1:0] {
    IDLE,
    BRANCH_WAIT
  } prefetch_state_e;

  // State register for the prefetch controller
  prefetch_state_e state_q, next_state;

  // Register to count the number of outstanding prefetch requests
  logic [FIFO_ADDR_DEPTH:0] cnt_q;
  logic [FIFO_ADDR_DEPTH:0] next_cnt;
  // Control signal to increment the outstanding request counter
  logic                     count_up;
  // Control signal to decrement the outstanding request counter
  logic                     count_down;

  // Register to track the number of valid entries to flush after a branch
  logic [FIFO_ADDR_DEPTH:0] flush_cnt_q;
  logic [FIFO_ADDR_DEPTH:0] next_flush_cnt;

  // Register to store the address for the current prefetch transaction
  logic [31:0] trans_addr_q, trans_addr_incr;
  // Logic to store the branch target address aligned to a 4-byte boundary
  logic [             31:0] aligned_branch_addr;

  // Logic signal indicating if the FIFO contains valid data
  logic                     fifo_valid;
  // Masked FIFO count for prefetch request logic
  logic [FIFO_ADDR_DEPTH:0] fifo_cnt_masked;

  // Assign busy output: controller has outstanding requests OR a transaction is in progress
  assign busy_o = (cnt_q != '0) || trans_valid_o;

  // Assign fetch valid output: FIFO has data OR a response is received AND no branch/flush
  assign fetch_valid_o = (fifo_valid || resp_valid_i) && !(branch_i || (flush_cnt_q > '0));

  // Align the branch target address to a 4-byte boundary
  assign aligned_branch_addr = {branch_addr_i[31:2], 2'b00};

  // Calculate the next sequential prefetch address
  assign trans_addr_incr = {trans_addr_q[31:2], 2'b00} + 32'd4;

  // Assign transaction valid output: request is active AND FIFO has space
  assign trans_valid_o = req_i && (fifo_cnt_masked + cnt_q < DEPTH);

  // Mask the FIFO count to zero during a branch to prevent new prefetches
  assign fifo_cnt_masked = (branch_i) ? '0 : fifo_cnt_i;

  // Combinational logic for the next state and transaction address
  always_comb begin
    next_state   = state_q;
    trans_addr_o = trans_addr_q;

    case (state_q)
      default: begin  // IDLE state
        // If a branch occurs, prefetch from the aligned branch address
        if (branch_i) begin
          trans_addr_o = aligned_branch_addr;
        end else begin
          // Otherwise, prefetch the next sequential address
          trans_addr_o = trans_addr_incr;
        end
        // If a branch occurs and the transaction is not yet initiated, wait
        if ((branch_i) && !(trans_valid_o && trans_ready_i)) begin
          next_state = BRANCH_WAIT;
        end
      end

      BRANCH_WAIT: begin
        // Keep the branch target address ready for transaction
        trans_addr_o = branch_i ? aligned_branch_addr : trans_addr_q;
        // Once the branch transaction is initiated, go back to IDLE
        if (trans_valid_o && trans_ready_i) begin
          next_state = IDLE;
        end
      end
    endcase
  end

  // Assign FIFO valid signal based on whether the FIFO is empty
  assign fifo_valid = !fifo_empty_i;
  // Assign FIFO push output: response received AND (FIFO has data OR fetch not ready) AND no branch/flush
  assign fifo_push_o = resp_valid_i &&
                       (fifo_valid || !fetch_ready_i) && !(branch_i || (flush_cnt_q > '0));
  // Assign FIFO pop output: FIFO has data AND fetch unit is ready
  assign fifo_pop_o = fifo_valid && fetch_ready_i;

  // Assign count up signal when a prefetch transaction is initiated
  assign count_up = trans_valid_o && trans_ready_i;
  // Assign count down signal when a prefetch response is received
  assign count_down = resp_valid_i;

  // Combinational logic to determine the next value of the outstanding request counter
  always_comb begin
    case ({
      count_up, count_down
    })
      2'b01:   next_cnt = cnt_q - 1'b1;  // Decrement on response
      2'b10:   next_cnt = cnt_q + 1'b1;  // Increment on transaction
      default: next_cnt = cnt_q;  // No change
    endcase
  end

  // Assign FIFO flush output when a branch occurs
  assign fifo_flush_o = branch_i;

  // Combinational logic to manage the flush counter
  always_comb begin
    next_flush_cnt = flush_cnt_q;
    // If a branch occurs, start flushing existing entries
    if (branch_i) begin
      next_flush_cnt = cnt_q;  // Initialize flush counter with outstanding requests
      // If a response is received during a branch flush, decrement the counter
      if (resp_valid_i && (cnt_q > '0)) begin
        next_flush_cnt = cnt_q - 1'b1;
      end
    end else if (resp_valid_i && (flush_cnt_q > '0)) begin
      // If not branching and still flushing, decrement the counter on response
      next_flush_cnt = flush_cnt_q - 1'b1;
    end
  end

  // Sequential logic block for updating registers
  always_ff @(posedge clk, negedge rst_n) begin
    // Reset condition
    if (rst_n == 1'b0) begin
      state_q      <= IDLE;
      cnt_q        <= '0;
      flush_cnt_q  <= '0;
      trans_addr_q <= '0;
    end else begin
      state_q     <= next_state;
      cnt_q       <= next_cnt;
      flush_cnt_q <= next_flush_cnt;
      // Update transaction address when a branch occurs or a transaction is initiated
      if (branch_i || (trans_valid_o && trans_ready_i)) begin
        trans_addr_q <= trans_addr_o;
      end
    end
  end

endmodule
