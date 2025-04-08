module rv32imf_cs_registers
  import rv32imf_pkg::*;  // Import package containing definitions
#(
    parameter int N_HWLP           = 2,   // Number of hardware loop registers
    parameter int N_PMP_ENTRIES    = 16,  // Number of PMP entries
    parameter int DEBUG_TRIGGER_EN = 1    // Enable debug trigger
) (

    input logic clk,   // Clock input
    input logic rst_n, // Asynchronous reset input (active low)

    input  logic [31:0] hart_id_i,     // Hart ID input
    output logic [23:0] mtvec_o,       // Machine trap vector output
    output logic [23:0] utvec_o,       // User trap vector output
    output logic [ 1:0] mtvec_mode_o,  // Machine trap vector mode output
    output logic [ 1:0] utvec_mode_o,  // User trap vector mode output

    input logic [31:0] mtvec_addr_i,     // Machine trap vector address input
    input logic        csr_mtvec_init_i, // Initialize MTVEC on reset

    input  csr_num_e           csr_addr_i,   // CSR address input
    input  logic        [31:0] csr_wdata_i,  // CSR write data input
    input  csr_opcode_e        csr_op_i,     // CSR operation input
    output logic        [31:0] csr_rdata_o,  // CSR read data output

    output logic               fs_off_o,     // Floating-point state off output
    output logic [        2:0] frm_o,        // Floating-point rounding mode output
    input  logic [C_FFLAG-1:0] fflags_i,     // Floating-point flags input
    input  logic               fflags_we_i,  // Floating-point flags write enable input
    input  logic               fregs_we_i,   // Floating-point registers write enable input

    output logic [31:0] mie_bypass_o,    // Machine interrupt enable bypass output
    input  logic [31:0] mip_i,           // Machine interrupt pending input
    output logic        m_irq_enable_o,  // Machine interrupt enable output
    output logic        u_irq_enable_o,  // User interrupt enable output

    input  logic        csr_irq_sec_i,  // Interrupt security level input
    output logic        sec_lvl_o,      // Security level output
    output logic [31:0] mepc_o,         // Machine exception program counter output
    output logic [31:0] uepc_o,         // User exception program counter output

    output logic [31:0] mcounteren_o,  // Machine counter enable output

    input  logic        debug_mode_i,         // Debug mode input
    input  logic [ 2:0] debug_cause_i,        // Debug cause input
    input  logic        debug_csr_save_i,     // Debug CSR save input
    output logic [31:0] depc_o,               // Debug exception program counter output
    output logic        debug_single_step_o,  // Debug single step output
    output logic        debug_ebreakm_o,      // Debug ebreak in M-mode output
    output logic        debug_ebreaku_o,      // Debug ebreak in U-mode output
    output logic        trigger_match_o,      // Trigger match output

    output logic [N_PMP_ENTRIES-1:0][31:0] pmp_addr_o,  // PMP address outputs
    output logic [N_PMP_ENTRIES-1:0][ 7:0] pmp_cfg_o,   // PMP configuration outputs

    output priv_lvl_t priv_lvl_o,  // Current privilege level output

    input logic [31:0] pc_if_i,  // PC from instruction fetch stage
    input logic [31:0] pc_id_i,  // PC from instruction decode stage
    input logic [31:0] pc_ex_i,  // PC from execute stage

    input logic csr_save_if_i,  // CSR save request from IF stage
    input logic csr_save_id_i,  // CSR save request from ID stage
    input logic csr_save_ex_i,  // CSR save request from EX stage

    input logic csr_restore_mret_i,  // CSR restore request for MRET
    input logic csr_restore_uret_i,  // CSR restore request for URET

    input logic csr_restore_dret_i,  // CSR restore request for DRET

    input logic [5:0] csr_cause_i,  // Exception cause input

    input logic csr_save_cause_i,  // CSR save cause request

    input logic [N_HWLP-1:0][31:0] hwlp_start_i,  // Hardware loop start addresses
    input logic [N_HWLP-1:0][31:0] hwlp_end_i,    // Hardware loop end addresses
    input logic [N_HWLP-1:0][31:0] hwlp_cnt_i,    // Hardware loop counters

    input logic mhpmevent_minstret_i,      // MHPM event for instruction retired
    input logic mhpmevent_load_i,          // MHPM event for load instruction
    input logic mhpmevent_store_i,         // MHPM event for store instruction
    input logic mhpmevent_jump_i,          // MHPM event for jump instruction
    input logic mhpmevent_branch_i,        // MHPM event for branch instruction
    input logic mhpmevent_branch_taken_i,  // MHPM event for taken branch
    input logic mhpmevent_compressed_i,    // MHPM event for compressed instruction
    input logic mhpmevent_jr_stall_i,      // MHPM event for JR stall
    input logic mhpmevent_imiss_i,         // MHPM event for instruction cache miss
    input logic mhpmevent_ld_stall_i,      // MHPM event for load stall
    input logic mhpmevent_pipe_stall_i,    // MHPM event for pipeline stall
    input logic apu_typeconflict_i,        // APU type conflict event
    input logic apu_contention_i,          // APU contention event
    input logic apu_dep_i,                 // APU dependency event
    input logic apu_wb_i,                  // APU writeback event

    input logic [63:0] time_i  // Time input for cycle counting
);

  // Number of hardware performance monitor events
  localparam int HmpEvents = 16;

  // Default MTVEC mode
  localparam int MtvecMode = 2'b01;

  // Maximum number of PMP entries
  localparam int MaxPmpEntries = 16;
  // Maximum number of PMP config registers
  localparam int MaxPmpConfigs = 4;
  // Number of PMP config regs
  localparam int PmpConfigs = N_PMP_ENTRIES % 4 == 0 ? N_PMP_ENTRIES / 4 : N_PMP_ENTRIES / 4 + 1;

  // User interrupt enable bit in MSTATUS
  localparam int MstatusUieBit = 0;
  // Supervisor interrupt enable bit in MSTATUS
  localparam int MstatusSieBit = 1;
  // Machine interrupt enable bit in MSTATUS
  localparam int MstatusMieBit = 3;
  // User previous interrupt enable bit in MSTATUS
  localparam int MstatusUpieBit = 4;
  // Supervisor previous interrupt enable bit in MSTATUS
  localparam int MstatusSpieBit = 5;
  // Machine previous interrupt enable bit in MSTATUS
  localparam int MstatusMpieBit = 7;
  // Supervisor previous privilege bit in MSTATUS
  localparam int MstatusSppBit = 8;
  // Machine previous privilege bit (low) in MSTATUS
  localparam int MstatusMppBitLow = 11;
  // Machine previous privilege bit (high) in MSTATUS
  localparam int MstatusMppBitHigh = 12;
  // Floating-point state bit (low) in MSTATUS
  localparam int MstatusFsBitLow = 13;
  // Floating-point state bit (high) in MSTATUS
  localparam int MstatusFsBitHigh = 14;
  // Machine privilege for load and store bit in MSTATUS
  localparam int MstatusMprvBit = 17;
  // Status dirty bit in MSTATUS
  localparam int MstatusSdBit = 31;

  // Machine XLEN (32-bit)
  localparam logic [1:0] MXL = 2'd1;
  localparam logic [31:0] MisaValue = (32'(0) << 0)  // MISA register value
  | (1 << 2)  // I extension
  | (1 << 3)  // M extension
  | (0 << 4)  // A extension
  | (32'(1) << 5)  // F extension
  | (1 << 8)  // C extension
  | (1 << 12)  // U extension
  | (0 << 13)  // S extension
  | (0 << 18)  // D extension
  | (32'(0) << 20)  // V extension
  | (32'(MXL) << 30);  // XLEN

  typedef struct packed {  // Structure for PMP registers
    logic [MaxPmpEntries-1:0][31:0] pmpaddr;        // PMP address registers
    logic [MaxPmpConfigs-1:0][31:0] pmpcfg_packed;  // Packed PMP configuration registers
    logic [MaxPmpEntries-1:0][7:0]  pmpcfg;         // PMP configuration registers
  } pmp_t;

  logic [31:0] csr_wdata_int;  // Internal CSR write data
  logic [31:0] csr_rdata_int;  // Internal CSR read data
  logic        csr_we_int;  // Internal CSR write enable

  logic [C_RM-1:0] frm_q, frm_n;  // Current and next rounding mode
  logic [C_FFLAG-1:0] fflags_q, fflags_n;  // Current and next floating-point flags
  logic fcsr_update;  // Flag to update FCSR

  logic [31:0] mepc_q, mepc_n;  // Current and next machine exception PC
  logic [31:0] uepc_q, uepc_n;  // Current and next user exception PC

  logic [31:0] tmatch_control_rdata;  // Read data for trigger match control
  logic [31:0] tmatch_value_rdata;  // Read data for trigger match value
  logic [15:0] tinfo_types;  // Trigger info types

  dcsr_t dcsr_q, dcsr_n;  // Current and next debug control and status register
  logic [31:0] depc_q, depc_n;  // Current and next debug exception PC
  logic [31:0] dscratch0_q, dscratch0_n;  // Current and next debug scratch register 0
  logic [31:0] dscratch1_q, dscratch1_n;  // Current and next debug scratch register 1
  logic [31:0] mscratch_q, mscratch_n;  // Current and next machine scratch register

  logic [31:0] exception_pc;  // PC to save on exception
  status_t mstatus_q, mstatus_n;  // Current and next machine status register
  logic mstatus_we_int;  // Internal write enable for MSTATUS
  fs_t mstatus_fs_q, mstatus_fs_n;  // Current and next floating-point status in MSTATUS
  logic [5:0] mcause_q, mcause_n;  // Current and next machine exception cause
  logic [5:0] ucause_q, ucause_n;  // Current and next user exception cause
  logic [23:0] mtvec_n, mtvec_q;  // Current and next machine trap vector base address
  logic [23:0] utvec_n, utvec_q;  // Current and next user trap vector base address
  logic [1:0] mtvec_mode_n, mtvec_mode_q;  // Current and next machine trap vector mode
  logic [1:0] utvec_mode_n, utvec_mode_q;  // Current and next user trap vector mode

  logic [31:0] mip;  // Machine interrupt pending
  logic [31:0] mie_q, mie_n;  // Current and next machine interrupt enable

  logic [31:0] csr_mie_wdata;  // Write data for MIE CSR
  logic        csr_mie_we;  // Write enable for MIE CSR

  logic        is_irq;  // Flag indicating if the cause is an interrupt
  priv_lvl_t priv_lvl_n, priv_lvl_q;  // Current and next privilege level
  pmp_t pmp_reg_q, pmp_reg_n;  // Current and next PMP registers

  logic [MaxPmpEntries-1:0] pmpaddr_we;  // Write enable for PMP address
  logic [MaxPmpEntries-1:0] pmpcfg_we;  // Write enable for PMP configuration

  logic [31:0][MHPMCOUNTER_WIDTH-1:0] mhpmcounter_q;  // MHPM counter registers
  logic [31:0][31:0] mhpmevent_q, mhpmevent_n;  // Current and next MHPM event registers
  logic [31:0] mcounteren_q, mcounteren_n;  // Current and next machine counter enable
  logic [31:0] mcountinhibit_q, mcountinhibit_n;  // Current and next machine counter inhibit
  logic [HmpEvents-1:0] hpm_events;  // Hardware performance monitor events
  logic [31:0][MHPMCOUNTER_WIDTH-1:0] mhpmcounter_increment;  // Increment value for MHPM counters
  logic [31:0] mhpmcounter_write_lower;  // Write enable for lower part of MHPM counter
  logic [31:0] mhpmcounter_write_upper;  // Write enable for upper part of MHPM counter
  logic [31:0] mhpmcounter_write_increment;  // Increment enable for MHPM counter

  assign is_irq = csr_cause_i[5];  // Check if the most significant bit of cause is set (interrupt)

  assign mip = mip_i;  // Assign input MIP to internal signal

  always_comb begin  // Logic for handling MIE CSR writes
    csr_mie_wdata = csr_wdata_i;
    csr_mie_we    = 1'b1;

    case (csr_op_i)
      CSR_OP_WRITE: csr_mie_wdata = csr_wdata_i;  // Write operation
      CSR_OP_SET:   csr_mie_wdata = csr_wdata_i | mie_q;  // Set bits operation
      CSR_OP_CLEAR: csr_mie_wdata = (~csr_wdata_i) & mie_q;  // Clear bits operation
      CSR_OP_READ: begin  // Read operation
        csr_mie_wdata = csr_wdata_i;
        csr_mie_we    = 1'b0; // No write during read
      end
    endcase
  end

  // Bypass MIE
  assign mie_bypass_o = ((csr_addr_i == CSR_MIE) && csr_mie_we) ? csr_mie_wdata & IRQ_MASK : mie_q;

  always_comb begin  // Logic for reading CSR registers
    case (csr_addr_i)

      CSR_TIME, CSR_MTIME: csr_rdata_int = time_i[31:0];  // Read TIME or MTIME
      CSR_TIMEH, CSR_MTIMEH: csr_rdata_int = time_i[63:32];  // Read TIMEH or MTIMEH

      CSR_FFLAGS: csr_rdata_int = {27'b0, fflags_q};  // Read FFLAGS
      CSR_FRM: csr_rdata_int = {29'b0, frm_q};  // Read FRM
      CSR_FCSR: csr_rdata_int = {24'b0, frm_q, fflags_q};  // Read FCSR

      CSR_MSTATUS:  // Read MSTATUS
      csr_rdata_int = {
        (mstatus_fs_q == FS_DIRTY ? 1'b1 : 1'b0),
        13'b0,
        mstatus_q.mprv,
        2'b0,
        mstatus_fs_q,
        mstatus_q.mpp,
        3'b0,
        mstatus_q.mpie,
        2'h0,
        mstatus_q.upie,
        mstatus_q.mie,
        2'h0,
        mstatus_q.uie
      };

      CSR_MISA: csr_rdata_int = MisaValue;  // Read MISA

      CSR_MIE: begin  // Read MIE
        csr_rdata_int = mie_q;
      end

      CSR_MTVEC: csr_rdata_int = {mtvec_q, 6'h0, mtvec_mode_q};  // Read MTVEC

      CSR_MSCRATCH: csr_rdata_int = mscratch_q;  // Read MSCRATCH

      CSR_MEPC: csr_rdata_int = mepc_q;  // Read MEPC

      CSR_MCAUSE: csr_rdata_int = {mcause_q[5], 26'b0, mcause_q[4:0]};  // Read MCAUSE

      CSR_MIP: begin  // Read MIP
        csr_rdata_int = mip;
      end

      CSR_MHARTID: csr_rdata_int = hart_id_i;  // Read MHARTID

      CSR_MVENDORID: csr_rdata_int = {MVENDORID_BANK, MVENDORID_OFFSET};  // Read MVENDORID

      CSR_MARCHID: csr_rdata_int = MARCHID;  // Read MARCHID

      CSR_MIMPID: begin  // Read MIMPID
        csr_rdata_int = 32'h1;
      end

      CSR_MTVAL: csr_rdata_int = 'b0;  // Read MTVAL (not implemented)

      CSR_TSELECT, CSR_TDATA3, CSR_MCONTEXT, CSR_SCONTEXT:
      csr_rdata_int = 'b0;  // Trigger CSRs (not impl)
      CSR_TDATA1: csr_rdata_int = tmatch_control_rdata;  // Read TDATA1
      CSR_TDATA2: csr_rdata_int = tmatch_value_rdata;  // Read TDATA2
      CSR_TINFO: csr_rdata_int = tinfo_types;  // Read TINFO

      CSR_DCSR: csr_rdata_int = dcsr_q;  // Read DCSR
      CSR_DPC: csr_rdata_int = depc_q;  // Read DPC
      CSR_DSCRATCH0: csr_rdata_int = dscratch0_q;  // Read DSCRATCH0
      CSR_DSCRATCH1: csr_rdata_int = dscratch1_q;  // Read DSCRATCH1

      CSR_MCYCLE,
      CSR_MINSTRET,
      CSR_MHPMCOUNTER3,
      CSR_MHPMCOUNTER4,  CSR_MHPMCOUNTER5,  CSR_MHPMCOUNTER6,  CSR_MHPMCOUNTER7,
      CSR_MHPMCOUNTER8,  CSR_MHPMCOUNTER9,  CSR_MHPMCOUNTER10, CSR_MHPMCOUNTER11,
      CSR_MHPMCOUNTER12, CSR_MHPMCOUNTER13, CSR_MHPMCOUNTER14, CSR_MHPMCOUNTER15,
      CSR_MHPMCOUNTER16, CSR_MHPMCOUNTER17, CSR_MHPMCOUNTER18, CSR_MHPMCOUNTER19,
      CSR_MHPMCOUNTER20, CSR_MHPMCOUNTER21, CSR_MHPMCOUNTER22, CSR_MHPMCOUNTER23,
      CSR_MHPMCOUNTER24, CSR_MHPMCOUNTER25, CSR_MHPMCOUNTER26, CSR_MHPMCOUNTER27,
      CSR_MHPMCOUNTER28, CSR_MHPMCOUNTER29, CSR_MHPMCOUNTER30, CSR_MHPMCOUNTER31,
      CSR_CYCLE,
      CSR_INSTRET,
      CSR_HPMCOUNTER3,
      CSR_HPMCOUNTER4,  CSR_HPMCOUNTER5,  CSR_HPMCOUNTER6,  CSR_HPMCOUNTER7,
      CSR_HPMCOUNTER8,  CSR_HPMCOUNTER9,  CSR_HPMCOUNTER10, CSR_HPMCOUNTER11,
      CSR_HPMCOUNTER12, CSR_HPMCOUNTER13, CSR_HPMCOUNTER14, CSR_HPMCOUNTER15,
      CSR_HPMCOUNTER16, CSR_HPMCOUNTER17, CSR_HPMCOUNTER18, CSR_HPMCOUNTER19,
      CSR_HPMCOUNTER20, CSR_HPMCOUNTER21, CSR_HPMCOUNTER22, CSR_HPMCOUNTER23,
      CSR_HPMCOUNTER24, CSR_HPMCOUNTER25, CSR_HPMCOUNTER26, CSR_HPMCOUNTER27,
      CSR_HPMCOUNTER28, CSR_HPMCOUNTER29, CSR_HPMCOUNTER30, CSR_HPMCOUNTER31:
      csr_rdata_int = mhpmcounter_q[csr_addr_i[4:0]][31:0];  // Read lower MHPM counter

      // Read upper MHPM counter
      CSR_MCYCLEH, CSR_MINSTRETH, CSR_MHPMCOUNTER3H, CSR_MHPMCOUNTER4H,  CSR_MHPMCOUNTER5H,
      CSR_MHPMCOUNTER6H,  CSR_MHPMCOUNTER7H, CSR_MHPMCOUNTER8H,  CSR_MHPMCOUNTER9H,
      CSR_MHPMCOUNTER10H, CSR_MHPMCOUNTER11H, CSR_MHPMCOUNTER12H, CSR_MHPMCOUNTER13H,
      CSR_MHPMCOUNTER14H, CSR_MHPMCOUNTER15H, CSR_MHPMCOUNTER16H, CSR_MHPMCOUNTER17H,
      CSR_MHPMCOUNTER18H, CSR_MHPMCOUNTER19H, CSR_MHPMCOUNTER20H, CSR_MHPMCOUNTER21H,
      CSR_MHPMCOUNTER22H, CSR_MHPMCOUNTER23H, CSR_MHPMCOUNTER24H, CSR_MHPMCOUNTER25H,
      CSR_MHPMCOUNTER26H, CSR_MHPMCOUNTER27H, CSR_MHPMCOUNTER28H, CSR_MHPMCOUNTER29H,
      CSR_MHPMCOUNTER30H, CSR_MHPMCOUNTER31H, CSR_CYCLEH, CSR_INSTRETH, CSR_HPMCOUNTER3H,
      CSR_HPMCOUNTER4H,  CSR_HPMCOUNTER5H,  CSR_HPMCOUNTER6H,  CSR_HPMCOUNTER7H, CSR_HPMCOUNTER8H,
      CSR_HPMCOUNTER9H,  CSR_HPMCOUNTER10H, CSR_HPMCOUNTER11H, CSR_HPMCOUNTER12H,
      CSR_HPMCOUNTER13H, CSR_HPMCOUNTER14H, CSR_HPMCOUNTER15H, CSR_HPMCOUNTER16H,
      CSR_HPMCOUNTER17H, CSR_HPMCOUNTER18H, CSR_HPMCOUNTER19H, CSR_HPMCOUNTER20H,
      CSR_HPMCOUNTER21H, CSR_HPMCOUNTER22H, CSR_MHPMCOUNTER23H, CSR_MHPMCOUNTER24H,
      CSR_MHPMCOUNTER25H, CSR_MHPMCOUNTER26H, CSR_MHPMCOUNTER27H, CSR_MHPMCOUNTER28H,
      CSR_MHPMCOUNTER29H, CSR_MHPMCOUNTER30H, CSR_MHPMCOUNTER31H:
      csr_rdata_int = (MHPMCOUNTER_WIDTH == 64) ? mhpmcounter_q[csr_addr_i[4:0]][63:32] : '0;

      CSR_MCOUNTINHIBIT: csr_rdata_int = mcountinhibit_q;  // Read MCOUNTINHIBIT

      CSR_MHPMEVENT3,
      CSR_MHPMEVENT4,  CSR_MHPMEVENT5,  CSR_MHPMEVENT6,  CSR_MHPMEVENT7,
      CSR_MHPMEVENT8,  CSR_MHPMEVENT9,  CSR_MHPMEVENT10, CSR_MHPMEVENT11,
      CSR_MHPMEVENT12, CSR_MHPMEVENT13, CSR_MHPMEVENT14, CSR_MHPMEVENT15,
      CSR_MHPMEVENT16, CSR_MHPMEVENT17, CSR_MHPMEVENT18, CSR_MHPMEVENT19,
      CSR_MHPMEVENT20, CSR_MHPMEVENT21, CSR_MHPMEVENT22, CSR_MHPMEVENT23,
      CSR_MHPMEVENT24, CSR_MHPMEVENT25, CSR_MHPMEVENT26, CSR_MHPMEVENT27,
      CSR_MHPMEVENT28, CSR_MHPMEVENT29, CSR_MHPMEVENT30, CSR_MHPMEVENT31:
      csr_rdata_int = mhpmevent_q[csr_addr_i[4:0]];  // Read MHPM event
      default: csr_rdata_int = '0;  // Default read value
    endcase
  end

  always_comb begin  // Logic for calculating next state of CSRs
    fflags_n = fflags_q;
    frm_n = frm_q;
    mstatus_fs_n = mstatus_fs_q;
    fcsr_update = 1'b0;
    mscratch_n = mscratch_q;
    mepc_n = mepc_q;
    uepc_n = 'b0;
    depc_n = depc_q;
    dcsr_n = dcsr_q;
    dscratch0_n = dscratch0_q;
    dscratch1_n = dscratch1_q;

    mstatus_we_int = 1'b0;
    mstatus_n = mstatus_q;
    mcause_n = mcause_q;
    ucause_n = '0;
    exception_pc = pc_id_i;
    priv_lvl_n = priv_lvl_q;
    mtvec_n = csr_mtvec_init_i ? mtvec_addr_i[31:8] : mtvec_q;  // Initialize MTVEC if enabled
    utvec_n = '0;
    pmp_reg_n.pmpaddr = '0;
    pmp_reg_n.pmpcfg_packed = '0;
    pmp_reg_n.pmpcfg = '0;
    pmpaddr_we = '0;
    pmpcfg_we = '0;

    mie_n = mie_q;
    mtvec_mode_n = mtvec_mode_q;
    utvec_mode_n = '0;

    if (csr_we_int) begin
      case (csr_addr_i)  // Update next state based on CSR address

        CSR_FFLAGS:  // Write to FFLAGS
        begin
          fflags_n = csr_wdata_int[C_FFLAG-1:0];
          fcsr_update = 1'b1;
        end

        CSR_FRM:  // Write to FRM
        begin
          frm_n = csr_wdata_int[C_RM-1:0];
          fcsr_update = 1'b1;
        end

        CSR_FCSR:  // Write to FCSR
        begin
          fflags_n = csr_wdata_int[C_FFLAG-1:0];
          frm_n    = csr_wdata_int[C_RM+C_FFLAG-1:C_FFLAG];
          fcsr_update = 1'b1;
        end

        CSR_MSTATUS:  // Write to MSTATUS
        begin
          mstatus_n = '{
              uie: csr_wdata_int[MstatusUieBit],
              mie: csr_wdata_int[MstatusMieBit],
              upie: csr_wdata_int[MstatusUpieBit],
              mpie: csr_wdata_int[MstatusMpieBit],
              mpp: priv_lvl_t'(csr_wdata_int[MstatusMppBitHigh:MstatusMppBitLow]),
              mprv: csr_wdata_int[MstatusMprvBit]
          };
          mstatus_we_int = 1'b1;
          mstatus_fs_n = fs_t'(csr_wdata_int[MstatusFsBitHigh:MstatusFsBitLow]);
        end

        CSR_MIE:  // Write to MIE
        begin
          mie_n = csr_wdata_int & IRQ_MASK;
        end

        CSR_MTVEC:  // Write to MTVEC
        begin
          mtvec_n      = csr_wdata_int[31:8];
          mtvec_mode_n = {1'b0, csr_wdata_int[0]};
        end

        CSR_MSCRATCH:  // Write to MSCRATCH
        begin
          mscratch_n = csr_wdata_int;
        end

        CSR_MEPC:  // Write to MEPC
        begin
          mepc_n = csr_wdata_int & ~32'd1;
        end

        CSR_MCAUSE: // Write to MCAUSE
        begin
          mcause_n = {csr_wdata_int[31], csr_wdata_int[4:0]};
        end

        CSR_DCSR:  // Write to DCSR
        begin
          dcsr_n.ebreakm   = csr_wdata_int[15];
          dcsr_n.ebreaks   = 1'b0;
          dcsr_n.ebreaku   = 1'b0;
          dcsr_n.stepie    = csr_wdata_int[11];
          dcsr_n.stopcount = 1'b0;
          dcsr_n.stoptime  = 1'b0;
          dcsr_n.mprven    = 1'b0;
          dcsr_n.step      = csr_wdata_int[2];
          dcsr_n.prv       = PRIV_LVL_M;
        end

        CSR_DPC:  // Write to DPC
        begin
          depc_n = csr_wdata_int & ~32'd1;
        end

        CSR_DSCRATCH0:  // Write to DSCRATCH0
        begin
          dscratch0_n = csr_wdata_int;
        end

        CSR_DSCRATCH1:  // Write to DSCRATCH1
        begin
          dscratch1_n = csr_wdata_int;
        end

      endcase
    end

    if (fflags_we_i) begin  // Update FFLAGS if write enable is asserted
      fflags_n = fflags_i | fflags_q;
    end

    if ((fregs_we_i && !(mstatus_we_int && mstatus_fs_n != FS_DIRTY))
        || fflags_we_i || fcsr_update)
    begin
      mstatus_fs_n = FS_DIRTY;  // Mark floating-point state as dirty
    end

    if (csr_save_cause_i) begin  // Save CSRs on exception
      if (csr_save_if_i) exception_pc = pc_if_i;
      else if (csr_save_id_i) exception_pc = pc_id_i;
      else if (csr_save_ex_i) exception_pc = pc_ex_i;

      if (debug_csr_save_i) begin  // Save for debug mode
        dcsr_n.prv   = PRIV_LVL_M;
        dcsr_n.cause = debug_cause_i;
        depc_n       = exception_pc;
      end else begin  // Save for normal exception
        priv_lvl_n     = PRIV_LVL_M;
        mstatus_n.mpie = mstatus_q.mie;
        mstatus_n.mie  = 1'b0;
        mstatus_n.mpp  = PRIV_LVL_M;
        mepc_n         = exception_pc;
        mcause_n       = csr_cause_i;
      end
    end else if (csr_restore_mret_i) begin  // Restore CSRs on MRET
      mstatus_n.mie  = mstatus_q.mpie;
      priv_lvl_n    = PRIV_LVL_M;
      mstatus_n.mpie = 1'b1;
      mstatus_n.mpp  = PRIV_LVL_M;
    end else if (csr_restore_dret_i) begin  // Restore CSRs on DRET
      priv_lvl_n = dcsr_q.prv;
    end

  end

  always_comb begin  // Logic for internal CSR write enable
    csr_wdata_int = csr_wdata_i;
    csr_we_int    = 1'b1;

    case (csr_op_i)
      CSR_OP_WRITE: csr_wdata_int = csr_wdata_i;  // Write operation
      CSR_OP_SET:   csr_wdata_int = csr_wdata_i | csr_rdata_o;  // Set bits operation
      CSR_OP_CLEAR: csr_wdata_int = (~csr_wdata_i) & csr_rdata_o;  // Clear bits operation

      CSR_OP_READ: begin  // Read operation
        csr_wdata_int = csr_wdata_i;
        csr_we_int    = 1'b0; // No write during read
      end
    endcase
  end

  assign csr_rdata_o = csr_rdata_int;  // Output CSR read data

  assign m_irq_enable_o = mstatus_q.mie && !(dcsr_q.step && !dcsr_q.stepie);  // M-mode IRQ enable
  assign u_irq_enable_o = mstatus_q.uie && !(dcsr_q.step && !dcsr_q.stepie);  // U-mode IRQ enable
  assign priv_lvl_o = priv_lvl_q;  // Output current privilege level
  assign sec_lvl_o = priv_lvl_q[0];  // Output security level

  assign fs_off_o = (mstatus_fs_q == FS_OFF ? 1'b1 : 1'b0);  // Output FS off status
  assign frm_o = frm_q;  // Output rounding mode

  assign mtvec_o = mtvec_q;  // Output machine trap vector
  assign utvec_o = utvec_q;  // Output user trap vector
  assign mtvec_mode_o = mtvec_mode_q;  // Output machine trap vector mode
  assign utvec_mode_o = utvec_mode_q;  // Output user trap vector mode

  assign mepc_o = mepc_q;  // Output machine exception PC
  assign uepc_o = uepc_q;  // Output user exception PC

  assign mcounteren_o = '0;  // Output machine counter enable (not fully implemented)

  assign depc_o = depc_q;  // Output debug exception PC

  assign pmp_addr_o = pmp_reg_q.pmpaddr;  // Output PMP addresses
  assign pmp_cfg_o = pmp_reg_q.pmpcfg;  // Output PMP configurations

  assign debug_single_step_o = dcsr_q.step;  // Output debug single step
  assign debug_ebreakm_o = dcsr_q.ebreakm;  // Output debug ebreak in M-mode
  assign debug_ebreaku_o = dcsr_q.ebreaku;  // Output debug ebreak in U-mode

  assign pmp_reg_q = '0;  // Tie off PMP registers for now
  assign uepc_q = '0;  // Tie off user exception PC for now
  assign ucause_q = '0;  // Tie off user exception cause for now
  assign utvec_q = '0;  // Tie off user trap vector for now
  assign utvec_mode_q = '0;  // Tie off user trap vector mode for now
  assign priv_lvl_q = PRIV_LVL_M;  // Default privilege level

  always_ff @(posedge clk, negedge rst_n) begin  // Sequential logic for CSR registers
    if (rst_n == 1'b0) begin
      frm_q <= '0;  // Reset rounding mode
      fflags_q <= '0;  // Reset floating-point flags
      mstatus_fs_q <= FS_CLEAN;  // Reset floating-point status
      mstatus_q <= '{  // Reset machine status register
          uie: 1'b0,
          mie: 1'b0,
          upie: 1'b0,
          mpie: 1'b0,
          mpp: PRIV_LVL_M,
          mprv: 1'b0
      };
      mepc_q <= '0;  // Reset machine exception PC
      mcause_q <= '0;  // Reset machine exception cause

      depc_q <= '0;  // Reset debug exception PC
      dcsr_q <= '{
          xdebugver: XDEBUGVER_STD,
          cause: DBG_CAUSE_NONE,
          prv: PRIV_LVL_M,
          default: '0
      };  // Reset DCSR
      dscratch0_q <= '0;  // Reset debug scratch register 0
      dscratch1_q <= '0;  // Reset debug scratch register 1
      mscratch_q <= '0;  // Reset machine scratch register
      mie_q <= '0;  // Reset machine interrupt enable
      mtvec_q <= '0;  // Reset machine trap vector
      mtvec_mode_q <= MtvecMode;  // Reset machine trap vector mode
    end else begin
      frm_q <= frm_n;  // Update rounding mode
      fflags_q <= fflags_n;  // Update floating-point flags
      mstatus_fs_q <= mstatus_fs_n;  // Update floating-point status
      mstatus_q <= '{  // Update machine status register
          uie: 1'b0,
          mie: mstatus_n.mie,
          upie: 1'b0,
          mpie: mstatus_n.mpie,
          mpp: PRIV_LVL_M,
          mprv: 1'b0
      };
      mepc_q <= mepc_n;  // Update machine exception PC
      mcause_q <= mcause_n;  // Update machine exception cause
      depc_q <= depc_n;  // Update debug exception PC
      dcsr_q <= dcsr_n;  // Update DCSR
      dscratch0_q <= dscratch0_n;  // Update debug scratch register 0
      dscratch1_q <= dscratch1_n;  // Update debug scratch register 1
      mscratch_q <= mscratch_n;  // Update machine scratch register
      mie_q <= mie_n;  // Update machine interrupt enable
      mtvec_q <= mtvec_n;  // Update machine trap vector
      mtvec_mode_q <= mtvec_mode_n;  // Update machine trap vector mode
    end
  end

  if (DEBUG_TRIGGER_EN) begin : gen_trigger_regs  // Generate debug trigger registers

    logic        tmatch_control_exec_q;  // Queued trigger match control
    logic [31:0] tmatch_value_q;  // Queued trigger match value

    logic        tmatch_control_we;  // Write enable for trigger match control
    logic        tmatch_value_we;  // Write enable for trigger match value

    // Write enable
    assign tmatch_control_we = csr_we_int & debug_mode_i & (csr_addr_i == CSR_TDATA1);
    // Write enable
    assign tmatch_value_we   = csr_we_int & debug_mode_i & (csr_addr_i == CSR_TDATA2);

    always_ff @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
        tmatch_control_exec_q <= 'b0;  // Reset trigger control
        tmatch_value_q        <= 'b0;  // Reset trigger value
      end else begin
        if (tmatch_control_we) tmatch_control_exec_q <= csr_wdata_int[2];  // Update control
        if (tmatch_value_we) tmatch_value_q <= csr_wdata_int[31:0];  // Update value
      end
    end

    assign tinfo_types = 1 << TTYPE_MCONTROL;  // Trigger type is MCONTROL

    assign tmatch_control_rdata = {  // Read data for trigger control
          TTYPE_MCONTROL,
          1'b1,
          6'h00,
          1'b0,
          1'b0,
          1'b0,
          2'b00,
          4'h1,
          1'b0,
          4'h0,
          1'b1,
          1'b0,
          1'b0,
          1'b0,
          tmatch_control_exec_q,
          1'b0,
          1'b0
        };

    assign tmatch_value_rdata = tmatch_value_q;  // Read data for trigger value

    // Trigger match
    assign trigger_match_o = tmatch_control_exec_q & (pc_id_i[31:0] == tmatch_value_q[31:0]);
  end else begin : gen_no_trigger_regs  // Generate no trigger registers
    assign tinfo_types          = 'b0;
    assign tmatch_control_rdata = 'b0;
    assign tmatch_value_rdata   = 'b0;
    assign trigger_match_o      = 'b0;
  end

  assign hpm_events[0]  = 1'b1;  // Cycle counter event
  assign hpm_events[1]  = mhpmevent_minstret_i;  // Instruction retired event
  assign hpm_events[2]  = mhpmevent_ld_stall_i;  // Load stall event
  assign hpm_events[3]  = mhpmevent_jr_stall_i;  // Jump register stall event
  assign hpm_events[4]  = mhpmevent_imiss_i;  // Instruction cache miss event
  assign hpm_events[5]  = mhpmevent_load_i;  // Load instruction event
  assign hpm_events[6]  = mhpmevent_store_i;  // Store instruction event
  assign hpm_events[7]  = mhpmevent_jump_i;  // Jump instruction event
  assign hpm_events[8]  = mhpmevent_branch_i;  // Branch instruction event
  assign hpm_events[9]  = mhpmevent_branch_taken_i;  // Branch taken event
  assign hpm_events[10] = mhpmevent_compressed_i;  // Compressed instruction event
  assign hpm_events[11] = 1'b0;
  assign hpm_events[12] = apu_typeconflict_i && !apu_dep_i;  // APU type conflict
  assign hpm_events[13] = apu_contention_i;  // APU contention
  assign hpm_events[14] = apu_dep_i && !apu_contention_i;  // APU dependency
  assign hpm_events[15] = apu_wb_i;  // APU writeback

  logic mcounteren_we;  // Write enable for MCOUNTEREN
  logic mcountinhibit_we;  // Write enable for MCOUNTINHIBIT
  logic mhpmevent_we;  // Write enable for MHPMEVENT

  assign mcounteren_we = csr_we_int & (csr_addr_i == CSR_MCOUNTEREN);  // Write enable
  assign mcountinhibit_we = csr_we_int & (csr_addr_i == CSR_MCOUNTINHIBIT);  // Write enable
  assign mhpmevent_we = csr_we_int & ((csr_addr_i == CSR_MHPMEVENT3) ||  // Write enable
      (csr_addr_i == CSR_MHPMEVENT4  ) ||
                                      (csr_addr_i == CSR_MHPMEVENT5  ) ||
                                      (csr_addr_i == CSR_MHPMEVENT6  ) ||
                                      (csr_addr_i == CSR_MHPMEVENT7  ) ||
                                      (csr_addr_i == CSR_MHPMEVENT8  ) ||
                                      (csr_addr_i == CSR_MHPMEVENT9  ) ||
                                      (csr_addr_i == CSR_MHPMEVENT10 ) ||
                                      (csr_addr_i == CSR_MHPMEVENT11 ) ||
                                      (csr_addr_i == CSR_MHPMEVENT12 ) ||
                                      (csr_addr_i == CSR_MHPMEVENT13 ) ||
                                      (csr_addr_i == CSR_MHPMEVENT14 ) ||
                                      (csr_addr_i == CSR_MHPMEVENT15 ) ||
                                      (csr_addr_i == CSR_MHPMEVENT16 ) ||
                                      (csr_addr_i == CSR_MHPMEVENT17 ) ||
                                      (csr_addr_i == CSR_MHPMEVENT18 ) ||
                                      (csr_addr_i == CSR_MHPMEVENT19 ) ||
                                      (csr_addr_i == CSR_MHPMEVENT20 ) ||
                                      (csr_addr_i == CSR_MHPMEVENT21 ) ||
                                      (csr_addr_i == CSR_MHPMEVENT22 ) ||
                                      (csr_addr_i == CSR_MHPMEVENT23 ) ||
                                      (csr_addr_i == CSR_MHPMEVENT24 ) ||
                                      (csr_addr_i == CSR_MHPMEVENT25 ) ||
                                      (csr_addr_i == CSR_MHPMEVENT26 ) ||
                                      (csr_addr_i == CSR_MHPMEVENT27 ) ||
                                      (csr_addr_i == CSR_MHPMEVENT28 ) ||
                                      (csr_addr_i == CSR_MHPMEVENT29 ) ||
                                      (csr_addr_i == CSR_MHPMEVENT30 ) ||
                                      (csr_addr_i == CSR_MHPMEVENT31 ) );

  for (genvar incr_gidx = 0; incr_gidx < 32; incr_gidx++) begin : gen_mhpmcounter_increment
    assign mhpmcounter_increment[incr_gidx] = mhpmcounter_q[incr_gidx] + 1;  // Increment logic
  end

  always_comb begin  // Next state logic for MCOUNTEREN, MCOUNTINHIBIT, MHPMEVENT
    mcounteren_n    = mcounteren_q;
    mcountinhibit_n = mcountinhibit_q;
    mhpmevent_n     = mhpmevent_q;
    if (mcountinhibit_we) mcountinhibit_n = csr_wdata_int;  // Update MCOUNTINHIBIT
    if (mhpmevent_we) mhpmevent_n[csr_addr_i[4:0]] = csr_wdata_int;  // Update MHPMEVENT
  end

  for (genvar wcnt_gidx = 0; wcnt_gidx < 32; wcnt_gidx++) begin : gen_mhpmcounter_write

    // Write lower
    assign mhpmcounter_write_lower[wcnt_gidx] = csr_we_int &&
           (csr_addr_i == (CSR_MCYCLE + wcnt_gidx));

    // Write upper
    assign mhpmcounter_write_upper[wcnt_gidx] = !mhpmcounter_write_lower[wcnt_gidx] &&
           csr_we_int && (csr_addr_i == (CSR_MCYCLEH + wcnt_gidx)) && (MHPMCOUNTER_WIDTH == 64);

    if (wcnt_gidx == 0) begin : gen_mhpmcounter_mcycle  // Increment for MCYCLE

      assign mhpmcounter_write_increment[wcnt_gidx] = !mhpmcounter_write_lower[wcnt_gidx] &&
             !mhpmcounter_write_upper[wcnt_gidx] &&
             !mcountinhibit_q[wcnt_gidx];
    end else if (wcnt_gidx == 2) begin : gen_mhpmcounter_minstret  // Increment for MINSTRET

      assign mhpmcounter_write_increment[wcnt_gidx] = !mhpmcounter_write_lower[wcnt_gidx] &&
             !mhpmcounter_write_upper[wcnt_gidx] &&
             !mcountinhibit_q[wcnt_gidx] &&
             hpm_events[1];
      // Increment for MHPM counters
    end else if ((wcnt_gidx > 2) && (wcnt_gidx < (4))) begin : gen_mhpmcounter

      assign mhpmcounter_write_increment[wcnt_gidx] = !mhpmcounter_write_lower[wcnt_gidx] &&
             !mhpmcounter_write_upper[wcnt_gidx] && !mcountinhibit_q[wcnt_gidx] &&
             |(hpm_events & mhpmevent_q[wcnt_gidx][HmpEvents-1:0]);
    end else begin : gen_mhpmcounter_not_implemented  // Not implemented
      assign mhpmcounter_write_increment[wcnt_gidx] = 1'b0;
    end
  end

  for (genvar cnt_gidx = 0; cnt_gidx < 32; cnt_gidx++) begin : gen_mhpmcounter

    if ((cnt_gidx == 1) || (cnt_gidx >= (4))) begin : gen_non_implemented  // Not implemented
      assign mhpmcounter_q[cnt_gidx] = 'b0;
    end else begin : gen_implemented  // Implemented counters
      always_ff @(posedge clk, negedge rst_n)
        if (!rst_n) begin
          mhpmcounter_q[cnt_gidx] <= 'b0;
        end else begin
          if (mhpmcounter_write_lower[cnt_gidx]) begin
            mhpmcounter_q[cnt_gidx][31:0] <= csr_wdata_int;
          end else if (mhpmcounter_write_upper[cnt_gidx]) begin
            mhpmcounter_q[cnt_gidx][63:32] <= csr_wdata_int;
          end else if (mhpmcounter_write_increment[cnt_gidx]) begin
            mhpmcounter_q[cnt_gidx] <= mhpmcounter_increment[cnt_gidx];
          end
        end
    end
  end

  for (genvar evt_gidx = 0; evt_gidx < 32; evt_gidx++) begin : gen_mhpmevent

    if ((evt_gidx < 3) || (evt_gidx >= (4))) begin : gen_non_implemented  // Not implemented
      assign mhpmevent_q[evt_gidx] = 'b0;
    end else begin : gen_implemented  // Implemented events
      if (HmpEvents < 32) begin : gen_tie_off  // Tie off unused bits
        assign mhpmevent_q[evt_gidx][31:HmpEvents] = 'b0;
      end
      always_ff @(posedge clk, negedge rst_n)
        if (!rst_n) mhpmevent_q[evt_gidx][HmpEvents-1:0] <= 'b0;
        else mhpmevent_q[evt_gidx][HmpEvents-1:0] <= mhpmevent_n[evt_gidx][HmpEvents-1:0];
    end
  end

  for (genvar en_gidx = 0; en_gidx < 32; en_gidx++) begin : gen_mcounteren  // Tie off MCOUNTEREN
    assign mcounteren_q[en_gidx] = 'b0;
  end

  for (genvar inh_gidx = 0; inh_gidx < 32; inh_gidx++) begin : gen_mcountinhibit
    if ((inh_gidx == 1) || (inh_gidx >= (4))) begin : gen_non_implemented  // Not implemented
      assign mcountinhibit_q[inh_gidx] = 'b0;
    end else begin : gen_implemented  // Implemented inhibit bits
      always_ff @(posedge clk, negedge rst_n)
        if (!rst_n) mcountinhibit_q[inh_gidx] <= 'b1;
        else mcountinhibit_q[inh_gidx] <= mcountinhibit_n[inh_gidx];
    end
  end

endmodule
