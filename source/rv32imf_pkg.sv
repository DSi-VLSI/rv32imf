// Package definition for the RV32IMF architecture
package rv32imf_pkg;

  // Parameter defining the opcode for system instructions
  parameter int OPCODE_SYSTEM = 7'h73;
  // Parameter defining the opcode for fence instructions
  parameter int OPCODE_FENCE = 7'h0f;
  // Parameter defining the opcode for general arithmetic/logic instructions
  parameter int OPCODE_OP = 7'h33;
  // Parameter defining the opcode for immediate arithmetic/logic instructions
  parameter int OPCODE_OPIMM = 7'h13;
  // Parameter defining the opcode for store instructions
  parameter int OPCODE_STORE = 7'h23;
  // Parameter defining the opcode for load instructions
  parameter int OPCODE_LOAD = 7'h03;
  // Parameter defining the opcode for branch instructions
  parameter int OPCODE_BRANCH = 7'h63;
  // Parameter defining the opcode for jump and link register instruction
  parameter int OPCODE_JALR = 7'h67;
  // Parameter defining the opcode for jump and link instruction
  parameter int OPCODE_JAL = 7'h6f;
  // Parameter defining the opcode for add upper immediate to PC instruction
  parameter int OPCODE_AUIPC = 7'h17;
  // Parameter defining the opcode for load upper immediate instruction
  parameter int OPCODE_LUI = 7'h37;
  // Parameter defining the opcode for floating-point arithmetic instructions
  parameter int OPCODE_OP_FP = 7'h53;
  // Parameter defining the opcode for floating-point fused multiply-add
  parameter int OPCODE_OP_FMADD = 7'h43;
  // Parameter defining the opcode for floating-point fused multiply-negate-add
  parameter int OPCODE_OP_FNMADD = 7'h4f;
  // Parameter defining the opcode for floating-point fused multiply-subtract
  parameter int OPCODE_OP_FMSUB = 7'h47;
  // Parameter defining the opcode for floating-point fused multiply-negate-subtract
  parameter int OPCODE_OP_FNMSUB = 7'h4b;
  // Parameter defining the opcode for floating-point store instructions
  parameter int OPCODE_STORE_FP = 7'h27;
  // Parameter defining the opcode for floating-point load instructions
  parameter int OPCODE_LOAD_FP = 7'h07;
  // Parameter defining the opcode for atomic memory operations
  parameter int OPCODE_AMO = 7'h2F;

  // Parameter defining the opcode for custom instruction 0
  parameter int OPCODE_CUSTOM_0 = 7'h0b;
  // Parameter defining the opcode for custom instruction 1
  parameter int OPCODE_CUSTOM_1 = 7'h2b;
  // Parameter defining the opcode for custom instruction 2
  parameter int OPCODE_CUSTOM_2 = 7'h5b;
  // Parameter defining the opcode for custom instruction 3
  parameter int OPCODE_CUSTOM_3 = 7'h7b;

  // Parameter defining the register class for source register 1
  parameter int REGC_S1 = 2'b10;
  // Parameter defining the register class for source register 4 (unused in standard RV32I)
  parameter int REGC_S4 = 2'b00;
  // Parameter defining the register class for the destination register
  parameter int REGC_RD = 2'b01;
  // Parameter defining the register class for the zero register
  parameter int REGC_ZERO = 2'b11;

  // Parameter defining the width of the ALU operation code
  parameter int ALU_OP_WIDTH = 7;

  // Typedef for the ALU opcode enumeration
  typedef enum logic [ALU_OP_WIDTH-1:0] {
    // ALU operation: Addition
    ALU_ADD   = 7'b0011000,
    // ALU operation: Subtraction
    ALU_SUB   = 7'b0011001,
    // ALU operation: Unsigned addition
    ALU_ADDU  = 7'b0011010,
    // ALU operation: Unsigned subtraction
    ALU_SUBU  = 7'b0011011,
    // ALU operation: Reverse addition (operand order swapped)
    ALU_ADDR  = 7'b0011100,
    // ALU operation: Reverse subtraction (operand order swapped)
    ALU_SUBR  = 7'b0011101,
    // ALU operation: Reverse unsigned addition
    ALU_ADDUR = 7'b0011110,
    // ALU operation: Reverse unsigned subtraction
    ALU_SUBUR = 7'b0011111,

    // ALU operation: Bitwise XOR
    ALU_XOR = 7'b0101111,
    // ALU operation: Bitwise OR
    ALU_OR  = 7'b0101110,
    // ALU operation: Bitwise AND
    ALU_AND = 7'b0010101,

    // ALU operation: Arithmetic right shift
    ALU_SRA = 7'b0100100,
    // ALU operation: Logical right shift
    ALU_SRL = 7'b0100101,
    // ALU operation: Rotate right
    ALU_ROR = 7'b0100110,
    // ALU operation: Logical left shift
    ALU_SLL = 7'b0100111,

    // ALU operation: Bit extract
    ALU_BEXT  = 7'b0101000,
    // ALU operation: Unsigned bit extract
    ALU_BEXTU = 7'b0101001,
    // ALU operation: Bit insert
    ALU_BINS  = 7'b0101010,
    // ALU operation: Bit clear
    ALU_BCLR  = 7'b0101011,
    // ALU operation: Bit set
    ALU_BSET  = 7'b0101100,
    // ALU operation: Bit reverse
    ALU_BREV  = 7'b1001001,

    // ALU operation: Find first one
    ALU_FF1 = 7'b0110110,
    // ALU operation: Find last one
    ALU_FL1 = 7'b0110111,
    // ALU operation: Count leading zeros
    ALU_CNT = 7'b0110100,
    // ALU operation: Count leading bits (sign bit)
    ALU_CLB = 7'b0110101,

    // ALU operation: Sign extension
    ALU_EXTS = 7'b0111110,
    // ALU operation: Zero extension (typically redundant for RV32)
    ALU_EXT  = 7'b0111111,

    // ALU operation: Less than signed
    ALU_LTS = 7'b0000000,
    // ALU operation: Less than unsigned
    ALU_LTU = 7'b0000001,
    // ALU operation: Less than or equal to signed
    ALU_LES = 7'b0000100,
    // ALU operation: Less than or equal to unsigned
    ALU_LEU = 7'b0000101,
    // ALU operation: Greater than signed
    ALU_GTS = 7'b0001000,
    // ALU operation: Greater than unsigned
    ALU_GTU = 7'b0001001,
    // ALU operation: Greater than or equal to signed
    ALU_GES = 7'b0001010,
    // ALU operation: Greater than or equal to unsigned
    ALU_GEU = 7'b0001011,
    // ALU operation: Equal
    ALU_EQ  = 7'b0001100,
    // ALU operation: Not equal
    ALU_NE  = 7'b0001101,

    // ALU operation: Set less than signed
    ALU_SLTS  = 7'b0000010,
    // ALU operation: Set less than unsigned
    ALU_SLTU  = 7'b0000011,
    // ALU operation: Set less than or equal to signed
    ALU_SLETS = 7'b0000110,
    // ALU operation: Set less than or equal to unsigned
    ALU_SLETU = 7'b0000111,

    // ALU operation: Absolute value
    ALU_ABS   = 7'b0010100,
    // ALU operation: Clip to signed range
    ALU_CLIP  = 7'b0010110,
    // ALU operation: Clip to unsigned range
    ALU_CLIPU = 7'b0010111,

    // ALU operation: Insert bits
    ALU_INS = 7'b0101101,

    // ALU operation: Minimum signed
    ALU_MIN  = 7'b0010000,
    // ALU operation: Minimum unsigned
    ALU_MINU = 7'b0010001,
    // ALU operation: Maximum signed
    ALU_MAX  = 7'b0010010,
    // ALU operation: Maximum unsigned
    ALU_MAXU = 7'b0010011,

    // ALU operation: Divide unsigned
    ALU_DIVU = 7'b0110000,
    // ALU operation: Divide signed
    ALU_DIV  = 7'b0110001,
    // ALU operation: Remainder unsigned
    ALU_REMU = 7'b0110010,
    // ALU operation: Remainder signed
    ALU_REM  = 7'b0110011,

    // ALU operation: Shuffle
    ALU_SHUF  = 7'b0111010,
    // ALU operation: Shuffle with two inputs
    ALU_SHUF2 = 7'b0111011,
    // ALU operation: Pack low
    ALU_PCKLO = 7'b0111000,
    // ALU operation: Pack high
    ALU_PCKHI = 7'b0111001
  } alu_opcode_e;

  // Parameter defining the width of the multiplier operation code
  parameter int MUL_OP_WIDTH = 3;

  // Typedef for the multiplier opcode enumeration
  typedef enum logic [MUL_OP_WIDTH-1:0] {
    // Multiplier operation: Multiply-accumulate 32-bit
    MUL_MAC32 = 3'b000,
    // Multiplier operation: Multiply-subtract 32-bit
    MUL_MSU32 = 3'b001,
    // Multiplier operation: Integer multiplication
    MUL_I     = 3'b010,
    // Multiplier operation: Integer multiplication with result in high part
    MUL_IR    = 3'b011,
    // Multiplier operation: Dot product of 8-bit elements
    MUL_DOT8  = 3'b100,
    // Multiplier operation: Dot product of 16-bit elements
    MUL_DOT16 = 3'b101,
    // Multiplier operation: Half-word multiplication
    MUL_H     = 3'b110
  } mul_opcode_e;

  // Parameter defining the vector mode for 32-bit elements
  parameter int VEC_MODE32 = 2'b00;
  // Parameter defining the vector mode for 16-bit elements
  parameter int VEC_MODE16 = 2'b10;
  // Parameter defining the vector mode for 8-bit elements
  parameter int VEC_MODE8 = 2'b11;

  // Typedef for the control state enumeration
  typedef enum logic [4:0] {
    // Processor state: Reset
    RESET,
    // Processor state: Boot setting
    BOOT_SET,
    // Processor state: Sleep mode
    SLEEP,
    // Processor state: Waiting for sleep
    WAIT_SLEEP,
    // Processor state: First instruction fetch
    FIRST_FETCH,
    // Processor state: Instruction decode
    DECODE,
    // Processor state: Interrupt/Exception initiated flush for ELW
    IRQ_FLUSH_ELW,
    // Processor state: Execute load-word instruction
    ELW_EXE,
    // Processor state: Flush execute stage
    FLUSH_EX,
    // Processor state: Flush write-back stage
    FLUSH_WB,
    // Processor state: Jump from exception return
    XRET_JUMP,
    // Processor state: Debug taken in ID stage
    DBG_TAKEN_ID,
    // Processor state: Debug taken in IF stage
    DBG_TAKEN_IF,
    // Processor state: Debug flush
    DBG_FLUSH,
    // Processor state: Debug wait for branch
    DBG_WAIT_BRANCH,
    // Processor state: Decode for hardware loop
    DECODE_HWLOOP
  } ctrl_state_e;

  // Parameter defining the index for "have reset" debug state
  parameter int HAVERESET_INDEX = 0;
  // Parameter defining the index for "running" debug state
  parameter int RUNNING_INDEX = 1;
  // Parameter defining the index for "halted" debug state
  parameter int HALTED_INDEX = 2;

  // Typedef for the debug state enumeration
  typedef enum logic [2:0] {
    // Debug state: Have reset
    HAVERESET = 3'b001,
    // Debug state: Running
    RUNNING   = 3'b010,
    // Debug state: Halted
    HALTED    = 3'b100
  } debug_state_e;

  // Typedef for the prefetch state enumeration
  typedef enum logic {
    // Prefetch state: Idle
    IDLE,
    // Prefetch state: Waiting for branch resolution
    BRANCH_WAIT
  } prefetch_state_e;

  // Typedef for the multiplier state enumeration
  typedef enum logic [2:0] {
    // Multiplier state: Idle
    IDLE_MULT,
    // Multiplier state: Step 0 of multiplication
    STEP0,
    // Multiplier state: Step 1 of multiplication
    STEP1,
    // Multiplier state: Step 2 of multiplication
    STEP2,
    // Multiplier state: Multiplication finished
    FINISH
  } mult_state_e;

  // Typedef for the CSR number enumeration
  typedef enum logic [11:0] {
    // User status register
    CSR_USTATUS  = 12'h000,
    // User floating-point flags register
    CSR_FFLAGS   = 12'h001,
    // User floating-point rounding mode register
    CSR_FRM      = 12'h002,
    // User floating-point control and status register
    CSR_FCSR     = 12'h003,
    // User trap vector base address register
    CSR_UTVEC    = 12'h005,
    // User exception program counter register
    CSR_UEPC     = 12'h041,
    // User trap cause register
    CSR_UCAUSE   = 12'h042,
    // User loop start address 0 register
    CSR_LPSTART0 = 12'hCC0,
    // User loop end address 0 register
    CSR_LPEND0   = 12'hCC1,
    // User loop counter 0 register
    CSR_LPCOUNT0 = 12'hCC2,
    // User loop start address 1 register
    CSR_LPSTART1 = 12'hCC4,
    // User loop end address 1 register
    CSR_LPEND1   = 12'hCC5,
    // User loop counter 1 register
    CSR_LPCOUNT1 = 12'hCC6,
    // User hardware thread ID register
    CSR_UHARTID  = 12'hCD0,
    // User privilege level register
    CSR_PRIVLV   = 12'hCD1,
    // User Zfinx extension control register
    CSR_ZFINX    = 12'hCD2,

    // Machine status register
    CSR_MSTATUS       = 12'h300,
    // Machine ISA register
    CSR_MISA          = 12'h301,
    // Machine interrupt enable register
    CSR_MIE           = 12'h304,
    // Machine trap vector base address register
    CSR_MTVEC         = 12'h305,
    // Machine counter enable register
    CSR_MCOUNTEREN    = 12'h306,
    // Machine count inhibit register
    CSR_MCOUNTINHIBIT = 12'h320,

    // Machine performance monitoring event selector 3 register
    CSR_MHPMEVENT3  = 12'h323,
    // Machine performance monitoring event selector 4 register
    CSR_MHPMEVENT4  = 12'h324,
    // Machine performance monitoring event selector 5 register
    CSR_MHPMEVENT5  = 12'h325,
    // Machine performance monitoring event selector 6 register
    CSR_MHPMEVENT6  = 12'h326,
    // Machine performance monitoring event selector 7 register
    CSR_MHPMEVENT7  = 12'h327,
    // Machine performance monitoring event selector 8 register
    CSR_MHPMEVENT8  = 12'h328,
    // Machine performance monitoring event selector 9 register
    CSR_MHPMEVENT9  = 12'h329,
    // Machine performance monitoring event selector 10 register
    CSR_MHPMEVENT10 = 12'h32A,
    // Machine performance monitoring event selector 11 register
    CSR_MHPMEVENT11 = 12'h32B,
    // Machine performance monitoring event selector 12 register
    CSR_MHPMEVENT12 = 12'h32C,
    // Machine performance monitoring event selector 13 register
    CSR_MHPMEVENT13 = 12'h32D,
    // Machine performance monitoring event selector 14 register
    CSR_MHPMEVENT14 = 12'h32E,
    // Machine performance monitoring event selector 15 register
    CSR_MHPMEVENT15 = 12'h32F,
    // Machine performance monitoring event selector 16 register
    CSR_MHPMEVENT16 = 12'h330,
    // Machine performance monitoring event selector 17 register
    CSR_MHPMEVENT17 = 12'h331,
    // Machine performance monitoring event selector 18 register
    CSR_MHPMEVENT18 = 12'h332,
    // Machine performance monitoring event selector 19 register
    CSR_MHPMEVENT19 = 12'h333,
    // Machine performance monitoring event selector 20 register
    CSR_MHPMEVENT20 = 12'h334,
    // Machine performance monitoring event selector 21 register
    CSR_MHPMEVENT21 = 12'h335,
    // Machine performance monitoring event selector 22 register
    CSR_MHPMEVENT22 = 12'h336,
    // Machine performance monitoring event selector 23 register
    CSR_MHPMEVENT23 = 12'h337,
    // Machine performance monitoring event selector 24 register
    CSR_MHPMEVENT24 = 12'h338,
    // Machine performance monitoring event selector 25 register
    CSR_MHPMEVENT25 = 12'h339,
    // Machine performance monitoring event selector 26 register
    CSR_MHPMEVENT26 = 12'h33A,
    // Machine performance monitoring event selector 27 register
    CSR_MHPMEVENT27 = 12'h33B,
    // Machine performance monitoring event selector 28 register
    CSR_MHPMEVENT28 = 12'h33C,
    // Machine performance monitoring event selector 29 register
    CSR_MHPMEVENT29 = 12'h33D,
    // Machine performance monitoring event selector 30 register
    CSR_MHPMEVENT30 = 12'h33E,
    // Machine performance monitoring event selector 31 register
    CSR_MHPMEVENT31 = 12'h33F,

    // Machine scratch register
    CSR_MSCRATCH = 12'h340,
    // Machine exception program counter register
    CSR_MEPC     = 12'h341,
    // Machine trap cause register
    CSR_MCAUSE   = 12'h342,
    // Machine trap value register
    CSR_MTVAL    = 12'h343,
    // Machine interrupt pending register
    CSR_MIP      = 12'h344,

    // Physical memory protection configuration register 0
    CSR_PMPCFG0 = 12'h3A0,
    // Physical memory protection configuration register 1
    CSR_PMPCFG1 = 12'h3A1,
    // Physical memory protection configuration register 2
    CSR_PMPCFG2 = 12'h3A2,
    // Physical memory protection configuration register 3
    CSR_PMPCFG3 = 12'h3A3,

    // Physical memory protection address register 0
    CSR_PMPADDR0  = 12'h3B0,
    // Physical memory protection address register 1
    CSR_PMPADDR1  = 12'h3B1,
    // Physical memory protection address register 2
    CSR_PMPADDR2  = 12'h3B2,
    // Physical memory protection address register 3
    CSR_PMPADDR3  = 12'h3B3,
    // Physical memory protection address register 4
    CSR_PMPADDR4  = 12'h3B4,
    // Physical memory protection address register 5
    CSR_PMPADDR5  = 12'h3B5,
    // Physical memory protection address register 6
    CSR_PMPADDR6  = 12'h3B6,
    // Physical memory protection address register 7
    CSR_PMPADDR7  = 12'h3B7,
    // Physical memory protection address register 8
    CSR_PMPADDR8  = 12'h3B8,
    // Physical memory protection address register 9
    CSR_PMPADDR9  = 12'h3B9,
    // Physical memory protection address register 10
    CSR_PMPADDR10 = 12'h3BA,
    // Physical memory protection address register 11
    CSR_PMPADDR11 = 12'h3BB,
    // Physical memory protection address register 12
    CSR_PMPADDR12 = 12'h3BC,
    // Physical memory protection address register 13
    CSR_PMPADDR13 = 12'h3BD,
    // Physical memory protection address register 14
    CSR_PMPADDR14 = 12'h3BE,
    // Physical memory protection address register 15
    CSR_PMPADDR15 = 12'h3BF,

    // Trigger select register
    CSR_TSELECT   = 12'h7A0,
    // Trigger data 1 register
    CSR_TDATA1    = 12'h7A1,
    // Trigger data 2 register
    CSR_TDATA2    = 12'h7A2,
    // Trigger data 3 register
    CSR_TDATA3    = 12'h7A3,
    // Trigger info register
    CSR_TINFO     = 12'h7A4,
    // Machine context register for debugging
    CSR_MCONTEXT  = 12'h7A8,
    // Supervisor context register for debugging
    CSR_SCONTEXT  = 12'h7AA,
    // Debug control and status register
    CSR_DCSR      = 12'h7B0,
    // Debug program counter register
    CSR_DPC       = 12'h7B1,
    // Debug scratch register 0
    CSR_DSCRATCH0 = 12'h7B2,
    // Debug scratch register 1
    CSR_DSCRATCH1 = 12'h7B3,

    // Machine cycle counter register
    CSR_MCYCLE   = 12'hB00,
    // Machine instruction retired counter register
    CSR_MINSTRET = 12'hB02,

    // Machine performance monitoring counter 3 register
    CSR_MHPMCOUNTER3  = 12'hB03,
    // Machine performance monitoring counter 4 register
    CSR_MHPMCOUNTER4  = 12'hB04,
    // Machine performance monitoring counter 5 register
    CSR_MHPMCOUNTER5  = 12'hB05,
    // Machine performance monitoring counter 6 register
    CSR_MHPMCOUNTER6  = 12'hB06,
    // Machine performance monitoring counter 7 register
    CSR_MHPMCOUNTER7  = 12'hB07,
    // Machine performance monitoring counter 8 register
    CSR_MHPMCOUNTER8  = 12'hB08,
    // Machine performance monitoring counter 9 register
    CSR_MHPMCOUNTER9  = 12'hB09,
    // Machine performance monitoring counter 10 register
    CSR_MHPMCOUNTER10 = 12'hB0A,
    // Machine performance monitoring counter 11 register
    CSR_MHPMCOUNTER11 = 12'hB0B,
    // Machine performance monitoring counter 12 register
    CSR_MHPMCOUNTER12 = 12'hB0C,
    // Machine performance monitoring counter 13 register
    CSR_MHPMCOUNTER13 = 12'hB0D,
    // Machine performance monitoring counter 14 register
    CSR_MHPMCOUNTER14 = 12'hB0E,
    // Machine performance monitoring counter 15 register
    CSR_MHPMCOUNTER15 = 12'hB0F,
    // Machine performance monitoring counter 16 register
    CSR_MHPMCOUNTER16 = 12'hB10,
    // Machine performance monitoring counter 17 register
    CSR_MHPMCOUNTER17 = 12'hB11,
    // Machine performance monitoring counter 18 register
    CSR_MHPMCOUNTER18 = 12'hB12,
    // Machine performance monitoring counter 19 register
    CSR_MHPMCOUNTER19 = 12'hB13,
    // Machine performance monitoring counter 20 register
    CSR_MHPMCOUNTER20 = 12'hB14,
    // Machine performance monitoring counter 21 register
    CSR_MHPMCOUNTER21 = 12'hB15,
    // Machine performance monitoring counter 22 register
    CSR_MHPMCOUNTER22 = 12'hB16,
    // Machine performance monitoring counter 23 register
    CSR_MHPMCOUNTER23 = 12'hB17,
    // Machine performance monitoring counter 24 register
    CSR_MHPMCOUNTER24 = 12'hB18,
    // Machine performance monitoring counter 25 register
    CSR_MHPMCOUNTER25 = 12'hB19,
    // Machine performance monitoring counter 26 register
    CSR_MHPMCOUNTER26 = 12'hB1A,
    // Machine performance monitoring counter 27 register
    CSR_MHPMCOUNTER27 = 12'hB1B,
    // Machine performance monitoring counter 28 register
    CSR_MHPMCOUNTER28 = 12'hB1C,
    // Machine performance monitoring counter 29 register
    CSR_MHPMCOUNTER29 = 12'hB1D,
    // Machine performance monitoring counter 30 register
    CSR_MHPMCOUNTER30 = 12'hB1E,
    // Machine performance monitoring counter 31 register
    CSR_MHPMCOUNTER31 = 12'hB1F,

    // Machine cycle counter high bits register
    CSR_MCYCLEH   = 12'hB80,
    // Machine instruction retired counter high bits register
    CSR_MINSTRETH = 12'hB82,

    // Machine performance monitoring counter 3 high bits register
    CSR_MHPMCOUNTER3H  = 12'hB83,
    // Machine performance monitoring counter 4 high bits register
    CSR_MHPMCOUNTER4H  = 12'hB84,
    // Machine performance monitoring counter 5 high bits register
    CSR_MHPMCOUNTER5H  = 12'hB85,
    // Machine performance monitoring counter 6 high bits register
    CSR_MHPMCOUNTER6H  = 12'hB86,
    // Machine performance monitoring counter 7 high bits register
    CSR_MHPMCOUNTER7H  = 12'hB87,
    // Machine performance monitoring counter 8 high bits register
    CSR_MHPMCOUNTER8H  = 12'hB88,
    // Machine performance monitoring counter 9 high bits register
    CSR_MHPMCOUNTER9H  = 12'hB89,
    // Machine performance monitoring counter 10 high bits register
    CSR_MHPMCOUNTER10H = 12'hB8A,
    // Machine performance monitoring counter 11 high bits register
    CSR_MHPMCOUNTER11H = 12'hB8B,
    // Machine performance monitoring counter 12 high bits register
    CSR_MHPMCOUNTER12H = 12'hB8C,
    // Machine performance monitoring counter 13 high bits register
    CSR_MHPMCOUNTER13H = 12'hB8D,
    // Machine performance monitoring counter 14 high bits register
    CSR_MHPMCOUNTER14H = 12'hB8E,
    // Machine performance monitoring counter 15 high bits register
    CSR_MHPMCOUNTER15H = 12'hB8F,
    // Machine performance monitoring counter 16 high bits register
    CSR_MHPMCOUNTER16H = 12'hB90,
    // Machine performance monitoring counter 17 high bits register
    CSR_MHPMCOUNTER17H = 12'hB91,
    // Machine performance monitoring counter 18 high bits register
    CSR_MHPMCOUNTER18H = 12'hB92,
    // Machine performance monitoring counter 19 high bits register
    CSR_MHPMCOUNTER19H = 12'hB93,
    // Machine performance monitoring counter 20 high bits register
    CSR_MHPMCOUNTER20H = 12'hB94,
    // Machine performance monitoring counter 21 high bits register
    CSR_MHPMCOUNTER21H = 12'hB95,
    // Machine performance monitoring counter 22 high bits register
    CSR_MHPMCOUNTER22H = 12'hB96,
    // Machine performance monitoring counter 23 high bits register
    CSR_MHPMCOUNTER23H = 12'hB97,
    // Machine performance monitoring counter 24 high bits register
    CSR_MHPMCOUNTER24H = 12'hB98,
    // Machine performance monitoring counter 25 high bits register
    CSR_MHPMCOUNTER25H = 12'hB99,
    // Machine performance monitoring counter 26 high bits register
    CSR_MHPMCOUNTER26H = 12'hB9A,
    // Machine performance monitoring counter 27 high bits register
    CSR_MHPMCOUNTER27H = 12'hB9B,
    // Machine performance monitoring counter 28 high bits register
    CSR_MHPMCOUNTER28H = 12'hB9C,
    // Machine performance monitoring counter 29 high bits register
    CSR_MHPMCOUNTER29H = 12'hB9D,
    // Machine performance monitoring counter 30 high bits register
    CSR_MHPMCOUNTER30H = 12'hB9E,
    // Machine performance monitoring counter 31 high bits register
    CSR_MHPMCOUNTER31H = 12'hB9F,

    // Cycle counter register
    CSR_CYCLE   = 12'hC00,
    // Instruction retired counter register
    CSR_INSTRET = 12'hC02,

    // Hardware performance monitoring counter 3 register
    CSR_HPMCOUNTER3  = 12'hC03,
    // Hardware performance monitoring counter 4 register
    CSR_HPMCOUNTER4  = 12'hC04,
    // Hardware performance monitoring counter 5 register
    CSR_HPMCOUNTER5  = 12'hC05,
    // Hardware performance monitoring counter 6 register
    CSR_HPMCOUNTER6  = 12'hC06,
    // Hardware performance monitoring counter 7 register
    CSR_HPMCOUNTER7  = 12'hC07,
    // Hardware performance monitoring counter 8 register
    CSR_HPMCOUNTER8  = 12'hC08,
    // Hardware performance monitoring counter 9 register
    CSR_HPMCOUNTER9  = 12'hC09,
    // Hardware performance monitoring counter 10 register
    CSR_HPMCOUNTER10 = 12'hC0A,
    // Hardware performance monitoring counter 11 register
    CSR_HPMCOUNTER11 = 12'hC0B,
    // Hardware performance monitoring counter 12 register
    CSR_HPMCOUNTER12 = 12'hC0C,
    // Hardware performance monitoring counter 13 register
    CSR_HPMCOUNTER13 = 12'hC0D,
    // Hardware performance monitoring counter 14 register
    CSR_HPMCOUNTER14 = 12'hC0E,
    // Hardware performance monitoring counter 15 register
    CSR_HPMCOUNTER15 = 12'hC0F,
    // Hardware performance monitoring counter 16 register
    CSR_HPMCOUNTER16 = 12'hC10,
    // Hardware performance monitoring counter 17 register
    CSR_HPMCOUNTER17 = 12'hC11,
    // Hardware performance monitoring counter 18 register
    CSR_HPMCOUNTER18 = 12'hC12,
    // Hardware performance monitoring counter 19 register
    CSR_HPMCOUNTER19 = 12'hC13,
    // Hardware performance monitoring counter 20 register
    CSR_HPMCOUNTER20 = 12'hC14,
    // Hardware performance monitoring counter 21 register
    CSR_HPMCOUNTER21 = 12'hC15,
    // Hardware performance monitoring counter 22 register
    CSR_HPMCOUNTER22 = 12'hC16,
    // Hardware performance monitoring counter 23 register
    CSR_HPMCOUNTER23 = 12'hC17,
    // Hardware performance monitoring counter 24 register
    CSR_HPMCOUNTER24 = 12'hC18,
    // Hardware performance monitoring counter 25 register
    CSR_HPMCOUNTER25 = 12'hC19,
    // Hardware performance monitoring counter 26 register
    CSR_HPMCOUNTER26 = 12'hC1A,
    // Hardware performance monitoring counter 27 register
    CSR_HPMCOUNTER27 = 12'hC1B,
    // Hardware performance monitoring counter 28 register
    CSR_HPMCOUNTER28 = 12'hC1C,
    // Hardware performance monitoring counter 29 register
    CSR_HPMCOUNTER29 = 12'hC1D,
    // Hardware performance monitoring counter 30 register
    CSR_HPMCOUNTER30 = 12'hC1E,
    // Hardware performance monitoring counter 31 register
    CSR_HPMCOUNTER31 = 12'hC1F,

    // Cycle counter high bits register
    CSR_CYCLEH   = 12'hC80,
    // Instruction retired counter high bits register
    CSR_INSTRETH = 12'hC82,

    // Hardware performance monitoring counter 3 high bits register
    CSR_HPMCOUNTER3H  = 12'hC83,
    // Hardware performance monitoring counter 4 high bits register
    CSR_HPMCOUNTER4H  = 12'hC84,
    // Hardware performance monitoring counter 5 high bits register
    CSR_HPMCOUNTER5H  = 12'hC85,
    // Hardware performance monitoring counter 6 high bits register
    CSR_HPMCOUNTER6H  = 12'hC86,
    // Hardware performance monitoring counter 7 high bits register
    CSR_HPMCOUNTER7H  = 12'hC87,
    // Hardware performance monitoring counter 8 high bits register
    CSR_HPMCOUNTER8H  = 12'hC88,
    // Hardware performance monitoring counter 9 high bits register
    CSR_HPMCOUNTER9H  = 12'hC89,
    // Hardware performance monitoring counter 10 high bits register
    CSR_HPMCOUNTER10H = 12'hC8A,
    // Hardware performance monitoring counter 11 high bits register
    CSR_HPMCOUNTER11H = 12'hC8B,
    // Hardware performance monitoring counter 12 high bits register
    CSR_HPMCOUNTER12H = 12'hC8C,
    // Hardware performance monitoring counter 13 high bits register
    CSR_HPMCOUNTER13H = 12'hC8D,
    // Hardware performance monitoring counter 14 high bits register
    CSR_HPMCOUNTER14H = 12'hC8E,
    // Hardware performance monitoring counter 15 high bits register
    CSR_HPMCOUNTER15H = 12'hC8F,
    // Hardware performance monitoring counter 16 high bits register
    CSR_HPMCOUNTER16H = 12'hC90,
    // Hardware performance monitoring counter 17 high bits register
    CSR_HPMCOUNTER17H = 12'hC91,
    // Hardware performance monitoring counter 18 high bits register
    CSR_HPMCOUNTER18H = 12'hC92,
    // Hardware performance monitoring counter 19 high bits register
    CSR_HPMCOUNTER19H = 12'hC93,
    // Hardware performance monitoring counter 20 high bits register
    CSR_HPMCOUNTER20H = 12'hC94,
    // Hardware performance monitoring counter 21 high bits register
    CSR_HPMCOUNTER21H = 12'hC95,
    // Hardware performance monitoring counter 22 high bits register
    CSR_HPMCOUNTER22H = 12'hC96,
    // Hardware performance monitoring counter 23 high bits register
    CSR_HPMCOUNTER23H = 12'hC97,
    // Hardware performance monitoring counter 24 high bits register
    CSR_HPMCOUNTER24H = 12'hC98,
    // Hardware performance monitoring counter 25 high bits register
    CSR_HPMCOUNTER25H = 12'hC99,
    // Hardware performance monitoring counter 26 high bits register
    CSR_HPMCOUNTER26H = 12'hC9A,
    // Hardware performance monitoring counter 27 high bits register
    CSR_HPMCOUNTER27H = 12'hC9B,
    // Hardware performance monitoring counter 28 high bits register
    CSR_HPMCOUNTER28H = 12'hC9C,
    // Hardware performance monitoring counter 29 high bits register
    CSR_HPMCOUNTER29H = 12'hC9D,
    // Hardware performance monitoring counter 30 high bits register
    CSR_HPMCOUNTER30H = 12'hC9E,
    // Hardware performance monitoring counter 31 high bits register
    CSR_HPMCOUNTER31H = 12'hC9F,

    // Vendor ID register
    CSR_MVENDORID = 12'hF11,
    // Architecture ID register
    CSR_MARCHID   = 12'hF12,
    // Implementation ID register
    CSR_MIMPID    = 12'hF13,
    // Hardware thread ID register
    CSR_MHARTID   = 12'hF14
  } csr_num_e;

  // Parameter defining the width of the CSR operation code
  parameter int CSR_OP_WIDTH = 2;

  // Typedef for the CSR opcode enumeration
  typedef enum logic [CSR_OP_WIDTH-1:0] {
    // CSR operation: Read
    CSR_OP_READ  = 2'b00,
    // CSR operation: Write
    CSR_OP_WRITE = 2'b01,
    // CSR operation: Set bits
    CSR_OP_SET   = 2'b10,
    // CSR operation: Clear bits
    CSR_OP_CLEAR = 2'b11
  } csr_opcode_e;

  // Parameter defining the bit position for MSIX interrupt enable in MIE
  parameter int unsigned CSR_MSIX_BIT = 3;

  // Parameter defining the bit position for timer interrupt enable in MIE
  parameter int unsigned CSR_MTIX_BIT = 7;

  // Parameter defining the bit position for external interrupt enable in MIE
  parameter int unsigned CSR_MEIX_BIT = 11;

  // Parameter defining the lower bit position for floating-point interrupt enable in MIE
  parameter int unsigned CSR_MFIX_BIT_LOW = 16;

  // Parameter defining the higher bit position for floating-point interrupt enable in MIE
  parameter int unsigned CSR_MFIX_BIT_HIGH = 31;

  // Parameter defining the address for SP_DCR0 register (likely a custom register)
  parameter int SP_DCR0 = 16'h3008;
  // Parameter defining the address for SP_DVR0 register (likely a custom register)
  parameter int SP_DVR0 = 16'h3000;
  // Parameter defining the address for SP_DMR1 register (likely a custom register)
  parameter int SP_DMR1 = 16'h3010;
  // Parameter defining the address for SP_DMR2 register (likely a custom register)
  parameter int SP_DMR2 = 16'h3011;

  // Parameter defining the MSB for SP_DVR register
  parameter int SP_DVR_MSB = 8'h00;
  // Parameter defining the MSB for SP_DCR register
  parameter int SP_DCR_MSB = 8'h01;
  // Parameter defining the MSB for SP_DMR register
  parameter int SP_DMR_MSB = 8'h02;
  // Parameter defining the MSB for SP_DSR register
  parameter int SP_DSR_MSB = 8'h04;

  // Typedef for the privilege level type
  typedef enum logic [1:0] {
    // Privilege level: Machine mode
    PRIV_LVL_M = 2'b11,
    // Privilege level: Hypervisor mode (not standard for RV32)
    PRIV_LVL_H = 2'b10,
    // Privilege level: Supervisor mode (not standard for RV32)
    PRIV_LVL_S = 2'b01,
    // Privilege level: User mode
    PRIV_LVL_U = 2'b00
  } priv_lvl_t;

  // Typedef for the status register structure
  typedef struct packed {
    // User interrupt enable
    logic uie;
    // Machine interrupt enable
    logic mie;
    // User previous interrupt enable
    logic upie;
    // Machine previous interrupt enable
    logic mpie;
    // Machine previous privilege mode
    priv_lvl_t mpp;
    // Machine privilege mode prior to exception
    logic mprv;
  } status_t;

  // Typedef for the debug control and status register structure
  typedef struct packed {
    // Debug version
    logic [31:28] xdebugver;
    // Reserved bits
    logic [27:16] zero2;
    // Enable breakpoint in machine mode
    logic         ebreakm;
    // Reserved bit
    logic         zero1;
    // Enable breakpoint in supervisor mode
    logic         ebreaks;
    // Enable breakpoint in user mode
    logic         ebreaku;
    // Enable single-step interrupt
    logic         stepie;
    // Stop counting (for performance counters)
    logic         stopcount;
    // Stop time (for performance counters)
    logic         stoptime;
    // Debug cause
    logic [8:6]   cause;
    // Reserved bit
    logic         zero0;
    // Enable machine privilege mode for data access
    logic         mprven;
    // Non-maskable interrupt pending
    logic         nmip;
    // Single-step enable
    logic         step;
    // Current privilege level
    priv_lvl_t    prv;
  } dcsr_t;

  // Typedef for the floating-point status enumeration
  typedef enum logic [1:0] {
    // Floating-point status: Off
    FS_OFF    = 2'b00,
    // Floating-point status: Initial (all flags clear)
    FS_INITIAL = 2'b01,
    // Floating-point status: Clean (no exceptions since last clear)
    FS_CLEAN   = 2'b10,
    // Floating-point status: Dirty (at least one exception occurred)
    FS_DIRTY   = 2'b11
  } fs_t;

  // Parameter defining the offset for MVENDORID in a memory bank
  parameter int MVENDORID_OFFSET = 7'h2;
  // Parameter defining the memory bank for MVENDORID
  parameter int MVENDORID_BANK = 25'hC;

  // Parameter defining the value for MARCHID
  parameter int MARCHID = 32'h4;

  // Parameter defining the width of the machine hardware performance monitoring counter
  parameter int MHPMCOUNTER_WIDTH = 64;

  // Parameter defining the selection for the register file
  parameter int SEL_REGFILE = 2'b00;
  // Parameter defining the selection for forwarding from execute stage
  parameter int SEL_FW_EX = 2'b01;
  // Parameter defining the selection for forwarding from write-back stage
  parameter int SEL_FW_WB = 2'b10;

  // Parameter defining operand A source: register A or forwarding
  parameter int OP_A_REGA_OR_FWD = 3'b000;
  // Parameter defining operand A source: current PC
  parameter int OP_A_CURRPC = 3'b001;
  // Parameter defining operand A source: immediate value
  parameter int OP_A_IMM = 3'b010;
  // Parameter defining operand A source: register B or forwarding
  parameter int OP_A_REGB_OR_FWD = 3'b011;
  // Parameter defining operand A source: register C or forwarding
  parameter int OP_A_REGC_OR_FWD = 3'b100;

  // Parameter defining immediate A select: zero
  parameter int IMMA_Z = 1'b0;
  // Parameter defining immediate A select: zero (alternative)
  parameter int IMMA_ZERO = 1'b1;

  // Parameter defining operand B source: register B or forwarding
  parameter int OP_B_REGB_OR_FWD = 3'b000;
  // Parameter defining operand B source: register C or forwarding
  parameter int OP_B_REGC_OR_FWD = 3'b001;
  // Parameter defining operand B source: immediate value
  parameter int OP_B_IMM = 3'b010;
  // Parameter defining operand B source: register A or forwarding
  parameter int OP_B_REGA_OR_FWD = 3'b011;
  // Parameter defining operand B source: bitmask
  parameter int OP_B_BMASK = 3'b100;

  // Parameter defining immediate B format: I-type
  parameter int IMMB_I = 4'b0000;
  // Parameter defining immediate B format: S-type
  parameter int IMMB_S = 4'b0001;
  // Parameter defining immediate B format: U-type
  parameter int IMMB_U = 4'b0010;
  // Parameter defining immediate B format: PC increment
  parameter int IMMB_PCINCR = 4'b0011;
  // Parameter defining immediate B format: S-type with shift by 2
  parameter int IMMB_S2 = 4'b0100;
  // Parameter defining immediate B format: S-type with shift by 3
  parameter int IMMB_S3 = 4'b0101;
  // Parameter defining immediate B format: Vector-scalar
  parameter int IMMB_VS = 4'b0110;
  // Parameter defining immediate B format: Vector-unsigned
  parameter int IMMB_VU = 4'b0111;
  // Parameter defining immediate B format: Shuffle
  parameter int IMMB_SHUF = 4'b1000;
  // Parameter defining immediate B format: Clip
  parameter int IMMB_CLIP = 4'b1001;
  // Parameter defining immediate B format: Bitwise immediate
  parameter int IMMB_BI = 4'b1011;

  // Parameter defining bitmask A select: zero
  parameter int BMASK_A_ZERO = 1'b0;
  // Parameter defining bitmask A select: S3 register
  parameter int BMASK_A_S3 = 1'b1;

  // Parameter defining bitmask B select: S2 register
  parameter int BMASK_B_S2 = 2'b00;
  // Parameter defining bitmask B select: S3 register
  parameter int BMASK_B_S3 = 2'b01;
  // Parameter defining bitmask B select: zero
  parameter int BMASK_B_ZERO = 2'b10;
  // Parameter defining bitmask B select: one
  parameter int BMASK_B_ONE = 2'b11;

  // Parameter defining bitmask A source: register
  parameter int BMASK_A_REG = 1'b0;
  // Parameter defining bitmask A source: immediate
  parameter int BMASK_A_IMM = 1'b1;
  // Parameter defining bitmask B source: register
  parameter int BMASK_B_REG = 1'b0;
  // Parameter defining bitmask B source: immediate
  parameter int BMASK_B_IMM = 1'b1;

  // Parameter defining multiplier immediate select: zero
  parameter int MIMM_ZERO = 1'b0;
  // Parameter defining multiplier immediate select: S3 register
  parameter int MIMM_S3 = 1'b1;

  // Parameter defining operand C source: register C or forwarding
  parameter int OP_C_REGC_OR_FWD = 2'b00;
  // Parameter defining operand C source: register B or forwarding
  parameter int OP_C_REGB_OR_FWD = 2'b01;
  // Parameter defining operand C source: jump target
  parameter int OP_C_JT = 2'b10;

  // Parameter defining branch type: none
  parameter int BRANCH_NONE = 2'b00;
  // Parameter defining branch type: jump and link
  parameter int BRANCH_JAL = 2'b01;
  // Parameter defining branch type: jump and link register
  parameter int BRANCH_JALR = 2'b10;
  // Parameter defining branch type: conditional branch
  parameter int BRANCH_COND = 2'b11;

  // Parameter defining jump target type: jump and link
  parameter int JT_JAL = 2'b01;
  // Parameter defining jump target type: jump and link register
  parameter int JT_JALR = 2'b10;
  // Parameter defining jump target type: conditional branch
  parameter int JT_COND = 2'b11;

  // Parameter defining AMO operation: load-reserved
  parameter int AMO_LR = 5'b00010;
  // Parameter defining AMO operation: store-conditional
  parameter int AMO_SC = 5'b00011;
  // Parameter defining AMO operation: swap
  parameter int AMO_SWAP = 5'b00001;
  // Parameter defining AMO operation: add
  parameter int AMO_ADD = 5'b00000;
  // Parameter defining AMO operation: xor
  parameter int AMO_XOR = 5'b00100;
  // Parameter defining AMO operation: and
  parameter int AMO_AND = 5'b01100;
  // Parameter defining AMO operation: or
  parameter int AMO_OR = 5'b01000;
  // Parameter defining AMO operation: min signed
  parameter int AMO_MIN = 5'b10000;
  // Parameter defining AMO operation: max signed
  parameter int AMO_MAX = 5'b10100;
  // Parameter defining AMO operation: min unsigned
  parameter int AMO_MINU = 5'b11000;
  // Parameter defining AMO operation: max unsigned
  parameter int AMO_MAXU = 5'b11100;

  // Parameter defining PC update type: boot address
  parameter int PC_BOOT = 4'b0000;
  // Parameter defining PC update type: jump
  parameter int PC_JUMP = 4'b0010;
  // Parameter defining PC update type: branch
  parameter int PC_BRANCH = 4'b0011;
  // Parameter defining PC update type: exception
  parameter int PC_EXCEPTION = 4'b0100;
  // Parameter defining PC update type: fence.i
  parameter int PC_FENCEI = 4'b0001;
  // Parameter defining PC update type: machine return from trap
  parameter int PC_MRET = 4'b0101;
  // Parameter defining PC update type: user return from trap
  parameter int PC_URET = 4'b0110;
  // Parameter defining PC update type: debug return
  parameter int PC_DRET = 4'b0111;
  // Parameter defining PC update type: hardware loop
  parameter int PC_HWLOOP = 4'b1000;

  // Parameter defining exception PC source: exception
  parameter int EXC_PC_EXCEPTION = 3'b000;
  // Parameter defining exception PC source: interrupt request
  parameter int EXC_PC_IRQ = 3'b001;

  // Parameter defining exception PC source: debug breakpoint
  parameter int EXC_PC_DBD = 3'b010;
  // Parameter defining exception PC source: debug exception
  parameter int EXC_PC_DBE = 3'b011;

  // Parameter defining exception cause: instruction access fault
  parameter int EXC_CAUSE_INSTR_FAULT = 5'h01;
  // Parameter defining exception cause: illegal instruction
  parameter int EXC_CAUSE_ILLEGAL_INSN = 5'h02;
  // Parameter defining exception cause: breakpoint
  parameter int EXC_CAUSE_BREAKPOINT = 5'h03;
  // Parameter defining exception cause: load access fault
  parameter int EXC_CAUSE_LOAD_FAULT = 5'h05;
  // Parameter defining exception cause: store access fault
  parameter int EXC_CAUSE_STORE_FAULT = 5'h07;
  // Parameter defining exception cause: ecall in user mode
  parameter int EXC_CAUSE_ECALL_UMODE = 5'h08;
  // Parameter defining exception cause: ecall in machine mode
  parameter int EXC_CAUSE_ECALL_MMODE = 5'h0B;

  // Parameter defining the interrupt request mask
  parameter int IRQ_MASK = 32'hFFFF0888;

  // Parameter defining trap target: machine mode
  parameter int TRAP_MACHINE = 2'b00;
  // Parameter defining trap target: user mode
  parameter int TRAP_USER = 2'b01;

  // Parameter defining debug cause: none
  parameter int DBG_CAUSE_NONE = 3'h0;
  // Parameter defining debug cause: ebreak instruction
  parameter int DBG_CAUSE_EBREAK = 3'h1;
  // Parameter defining debug cause: trigger matched
  parameter int DBG_CAUSE_TRIGGER = 3'h2;
  // Parameter defining debug cause: halt request
  parameter int DBG_CAUSE_HALTREQ = 3'h3;
  // Parameter defining debug cause: single-step
  parameter int DBG_CAUSE_STEP = 3'h4;
  // Parameter defining debug cause: reset halt request
  parameter int DBG_CAUSE_RSTHALTREQ = 3'h5;

  // Parameter defining the set index for watchpoint debug set
  parameter int DBG_SETS_W = 6;
  // Parameter defining the set index for IRQ debug set
  parameter int DBG_SETS_IRQ = 5;
  // Parameter defining the set index for ECall debug set
  parameter int DBG_SETS_ECALL = 4;
  // Parameter defining the set index for illegal instruction debug set
  parameter int DBG_SETS_EILL = 3;
  // Parameter defining the set index for load/store unit debug set
  parameter int DBG_SETS_ELSU = 2;
  // Parameter defining the set index for EBreak debug set
  parameter int DBG_SETS_EBRK = 1;
  // Parameter defining the set index for single-step debug set
  parameter int DBG_SETS_SSTE = 0;

  // Parameter defining the debug cause: halt
  parameter int DBG_CAUSE_HALT = 6'h1F;

  // Typedef for the xdebugver enumeration
  typedef enum logic [3:0] {
    // Debug version: None
    XDEBUGVER_NO     = 4'd0,
    // Debug version: Standard
    XDEBUGVER_STD    = 4'd4,
    // Debug version: Non-standard
    XDEBUGVER_NONSTD = 4'd15
  } x_debug_ver_e;

  // Typedef for the trigger type enumeration
  typedef enum logic [3:0] {
    // Trigger type: Memory control
    TTYPE_MCONTROL = 4'h2,
    // Trigger type: Instruction count
    TTYPE_ICOUNT   = 4'h3,
    // Trigger type: Instruction trigger
    TTYPE_ITRIGGER = 4'h4,
    // Trigger type: Exception trigger
    TTYPE_ETRIGGER = 4'h5
  } trigger_type_e;

  // Parameter indicating support for the RVF extension (single-precision FP)
  parameter bit C_RVF = 1'b1;

  // Parameter indicating support for the RVD extension (double-precision FP)
  parameter bit C_RVD = 1'b0;

  // Parameter indicating support for the XF16 extension (half-precision FP)
  parameter bit C_XF16 = 1'b0;

  // Parameter indicating support for the XF16ALT extension (alternative half-precision FP)
  parameter bit C_XF16ALT = 1'b0;

  // Parameter indicating support for the XF8 extension (quarter-precision FP)
  parameter bit C_XF8 = 1'b0;

  // Parameter indicating support for the XFVEC extension (vector FP)
  parameter bit C_XFVEC = 1'b0;

  // Parameter defining the latency for FP64 operations
  parameter int unsigned C_LAT_FP64 = 'd0;

  // Parameter defining the latency for FP16 operations
  parameter int unsigned C_LAT_FP16 = 'd0;

  // Parameter defining the latency for FP16ALT operations
  parameter int unsigned C_LAT_FP16ALT = 'd0;

  // Parameter defining the latency for FP8 operations
  parameter int unsigned C_LAT_FP8 = 'd0;

  // Parameter defining the latency for division and square root operations
  parameter int unsigned C_LAT_DIVSQRT = 'd1;

  // Parameter defining the floating-point register length based on supported extensions
  parameter int C_FLEN = C_RVD ? 64 : C_RVF ? 32 : C_XF16 ? 16 : C_XF16ALT ? 16 : C_XF8 ? 8 : 0;

  // Parameter defining the number of bits for floating-point flags
  parameter int C_FFLAG = 5;
  // Parameter defining the number of bits for floating-point rounding mode
  parameter int C_RM = 3;

endpackage
