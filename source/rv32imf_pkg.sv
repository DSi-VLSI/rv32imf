package rv32imf_pkg;

  // Instruction Opcodes (7-bit)
  parameter int OPCODE_SYSTEM = 7'h73;  // System instructions (e.g., ECALL, EBREAK)
  parameter int OPCODE_FENCE = 7'h0f;  // Memory ordering instruction
  parameter int OPCODE_OP = 7'h33;  // Arithmetic and logical operations (register-register)
  parameter int OPCODE_OPIMM = 7'h13;  // Arithmetic and logical operations (register-immediate)
  parameter int OPCODE_STORE = 7'h23;  // Store instructions
  parameter int OPCODE_LOAD = 7'h03;  // Load instructions
  parameter int OPCODE_BRANCH = 7'h63;  // Branch instructions
  parameter int OPCODE_JALR = 7'h67;  // Jump and Link Register
  parameter int OPCODE_JAL = 7'h6f;  // Jump and Link
  parameter int OPCODE_AUIPC = 7'h17;  // Add Upper Immediate to PC
  parameter int OPCODE_LUI = 7'h37;  // Load Upper Immediate
  parameter int OPCODE_OP_FP = 7'h53;  // Floating-point arithmetic operations (register-register)
  parameter int OPCODE_OP_FMADD = 7'h43;  // Floating-point fused multiply-add
  parameter int OPCODE_OP_FNMADD = 7'h4f;  // Floating-point fused negative multiply-add
  parameter int OPCODE_OP_FMSUB = 7'h47;  // Floating-point fused multiply-subtract
  parameter int OPCODE_OP_FNMSUB = 7'h4b;  // Floating-point fused negative multiply-subtract
  parameter int OPCODE_STORE_FP = 7'h27;  // Floating-point store instructions
  parameter int OPCODE_LOAD_FP = 7'h07;  // Floating-point load instructions
  parameter int OPCODE_AMO = 7'h2F;  // Atomic memory operations

  // Custom Instruction Opcodes (7-bit)
  parameter int OPCODE_CUSTOM_0 = 7'h0b;  // Reserved for custom instructions
  parameter int OPCODE_CUSTOM_1 = 7'h2b;  // Reserved for custom instructions
  parameter int OPCODE_CUSTOM_2 = 7'h5b;  // Reserved for custom instructions
  parameter int OPCODE_CUSTOM_3 = 7'h7b;  // Reserved for custom instructions

  // Register Class Selectors (2-bit)
  parameter int REGC_S1 = 2'b10;  // Register class selector for source register 1
  parameter int REGC_S4 = 2'b00;  // Register class selector for source register 4
  parameter int REGC_RD = 2'b01;  // Register class selector for destination register
  parameter int REGC_ZERO = 2'b11;  // Register class selector for the zero register

  // ALU Operation Width
  parameter int ALU_OP_WIDTH = 7;

  // ALU Operation Codes (7-bit)
  typedef enum logic [ALU_OP_WIDTH-1:0] {
    // Arithmetic operations
    ALU_ADD   = 7'b0011000,  // Addition
    ALU_SUB   = 7'b0011001,  // Subtraction
    ALU_ADDU  = 7'b0011010,  // Addition with unsigned operands
    ALU_SUBU  = 7'b0011011,  // Subtraction with unsigned operands
    ALU_ADDR  = 7'b0011100,  // Add with register operand
    ALU_SUBR  = 7'b0011101,  // Subtract with register operand
    ALU_ADDUR = 7'b0011110,  // Add unsigned with register operand
    ALU_SUBUR = 7'b0011111,  // Subtract unsigned with register operand

    // Logical operations
    ALU_XOR = 7'b0101111,  // Bitwise XOR
    ALU_OR  = 7'b0101110,  // Bitwise OR
    ALU_AND = 7'b0010101,  // Bitwise AND

    // Shift operations
    ALU_SRA = 7'b0100100,  // Arithmetic right shift
    ALU_SRL = 7'b0100101,  // Logical right shift
    ALU_ROR = 7'b0100110,  // Rotate right
    ALU_SLL = 7'b0100111,  // Logical left shift

    // Bit manipulation operations
    ALU_BEXT  = 7'b0101000,  // Bit extract
    ALU_BEXTU = 7'b0101001,  // Bit extract unsigned
    ALU_BINS  = 7'b0101010,  // Bit insert
    ALU_BCLR  = 7'b0101011,  // Bit clear
    ALU_BSET  = 7'b0101100,  // Bit set
    ALU_BREV  = 7'b1001001,  // Bit reverse

    // Count leading/trailing ones/zeros
    ALU_FF1 = 7'b0110110,  // Find first one
    ALU_FL1 = 7'b0110111,  // Find last one
    ALU_CNT = 7'b0110100,  // Count set bits
    ALU_CLB = 7'b0110101,  // Count leading bits

    // Extension operations
    ALU_EXTS = 7'b0111110,  // Sign extension
    ALU_EXT  = 7'b0111111,  // Zero extension

    // Comparison operations (set less than, equal, etc.)
    ALU_LTS = 7'b0000000,  // Less than signed
    ALU_LTU = 7'b0000001,  // Less than unsigned
    ALU_LES = 7'b0000100,  // Less than or equal signed
    ALU_LEU = 7'b0000101,  // Less than or equal unsigned
    ALU_GTS = 7'b0001000,  // Greater than signed
    ALU_GTU = 7'b0001001,  // Greater than unsigned
    ALU_GES = 7'b0001010,  // Greater than or equal signed
    ALU_GEU = 7'b0001011,  // Greater than or equal unsigned
    ALU_EQ  = 7'b0001100,  // Equal
    ALU_NE  = 7'b0001101,  // Not equal

    // Set less than immediate
    ALU_SLTS  = 7'b0000010,  // Set less than signed immediate
    ALU_SLTU  = 7'b0000011,  // Set less than unsigned immediate
    ALU_SLETS = 7'b0000110,  // Set less than or equal signed immediate
    ALU_SLETU = 7'b0000111,  // Set less than or equal unsigned immediate

    // Absolute value and clip
    ALU_ABS   = 7'b0010100,  // Absolute value
    ALU_CLIP  = 7'b0010110,  // Clip to a signed range
    ALU_CLIPU = 7'b0010111,  // Clip to an unsigned range

    // Insert operation
    ALU_INS = 7'b0101101,  // Insert bits

    // Minimum and maximum operations
    ALU_MIN  = 7'b0010000,  // Minimum signed
    ALU_MINU = 7'b0010001,  // Minimum unsigned
    ALU_MAX  = 7'b0010010,  // Maximum signed
    ALU_MAXU = 7'b0010011,  // Maximum unsigned

    // Division and remainder operations
    ALU_DIVU = 7'b0110000,  // Division unsigned
    ALU_DIV  = 7'b0110001,  // Division signed
    ALU_REMU = 7'b0110010,  // Remainder unsigned
    ALU_REM  = 7'b0110011,  // Remainder signed

    // Shuffle and pack operations
    ALU_SHUF  = 7'b0111010,  // Shuffle bytes
    ALU_SHUF2 = 7'b0111011,  // Shuffle two elements
    ALU_PCKLO = 7'b0111000,  // Pack low
    ALU_PCKHI = 7'b0111001   // Pack high
  } alu_opcode_e;

  // Multiplication Operation Width
  parameter int MUL_OP_WIDTH = 3;

  // Multiplication Operation Codes (3-bit)
  typedef enum logic [MUL_OP_WIDTH-1:0] {
    MUL_MAC32 = 3'b000,  // Multiply-accumulate 32-bit
    MUL_MSU32 = 3'b001,  // Multiply-subtract 32-bit
    MUL_I     = 3'b010,  // Integer multiply
    MUL_IR    = 3'b011,  // Integer multiply with rounding
    MUL_DOT8  = 3'b100,  // Dot product of 8-bit elements
    MUL_DOT16 = 3'b101,  // Dot product of 16-bit elements
    MUL_H     = 3'b110   // Multiply high bits
  } mul_opcode_e;

  // Vector Processing Modes (2-bit)
  parameter int VEC_MODE32 = 2'b00;  // Vector mode for 32-bit elements
  parameter int VEC_MODE16 = 2'b10;  // Vector mode for 16-bit elements
  parameter int VEC_MODE8 = 2'b11;  // Vector mode for 8-bit elements

  // Control Unit State Machine States (5-bit)
  typedef enum logic [4:0] {
    RESET,            // Initial reset state
    BOOT_SET,         // State for setting up after reset
    SLEEP,            // Low power sleep state
    WAIT_SLEEP,       // State waiting to enter sleep
    FIRST_FETCH,      // State for fetching the first instruction
    DECODE,           // Instruction decode stage
    IRQ_FLUSH_ELW,    // Flush pipeline due to interrupt during early load word
    ELW_EXE,          // Execute stage for early load word instructions
    FLUSH_EX,         // Flush pipeline after execute stage
    FLUSH_WB,         // Flush pipeline after writeback stage
    XRET_JUMP,        // State for jumping after exception return
    DBG_TAKEN_ID,     // Debug mode taken during instruction decode
    DBG_TAKEN_IF,     // Debug mode taken during instruction fetch
    DBG_FLUSH,        // Flush pipeline in debug mode
    DBG_WAIT_BRANCH,  // Debug mode waiting for branch to resolve
    DECODE_HWLOOP     // Decode state for hardware loop instructions
  } ctrl_state_e;

  // Debug Status Indices
  parameter int HAVERESET_INDEX = 0;  // Index for the 'have reset' status bit
  parameter int RUNNING_INDEX = 1;  // Index for the 'running' status bit
  parameter int HALTED_INDEX = 2;  // Index for the 'halted' status bit

  // Debug State Codes (3-bit)
  typedef enum logic [2:0] {
    HAVERESET = 3'b001, // Indicates the core has experienced a reset
    RUNNING   = 3'b010, // Indicates the core is currently executing instructions
    HALTED    = 3'b100  // Indicates the core is in a halted state (e.g., due to a breakpoint)
  } debug_state_e;

  // Prefetch Unit State Machine States (1-bit)
  typedef enum logic {
    IDLE,        // Prefetch unit is idle
    BRANCH_WAIT  // Prefetch unit is waiting for a branch to resolve
  } prefetch_state_e;

  // Multiplier Unit State Machine States (3-bit)
  typedef enum logic [2:0] {
    IDLE_MULT, // Multiplier unit is idle
    STEP0,     // First step of multiplication
    STEP1,     // Second step of multiplication
    STEP2,     // Third step of multiplication
    FINISH     // Multiplication operation is complete
  } mult_state_e;

  // Control and Status Register (CSR) Numbers (12-bit)
  typedef enum logic [11:0] {
    // User-level CSRs
    CSR_USTATUS  = 12'h000,  // User status register
    CSR_FFLAGS   = 12'h001,  // Floating-point flags
    CSR_FRM      = 12'h002,  // Floating-point rounding mode
    CSR_FCSR     = 12'h003,  // Floating-point control and status register
    CSR_UTVEC    = 12'h005,  // User trap vector base address
    CSR_UEPC     = 12'h041,  // User exception program counter
    CSR_UCAUSE   = 12'h042,  // User trap cause
    CSR_LPSTART0 = 12'hCC0,  // Loop start address 0
    CSR_LPEND0   = 12'hCC1,  // Loop end address 0
    CSR_LPCOUNT0 = 12'hCC2,  // Loop counter 0
    CSR_LPSTART1 = 12'hCC4,  // Loop start address 1
    CSR_LPEND1   = 12'hCC5,  // Loop end address 1
    CSR_LPCOUNT1 = 12'hCC6,  // Loop counter 1
    CSR_UHARTID  = 12'hCD0,  // User hardware thread ID
    CSR_PRIVLV   = 12'hCD1,  // User privilege level
    CSR_ZFINX    = 12'hCD2,  // User floating-point invalid operation flag

    // Machine-level CSRs
    CSR_MSTATUS       = 12'h300,  // Machine status register
    CSR_MISA          = 12'h301,  // Machine ISA and extensions
    CSR_MIE           = 12'h304,  // Machine interrupt enable
    CSR_MTVEC         = 12'h305,  // Machine trap vector base address
    CSR_MCOUNTEREN    = 12'h306,  // Machine counter enable
    CSR_MCOUNTINHIBIT = 12'h320,  // Machine counter inhibit

    // Machine-level Performance Monitoring Event Selectors
    CSR_MHPMEVENT3  = 12'h323,
    CSR_MHPMEVENT4  = 12'h324,
    CSR_MHPMEVENT5  = 12'h325,
    CSR_MHPMEVENT6  = 12'h326,
    CSR_MHPMEVENT7  = 12'h327,
    CSR_MHPMEVENT8  = 12'h328,
    CSR_MHPMEVENT9  = 12'h329,
    CSR_MHPMEVENT10 = 12'h32A,
    CSR_MHPMEVENT11 = 12'h32B,
    CSR_MHPMEVENT12 = 12'h32C,
    CSR_MHPMEVENT13 = 12'h32D,
    CSR_MHPMEVENT14 = 12'h32E,
    CSR_MHPMEVENT15 = 12'h32F,
    CSR_MHPMEVENT16 = 12'h330,
    CSR_MHPMEVENT17 = 12'h331,
    CSR_MHPMEVENT18 = 12'h332,
    CSR_MHPMEVENT19 = 12'h333,
    CSR_MHPMEVENT20 = 12'h334,
    CSR_MHPMEVENT21 = 12'h335,
    CSR_MHPMEVENT22 = 12'h336,
    CSR_MHPMEVENT23 = 12'h337,
    CSR_MHPMEVENT24 = 12'h338,
    CSR_MHPMEVENT25 = 12'h339,
    CSR_MHPMEVENT26 = 12'h33A,
    CSR_MHPMEVENT27 = 12'h33B,
    CSR_MHPMEVENT28 = 12'h33C,
    CSR_MHPMEVENT29 = 12'h33D,
    CSR_MHPMEVENT30 = 12'h33E,
    CSR_MHPMEVENT31 = 12'h33F,

    CSR_MSCRATCH = 12'h340,  // Machine scratch register
    CSR_MEPC     = 12'h341,  // Machine exception program counter
    CSR_MCAUSE   = 12'h342,  // Machine trap cause
    CSR_MTVAL    = 12'h343,  // Machine trap value
    CSR_MIP      = 12'h344,  // Machine interrupt pending

    // Physical Memory Protection Configuration Registers
    CSR_PMPCFG0 = 12'h3A0,
    CSR_PMPCFG1 = 12'h3A1,
    CSR_PMPCFG2 = 12'h3A2,
    CSR_PMPCFG3 = 12'h3A3,

    // Physical Memory Protection Address Registers
    CSR_PMPADDR0  = 12'h3B0,
    CSR_PMPADDR1  = 12'h3B1,
    CSR_PMPADDR2  = 12'h3B2,
    CSR_PMPADDR3  = 12'h3B3,
    CSR_PMPADDR4  = 12'h3B4,
    CSR_PMPADDR5  = 12'h3B5,
    CSR_PMPADDR6  = 12'h3B6,
    CSR_PMPADDR7  = 12'h3B7,
    CSR_PMPADDR8  = 12'h3B8,
    CSR_PMPADDR9  = 12'h3B9,
    CSR_PMPADDR10 = 12'h3BA,
    CSR_PMPADDR11 = 12'h3BB,
    CSR_PMPADDR12 = 12'h3BC,
    CSR_PMPADDR13 = 12'h3BD,
    CSR_PMPADDR14 = 12'h3BE,
    CSR_PMPADDR15 = 12'h3BF,

    // Debug/Trace Registers
    CSR_TSELECT   = 12'h7A0,  // Trigger select
    CSR_TDATA1    = 12'h7A1,  // Trigger data 1
    CSR_TDATA2    = 12'h7A2,  // Trigger data 2
    CSR_TDATA3    = 12'h7A3,  // Trigger data 3
    CSR_TINFO     = 12'h7A4,  // Trigger info
    CSR_MCONTEXT  = 12'h7A8,  // Machine context
    CSR_SCONTEXT  = 12'h7AA,  // Supervisor context
    CSR_DCSR      = 12'h7B0,  // Debug control and status register
    CSR_DPC       = 12'h7B1,  // Debug program counter
    CSR_DSCRATCH0 = 12'h7B2,  // Debug scratch register 0
    CSR_DSCRATCH1 = 12'h7B3,  // Debug scratch register 1

    // Machine-level Cycle and Instruction Counters
    CSR_MCYCLE   = 12'hB00,  // Machine cycle counter
    CSR_MINSTRET = 12'hB02,  // Machine instruction retired counter

    // Machine-level Hardware Performance Monitoring Counters
    CSR_MHPMCOUNTER3  = 12'hB03,
    CSR_MHPMCOUNTER4  = 12'hB04,
    CSR_MHPMCOUNTER5  = 12'hB05,
    CSR_MHPMCOUNTER6  = 12'hB06,
    CSR_MHPMCOUNTER7  = 12'hB07,
    CSR_MHPMCOUNTER8  = 12'hB08,
    CSR_MHPMCOUNTER9  = 12'hB09,
    CSR_MHPMCOUNTER10 = 12'hB0A,
    CSR_MHPMCOUNTER11 = 12'hB0B,
    CSR_MHPMCOUNTER12 = 12'hB0C,
    CSR_MHPMCOUNTER13 = 12'hB0D,
    CSR_MHPMCOUNTER14 = 12'hB0E,
    CSR_MHPMCOUNTER15 = 12'hB0F,
    CSR_MHPMCOUNTER16 = 12'hB10,
    CSR_MHPMCOUNTER17 = 12'hB11,
    CSR_MHPMCOUNTER18 = 12'hB12,
    CSR_MHPMCOUNTER19 = 12'hB13,
    CSR_MHPMCOUNTER20 = 12'hB14,
    CSR_MHPMCOUNTER21 = 12'hB15,
    CSR_MHPMCOUNTER22 = 12'hB16,
    CSR_MHPMCOUNTER23 = 12'hB17,
    CSR_MHPMCOUNTER24 = 12'hB18,
    CSR_MHPMCOUNTER25 = 12'hB19,
    CSR_MHPMCOUNTER26 = 12'hB1A,
    CSR_MHPMCOUNTER27 = 12'hB1B,
    CSR_MHPMCOUNTER28 = 12'hB1C,
    CSR_MHPMCOUNTER29 = 12'hB1D,
    CSR_MHPMCOUNTER30 = 12'hB1E,
    CSR_MHPMCOUNTER31 = 12'hB1F,

    // Machine-level High Cycle and Instruction Counters
    CSR_MCYCLEH   = 12'hB80,  // Machine cycle counter high bits
    CSR_MINSTRETH = 12'hB82,  // Machine instruction retired counter high bits

    // Machine-level High Hardware Performance Monitoring Counters
    CSR_MHPMCOUNTER3H  = 12'hB83,
    CSR_MHPMCOUNTER4H  = 12'hB84,
    CSR_MHPMCOUNTER5H  = 12'hB85,
    CSR_MHPMCOUNTER6H  = 12'hB86,
    CSR_MHPMCOUNTER7H  = 12'hB87,
    CSR_MHPMCOUNTER8H  = 12'hB88,
    CSR_MHPMCOUNTER9H  = 12'hB89,
    CSR_MHPMCOUNTER10H = 12'hB8A,
    CSR_MHPMCOUNTER11H = 12'hB8B,
    CSR_MHPMCOUNTER12H = 12'hB8C,
    CSR_MHPMCOUNTER13H = 12'hB8D,
    CSR_MHPMCOUNTER14H = 12'hB8E,
    CSR_MHPMCOUNTER15H = 12'hB8F,
    CSR_MHPMCOUNTER16H = 12'hB90,
    CSR_MHPMCOUNTER17H = 12'hB91,
    CSR_MHPMCOUNTER18H = 12'hB92,
    CSR_MHPMCOUNTER19H = 12'hB93,
    CSR_MHPMCOUNTER20H = 12'hB94,
    CSR_MHPMCOUNTER21H = 12'hB95,
    CSR_MHPMCOUNTER22H = 12'hB96,
    CSR_MHPMCOUNTER23H = 12'hB97,
    CSR_MHPMCOUNTER24H = 12'hB98,
    CSR_MHPMCOUNTER25H = 12'hB99,
    CSR_MHPMCOUNTER26H = 12'hB9A,
    CSR_MHPMCOUNTER27H = 12'hB9B,
    CSR_MHPMCOUNTER28H = 12'hB9C,
    CSR_MHPMCOUNTER29H = 12'hB9D,
    CSR_MHPMCOUNTER30H = 12'hB9E,
    CSR_MHPMCOUNTER31H = 12'hB9F,

    // Cycle and Instruction Counters
    CSR_CYCLE   = 12'hC00,  // Cycle counter
    CSR_INSTRET = 12'hC02,  // Instruction retired counter

    // Hardware Performance Monitoring Counters
    CSR_HPMCOUNTER3  = 12'hC03,
    CSR_HPMCOUNTER4  = 12'hC04,
    CSR_HPMCOUNTER5  = 12'hC05,
    CSR_HPMCOUNTER6  = 12'hC06,
    CSR_HPMCOUNTER7  = 12'hC07,
    CSR_HPMCOUNTER8  = 12'hC08,
    CSR_HPMCOUNTER9  = 12'hC09,
    CSR_HPMCOUNTER10 = 12'hC0A,
    CSR_HPMCOUNTER11 = 12'hC0B,
    CSR_HPMCOUNTER12 = 12'hC0C,
    CSR_HPMCOUNTER13 = 12'hC0D,
    CSR_HPMCOUNTER14 = 12'hC0E,
    CSR_HPMCOUNTER15 = 12'hC0F,
    CSR_HPMCOUNTER16 = 12'hC10,
    CSR_HPMCOUNTER17 = 12'hC11,
    CSR_HPMCOUNTER18 = 12'hC12,
    CSR_HPMCOUNTER19 = 12'hC13,
    CSR_HPMCOUNTER20 = 12'hC14,
    CSR_HPMCOUNTER21 = 12'hC15,
    CSR_HPMCOUNTER22 = 12'hC16,
    CSR_HPMCOUNTER23 = 12'hC17,
    CSR_HPMCOUNTER24 = 12'hC18,
    CSR_HPMCOUNTER25 = 12'hC19,
    CSR_HPMCOUNTER26 = 12'hC1A,
    CSR_HPMCOUNTER27 = 12'hC1B,
    CSR_HPMCOUNTER28 = 12'hC1C,
    CSR_HPMCOUNTER29 = 12'hC1D,
    CSR_HPMCOUNTER30 = 12'hC1E,
    CSR_HPMCOUNTER31 = 12'hC1F,

    // High Cycle and Instruction Counters
    CSR_CYCLEH   = 12'hC80,  // Cycle counter high bits
    CSR_INSTRETH = 12'hC82,  // Instruction retired counter high bits

    // High Hardware Performance Monitoring Counters
    CSR_HPMCOUNTER3H  = 12'hC83,
    CSR_HPMCOUNTER4H  = 12'hC84,
    CSR_HPMCOUNTER5H  = 12'hC85,
    CSR_HPMCOUNTER6H  = 12'hC86,
    CSR_HPMCOUNTER7H  = 12'hC87,
    CSR_HPMCOUNTER8H  = 12'hC88,
    CSR_HPMCOUNTER9H  = 12'hC89,
    CSR_HPMCOUNTER10H = 12'hC8A,
    CSR_HPMCOUNTER11H = 12'hC8B,
    CSR_HPMCOUNTER12H = 12'hC8C,
    CSR_HPMCOUNTER13H = 12'hC8D,
    CSR_HPMCOUNTER14H = 12'hC8E,
    CSR_HPMCOUNTER15H = 12'hC8F,
    CSR_HPMCOUNTER16H = 12'hC90,
    CSR_HPMCOUNTER17H = 12'hC91,
    CSR_HPMCOUNTER18H = 12'hC92,
    CSR_HPMCOUNTER19H = 12'hC93,
    CSR_HPMCOUNTER20H = 12'hC94,
    CSR_HPMCOUNTER21H = 12'hC95,
    CSR_HPMCOUNTER22H = 12'hC96,
    CSR_HPMCOUNTER23H = 12'hC97,
    CSR_HPMCOUNTER24H = 12'hC98,
    CSR_HPMCOUNTER25H = 12'hC99,
    CSR_HPMCOUNTER26H = 12'hC9A,
    CSR_HPMCOUNTER27H = 12'hC9B,
    CSR_HPMCOUNTER28H = 12'hC9C,
    CSR_HPMCOUNTER29H = 12'hC9D,
    CSR_HPMCOUNTER30H = 12'hC9E,
    CSR_HPMCOUNTER31H = 12'hC9F,

    // Machine Information Registers
    CSR_MVENDORID = 12'hF11, // Vendor ID
    CSR_MARCHID   = 12'hF12, // Architecture ID
    CSR_MIMPID    = 12'hF13, // Implementation ID
    CSR_MHARTID   = 12'hF14  // Hardware thread ID
  } csr_num_e;

  // CSR Operation Width
  parameter int CSR_OP_WIDTH = 2;

  // CSR Operation Codes (2-bit)
  typedef enum logic [CSR_OP_WIDTH-1:0] {
    CSR_OP_READ  = 2'b00,  // Read CSR
    CSR_OP_WRITE = 2'b01,  // Write CSR
    CSR_OP_SET   = 2'b10,  // Set bits in CSR
    CSR_OP_CLEAR = 2'b11   // Clear bits in CSR
  } csr_opcode_e;

  // // CSR Bit Position Parameters
  // Machine software interrupt enable bit index in MIE
  parameter int unsigned CSR_MSIX_BIT = 3;
  // Machine timer interrupt enable bit index in MIE
  parameter int unsigned CSR_MTIX_BIT = 7;
  // Machine external interrupt enable bit index in MIE
  parameter int unsigned CSR_MEIX_BIT = 11;
  // Machine floating-point interrupt enable bit index (lower part)
  parameter int unsigned CSR_MFIX_BIT_LOW = 16;
  // Machine floating-point interrupt enable bit index (higher part)
  parameter int unsigned CSR_MFIX_BIT_HIGH = 31;

  // Special Purpose Register Addresses
  parameter int SP_DCR0 = 16'h3008;  // Data Cache Register 0 address
  parameter int SP_DVR0 = 16'h3000;  // Data Vector Register 0 address
  parameter int SP_DMR1 = 16'h3010;  // Data Mask Register 1 address
  parameter int SP_DMR2 = 16'h3011;  // Data Mask Register 2 address

  // Special Purpose Register MSB Positions
  parameter int SP_DVR_MSB = 8'h00;  // Most significant byte position for DVR
  parameter int SP_DCR_MSB = 8'h01;  // Most significant byte position for DCR
  parameter int SP_DMR_MSB = 8'h02;  // Most significant byte position for DMR
  parameter int SP_DSR_MSB = 8'h04; // Most significant byte position for DSR (assuming DSR exists)

  // Privilege Level Type (2-bit)
  typedef enum logic [1:0] {
    PRIV_LVL_M = 2'b11,  // Machine mode
    PRIV_LVL_H = 2'b10,  // Hypervisor mode (if supported)
    PRIV_LVL_S = 2'b01,  // Supervisor mode
    PRIV_LVL_U = 2'b00   // User mode
  } priv_lvl_t;

  // Machine Status Register Structure
  typedef struct packed {
    logic uie;  // User interrupt enable
    logic mie;  // Machine interrupt enable
    logic upie;  // User previous interrupt enable
    logic mpie;  // Machine previous interrupt enable
    priv_lvl_t mpp;  // Machine previous privilege mode
    logic mprv;  // Memory protection previous mode
  } status_t;

  // Debug Control and Status Register Structure
  typedef struct packed {
    logic [31:28] xdebugver;  // Debug specification version
    logic [27:16] zero2;      // Reserved bits
    logic         ebreakm;    // Machine-mode ebreak enable
    logic         zero1;      // Reserved bit
    logic         ebreaks;    // Supervisor-mode ebreak enable
    logic         ebreaku;    // User-mode ebreak enable
    logic         stepie;     // Single-step interrupt enable
    logic         stopcount;  // Stop counting cycles/instructions
    logic         stoptime;   // Stop when timer expires
    logic [8:6]   cause;      // Debug exception cause
    logic         zero0;      // Reserved bit
    logic         mprven;     // Memory protection register valid enable
    logic         nmip;       // Non-maskable interrupt pending
    logic         step;       // Single-step mode
    priv_lvl_t    prv;        // Current privilege level
  } dcsr_t;

  // Floating-Point Status Type (2-bit)
  typedef enum logic [1:0] {
    FS_OFF     = 2'b00,  // Floating-point unit is off
    FS_INITIAL = 2'b01,  // Floating-point unit is in initial state
    FS_CLEAN   = 2'b10,  // Floating-point unit has no pending exceptions
    FS_DIRTY   = 2'b11   // Floating-point unit has pending exceptions
  } fs_t;

  // Machine Vendor ID Configuration
  parameter int MVENDORID_OFFSET = 7'h2;  // Offset within the vendor ID register
  parameter int MVENDORID_BANK = 25'hC;  // Bank number for the vendor ID

  // Machine Architecture ID
  parameter int MARCHID = 32'h4;

  // Machine Hardware Performance Monitoring Counter Width
  parameter int MHPMCOUNTER_WIDTH = 64;

  // Forwarding Selectors (2-bit)
  parameter int SEL_REGFILE = 2'b00;  // Select data from the register file
  parameter int SEL_FW_EX = 2'b01;  // Select data forwarded from the Execute stage
  parameter int SEL_FW_WB = 2'b10;  // Select data forwarded from the Writeback stage

  // Operand A Selectors (3-bit)
  parameter int OP_A_REGA_OR_FWD = 3'b000;  // Select register A or forwarded value
  parameter int OP_A_CURRPC = 3'b001;  // Select current program counter (PC)
  parameter int OP_A_IMM = 3'b010;  // Select immediate value
  parameter int OP_A_REGB_OR_FWD = 3'b011;  // Select register B or forwarded value
  parameter int OP_A_REGC_OR_FWD = 3'b100;  // Select register C or forwarded value

  // Immediate A Selectors (1-bit)
  parameter int IMMA_Z = 1'b0;  // Select zero immediate
  parameter int IMMA_ZERO = 1'b1;  // Select zero immediate (redundant with IMMA_Z)

  // Operand B Selectors (3-bit)
  parameter int OP_B_REGB_OR_FWD = 3'b000;  // Select register B or forwarded value
  parameter int OP_B_REGC_OR_FWD = 3'b001;  // Select register C or forwarded value
  parameter int OP_B_IMM = 3'b010;  // Select immediate value
  parameter int OP_B_REGA_OR_FWD = 3'b011;  // Select register A or forwarded value
  parameter int OP_B_BMASK = 3'b100;  // Select bitmask

  // Immediate B Selectors (4-bit)
  parameter int IMMB_I = 4'b0000;  // I-type immediate
  parameter int IMMB_S = 4'b0001;  // S-type immediate
  parameter int IMMB_U = 4'b0010;  // U-type immediate
  parameter int IMMB_PCINCR = 4'b0011;  // PC increment for branch/jump
  parameter int IMMB_S2 = 4'b0100;  // Secondary S-type immediate (used in some extensions)
  parameter int IMMB_S3 = 4'b0101;  // Tertiary S-type immediate (used in some extensions)
  parameter int IMMB_VS = 4'b0110;  // Vector stride immediate
  parameter int IMMB_VU = 4'b0111;  // Vector unit immediate
  parameter int IMMB_SHUF = 4'b1000;  // Shuffle immediate
  parameter int IMMB_CLIP = 4'b1001;  // Clip immediate
  parameter int IMMB_BI = 4'b1011;  // Bit immediate

  // Bitmask A Selectors (1-bit)
  parameter int BMASK_A_ZERO = 1'b0;  // Bitmask A is all zeros
  parameter int BMASK_A_S3 = 1'b1;  // Bitmask A is derived from source register 3

  // Bitmask B Selectors (2-bit)
  parameter int BMASK_B_S2 = 2'b00;  // Bitmask B is derived from source register 2
  parameter int BMASK_B_S3 = 2'b01;  // Bitmask B is derived from source register 3
  parameter int BMASK_B_ZERO = 2'b10;  // Bitmask B is all zeros
  parameter int BMASK_B_ONE = 2'b11;  // Bitmask B is all ones

  // Bitmask Source Selectors
  parameter int BMASK_A_REG = 1'b0;  // Bitmask A source is a register
  parameter int BMASK_A_IMM = 1'b1;  // Bitmask A source is an immediate
  parameter int BMASK_B_REG = 1'b0;  // Bitmask B source is a register
  parameter int BMASK_B_IMM = 1'b1;  // Bitmask B source is an immediate

  // Multiplier Immediate Selectors (1-bit)
  parameter int MIMM_ZERO = 1'b0;  // Multiplier immediate is zero
  parameter int MIMM_S3 = 1'b1;  // Multiplier immediate is derived from source register 3

  // Operand C Selectors (2-bit)
  parameter int OP_C_REGC_OR_FWD = 2'b00;  // Select register C or forwarded value
  parameter int OP_C_REGB_OR_FWD = 2'b01;  // Select register B or forwarded value
  parameter int OP_C_JT = 2'b10;  // Select jump target

  // Branch Type Selectors (2-bit)
  parameter int BRANCH_NONE = 2'b00;  // No branch
  parameter int BRANCH_JAL = 2'b01;  // Jump and Link
  parameter int BRANCH_JALR = 2'b10;  // Jump and Link Register
  parameter int BRANCH_COND = 2'b11;  // Conditional branch

  // Jump Target Selectors (2-bit)
  parameter int JT_JAL = 2'b01;  // Jump and Link target
  parameter int JT_JALR = 2'b10;  // Jump and Link Register target
  parameter int JT_COND = 2'b11;  // Conditional branch target

  // Atomic Memory Operation Function Codes (5-bit)
  parameter int AMO_LR = 5'b00010;  // Load Reserved
  parameter int AMO_SC = 5'b00011;  // Store Conditional
  parameter int AMO_SWAP = 5'b00001;  // Swap
  parameter int AMO_ADD = 5'b00000;  // Atomic Add
  parameter int AMO_XOR = 5'b00100;  // Atomic XOR
  parameter int AMO_AND = 5'b01100;  // Atomic AND
  parameter int AMO_OR = 5'b01000;  // Atomic OR
  parameter int AMO_MIN = 5'b10000;  // Atomic Minimum (signed)
  parameter int AMO_MAX = 5'b10100;  // Atomic Maximum (signed)
  parameter int AMO_MINU = 5'b11000;  // Atomic Minimum (unsigned)
  parameter int AMO_MAXU = 5'b11100;  // Atomic Maximum (unsigned)

  // Program Counter Update Type Selectors (4-bit)
  parameter int PC_BOOT = 4'b0000;  // Initial boot address
  parameter int PC_JUMP = 4'b0010;  // Jump instruction
  parameter int PC_BRANCH = 4'b0011;  // Branch instruction
  parameter int PC_EXCEPTION = 4'b0100;  // Exception occurred
  parameter int PC_FENCEI = 4'b0001;  // Fence instruction (instruction cache flush)
  parameter int PC_MRET = 4'b0101;  // Machine mode return from exception
  parameter int PC_URET = 4'b0110;  // User mode return from exception
  parameter int PC_DRET = 4'b0111;  // Debug mode return
  parameter int PC_HWLOOP = 4'b1000;  // Hardware loop

  // Exception Program Counter Selectors (3-bit)
  parameter int EXC_PC_EXCEPTION = 3'b000;  // PC for normal exceptions
  parameter int EXC_PC_IRQ = 3'b001;  // PC for interrupts

  // Debug Exception Program Counter Selectors (3-bit)
  parameter int EXC_PC_DBD = 3'b010;  // PC for debug breakpoint
  parameter int EXC_PC_DBE = 3'b011;  // PC for debug exception

  // Exception Cause Codes (5-bit)
  parameter int EXC_CAUSE_INSTR_FAULT = 5'h01;  // Instruction access fault
  parameter int EXC_CAUSE_ILLEGAL_INSN = 5'h02;  // Illegal instruction
  parameter int EXC_CAUSE_BREAKPOINT = 5'h03;  // Breakpoint
  parameter int EXC_CAUSE_LOAD_FAULT = 5'h05;  // Load access fault
  parameter int EXC_CAUSE_STORE_FAULT = 5'h07;  // Store access fault
  parameter int EXC_CAUSE_ECALL_UMODE = 5'h08;  // Environment call from U-mode
  parameter int EXC_CAUSE_ECALL_MMODE = 5'h0B;  // Environment call from M-mode

  // Interrupt Request Mask
  parameter int IRQ_MASK = 32'hFFFF0888;  // Mask for pending interrupt requests

  // Trap Type Selectors (2-bit)
  parameter int TRAP_MACHINE = 2'b00;  // Machine mode trap
  parameter int TRAP_USER = 2'b01;  // User mode trap

  // Debug Cause Codes (3-bit)
  parameter int DBG_CAUSE_NONE = 3'h0;  // No debug cause
  parameter int DBG_CAUSE_EBREAK = 3'h1;  // EBREAK instruction encountered
  parameter int DBG_CAUSE_TRIGGER = 3'h2;  // Debug trigger matched
  parameter int DBG_CAUSE_HALTREQ = 3'h3;  // Halt request received
  parameter int DBG_CAUSE_STEP = 3'h4;  // Single-step completed
  parameter int DBG_CAUSE_RSTHALTREQ = 3'h5;  // Reset halt request

  // Debug Set Selectors
  parameter int DBG_SETS_W = 6;  // Debug set selector for watchpoints
  parameter int DBG_SETS_IRQ = 5;  // Debug set selector for interrupts
  parameter int DBG_SETS_ECALL = 4;  // Debug set selector for ECALL
  parameter int DBG_SETS_EILL = 3;  // Debug set selector for illegal instructions
  parameter int DBG_SETS_ELSU = 2;  // Debug set selector for load/store units
  parameter int DBG_SETS_EBRK = 1;  // Debug set selector for breakpoints
  parameter int DBG_SETS_SSTE = 0;  // Debug set selector for single-stepping

  // Debug Cause Code for Halt
  parameter int DBG_CAUSE_HALT = 6'h1F;  // Debug cause code indicating a halt

  // Xdebug Version Enum (4-bit)
  typedef enum logic [3:0] {
    XDEBUGVER_NO     = 4'd0,  // No debug support
    XDEBUGVER_STD    = 4'd4,  // Standard debug specification
    XDEBUGVER_NONSTD = 4'd15  // Non-standard debug extension
  } x_debug_ver_e;

  // Trigger Type Enum (4-bit)
  typedef enum logic [3:0] {
    TTYPE_MCONTROL = 4'h2,  // Memory access control trigger
    TTYPE_ICOUNT   = 4'h3,  // Instruction count trigger
    TTYPE_ITRIGGER = 4'h4,  // Instruction trigger
    TTYPE_ETRIGGER = 4'h5   // Exception trigger
  } trigger_type_e;

  // // Configuration Parameters (Boolean Flags)
  // RV32F (Single-precision floating-point) extension present
  parameter bit C_RVF = 1'b1;
  // RV32D (Double-precision floating-point) extension present
  parameter bit C_RVD = 1'b0;
  // Non-standard 16-bit floating-point extension present
  parameter bit C_XF16 = 1'b0;
  // Non-standard alternative 16-bit floating-point extension present
  parameter bit C_XF16ALT = 1'b0;
  // Non-standard 8-bit floating-point extension present
  parameter bit C_XF8 = 1'b0;
  // Non-standard vector floating-point extension present
  parameter bit C_XFVEC = 1'b0;

  // // Configuration Parameters (Latency)
  // Latency for 64-bit floating-point operations
  parameter int unsigned C_LAT_FP64 = 'd0;
  // Latency for 16-bit floating-point operations
  parameter int unsigned C_LAT_FP16 = 'd0;
  // Latency for alternative 16-bit floating-point operations
  parameter int unsigned C_LAT_FP16ALT = 'd0;
  // Latency for 8-bit floating-point operations
  parameter int unsigned C_LAT_FP8 = 'd0;
  // Latency for division and square root operations
  parameter int unsigned C_LAT_DIVSQRT = 'd1;

  // Derived Configuration Parameter (Floating-Point Register Length)
  parameter int C_FLEN = C_RVD ? 64 : C_RVF ? 32 : C_XF16 ? 16 : C_XF16ALT ? 16 : C_XF8 ? 8 : 0;

  // Configuration Parameters (Field Widths)
  parameter int C_FFLAG = 5;  // Width of the floating-point flag register
  parameter int C_RM = 3;  // Width of the floating-point rounding mode field

endpackage
