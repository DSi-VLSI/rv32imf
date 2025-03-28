// Module definition for the instruction aligner
module rv32imf_aligner (
    // Input clock signal
    input logic clk,
    // Input reset signal (active low)
    input logic rst_n,

    // Input signal indicating valid data fetched from memory
    input  logic fetch_valid_i,
    // Output signal indicating the aligner is ready for the next fetch
    output logic aligner_ready_o,

    // Input signal indicating the instruction fetch stage is valid/active
    input logic if_valid_i,

    // Input signal providing the 32-bit data fetched from memory
    input  logic [31:0] fetch_rdata_i,
    // Output signal providing the aligned instruction (16 or 32 bits)
    output logic [31:0] instr_aligned_o,
    // Output signal indicating the aligned instruction is valid
    output logic        instr_valid_o,

    // Input signal providing the target address of a branch instruction
    input logic [31:0] branch_addr_i,
    // Input signal indicating a branch instruction has occurred
    input logic        branch_i,

    // Input signal for a hardware loop address (not currently used in the logic)
    input logic [31:0] hwlp_addr_i,

    // Output signal providing the program counter for the next instruction
    output logic [31:0] pc_o
);

  // Define the states for the aligner's state machine
  typedef enum logic [2:0] {
    ALIGNED32,          // Currently processing a 32-bit aligned instruction
    MISALIGNED32,       // Processing a 32-bit instruction that started at an odd address
    MISALIGNED16,       // Processing the second half of a 32-bit misaligned instruction
    BRANCH_MISALIGNED,  // Handling a branch to a misaligned address
    WAIT_VALID_BRANCH   // Waiting for valid fetch data after a branch (not used in current logic)
  } state_t;
  // State register for the aligner's state machine
  state_t state, next_state;

  // Register to store the upper 16 bits of a fetched word for misaligned instructions
  logic [15:0] r_instr_h;
  // Register to store the hardware loop address (not used in current logic)
  logic [31:0] hwlp_addr_q;
  // Registers for the current and next program counter
  logic [31:0] pc_q, pc_n;
  // Control signal to trigger state and PC updates
  logic update_state;
  // Logic signals for PC + 4 and PC + 2 calculations
  logic [31:0] pc_plus4, pc_plus2;
  // Registers for aligner ready status and hardware loop PC update (not used in current logic)
  logic aligner_ready_q, hwlp_update_pc_q;

  // Assign the current program counter to the output
  assign pc_o = pc_q;

  // Calculate PC + 2 for potential 16-bit instruction boundaries
  assign pc_plus2 = pc_q + 2;
  // Calculate PC + 4 for standard 32-bit instruction increment
  assign pc_plus4 = pc_q + 4;

  // Sequential block for the aligner's state machine and register updates
  always_ff @(posedge clk or negedge rst_n) begin : proc_SEQ_FSM
    if (~rst_n) begin
      state            <= ALIGNED32;  // Initialize state to aligned 32-bit
      r_instr_h        <= '0;  // Initialize stored upper half instruction
      hwlp_addr_q      <= '0;  // Initialize hardware loop address
      pc_q             <= '0;  // Initialize program counter
      aligner_ready_q  <= 1'b0;  // Initialize aligner ready status
      hwlp_update_pc_q <= 1'b0;  // Initialize hardware loop PC update flag
    end else begin
      if (update_state) begin
        pc_q             <= pc_n;  // Update program counter
        state            <= next_state;  // Update state
        r_instr_h        <= fetch_rdata_i[31:16];  // Store upper half of fetched data
        aligner_ready_q  <= aligner_ready_o;  // Update aligner ready status
        hwlp_update_pc_q <= 1'b0;  // Reset hardware loop PC update flag
      end
    end
  end

  // Combinational block for next state logic, PC calculation, and output assignments
  always_comb begin

    pc_n            = pc_q;  // Default next PC is current PC
    instr_valid_o   = fetch_valid_i;  // Instruction is valid if fetch is valid
    instr_aligned_o = fetch_rdata_i;  // Default aligned instruction is the fetched data
    aligner_ready_o = 1'b1;  // Default aligner ready status is true
    update_state    = 1'b0;  // Default update state is false
    next_state      = state;  // Default next state is the current state

    case (state)
      ALIGNED32: begin
        // If the fetched instruction's lower 2 bits are '11' (indicating a 32-bit instruction)
        if (fetch_rdata_i[1:0] == 2'b11) begin
          next_state      = ALIGNED32;  // Stay in aligned 32-bit state
          pc_n            = pc_plus4;  // Increment PC by 4 for the next 32-bit instruction
          instr_aligned_o = fetch_rdata_i;  // Output the fetched 32-bit instruction

          // Update state if fetch and IF stage are valid
          update_state    = fetch_valid_i & if_valid_i;
          if (hwlp_update_pc_q) pc_n = hwlp_addr_q;  // Update PC from hardware loop (not used)
        end else begin
          next_state      = MISALIGNED32;  // Transition to misaligned 32-bit state
          pc_n            = pc_plus2;  // Increment PC by 2 (assuming 16-bit instruction start)
          instr_aligned_o = fetch_rdata_i;  // Output the fetched (potentially partial) data

          // Update state if fetch and IF stage are valid
          update_state    = fetch_valid_i & if_valid_i;
        end
      end

      MISALIGNED32: begin
        // If the stored upper 16 bits' lower 2 bits are '11' (completing a 32-bit instruction)
        if (r_instr_h[1:0] == 2'b11) begin
          next_state = MISALIGNED32;  // Stay in misaligned 32-bit state
          pc_n = pc_plus4;  // Increment PC by 4
          instr_aligned_o = {
            fetch_rdata_i[15:0], r_instr_h[15:0]
          };  // Combine lower and upper halves

          // Update state if fetch and IF stage are valid
          update_state = fetch_valid_i & if_valid_i;
        end else begin
          instr_aligned_o = {
            fetch_rdata_i[31:16], r_instr_h[15:0]
          };  // Combine previous upper and current lower halves
          next_state = MISALIGNED16;  // Transition to misaligned 16-bit state
          instr_valid_o = 1'b1;  // The 16-bit instruction is now valid
          pc_n = pc_plus2;  // Increment PC by 2

          aligner_ready_o = !fetch_valid_i;  // Aligner not ready if still waiting for next fetch

          update_state = if_valid_i;  // Update state if IF stage is valid
        end
      end

      MISALIGNED16: begin
        // Instruction valid if aligner was not ready or new fetch is valid
        instr_valid_o = !aligner_ready_q || fetch_valid_i;
        // If the newly fetched instruction's lower 2 bits are '11'
        if (fetch_rdata_i[1:0] == 2'b11) begin
          next_state      = ALIGNED32;  // Transition to aligned 32-bit state
          pc_n            = pc_plus4;  // Increment PC by 4
          instr_aligned_o = fetch_rdata_i;  // Output the fetched 32-bit instruction

          update_state    = (!aligner_ready_q | fetch_valid_i) & if_valid_i;  // Update state
        end else begin
          next_state      = MISALIGNED32;  // Transition to misaligned 32-bit state
          pc_n            = pc_plus2;  // Increment PC by 2
          instr_aligned_o = fetch_rdata_i;  // Output the fetched (potentially partial) data

          update_state    = (!aligner_ready_q | fetch_valid_i) & if_valid_i;  // Update state
        end
      end

      BRANCH_MISALIGNED: begin
        // If the fetched data (after a branch to a misaligned address) indicates a 32-bit instruction
        if (fetch_rdata_i[17:16] == 2'b11) begin
          next_state      = MISALIGNED32;  // Transition to misaligned 32-bit state
          instr_valid_o   = 1'b0;  // Instruction not immediately valid
          pc_n            = pc_q;  // Keep the PC as the branch target
          instr_aligned_o = fetch_rdata_i;  // Output the fetched data

          update_state    = fetch_valid_i & if_valid_i;  // Update state
        end else begin
          next_state      = ALIGNED32;  // Transition to aligned 32-bit state
          pc_n            = pc_plus2;  // Increment PC by 2
          instr_aligned_o = {fetch_rdata_i[31:16], fetch_rdata_i[31:16]};  // Duplicate upper half

          update_state    = fetch_valid_i & if_valid_i;  // Update state
        end
      end

      default: ;  // No action for default case

    endcase

    // Handle branch condition
    if (branch_i) begin
      update_state = 1'b1;  // Force update on a branch
      pc_n = branch_addr_i;  // Set PC to the branch target address

      // Set next state based on branch address alignment
      next_state = branch_addr_i[1] ? BRANCH_MISALIGNED : ALIGNED32;
    end

  end

endmodule
