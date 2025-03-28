// Module definition for a parameterized FIFO buffer
module rv32imf_fifo #(
    // Parameter to enable fall-through behavior (output directly reflects input when empty)
    parameter bit FALL_THROUGH = 1'b0,
    // Parameter defining the width of the data stored in the FIFO
    parameter int unsigned DATA_WIDTH = 32,
    // Parameter defining the maximum number of elements the FIFO can hold
    parameter int unsigned DEPTH = 8,

    // Parameter defining the number of address bits required for the FIFO memory
    parameter int unsigned ADDR_DEPTH = (DEPTH > 1) ? $clog2(DEPTH) : 1
) (
    // Input clock signal
    input logic clk_i,
    // Input reset signal (active low)
    input logic rst_ni,
    // Input signal to synchronously flush the entire FIFO
    input logic flush_i,
    // Input signal to flush all but the first element in the FIFO
    input logic flush_but_first_i,
    // Input signal for test mode (not used in the provided logic)
    input logic testmode_i,

    // Output signal indicating if the FIFO is full
    output logic full_o,
    // Output signal indicating if the FIFO is empty
    output logic empty_o,
    // Output signal indicating the current number of elements in the FIFO
    output logic [ADDR_DEPTH:0] cnt_o,

    // Input data to be written into the FIFO
    input logic [DATA_WIDTH-1:0] data_i,
    // Input signal to trigger writing data into the FIFO
    input logic push_i,

    // Output data read from the FIFO
    output logic [DATA_WIDTH-1:0] data_o,
    // Input signal to trigger reading data from the FIFO
    input logic pop_i
);

  // Local parameter to ensure FIFO depth is at least 1 if DEPTH is 0
  localparam int unsigned FifoDepth = (DEPTH > 0) ? DEPTH : 1;

  // Internal signal to gate the clock for memory writes (optimization)
  logic gate_clock;

  // Internal signals to store the read and write pointers
  logic [ADDR_DEPTH - 1:0] read_pointer_n, read_pointer_q, write_pointer_n, write_pointer_q;

  // Internal signals to track the number of elements in the FIFO
  logic [ADDR_DEPTH:0] status_cnt_n, status_cnt_q;

  // Internal memory array to store the FIFO data
  logic [FifoDepth - 1:0][DATA_WIDTH-1:0] mem_n, mem_q;

  // Assign the current count of FIFO elements to the output
  assign cnt_o = status_cnt_q;

  // Generate block to handle zero-depth FIFO (effectively a wire)
  generate
    if (DEPTH == 0) begin : gen_zero_depth
      // For zero depth, empty when not pushing
      assign empty_o = ~push_i;
      // For zero depth, full when not popping
      assign full_o  = ~pop_i;
    end else begin : gen_non_zero_depth
      // FIFO is full when the count equals the maximum depth
      assign full_o  = (status_cnt_q == FifoDepth[ADDR_DEPTH:0]);
      // FIFO is empty when count is zero AND fall-through is not active during a push
      assign empty_o = (status_cnt_q == 0) & ~(FALL_THROUGH & push_i);
    end
  endgenerate

  // Combinational block for read and write logic
  always_comb begin : read_write_comb

    // Default assignments for next state logic
    read_pointer_n  = read_pointer_q;
    write_pointer_n = write_pointer_q;
    status_cnt_n    = status_cnt_q;
    // Default data output: from memory at read pointer, or input if zero depth
    data_o          = (DEPTH == 0) ? data_i : mem_q[read_pointer_q];
    // Default next memory state is the current memory state
    mem_n           = mem_q;
    // By default, allow clock gating (no write)
    gate_clock      = 1'b1;

    // If push is active and FIFO is not full
    if (push_i && ~full_o) begin
      // Write the input data to the memory at the write pointer
      mem_n[write_pointer_q] = data_i;

      // Prevent clock gating for this cycle (memory write will occur)
      gate_clock = 1'b0;

      // Increment the write pointer, wrap around if necessary
      if (write_pointer_q == FifoDepth[ADDR_DEPTH-1:0] - 1) write_pointer_n = '0;
      else write_pointer_n = write_pointer_q + 1;

      // Increment the status count
      status_cnt_n = status_cnt_q + 1;
    end

    // If pop is active and FIFO is not empty
    if (pop_i && ~empty_o) begin
      // Increment the read pointer, wrap around if necessary
      if (read_pointer_n == FifoDepth[ADDR_DEPTH-1:0] - 1) read_pointer_n = '0;
      else read_pointer_n = read_pointer_q + 1;

      // Decrement the status count
      status_cnt_n = status_cnt_q - 1;
    end

    // If both push and pop are active and FIFO is neither full nor empty, count remains the same
    if (push_i && pop_i && ~full_o && ~empty_o) status_cnt_n = status_cnt_q;

    // Implement fall-through behavior
    if (FALL_THROUGH && (status_cnt_q == 0) && push_i) begin
      // Output data directly from the input
      data_o = data_i;
      // If also popping, maintain the count and pointers (no actual FIFO operation)
      if (pop_i) begin
        status_cnt_n = status_cnt_q;
        read_pointer_n = read_pointer_q;
        write_pointer_n = write_pointer_q;
      end
    end
  end

  // Sequential block for updating read pointer, write pointer, and status count
  always_ff @(posedge clk_i or negedge rst_ni) begin
    // Reset condition: when rst_ni is low
    if (~rst_ni) begin
      // Initialize read pointer to 0
      read_pointer_q  <= '0;
      // Initialize write pointer to 0
      write_pointer_q <= '0;
      // Initialize status count to 0 (empty)
      status_cnt_q    <= '0;
    end else begin
      // Handle flush and normal operation
      unique case (1'b1)

        // Synchronous flush: reset all pointers and count
        flush_i: begin
          read_pointer_q  <= '0;
          write_pointer_q <= '0;
          status_cnt_q    <= '0;
        end

        // Flush all but the first element
        flush_but_first_i: begin
          read_pointer_q  <= (status_cnt_q > 0) ? read_pointer_q : '0;
          write_pointer_q <= (status_cnt_q > 0) ? read_pointer_q + 1 : '0;
          status_cnt_q    <= (status_cnt_q > 0) ? 1'b1 : '0;
        end

        // Normal operation: update pointers and count
        default: begin
          read_pointer_q  <= read_pointer_n;
          write_pointer_q <= write_pointer_n;
          status_cnt_q    <= status_cnt_n;
        end
      endcase
    end
  end

  // Sequential block for updating the memory array
  always_ff @(posedge clk_i or negedge rst_ni) begin
    // Reset condition: clear the memory
    if (~rst_ni) begin
      mem_q <= '0;
    end else if (!gate_clock) begin
      // Update memory with the new value when not clock gated (during a push)
      mem_q <= mem_n;
    end
  end

endmodule
