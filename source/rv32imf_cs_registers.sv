module rv32imf_cs_registers
  import rv32imf_pkg::*;
#(
    parameter int N_HWLP           = 2,
    parameter int N_PMP_ENTRIES    = 16,
    parameter int DEBUG_TRIGGER_EN = 1
) (

    input logic clk,
    input logic rst_n,


    input  logic [31:0] hart_id_i,
    output logic [23:0] mtvec_o,
    output logic [23:0] utvec_o,
    output logic [ 1:0] mtvec_mode_o,
    output logic [ 1:0] utvec_mode_o,


    input logic [31:0] mtvec_addr_i,
    input logic        csr_mtvec_init_i,


    input  csr_num_e           csr_addr_i,
    input  logic        [31:0] csr_wdata_i,
    input  csr_opcode_e        csr_op_i,
    output logic        [31:0] csr_rdata_o,

    output logic               fs_off_o,
    output logic [        2:0] frm_o,
    input  logic [C_FFLAG-1:0] fflags_i,
    input  logic               fflags_we_i,
    input  logic               fregs_we_i,


    output logic [31:0] mie_bypass_o,
    input  logic [31:0] mip_i,
    output logic        m_irq_enable_o,
    output logic        u_irq_enable_o,


    input  logic        csr_irq_sec_i,
    output logic        sec_lvl_o,
    output logic [31:0] mepc_o,
    output logic [31:0] uepc_o,

    output logic [31:0] mcounteren_o,


    input  logic        debug_mode_i,
    input  logic [ 2:0] debug_cause_i,
    input  logic        debug_csr_save_i,
    output logic [31:0] depc_o,
    output logic        debug_single_step_o,
    output logic        debug_ebreakm_o,
    output logic        debug_ebreaku_o,
    output logic        trigger_match_o,


    output logic [N_PMP_ENTRIES-1:0][31:0] pmp_addr_o,
    output logic [N_PMP_ENTRIES-1:0][ 7:0] pmp_cfg_o,

    output priv_lvl_t priv_lvl_o,

    input logic [31:0] pc_if_i,
    input logic [31:0] pc_id_i,
    input logic [31:0] pc_ex_i,

    input logic csr_save_if_i,
    input logic csr_save_id_i,
    input logic csr_save_ex_i,

    input logic csr_restore_mret_i,
    input logic csr_restore_uret_i,

    input logic csr_restore_dret_i,

    input logic [5:0] csr_cause_i,

    input logic csr_save_cause_i,

    input logic [N_HWLP-1:0][31:0] hwlp_start_i,
    input logic [N_HWLP-1:0][31:0] hwlp_end_i,
    input logic [N_HWLP-1:0][31:0] hwlp_cnt_i,


    input logic mhpmevent_minstret_i,
    input logic mhpmevent_load_i,
    input logic mhpmevent_store_i,
    input logic mhpmevent_jump_i,
    input logic mhpmevent_branch_i,
    input logic mhpmevent_branch_taken_i,
    input logic mhpmevent_compressed_i,
    input logic mhpmevent_jr_stall_i,
    input logic mhpmevent_imiss_i,
    input logic mhpmevent_ld_stall_i,
    input logic mhpmevent_pipe_stall_i,
    input logic apu_typeconflict_i,
    input logic apu_contention_i,
    input logic apu_dep_i,
    input logic apu_wb_i
);

  localparam NUM_HPM_EVENTS = 16;

  localparam MTVEC_MODE = 2'b01;

  localparam MAX_N_PMP_ENTRIES = 16;
  localparam MAX_N_PMP_CFG = 4;
  localparam N_PMP_CFG = N_PMP_ENTRIES % 4 == 0 ? N_PMP_ENTRIES / 4 : N_PMP_ENTRIES / 4 + 1;

  localparam MSTATUS_UIE_BIT = 0;
  localparam MSTATUS_SIE_BIT = 1;
  localparam MSTATUS_MIE_BIT = 3;
  localparam MSTATUS_UPIE_BIT = 4;
  localparam MSTATUS_SPIE_BIT = 5;
  localparam MSTATUS_MPIE_BIT = 7;
  localparam MSTATUS_SPP_BIT = 8;
  localparam MSTATUS_MPP_BIT_LOW = 11;
  localparam MSTATUS_MPP_BIT_HIGH = 12;
  localparam MSTATUS_FS_BIT_LOW = 13;
  localparam MSTATUS_FS_BIT_HIGH = 14;
  localparam MSTATUS_MPRV_BIT = 17;
  localparam MSTATUS_SD_BIT = 31;


  localparam logic [1:0] MXL = 2'd1;
  localparam logic [31:0] MISA_VALUE = (32'(0) << 0)
  | (1 << 2)
  | (0 << 3)
  | (0 << 4)
  | (32'(1) << 5)
  | (1 << 8)
  | (1 << 12)
  | (0 << 13)
  | (0 << 18)
  | (32'(0) << 20)
  | (32'(MXL) << 30);

  typedef struct packed {
    logic [MAX_N_PMP_ENTRIES-1:0][31:0] pmpaddr;
    logic [MAX_N_PMP_CFG-1:0][31:0] pmpcfg_packed;
    logic [MAX_N_PMP_ENTRIES-1:0][7:0] pmpcfg;
  } pmp_t;


  logic [31:0] csr_wdata_int;
  logic [31:0] csr_rdata_int;
  logic        csr_we_int;


  logic [C_RM-1:0] frm_q, frm_n;
  logic [C_FFLAG-1:0] fflags_q, fflags_n;
  logic fcsr_update;


  logic [31:0] mepc_q, mepc_n;
  logic [31:0] uepc_q, uepc_n;

  logic [31:0] tmatch_control_rdata;
  logic [31:0] tmatch_value_rdata;
  logic [15:0] tinfo_types;

  dcsr_t dcsr_q, dcsr_n;
  logic [31:0] depc_q, depc_n;
  logic [31:0] dscratch0_q, dscratch0_n;
  logic [31:0] dscratch1_q, dscratch1_n;
  logic [31:0] mscratch_q, mscratch_n;

  logic [31:0] exception_pc;
  status_t mstatus_q, mstatus_n;
  logic mstatus_we_int;
  fs_t mstatus_fs_q, mstatus_fs_n;
  logic [5:0] mcause_q, mcause_n;
  logic [5:0] ucause_q, ucause_n;
  logic [23:0] mtvec_n, mtvec_q;
  logic [23:0] utvec_n, utvec_q;
  logic [1:0] mtvec_mode_n, mtvec_mode_q;
  logic [1:0] utvec_mode_n, utvec_mode_q;

  logic [31:0] mip;
  logic [31:0] mie_q, mie_n;

  logic [31:0] csr_mie_wdata;
  logic        csr_mie_we;

  logic        is_irq;
  priv_lvl_t priv_lvl_n, priv_lvl_q;
  pmp_t pmp_reg_q, pmp_reg_n;

  logic [MAX_N_PMP_ENTRIES-1:0]                        pmpaddr_we;
  logic [MAX_N_PMP_ENTRIES-1:0]                        pmpcfg_we;


  logic [                 31:0][MHPMCOUNTER_WIDTH-1:0] mhpmcounter_q;
  logic [31:0][31:0] mhpmevent_q, mhpmevent_n;
  logic [31:0] mcounteren_q, mcounteren_n;
  logic [31:0] mcountinhibit_q, mcountinhibit_n;
  logic [NUM_HPM_EVENTS-1:0] hpm_events;
  logic [31:0][MHPMCOUNTER_WIDTH-1:0] mhpmcounter_increment;
  logic [31:0] mhpmcounter_write_lower;
  logic [31:0] mhpmcounter_write_upper;
  logic [31:0] mhpmcounter_write_increment;

  assign is_irq = csr_cause_i[5];


  assign mip = mip_i;





  always_comb begin
    csr_mie_wdata = csr_wdata_i;
    csr_mie_we    = 1'b1;

    case (csr_op_i)
      CSR_OP_WRITE: csr_mie_wdata = csr_wdata_i;
      CSR_OP_SET:   csr_mie_wdata = csr_wdata_i | mie_q;
      CSR_OP_CLEAR: csr_mie_wdata = (~csr_wdata_i) & mie_q;
      CSR_OP_READ: begin
        csr_mie_wdata = csr_wdata_i;
        csr_mie_we    = 1'b0;
      end
    endcase
  end

  assign mie_bypass_o = ((csr_addr_i == CSR_MIE) && csr_mie_we) ? csr_mie_wdata & IRQ_MASK : mie_q;













  genvar j;

  always_comb begin

    case (csr_addr_i)

      CSR_FFLAGS: csr_rdata_int = {27'b0, fflags_q};
      CSR_FRM: csr_rdata_int = {29'b0, frm_q};
      CSR_FCSR: csr_rdata_int = {24'b0, frm_q, fflags_q};

      CSR_MSTATUS:
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

      CSR_MISA: csr_rdata_int = MISA_VALUE;

      CSR_MIE: begin
        csr_rdata_int = mie_q;
      end


      CSR_MTVEC: csr_rdata_int = {mtvec_q, 6'h0, mtvec_mode_q};

      CSR_MSCRATCH: csr_rdata_int = mscratch_q;

      CSR_MEPC: csr_rdata_int = mepc_q;

      CSR_MCAUSE: csr_rdata_int = {mcause_q[5], 26'b0, mcause_q[4:0]};

      CSR_MIP: begin
        csr_rdata_int = mip;
      end

      CSR_MHARTID: csr_rdata_int = hart_id_i;


      CSR_MVENDORID: csr_rdata_int = {MVENDORID_BANK, MVENDORID_OFFSET};


      CSR_MARCHID: csr_rdata_int = MARCHID;


      CSR_MIMPID: begin
        csr_rdata_int = 32'h1;
      end


      CSR_MTVAL: csr_rdata_int = 'b0;

      CSR_TSELECT, CSR_TDATA3, CSR_MCONTEXT, CSR_SCONTEXT: csr_rdata_int = 'b0;
      CSR_TDATA1: csr_rdata_int = tmatch_control_rdata;
      CSR_TDATA2: csr_rdata_int = tmatch_value_rdata;
      CSR_TINFO: csr_rdata_int = tinfo_types;

      CSR_DCSR: csr_rdata_int = dcsr_q;
      CSR_DPC: csr_rdata_int = depc_q;
      CSR_DSCRATCH0: csr_rdata_int = dscratch0_q;
      CSR_DSCRATCH1: csr_rdata_int = dscratch1_q;


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
      csr_rdata_int = mhpmcounter_q[csr_addr_i[4:0]][31:0];

      CSR_MCYCLEH,
      CSR_MINSTRETH,
      CSR_MHPMCOUNTER3H,
      CSR_MHPMCOUNTER4H,  CSR_MHPMCOUNTER5H,  CSR_MHPMCOUNTER6H,  CSR_MHPMCOUNTER7H,
      CSR_MHPMCOUNTER8H,  CSR_MHPMCOUNTER9H,  CSR_MHPMCOUNTER10H, CSR_MHPMCOUNTER11H,
      CSR_MHPMCOUNTER12H, CSR_MHPMCOUNTER13H, CSR_MHPMCOUNTER14H, CSR_MHPMCOUNTER15H,
      CSR_MHPMCOUNTER16H, CSR_MHPMCOUNTER17H, CSR_MHPMCOUNTER18H, CSR_MHPMCOUNTER19H,
      CSR_MHPMCOUNTER20H, CSR_MHPMCOUNTER21H, CSR_MHPMCOUNTER22H, CSR_MHPMCOUNTER23H,
      CSR_MHPMCOUNTER24H, CSR_MHPMCOUNTER25H, CSR_MHPMCOUNTER26H, CSR_MHPMCOUNTER27H,
      CSR_MHPMCOUNTER28H, CSR_MHPMCOUNTER29H, CSR_MHPMCOUNTER30H, CSR_MHPMCOUNTER31H,
      CSR_CYCLEH,
      CSR_INSTRETH,
      CSR_HPMCOUNTER3H,
      CSR_HPMCOUNTER4H,  CSR_HPMCOUNTER5H,  CSR_HPMCOUNTER6H,  CSR_HPMCOUNTER7H,
      CSR_HPMCOUNTER8H,  CSR_HPMCOUNTER9H,  CSR_HPMCOUNTER10H, CSR_HPMCOUNTER11H,
      CSR_HPMCOUNTER12H, CSR_HPMCOUNTER13H, CSR_HPMCOUNTER14H, CSR_HPMCOUNTER15H,
      CSR_HPMCOUNTER16H, CSR_HPMCOUNTER17H, CSR_HPMCOUNTER18H, CSR_HPMCOUNTER19H,
      CSR_HPMCOUNTER20H, CSR_HPMCOUNTER21H, CSR_HPMCOUNTER22H, CSR_HPMCOUNTER23H,
      CSR_HPMCOUNTER24H, CSR_HPMCOUNTER25H, CSR_HPMCOUNTER26H, CSR_HPMCOUNTER27H,
      CSR_HPMCOUNTER28H, CSR_HPMCOUNTER29H, CSR_HPMCOUNTER30H, CSR_HPMCOUNTER31H:
      csr_rdata_int = (MHPMCOUNTER_WIDTH == 64) ? mhpmcounter_q[csr_addr_i[4:0]][63:32] : '0;

      CSR_MCOUNTINHIBIT: csr_rdata_int = mcountinhibit_q;

      CSR_MHPMEVENT3,
      CSR_MHPMEVENT4,  CSR_MHPMEVENT5,  CSR_MHPMEVENT6,  CSR_MHPMEVENT7,
      CSR_MHPMEVENT8,  CSR_MHPMEVENT9,  CSR_MHPMEVENT10, CSR_MHPMEVENT11,
      CSR_MHPMEVENT12, CSR_MHPMEVENT13, CSR_MHPMEVENT14, CSR_MHPMEVENT15,
      CSR_MHPMEVENT16, CSR_MHPMEVENT17, CSR_MHPMEVENT18, CSR_MHPMEVENT19,
      CSR_MHPMEVENT20, CSR_MHPMEVENT21, CSR_MHPMEVENT22, CSR_MHPMEVENT23,
      CSR_MHPMEVENT24, CSR_MHPMEVENT25, CSR_MHPMEVENT26, CSR_MHPMEVENT27,
      CSR_MHPMEVENT28, CSR_MHPMEVENT29, CSR_MHPMEVENT30, CSR_MHPMEVENT31:
      csr_rdata_int = mhpmevent_q[csr_addr_i[4:0]];


      CSR_LPSTART0: csr_rdata_int = '0;
      CSR_LPEND0:   csr_rdata_int = '0;
      CSR_LPCOUNT0: csr_rdata_int = '0;
      CSR_LPSTART1: csr_rdata_int = '0;
      CSR_LPEND1:   csr_rdata_int = '0;
      CSR_LPCOUNT1: csr_rdata_int = '0;

      CSR_UHARTID: csr_rdata_int = '0;

      CSR_PRIVLV: csr_rdata_int = '0;

      CSR_ZFINX: csr_rdata_int = '0;
      default:   csr_rdata_int = '0;
    endcase
  end

  always_comb begin
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
    mtvec_n = csr_mtvec_init_i ? mtvec_addr_i[31:8] : mtvec_q;
    utvec_n = '0;
    pmp_reg_n.pmpaddr = '0;
    pmp_reg_n.pmpcfg_packed = '0;
    pmp_reg_n.pmpcfg = '0;
    pmpaddr_we = '0;
    pmpcfg_we = '0;

    mie_n = mie_q;
    mtvec_mode_n = mtvec_mode_q;
    utvec_mode_n = '0;

    case (csr_addr_i)

      CSR_FFLAGS:
      if (csr_we_int) begin
        fflags_n = csr_wdata_int[C_FFLAG-1:0];
        fcsr_update = 1'b1;
      end
      CSR_FRM:
      if (csr_we_int) begin
        frm_n = csr_wdata_int[C_RM-1:0];
        fcsr_update = 1'b1;
      end
      CSR_FCSR:
      if (csr_we_int) begin
        fflags_n = csr_wdata_int[C_FFLAG-1:0];
        frm_n    = csr_wdata_int[C_RM+C_FFLAG-1:C_FFLAG];
        fcsr_update = 1'b1;
      end


      CSR_MSTATUS:
      if (csr_we_int) begin
        mstatus_n = '{
            uie: csr_wdata_int[MSTATUS_UIE_BIT],
            mie: csr_wdata_int[MSTATUS_MIE_BIT],
            upie: csr_wdata_int[MSTATUS_UPIE_BIT],
            mpie: csr_wdata_int[MSTATUS_MPIE_BIT],
            mpp: priv_lvl_t'(csr_wdata_int[MSTATUS_MPP_BIT_HIGH:MSTATUS_MPP_BIT_LOW]),
            mprv: csr_wdata_int[MSTATUS_MPRV_BIT]
        };
        mstatus_we_int = 1'b1;
        mstatus_fs_n = fs_t'(csr_wdata_int[MSTATUS_FS_BIT_HIGH:MSTATUS_FS_BIT_LOW]);
      end

      CSR_MIE:
      if (csr_we_int) begin
        mie_n = csr_wdata_int & IRQ_MASK;
      end

      CSR_MTVEC:
      if (csr_we_int) begin
        mtvec_n      = csr_wdata_int[31:8];
        mtvec_mode_n = {1'b0, csr_wdata_int[0]};
      end

      CSR_MSCRATCH:
      if (csr_we_int) begin
        mscratch_n = csr_wdata_int;
      end

      CSR_MEPC:
      if (csr_we_int) begin
        mepc_n = csr_wdata_int & ~32'b1;
      end

      CSR_MCAUSE: if (csr_we_int) mcause_n = {csr_wdata_int[31], csr_wdata_int[4:0]};

      CSR_DCSR:
      if (csr_we_int) begin






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

      CSR_DPC:
      if (csr_we_int) begin
        depc_n = csr_wdata_int & ~32'b1;
      end

      CSR_DSCRATCH0:
      if (csr_we_int) begin
        dscratch0_n = csr_wdata_int;
      end

      CSR_DSCRATCH1:
      if (csr_we_int) begin
        dscratch1_n = csr_wdata_int;
      end

    endcase

    if (fflags_we_i) begin
      fflags_n = fflags_i | fflags_q;
    end


    if ((fregs_we_i && !(mstatus_we_int && mstatus_fs_n != FS_DIRTY)) || fflags_we_i || fcsr_update) begin
      mstatus_fs_n = FS_DIRTY;
    end


    unique case (1'b1)

      csr_save_cause_i: begin
        unique case (1'b1)
          csr_save_if_i: exception_pc = pc_if_i;
          csr_save_id_i: exception_pc = pc_id_i;
          csr_save_ex_i: exception_pc = pc_ex_i;
          default: ;
        endcase

        if (debug_csr_save_i) begin


          dcsr_n.prv   = PRIV_LVL_M;
          dcsr_n.cause = debug_cause_i;
          depc_n       = exception_pc;
        end else begin
          priv_lvl_n     = PRIV_LVL_M;
          mstatus_n.mpie = mstatus_q.mie;
          mstatus_n.mie  = 1'b0;
          mstatus_n.mpp  = PRIV_LVL_M;
          mepc_n         = exception_pc;
          mcause_n       = csr_cause_i;
        end
      end

      csr_restore_mret_i: begin
        mstatus_n.mie  = mstatus_q.mpie;
        priv_lvl_n     = PRIV_LVL_M;
        mstatus_n.mpie = 1'b1;
        mstatus_n.mpp  = PRIV_LVL_M;
      end

      csr_restore_dret_i: begin

        priv_lvl_n = dcsr_q.prv;
      end

      default: ;
    endcase
  end


  always_comb begin
    csr_wdata_int = csr_wdata_i;
    csr_we_int    = 1'b1;

    case (csr_op_i)
      CSR_OP_WRITE: csr_wdata_int = csr_wdata_i;
      CSR_OP_SET:   csr_wdata_int = csr_wdata_i | csr_rdata_o;
      CSR_OP_CLEAR: csr_wdata_int = (~csr_wdata_i) & csr_rdata_o;

      CSR_OP_READ: begin
        csr_wdata_int = csr_wdata_i;
        csr_we_int    = 1'b0;
      end
    endcase
  end

  assign csr_rdata_o         = csr_rdata_int;


  assign m_irq_enable_o      = mstatus_q.mie && !(dcsr_q.step && !dcsr_q.stepie);
  assign u_irq_enable_o      = mstatus_q.uie && !(dcsr_q.step && !dcsr_q.stepie);
  assign priv_lvl_o          = priv_lvl_q;
  assign sec_lvl_o           = priv_lvl_q[0];


  assign fs_off_o            = (mstatus_fs_q == FS_OFF ? 1'b1 : 1'b0);
  assign frm_o               = frm_q;

  assign mtvec_o             = mtvec_q;
  assign utvec_o             = utvec_q;
  assign mtvec_mode_o        = mtvec_mode_q;
  assign utvec_mode_o        = utvec_mode_q;

  assign mepc_o              = mepc_q;
  assign uepc_o              = uepc_q;

  assign mcounteren_o        = '0;

  assign depc_o              = depc_q;

  assign pmp_addr_o          = pmp_reg_q.pmpaddr;
  assign pmp_cfg_o           = pmp_reg_q.pmpcfg;

  assign debug_single_step_o = dcsr_q.step;
  assign debug_ebreakm_o     = dcsr_q.ebreakm;
  assign debug_ebreaku_o     = dcsr_q.ebreaku;

  assign pmp_reg_q           = '0;
  assign uepc_q              = '0;
  assign ucause_q            = '0;
  assign utvec_q             = '0;
  assign utvec_mode_q        = '0;
  assign priv_lvl_q          = PRIV_LVL_M;


  always_ff @(posedge clk, negedge rst_n) begin
    if (rst_n == 1'b0) begin
      frm_q <= '0;
      fflags_q <= '0;
      mstatus_fs_q <= FS_CLEAN;  // TODO FIX
      mstatus_q <= '{
          uie: 1'b0,
          mie: 1'b0,
          upie: 1'b0,
          mpie: 1'b0,
          mpp: PRIV_LVL_M,
          mprv: 1'b0
      };
      mepc_q <= '0;
      mcause_q <= '0;

      depc_q <= '0;
      dcsr_q <= '{xdebugver: XDEBUGVER_STD, cause: DBG_CAUSE_NONE, prv: PRIV_LVL_M, default: '0};
      dscratch0_q <= '0;
      dscratch1_q <= '0;
      mscratch_q <= '0;
      mie_q <= '0;
      mtvec_q <= '0;
      mtvec_mode_q <= MTVEC_MODE;
    end else begin
      frm_q <= frm_n;
      fflags_q <= fflags_n;
      mstatus_fs_q <= mstatus_fs_n;
      mstatus_q <= '{
          uie: 1'b0,
          mie: mstatus_n.mie,
          upie: 1'b0,
          mpie: mstatus_n.mpie,
          mpp: PRIV_LVL_M,
          mprv: 1'b0
      };
      mepc_q <= mepc_n;
      mcause_q <= mcause_n;
      depc_q <= depc_n;
      dcsr_q <= dcsr_n;
      dscratch0_q <= dscratch0_n;
      dscratch1_q <= dscratch1_n;
      mscratch_q <= mscratch_n;
      mie_q <= mie_n;
      mtvec_q <= mtvec_n;
      mtvec_mode_q <= mtvec_mode_n;
    end
  end









  if (DEBUG_TRIGGER_EN) begin : gen_trigger_regs

    logic        tmatch_control_exec_q;
    logic [31:0] tmatch_value_q;

    logic        tmatch_control_we;
    logic        tmatch_value_we;


    assign tmatch_control_we = csr_we_int & debug_mode_i & (csr_addr_i == CSR_TDATA1);
    assign tmatch_value_we   = csr_we_int & debug_mode_i & (csr_addr_i == CSR_TDATA2);



    always_ff @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
        tmatch_control_exec_q <= 'b0;
        tmatch_value_q        <= 'b0;
      end else begin
        if (tmatch_control_we) tmatch_control_exec_q <= csr_wdata_int[2];
        if (tmatch_value_we) tmatch_value_q <= csr_wdata_int[31:0];
      end
    end


    assign tinfo_types = 1 << TTYPE_MCONTROL;



    assign tmatch_control_rdata = {
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


    assign tmatch_value_rdata = tmatch_value_q;



    assign trigger_match_o = tmatch_control_exec_q & (pc_id_i[31:0] == tmatch_value_q[31:0]);

  end else begin : gen_no_trigger_regs
    assign tinfo_types          = 'b0;
    assign tmatch_control_rdata = 'b0;
    assign tmatch_value_rdata   = 'b0;
    assign trigger_match_o      = 'b0;
  end












  assign hpm_events[0]  = 1'b1;
  assign hpm_events[1]  = mhpmevent_minstret_i;
  assign hpm_events[2]  = mhpmevent_ld_stall_i;
  assign hpm_events[3]  = mhpmevent_jr_stall_i;
  assign hpm_events[4]  = mhpmevent_imiss_i;
  assign hpm_events[5]  = mhpmevent_load_i;
  assign hpm_events[6]  = mhpmevent_store_i;
  assign hpm_events[7]  = mhpmevent_jump_i;
  assign hpm_events[8]  = mhpmevent_branch_i;
  assign hpm_events[9]  = mhpmevent_branch_taken_i;
  assign hpm_events[10] = mhpmevent_compressed_i;
  assign hpm_events[11] = 1'b0;
  assign hpm_events[12] = apu_typeconflict_i && !apu_dep_i;
  assign hpm_events[13] = apu_contention_i;
  assign hpm_events[14] = apu_dep_i && !apu_contention_i;
  assign hpm_events[15] = apu_wb_i;



  logic mcounteren_we;
  logic mcountinhibit_we;
  logic mhpmevent_we;

  assign mcounteren_we = csr_we_int & (csr_addr_i == CSR_MCOUNTEREN);
  assign mcountinhibit_we = csr_we_int & (csr_addr_i == CSR_MCOUNTINHIBIT);
  assign mhpmevent_we     = csr_we_int & ( (csr_addr_i == CSR_MHPMEVENT3  )||
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



  genvar incr_gidx;
  generate
    for (incr_gidx = 0; incr_gidx < 32; incr_gidx++) begin : gen_mhpmcounter_increment
      assign mhpmcounter_increment[incr_gidx] = mhpmcounter_q[incr_gidx] + 1;
    end
  endgenerate



  always_comb begin
    mcounteren_n    = mcounteren_q;
    mcountinhibit_n = mcountinhibit_q;
    mhpmevent_n     = mhpmevent_q;
    if (mcountinhibit_we) mcountinhibit_n = csr_wdata_int;
    if (mhpmevent_we) mhpmevent_n[csr_addr_i[4:0]] = csr_wdata_int;
  end

  genvar wcnt_gidx;
  generate
    for (wcnt_gidx = 0; wcnt_gidx < 32; wcnt_gidx++) begin : gen_mhpmcounter_write


      assign mhpmcounter_write_lower[wcnt_gidx] = csr_we_int && (csr_addr_i == (CSR_MCYCLE + wcnt_gidx));


      assign mhpmcounter_write_upper[wcnt_gidx] = !mhpmcounter_write_lower[wcnt_gidx] &&
                                                  csr_we_int && (csr_addr_i == (CSR_MCYCLEH + wcnt_gidx)) && (MHPMCOUNTER_WIDTH == 64);


      if (wcnt_gidx == 0) begin : gen_mhpmcounter_mcycle

        assign mhpmcounter_write_increment[wcnt_gidx] = !mhpmcounter_write_lower[wcnt_gidx] &&
                                                          !mhpmcounter_write_upper[wcnt_gidx] &&
                                                          !mcountinhibit_q[wcnt_gidx];
      end else if (wcnt_gidx == 2) begin : gen_mhpmcounter_minstret

        assign mhpmcounter_write_increment[wcnt_gidx] = !mhpmcounter_write_lower[wcnt_gidx] &&
                                                          !mhpmcounter_write_upper[wcnt_gidx] &&
                                                          !mcountinhibit_q[wcnt_gidx] &&
                                                          hpm_events[1];
      end else if ((wcnt_gidx > 2) && (wcnt_gidx < (4))) begin : gen_mhpmcounter

        assign mhpmcounter_write_increment[wcnt_gidx] = !mhpmcounter_write_lower[wcnt_gidx] &&
                                                          !mhpmcounter_write_upper[wcnt_gidx] &&
                                                          !mcountinhibit_q[wcnt_gidx] &&
                                                          |(hpm_events & mhpmevent_q[wcnt_gidx][NUM_HPM_EVENTS-1:0]);
      end else begin : gen_mhpmcounter_not_implemented
        assign mhpmcounter_write_increment[wcnt_gidx] = 1'b0;
      end
    end
  endgenerate




  genvar cnt_gidx;
  generate
    for (cnt_gidx = 0; cnt_gidx < 32; cnt_gidx++) begin : gen_mhpmcounter




      if ((cnt_gidx == 1) || (cnt_gidx >= (4))) begin : gen_non_implemented
        assign mhpmcounter_q[cnt_gidx] = 'b0;
      end else begin : gen_implemented
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
  endgenerate


  genvar evt_gidx;
  generate
    for (evt_gidx = 0; evt_gidx < 32; evt_gidx++) begin : gen_mhpmevent

      if ((evt_gidx < 3) || (evt_gidx >= (4))) begin : gen_non_implemented
        assign mhpmevent_q[evt_gidx] = 'b0;
      end else begin : gen_implemented
        if (NUM_HPM_EVENTS < 32) begin : gen_tie_off
          assign mhpmevent_q[evt_gidx][31:NUM_HPM_EVENTS] = 'b0;
        end
        always_ff @(posedge clk, negedge rst_n)
          if (!rst_n) mhpmevent_q[evt_gidx][NUM_HPM_EVENTS-1:0] <= 'b0;
          else
            mhpmevent_q[evt_gidx][NUM_HPM_EVENTS-1:0] <= mhpmevent_n[evt_gidx][NUM_HPM_EVENTS-1:0];
      end
    end
  endgenerate


  genvar en_gidx;
  generate
    for (en_gidx = 0; en_gidx < 32; en_gidx++) begin : gen_mcounteren
      assign mcounteren_q[en_gidx] = 'b0;
    end
  endgenerate



  genvar inh_gidx;
  generate
    for (inh_gidx = 0; inh_gidx < 32; inh_gidx++) begin : gen_mcountinhibit
      if ((inh_gidx == 1) || (inh_gidx >= (4))) begin : gen_non_implemented
        assign mcountinhibit_q[inh_gidx] = 'b0;
      end else begin : gen_implemented
        always_ff @(posedge clk, negedge rst_n)
          if (!rst_n) mcountinhibit_q[inh_gidx] <= 'b1;
          else mcountinhibit_q[inh_gidx] <= mcountinhibit_n[inh_gidx];
      end
    end
  endgenerate

endmodule
