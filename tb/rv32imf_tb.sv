module rv32imf_tb;

  // Display messages at the start and end of the test
  initial $display("\033[7;38m---------------------- TEST STARTED ----------------------\033[0m");
  final $display("\033[7;38m----------------------- TEST ENDED -----------------------\033[0m");

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // DEFINES
  //////////////////////////////////////////////////////////////////////////////////////////////////

  `define CORE rv32imf_tb.u_rv32imf.core_i

  `define IF_STAGE `CORE.if_stage_i
  `define ID_STAGE `CORE.id_stage_i
  `define EX_STAGE `CORE.ex_stage_i

  `define REGFILE `ID_STAGE.register_file_i

  `define GPR `REGFILE.mem
  `define FPR `REGFILE.mem_fp

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // DUT Instantiation
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Declare signals for the Device Under Test (DUT)
  logic        clk;
  logic        rst_n;
  logic [31:0] boot_addr;
  logic [31:0] dm_halt_addr;
  logic [31:0] hart_id;
  logic [31:0] dm_exception_addr;
  logic        instr_req;
  logic        instr_gnt;
  logic        instr_rvalid;
  logic [31:0] instr_addr;
  logic [31:0] instr_rdata;
  logic        data_req;
  logic        data_gnt;
  logic        data_rvalid;
  logic        data_we;
  logic [ 3:0] data_be;
  logic [31:0] data_addr;
  logic [31:0] data_wdata;
  logic [31:0] data_rdata;
  logic [31:0] irq;
  logic        irq_ack;
  logic [ 4:0] irq_id;

  // Instantiate the DUT
  rv32imf u_rv32imf (
      .clk_i              (clk),
      .rst_ni             (rst_n),
      .boot_addr_i        (boot_addr),
      .dm_halt_addr_i     (dm_halt_addr),
      .hart_id_i          (hart_id),
      .dm_exception_addr_i(dm_exception_addr),
      .instr_req_o        (instr_req),
      .instr_gnt_i        (instr_gnt),
      .instr_rvalid_i     (instr_rvalid),
      .instr_addr_o       (instr_addr),
      .instr_rdata_i      (instr_rdata),
      .data_req_o         (data_req),
      .data_gnt_i         (data_gnt),
      .data_rvalid_i      (data_rvalid),
      .data_we_o          (data_we),
      .data_be_o          (data_be),
      .data_addr_o        (data_addr),
      .data_wdata_o       (data_wdata),
      .data_rdata_i       (data_rdata),
      .irq_i              (irq),
      .irq_ack_o          (irq_ack),
      .irq_id_o           (irq_id)
  );

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // Memory
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Instantiate the simulated memory
  sim_memory u_mem (
      .clk_i         (clk),
      .rst_ni        (rst_n),
      .instr_req_i   (instr_req),
      .instr_addr_i  (instr_addr),
      .instr_gnt_o   (instr_gnt),
      .instr_rdata_o (instr_rdata),
      .instr_rvalid_o(instr_rvalid),
      .data_req_i    (data_req),
      .data_addr_i   (data_addr),
      .data_we_i     (data_we),
      .data_wdata_i  (data_wdata),
      .data_be_i     (data_be),
      .data_gnt_o    (data_gnt),
      .data_rvalid_o (data_rvalid),
      .data_rdata_o  (data_rdata)
  );

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // Variables
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Declare dictionary of symbols
  int sym [string];

  // Coverage file pointer
  int cfp;


  //////////////////////////////////////////////////////////////////////////////////////////////////
  // Methods
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Task to start the clock signal
  task static start_clock();
    fork
      forever begin
        clk <= 1'b1;
        #5ns;
        clk <= 1'b0;
        #5ns;
      end
    join_none
  endtask

  // Task to apply reset and initialize inputs
  task static apply_reset();
    #100ns;
    clk               <= '0;
    rst_n             <= '0;
    dm_halt_addr      <= '0;
    hart_id           <= '0;
    dm_exception_addr <= '0;
    irq               <= '0;
    #100ns;
    rst_n <= 1'b1;
    #100ns;
  endtask

  // Task to dump trace
  task static dump_trace();
    int file_pointer;
    int running_pc;
    logic [31:0] rf_states[2][32];
    mailbox #(int) pc_mbx = new();
    mailbox #(bit) rf_read_req_mbx = new();
    mailbox #(string) rf_change_dump_mbx = new();
    mailbox #(string) dmem_p1_mbx = new();
    mailbox #(string) dmem_p2_mbx = new();
    mailbox #(string) dmem_final_mbx = new();
    running_pc   = 0;
    file_pointer = $fopen("prog.trace", "w");
    fork
      forever begin
        fork
          @(negedge `IF_STAGE.clk);
          @(negedge `ID_STAGE.clk);
        join_any
        if (`IF_STAGE.rst_n && `IF_STAGE.branch_req) begin
          running_pc = `IF_STAGE.branch_addr_n;
          pc_mbx.put(`IF_STAGE.branch_addr_n);
          while (`ID_STAGE.pc_id_i != running_pc) begin
            @(posedge `IF_STAGE.clk);
          end
        end else if (`ID_STAGE.rst_n && `ID_STAGE.pc_id_i != running_pc) begin
          running_pc = `ID_STAGE.pc_id_i;
          pc_mbx.put(`ID_STAGE.pc_id_i);
        end
      end
      forever begin
        @(posedge `EX_STAGE.clk);
        if (`EX_STAGE.rst_n && `EX_STAGE.ex_valid_o && `EX_STAGE.ex_ready_o) begin
          rf_read_req_mbx.put(1'b1);
        end
      end
      forever begin
        @(`REGFILE.rst_n);
        for (int i = 0; i < 32; i++) begin
          rf_states[0][i] = `GPR[i];
          rf_states[0][i] = `FPR[i];
        end
      end
      forever begin
        bit rf_read_req;
        string txt;
        txt = "";
        rf_read_req_mbx.get(rf_read_req);
        @(negedge `REGFILE.clk);
        foreach (`GPR[i]) begin
          if (`GPR[i] != rf_states[0][i]) begin
            $sformat(txt, "%sGPR%0d: 0x%08x -> 0x%08x\n", txt, i, rf_states[0][i], `GPR[i]);
            rf_states[0][i] = `GPR[i];
          end
        end
        foreach (`FPR[i]) begin
          if (`FPR[i] != rf_states[1][i]) begin
            $sformat(txt, "%sFPR%0d: 0x%08x -> 0x%08x\n", txt, i, rf_states[1][i], `FPR[i]);
            rf_states[1][i] = `FPR[i];
          end
        end
        rf_change_dump_mbx.put(txt);
      end
      forever begin
        @(posedge clk);
        if (rst_n && data_req && data_gnt) begin
          string txt;
          txt = "";
          $sformat(txt, "%s ADDR:0x%08h BE:0b%04b", (data_we ? "WR" : "RD"), data_addr, data_be);
          if (data_we) begin
            $sformat(txt, "%s DATA:0x%08h", txt, data_wdata);
          end
          dmem_p1_mbx.put(txt);
        end
      end
      forever begin
        @(posedge clk);
        if (rst_n && data_rvalid) begin
          string txt;
          txt = "";
          $sformat(txt, "RDATA:0x%08h", data_rdata);
          dmem_p2_mbx.put(txt);
        end
      end
      forever begin
        string p1;
        string p2;
        dmem_p1_mbx.get(p1);
        dmem_p2_mbx.get(p2);
        if (p1[0] == "R") begin
          dmem_final_mbx.put($sformatf("DMEM %s %s", p1, p2));
        end else if (p1[0] == "W") begin
          dmem_final_mbx.put($sformatf("DMEM %s", p1));
        end
      end
      forever begin
        int program_counter;
        string rf_change_dump;
        pc_mbx.get(program_counter);
        rf_change_dump_mbx.get(rf_change_dump);
        $fwrite(file_pointer, "PROGRAM_COUNTER:0x%0h\n", program_counter);
        if (dmem_final_mbx.num()) begin
          while (dmem_final_mbx.num()) begin
            string dmem_dump;
            dmem_final_mbx.get(dmem_dump);
            $fwrite(file_pointer, "%s\n", dmem_dump);
          end
        end
        $fwrite(file_pointer, "%s\n", rf_change_dump);
        $fwrite(file_pointer, "\n");
      end
    join_none
  endtask

  // Function to load memory contents from a file
  function automatic void load_memory(string filename);
    $readmemh(filename, u_mem.mem);
  endfunction

  // Function to load symbols from a file
  function automatic void load_symbols(string filename);
    int file, r;
    string line;
    string key;
    int value;
    file = $fopen(filename, "r");
    if (file == 0) begin
      $display("Error: Could not open file %s", filename);
      $finish;
    end
    while (!$feof(
        file
    )) begin
      r = $fgets(line, file);
      if (r != 0) begin
        r = $sscanf(line, "%h %*s %s", value, key);
        sym[key] = value;
      end
    end
    $fclose(file);
  endfunction

  // Task to monitor and print characters written to the simulated STDOUT
  task static monitor_prints();
    string prints;
    prints = "";
    fork
      forever begin
        @(posedge clk);
        if ((data_addr === sym["putchar_stdout"]
                     && data_we === '1 && data_req === '1 && data_gnt === '1))
                begin
          if (data_wdata[7:0] == "\n") begin
            $display("\033[1;33mSTDOUT         : %s\033[0m [%0t]", prints, $realtime);
            prints = "";
          end else begin
            $sformat(prints, "%s%c", prints, data_wdata[7:0]);
          end
        end
      end
    join_none
  endtask

  // Task to wait for the test to exit and display the exit code
  task static wait_exit();
    int exit_code;
    exit_code = '1;
    fork
      begin
        do begin
          @(posedge clk);
        end while (!(data_addr === sym["tohost"] && data_we === '1 && data_be === 'hf &&
                     data_req === '1 && data_gnt === '1));
        exit_code = data_wdata;
      end
      begin
        #1ms;
      end
    join_any
    $display("\033[0;35mEXIT CODE      : 0x%08x\033[0m", data_wdata);
    if (data_wdata == 0) $display("\033[1;32m************** TEST PASSED **************\033[0m");
    else $display("\033[1;31m************** TEST FAILED **************\033[0m");
  endtask

  function automatic void write_instruction_covered();
    casex (`ID_STAGE.instr)
      32'bxxxxxxxxxxxxxxxxxxxxxxxxx0110111: $fwrite(cfp, "INSTR_COV: LUI\n");
      32'bxxxxxxxxxxxxxxxxxxxxxxxxx0010111: $fwrite(cfp, "INSTR_COV: AUIPC\n");
      32'bxxxxxxxxxxxxxxxxxxxxxxxxx1101111: $fwrite(cfp, "INSTR_COV: JAL\n");
      32'bxxxxxxxxxxxxxxxxx000xxxxx1100111: $fwrite(cfp, "INSTR_COV: JALR\n");
      32'bxxxxxxxxxxxxxxxxx000xxxxx1100011: $fwrite(cfp, "INSTR_COV: BEQ\n");
      32'bxxxxxxxxxxxxxxxxx001xxxxx1100011: $fwrite(cfp, "INSTR_COV: BNE\n");
      32'bxxxxxxxxxxxxxxxxx100xxxxx1100011: $fwrite(cfp, "INSTR_COV: BLT\n");
      32'bxxxxxxxxxxxxxxxxx101xxxxx1100011: $fwrite(cfp, "INSTR_COV: BGE\n");
      32'bxxxxxxxxxxxxxxxxx110xxxxx1100011: $fwrite(cfp, "INSTR_COV: BLTU\n");
      32'bxxxxxxxxxxxxxxxxx111xxxxx1100011: $fwrite(cfp, "INSTR_COV: BGEU\n");
      32'bxxxxxxxxxxxxxxxxx000xxxxx0000011: $fwrite(cfp, "INSTR_COV: LB\n");
      32'bxxxxxxxxxxxxxxxxx001xxxxx0000011: $fwrite(cfp, "INSTR_COV: LH\n");
      32'bxxxxxxxxxxxxxxxxx010xxxxx0000011: $fwrite(cfp, "INSTR_COV: LW\n");
      32'bxxxxxxxxxxxxxxxxx100xxxxx0000011: $fwrite(cfp, "INSTR_COV: LBU\n");
      32'bxxxxxxxxxxxxxxxxx101xxxxx0000011: $fwrite(cfp, "INSTR_COV: LHU\n");
      32'bxxxxxxxxxxxxxxxxx000xxxxx0100011: $fwrite(cfp, "INSTR_COV: SB\n");
      32'bxxxxxxxxxxxxxxxxx001xxxxx0100011: $fwrite(cfp, "INSTR_COV: SH\n");
      32'bxxxxxxxxxxxxxxxxx010xxxxx0100011: $fwrite(cfp, "INSTR_COV: SW\n");
      32'bxxxxxxxxxxxxxxxxx000xxxxx0010011: $fwrite(cfp, "INSTR_COV: ADDI\n");
      32'bxxxxxxxxxxxxxxxxx010xxxxx0010011: $fwrite(cfp, "INSTR_COV: SLTI\n");
      32'bxxxxxxxxxxxxxxxxx011xxxxx0010011: $fwrite(cfp, "INSTR_COV: SLTIU\n");
      32'bxxxxxxxxxxxxxxxxx100xxxxx0010011: $fwrite(cfp, "INSTR_COV: XORI\n");
      32'bxxxxxxxxxxxxxxxxx110xxxxx0010011: $fwrite(cfp, "INSTR_COV: ORI\n");
      32'bxxxxxxxxxxxxxxxxx111xxxxx0010011: $fwrite(cfp, "INSTR_COV: ANDI\n");
      32'b0000000xxxxxxxxxx001xxxxx0010011: $fwrite(cfp, "INSTR_COV: SLLI\n");
      32'b0000000xxxxxxxxxx101xxxxx0010011: $fwrite(cfp, "INSTR_COV: SRLI\n");
      32'b0100000xxxxxxxxxx101xxxxx0010011: $fwrite(cfp, "INSTR_COV: SRAI\n");
      32'b0000000xxxxxxxxxx000xxxxx0110011: $fwrite(cfp, "INSTR_COV: ADD\n");
      32'b0100000xxxxxxxxxx000xxxxx0110011: $fwrite(cfp, "INSTR_COV: SUB\n");
      32'b0000000xxxxxxxxxx001xxxxx0110011: $fwrite(cfp, "INSTR_COV: SLL\n");
      32'b0000000xxxxxxxxxx010xxxxx0110011: $fwrite(cfp, "INSTR_COV: SLT\n");
      32'b0000000xxxxxxxxxx011xxxxx0110011: $fwrite(cfp, "INSTR_COV: SLTU\n");
      32'b0000000xxxxxxxxxx100xxxxx0110011: $fwrite(cfp, "INSTR_COV: XOR\n");
      32'b0000000xxxxxxxxxx101xxxxx0110011: $fwrite(cfp, "INSTR_COV: SRL\n");
      32'b0100000xxxxxxxxxx101xxxxx0110011: $fwrite(cfp, "INSTR_COV: SRA\n");
      32'b0000000xxxxxxxxxx110xxxxx0110011: $fwrite(cfp, "INSTR_COV: OR\n");
      32'b0000000xxxxxxxxxx111xxxxx0110011: $fwrite(cfp, "INSTR_COV: AND\n");
      32'bxxxxxxxxxxxxxxxxx000xxxxx0001111: $fwrite(cfp, "INSTR_COV: FENCE\n");
      32'b00000000000000000000000001110011: $fwrite(cfp, "INSTR_COV: ECALL\n");
      32'b00000000000100000000000001110011: $fwrite(cfp, "INSTR_COV: EBREAK\n");
      32'bxxxxxxxxxxxxxxxxx001xxxxx1110011: $fwrite(cfp, "INSTR_COV: CSRRW\n");
      32'bxxxxxxxxxxxxxxxxx010xxxxx1110011: $fwrite(cfp, "INSTR_COV: CSRRS\n");
      32'bxxxxxxxxxxxxxxxxx011xxxxx1110011: $fwrite(cfp, "INSTR_COV: CSRRC\n");
      32'bxxxxxxxxxxxxxxxxx101xxxxx1110011: $fwrite(cfp, "INSTR_COV: CSRRWI\n");
      32'bxxxxxxxxxxxxxxxxx110xxxxx1110011: $fwrite(cfp, "INSTR_COV: CSRRSI\n");
      32'bxxxxxxxxxxxxxxxxx111xxxxx1110011: $fwrite(cfp, "INSTR_COV: CSRRCI\n");
      32'b0000001xxxxxxxxxx000xxxxx0110011: $fwrite(cfp, "INSTR_COV: MUL\n");
      32'b0000001xxxxxxxxxx001xxxxx0110011: $fwrite(cfp, "INSTR_COV: MULH\n");
      32'b0000001xxxxxxxxxx010xxxxx0110011: $fwrite(cfp, "INSTR_COV: MULHSU\n");
      32'b0000001xxxxxxxxxx011xxxxx0110011: $fwrite(cfp, "INSTR_COV: MULHU\n");
      32'b0000001xxxxxxxxxx100xxxxx0110011: $fwrite(cfp, "INSTR_COV: DIV\n");
      32'b0000001xxxxxxxxxx101xxxxx0110011: $fwrite(cfp, "INSTR_COV: DIVU\n");
      32'b0000001xxxxxxxxxx110xxxxx0110011: $fwrite(cfp, "INSTR_COV: REM\n");
      32'b0000001xxxxxxxxxx111xxxxx0110011: $fwrite(cfp, "INSTR_COV: REMU\n");
      32'bxxxxxxxxxxxxxxxxx010xxxxx0000111: $fwrite(cfp, "INSTR_COV: FLW\n");
      32'bxxxxxxxxxxxxxxxxx010xxxxx0100111: $fwrite(cfp, "INSTR_COV: FSW\n");
      32'bxxxxx00xxxxxxxxxxxxxxxxxx1000011: $fwrite(cfp, "INSTR_COV: FMADD_S\n");
      32'bxxxxx00xxxxxxxxxxxxxxxxxx1000111: $fwrite(cfp, "INSTR_COV: FMSUB_S\n");
      32'bxxxxx00xxxxxxxxxxxxxxxxxx1001011: $fwrite(cfp, "INSTR_COV: FNMSUB_S\n");
      32'bxxxxx00xxxxxxxxxxxxxxxxxx1001111: $fwrite(cfp, "INSTR_COV: FNMADD_S\n");
      32'b0000000xxxxxxxxxxxxxxxxxx1010011: $fwrite(cfp, "INSTR_COV: FADD_S\n");
      32'b0000100xxxxxxxxxxxxxxxxxx1010011: $fwrite(cfp, "INSTR_COV: FSUB_S\n");
      32'b0001000xxxxxxxxxxxxxxxxxx1010011: $fwrite(cfp, "INSTR_COV: FMUL_S\n");
      32'b0001100xxxxxxxxxxxxxxxxxx1010011: $fwrite(cfp, "INSTR_COV: FDIV_S\n");
      32'b010110000000xxxxxxxxxxxxx1010011: $fwrite(cfp, "INSTR_COV: FSQRT_S\n");
      32'b0010000xxxxxxxxxx000xxxxx1010011: $fwrite(cfp, "INSTR_COV: FSGNJ_S\n");
      32'b0010000xxxxxxxxxx001xxxxx1010011: $fwrite(cfp, "INSTR_COV: FSGNJN_S\n");
      32'b0010000xxxxxxxxxx010xxxxx1010011: $fwrite(cfp, "INSTR_COV: FSGNJX_S\n");
      32'b0010100xxxxxxxxxx000xxxxx1010011: $fwrite(cfp, "INSTR_COV: FMIN_S\n");
      32'b0010100xxxxxxxxxx001xxxxx1010011: $fwrite(cfp, "INSTR_COV: FMAX_S\n");
      32'b110000000000xxxxxxxxxxxxx1010011: $fwrite(cfp, "INSTR_COV: FCVT_W_S\n");
      32'b110000000001xxxxxxxxxxxxx1010011: $fwrite(cfp, "INSTR_COV: FCVT_WU_S\n");
      32'b111000000000xxxxx000xxxxx1010011: $fwrite(cfp, "INSTR_COV: FMV_X_W\n");
      32'b1010000xxxxxxxxxx010xxxxx1010011: $fwrite(cfp, "INSTR_COV: FEQ_S\n");
      32'b1010000xxxxxxxxxx001xxxxx1010011: $fwrite(cfp, "INSTR_COV: FLT_S\n");
      32'b1010000xxxxxxxxxx000xxxxx1010011: $fwrite(cfp, "INSTR_COV: FLE_S\n");
      32'b111000000000xxxxx001xxxxx1010011: $fwrite(cfp, "INSTR_COV: FCLASS_S\n");
      32'b110100000000xxxxxxxxxxxxx1010011: $fwrite(cfp, "INSTR_COV: FCVT_S_W\n");
      32'b110100000001xxxxxxxxxxxxx1010011: $fwrite(cfp, "INSTR_COV: FCVT_S_WU\n");
      32'b111100000000xxxxx000xxxxx1010011: $fwrite(cfp, "INSTR_COV: FMV_W_X\n");
      default: $fwrite(cfp, "INSTR_COV: UNKNOWN 0x%08x\n", `ID_STAGE.instr);
    endcase
  endfunction


  task static log_coverage();
    int running_pc;
    running_pc = 0;
    fork
      forever begin  // instruction coverage
        fork
          @(negedge `IF_STAGE.clk);
          @(negedge `ID_STAGE.clk);
        join_any
        if (`IF_STAGE.rst_n && `IF_STAGE.branch_req) begin
          running_pc = `IF_STAGE.branch_addr_n;
          while (`ID_STAGE.pc_id_i != running_pc) begin
            @(negedge `IF_STAGE.clk);
          end
          write_instruction_covered();
        end else if (`ID_STAGE.rst_n && `ID_STAGE.pc_id_i != running_pc) begin
          running_pc = `ID_STAGE.pc_id_i;
          write_instruction_covered();
        end
      end
    join_none
  endtask

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // Interrupt Generation
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Always block to trigger every 2us and assert an interrupt
  always begin
    #50us;
    fork
      begin
        @(posedge clk);
        irq <= 'h800;  // Assert interrupt
        @(posedge clk);
        irq <= 'h0;  // Deassert interrupt
      end
    join_none
  end

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // Procedural Blocks
  //////////////////////////////////////////////////////////////////////////////////////////////////

  initial begin

    // Set time format to microseconds
    $timeformat(-6, 3, "us");

    if ($test$plusargs("DEBUG")) begin
      $display("\033[1;33m###### DEBUG ENABLED ######\033[0m");

      // Dump VCD file
      $dumpfile("prog.vcd");
      $dumpvars(0, rv32imf_tb);

      // Dump trace
      dump_trace();
    end

    // Set the coverage file name
    cfp = $fopen("prog.cov", "w");
    if (cfp == 0) begin
      $fatal(1, "Error: Could not open file prog.cov");
    end

    // Load simulation memory and symbols
    load_memory("prog.hex");
    load_symbols("prog.sym");

    // Set boot address to the start of the program
    boot_addr <= sym["_start"];

    $display("\033[0;35mBOOTADDR       : 0x%08x\033[0m", sym["_start"]);
    $display("\033[0;35mTOHOSTADDR     : 0x%08x\033[0m", sym["tohost"]);
    $display("\033[0;35mPUTCHAR_STDOUT : 0x%08x\033[0m", sym["putchar_stdout"]);

    // Monitor STDOUT prints
    monitor_prints();

    // Log Coverage
    log_coverage();

    // Apply reset and start clock
    apply_reset();
    start_clock();

    // Wait for the test to exit
    wait_exit();

    // Finish simulation after 100ns
    #100ns $finish;

  end

endmodule
