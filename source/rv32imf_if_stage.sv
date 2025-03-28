// Module definition for the Instruction Fetch (IF) stage
module rv32imf_if_stage #(
) (
    // Input clock signal
    input logic clk,
    // Input reset signal (active low)
    input logic rst_n,

    // Input base address for machine mode trap vector
    input logic [23:0] m_trap_base_addr_i,
    // Input base address for user mode trap vector
    input logic [23:0] u_trap_base_addr_i,
    // Input to select the trap base address (e.g., for machine or user mode)
    input logic [ 1:0] trap_addr_mux_i,

    // Input boot address for the processor
    input logic [31:0] boot_addr_i,
    // Input address for debug mode exception
    input logic [31:0] dm_exception_addr_i,
    // Input address for debug mode halt
    input logic [31:0] dm_halt_addr_i,

    // Input request signal to start fetching instructions
    input logic req_i,

    // Output request signal to the instruction memory interface
    output logic instr_req_o,
    // Output address for the instruction memory request
    output logic [31:0] instr_addr_o,
    // Input grant signal from the instruction memory interface
    input logic instr_gnt_i,
    // Input valid signal indicating fetched instruction data is ready
    input logic instr_rvalid_i,
    // Input fetched instruction data from memory
    input logic [31:0] instr_rdata_i,
    // Input error signal from the instruction memory interface
    input logic instr_err_i,
    // Input PMP (Physical Memory Protection) error signal from instruction memory
    input logic instr_err_pmp_i,

    // Output valid signal for the instruction going to the ID (Decode) stage
    output logic instr_valid_id_o,
    // Output instruction data going to the ID stage
    output logic [31:0] instr_rdata_id_o,
    // Output signal indicating if the instruction going to ID stage was compressed
    output logic is_compressed_id_o,
    // Output signal indicating if the compressed instruction was illegal
    output logic illegal_c_insn_id_o,
    // Output program counter value at the IF stage (before alignment)
    output logic [31:0] pc_if_o,
    // Output program counter value going to the ID stage
    output logic [31:0] pc_id_o,
    // Output signal indicating if the instruction fetch failed
    output logic is_fetch_failed_o,

    // Input signal to clear the instruction valid signal to the ID stage
    input logic        clear_instr_valid_i,
    // Input signal indicating that the PC should be set to a new value
    input logic        pc_set_i,
    // Input Machine mode Exception Program Counter
    input logic [31:0] mepc_i,
    // Input User mode Exception Program Counter
    input logic [31:0] uepc_i,
    // Input Debug mode Exception Program Counter
    input logic [31:0] depc_i,

    // Input to select the next PC source
    input  logic [3:0] pc_mux_i,
    // Input to select the exception PC source
    input  logic [2:0] exc_pc_mux_i,
    // Input to select the machine mode exception vector offset
    input  logic [4:0] m_exc_vec_pc_mux_i,
    // Input to select the user mode exception vector offset
    input  logic [4:0] u_exc_vec_pc_mux_i,
    // Output signal to indicate that CSR mtvec should be initialized (on boot)
    output logic       csr_mtvec_init_o,

    // Input jump target address from the ID stage
    input logic [31:0] jump_target_id_i,
    // Input jump target address from the EX (Execute) stage (for branches)
    input logic [31:0] jump_target_ex_i,

    // Input target address for hardware loops
    input logic [31:0] hwlp_target_i,

    // Input signal to halt the IF stage
    input logic halt_if_i,
    // Input signal indicating that the ID stage is ready to accept a new instruction
    input logic id_ready_i,

    // Output signal indicating if the IF stage is busy (e.g., waiting for memory)
    output logic if_busy_o,
    // Output signal for performance monitoring, indicating an instruction miss
    output logic perf_imiss_o
);

  // Import the package containing definitions for opcodes, constants, etc.
  import rv32imf_pkg::*;

  // Internal signals for IF stage control and data flow
  logic if_valid, if_ready;
  logic        prefetch_busy;
  logic        branch_req;
  logic [31:0] branch_addr_n;
  logic        fetch_valid;
  logic        fetch_ready;
  logic [31:0] fetch_rdata;
  logic [31:0] exc_pc;
  logic [23:0] trap_base_addr;
  logic [ 4:0] exc_vec_pc_mux;
  logic        fetch_failed;
  logic        aligner_ready;
  logic        instr_valid;
  logic        illegal_c_insn;
  logic [31:0] instr_aligned;
  logic [31:0] instr_decompressed;
  logic        instr_compressed_int;

  // Combinational block to determine the exception program counter (exc_pc)
  always_comb begin : EXC_PC_MUX
    // Select the trap base address based on the trap_addr_mux_i input
    unique case (trap_addr_mux_i)
      TRAP_MACHINE: trap_base_addr = m_trap_base_addr_i;  // Machine mode trap base address
      TRAP_USER:    trap_base_addr = u_trap_base_addr_i;  // User mode trap base address
      default:      trap_base_addr = m_trap_base_addr_i;  // Default to machine mode
    endcase

    // Select the exception vector offset mux based on the trap_addr_mux_i input
    unique case (trap_addr_mux_i)
      TRAP_MACHINE: exc_vec_pc_mux = m_exc_vec_pc_mux_i;  // Machine mode exception vector offset
      TRAP_USER:    exc_vec_pc_mux = u_exc_vec_pc_mux_i;  // User mode exception vector offset
      default:      exc_vec_pc_mux = m_exc_vec_pc_mux_i;  // Default to machine mode
    endcase

    // Determine the exception PC based on the exc_pc_mux_i input
    unique case (exc_pc_mux_i)
      EXC_PC_EXCEPTION:
      exc_pc = {trap_base_addr, 8'h0};  // Base address for synchronous exceptions
      EXC_PC_IRQ:
      exc_pc = {trap_base_addr, 1'b0, exc_vec_pc_mux, 2'b0};  // Base + interrupt vector offset
      EXC_PC_DBD: exc_pc = {dm_halt_addr_i[31:2], 2'b0};  // Debug mode halt address
      EXC_PC_DBE: exc_pc = {dm_exception_addr_i[31:2], 2'b0};  // Debug mode exception address
      default: exc_pc = {trap_base_addr, 8'h0};  // Default to exception base address
    endcase
  end

  // Combinational block to determine the next branch address (branch_addr_n)
  always_comb begin
    // Default next PC is the boot address
    branch_addr_n = {boot_addr_i[31:2], 2'b0};

    // Select the next PC source based on the pc_mux_i input
    unique case (pc_mux_i)
      PC_BOOT:      branch_addr_n = {boot_addr_i[31:2], 2'b0};  // Boot address
      PC_JUMP:      branch_addr_n = jump_target_id_i;  // Jump target from ID stage
      PC_BRANCH:    branch_addr_n = jump_target_ex_i;  // Branch target from EX stage
      PC_EXCEPTION: branch_addr_n = exc_pc;  // Exception handler address
      PC_MRET:      branch_addr_n = mepc_i;  // Machine mode return address
      PC_URET:      branch_addr_n = uepc_i;  // User mode return address
      PC_DRET:      branch_addr_n = depc_i;  // Debug mode return address
      PC_FENCEI:    branch_addr_n = pc_id_o + 4;  // PC + 4 after FENCE.I instruction
      PC_HWLOOP:    branch_addr_n = hwlp_target_i;  // Hardware loop target address
      default:      ;  // Keep the default value
    endcase
  end

  // Assign the csr_mtvec_init_o output, indicating MTvec initialization on boot
  assign csr_mtvec_init_o = (pc_mux_i == PC_BOOT) & pc_set_i;

  // Fetch failed signal (currently always false in this implementation)
  assign fetch_failed = 1'b0;

  // Instantiate the prefetch buffer module
  rv32imf_prefetch_buffer #() prefetch_buffer_i (
      .clk  (clk),
      .rst_n(rst_n),

      .req_i(req_i),

      .branch_i     (branch_req),
      .branch_addr_i({branch_addr_n[31:1], 1'b0}), // Pass branch address to prefetch buffer

      .hwlp_target_i(hwlp_target_i),

      .fetch_ready_i(fetch_ready),
      .fetch_valid_o(fetch_valid),
      .fetch_rdata_o(fetch_rdata),

      .instr_req_o   (instr_req_o),
      .instr_addr_o  (instr_addr_o),
      .instr_gnt_i   (instr_gnt_i),
      .instr_rvalid_i(instr_rvalid_i),
      .instr_err_i   (instr_err_i),
      .instr_err_pmp_i(instr_err_pmp_i),
      .instr_rdata_i (instr_rdata_i),

      .busy_o(prefetch_busy)
  );

  // Combinational block to control fetch ready and branch request signals
  always_comb begin
    fetch_ready = 1'b0;  // Default fetch ready is false
    branch_req  = 1'b0;  // Default branch request is false

    // If a new PC is being set
    if (pc_set_i) begin
      branch_req = 1'b1;  // Indicate a branch (PC update) to the prefetch buffer
    end else if (fetch_valid) begin
      // If data was fetched and the IF stage is active
      if (req_i && if_valid) begin
        fetch_ready = aligner_ready; // Ready to fetch the next instruction if the aligner is ready
      end
    end
  end

  // Assign the IF stage busy status to the prefetch buffer's busy signal
  assign if_busy_o = prefetch_busy;
  // Assign the performance instruction miss signal
  assign perf_imiss_o = !fetch_valid && !branch_req;

  // Sequential block for the IF/ID pipeline registers
  always_ff @(posedge clk, negedge rst_n) begin : IF_ID_PIPE_REGISTERS
    if (rst_n == 1'b0) begin
      instr_valid_id_o    <= 1'b0;  // Initialize instruction valid to ID stage
      instr_rdata_id_o    <= '0;  // Initialize instruction data to ID stage
      is_fetch_failed_o   <= 1'b0;  // Initialize fetch failed status
      pc_id_o             <= '0;  // Initialize PC to ID stage
      is_compressed_id_o  <= 1'b0;  // Initialize compressed instruction flag
      illegal_c_insn_id_o <= 1'b0;  // Initialize illegal compressed instruction flag
    end else begin
      // If the IF stage is valid and an instruction is valid from the aligner
      if (if_valid && instr_valid) begin
        instr_valid_id_o <= 1'b1;  // Mark instruction as valid for ID stage
        instr_rdata_id_o <= instr_decompressed;  // Pass the decompressed instruction to ID stage
        is_compressed_id_o <= instr_compressed_int;  // Pass the compressed status to ID stage
        illegal_c_insn_id_o <= illegal_c_insn;  // Pass the illegal compressed status to ID stage
        is_fetch_failed_o <= 1'b0;  // Reset fetch failed status
        pc_id_o <= pc_if_o;  // Pass the PC to the ID stage
      end else if (clear_instr_valid_i) begin
        // If a signal to clear the instruction valid is received
        instr_valid_id_o  <= 1'b0;  // Clear the instruction valid signal
        is_fetch_failed_o <= fetch_failed;  // Update fetch failed status
      end
    end
  end

  // Assign the IF stage valid signal (ready to send instruction to ID)
  // Valid if fetch data is available and ID stage is ready
  assign if_ready = fetch_valid & id_ready_i;
  // IF stage is valid if not halted and ready
  assign if_valid = (~halt_if_i) & if_ready;

  // Instantiate the instruction aligner module
  rv32imf_aligner aligner_i (
      .clk            (clk),
      .rst_n          (rst_n),
      .fetch_valid_i  (fetch_valid),
      .aligner_ready_o(aligner_ready),
      .if_valid_i     (if_valid),
      .fetch_rdata_i  (fetch_rdata),
      .instr_aligned_o(instr_aligned),
      .instr_valid_o  (instr_valid),
      .branch_addr_i  ({branch_addr_n[31:1], 1'b0}),  // Pass branch address to aligner
      .branch_i       (branch_req),
      .hwlp_addr_i    (hwlp_target_i),
      .pc_o           (pc_if_o)
  );

  // Instantiate the compressed instruction decoder module
  rv32imf_compressed_decoder #() compressed_decoder_i (
      .instr_i        (instr_aligned),
      .instr_o        (instr_decompressed),
      .is_compressed_o(instr_compressed_int),
      .illegal_instr_o(illegal_c_insn)
  );

endmodule
