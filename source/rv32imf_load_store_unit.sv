module rv32imf_load_store_unit #(
) (
    input logic clk,   // Clock input
    input logic rst_n, // Asynchronous reset input (active low)

    output logic data_req_o,     // Data request output to memory system
    input  logic data_gnt_i,     // Data grant input from memory system
    input  logic data_rvalid_i,  // Data response valid input from memory system
    input  logic data_err_i,     // Data error input from memory system
    input  logic data_err_pmp_i, // Data PMP error input from memory system

    output logic [31:0] data_addr_o,   // Data address output to memory system
    output logic        data_we_o,     // Data write enable output to memory system
    output logic [ 3:0] data_be_o,     // Data byte enable output to memory system
    output logic [31:0] data_wdata_o,  // Data write data output to memory system
    input  logic [31:0] data_rdata_i,  // Data read data input from memory system

    input logic        data_we_ex_i,          // Write enable from execute stage
    input logic [ 1:0] data_type_ex_i,        // Data type (size) from execute stage
    input logic [31:0] data_wdata_ex_i,       // Write data from execute stage
    input logic [ 1:0] data_reg_offset_ex_i,  // Register offset for write data from execute
    input logic [ 1:0] data_sign_ext_ex_i,    // Sign extension type from execute stage

    output logic [31:0] data_rdata_ex_o,   // Read data output to execute stage
    input  logic        data_req_ex_i,     // Data request from execute stage
    input  logic [31:0] operand_a_ex_i,    // Operand A from execute stage (base address)
    input  logic [31:0] operand_b_ex_i,    // Operand B from execute stage (offset)
    input  logic        addr_useincr_ex_i, // Use incremented address from execute stage

    input  logic data_misaligned_ex_i,  // Misaligned access from execute stage
    output logic data_misaligned_o,     // Misaligned access detected

    input  logic [5:0] data_atop_ex_i,  // Atomic operation type from execute stage
    output logic [5:0] data_atop_o,     // Atomic operation type output

    output logic lsu_ready_ex_o,  // LSU ready for execute stage
    output logic lsu_ready_wb_o,  // LSU ready for writeback stage

    output logic busy_o  // LSU busy status
);

  localparam int DEPTH = 2;  // Depth of the request queue

  logic        trans_valid;  // Transaction valid flag
  logic        trans_ready;  // Transaction ready flag from OBI interface
  logic [31:0] trans_addr;  // Transaction address
  logic        trans_we;  // Transaction write enable
  logic [ 3:0] trans_be;  // Transaction byte enable
  logic [31:0] trans_wdata;  // Transaction write data
  logic [ 5:0] trans_atop;  // Transaction atomic operation type

  logic        resp_valid;  // Response valid flag from OBI interface
  logic [31:0] resp_rdata;  // Response read data from OBI interface
  logic        resp_err;  // Response error flag from OBI interface

  logic [ 1:0] cnt_q;  // Request counter current state
  logic [ 1:0] next_cnt;  // Request counter next state
  logic        count_up;  // Flag to increment request counter
  logic        count_down;  // Flag to decrement request counter

  logic        ctrl_update;  // Control update enable

  logic [31:0] data_addr_int;  // Internal data address

  logic [ 1:0] data_type_q;  // Queued data type
  logic [ 1:0] rdata_offset_q;  // Queued read data offset
  logic [ 1:0] data_sign_ext_q;  // Queued sign extension type
  logic        data_we_q;  // Queued write enable

  logic [ 1:0] wdata_offset;  // Write data offset

  logic [ 3:0] data_be;  // Data byte enable
  logic [31:0] data_wdata;  // Data write data

  logic        misaligned_st;  // Misaligned status
  logic load_err_o, store_err_o;  // Load and store error flags

  logic [31:0] rdata_q;  // Queued read data

  always_comb begin
    case (data_type_ex_i)  // Determine byte enable based on data type and address
      2'b00: begin  // Word access
        if (misaligned_st == 1'b0) begin  // Aligned word access
          case (data_addr_int[1:0])
            2'b00:   data_be = 4'b1111;  // Address ends in 00
            2'b01:   data_be = 4'b1110;  // Address ends in 01
            2'b10:   data_be = 4'b1100;  // Address ends in 10
            default: data_be = 4'b1000;  // Address ends in 11
          endcase
        end else begin  // Misaligned word access
          case (data_addr_int[1:0])
            2'b01:   data_be = 4'b0001;  // Address ends in 01
            2'b10:   data_be = 4'b0011;  // Address ends in 10
            2'b11:   data_be = 4'b0111;  // Address ends in 11
            default: data_be = 4'b0000;  // Address ends in 00
          endcase
        end
      end

      2'b01: begin  // Half-word access
        if (misaligned_st == 1'b0) begin  // Aligned half-word access
          case (data_addr_int[1:0])
            2'b00:   data_be = 4'b0011;  // Address ends in 00
            2'b01:   data_be = 4'b0110;  // Address ends in 01
            2'b10:   data_be = 4'b1100;  // Address ends in 10
            default: data_be = 4'b1000;  // Address ends in 11
          endcase
        end else begin  // Misaligned half-word access
          data_be = 4'b0001;  // Only one byte enabled
        end
      end

      default: begin  // Byte access
        case (data_addr_int[1:0])
          2'b00:   data_be = 4'b0001;  // Address ends in 00
          2'b01:   data_be = 4'b0010;  // Address ends in 01
          2'b10:   data_be = 4'b0100;  // Address ends in 10
          default: data_be = 4'b1000;  // Address ends in 11
        endcase
      end
    endcase
  end

  // Calculate write data offset
  assign wdata_offset = data_addr_int[1:0] - data_reg_offset_ex_i[1:0];
  always_comb begin
    case (wdata_offset)  // Align write data based on offset
      2'b00:   data_wdata = data_wdata_ex_i[31:0];  // No offset
      2'b01:   data_wdata = {data_wdata_ex_i[23:0], data_wdata_ex_i[31:24]};  // Offset by 1 byte
      2'b10:   data_wdata = {data_wdata_ex_i[15:0], data_wdata_ex_i[31:16]};  // Offset by 2 bytes
      default: data_wdata = {data_wdata_ex_i[7:0], data_wdata_ex_i[31:8]};  // Offset by 3 bytes
    endcase
  end

  always_ff @(posedge clk, negedge rst_n) begin
    if (rst_n == 1'b0) begin
      data_type_q     <= '0;  // Reset queued data type
      rdata_offset_q  <= '0;  // Reset queued read data offset
      data_sign_ext_q <= '0;  // Reset queued sign extension type
      data_we_q       <= 1'b0;  // Reset queued write enable
    end else if (ctrl_update) begin
      data_type_q     <= data_type_ex_i;  // Update queued data type
      rdata_offset_q  <= data_addr_int[1:0];  // Update queued read data offset
      data_sign_ext_q <= data_sign_ext_ex_i;  // Update queued sign extension type
      data_we_q       <= data_we_ex_i;  // Update queued write enable
    end
  end

  logic [31:0] data_rdata_ext;  // Extended read data
  logic [31:0] rdata_w_ext;  // Extended read data for word
  logic [31:0] rdata_h_ext;  // Extended read data for half-word
  logic [31:0] rdata_b_ext;  // Extended read data for byte

  always_comb begin
    case (rdata_offset_q)  // Align read data for word access
      2'b00:   rdata_w_ext = resp_rdata[31:0];  // No offset
      2'b01:   rdata_w_ext = {resp_rdata[7:0], rdata_q[31:8]};  // Offset by 1 byte
      2'b10:   rdata_w_ext = {resp_rdata[15:0], rdata_q[31:16]};  // Offset by 2 bytes
      default: rdata_w_ext = {resp_rdata[23:0], rdata_q[31:24]};  // Offset by 3 bytes
    endcase
  end

  always_comb begin
    case (rdata_offset_q)  // Extend and align read data for half-word access
      2'b00: begin
        if (data_sign_ext_q == 2'b00) rdata_h_ext = {16'h0000, resp_rdata[15:0]};  // Zero extend
        else if (data_sign_ext_q == 2'b10)
          rdata_h_ext = {16'hffff, resp_rdata[15:0]};  // Sign extend
        else rdata_h_ext = {{16{resp_rdata[15]}}, resp_rdata[15:0]};  // Sign extend
      end

      2'b01: begin
        if (data_sign_ext_q == 2'b00) rdata_h_ext = {16'h0000, resp_rdata[23:8]};  // Zero extend
        else if (data_sign_ext_q == 2'b10)
          rdata_h_ext = {16'hffff, resp_rdata[23:8]};  // Sign extend
        else rdata_h_ext = {{16{resp_rdata[23]}}, resp_rdata[23:8]};  // Sign extend
      end

      2'b10: begin
        if (data_sign_ext_q == 2'b00) rdata_h_ext = {16'h0000, resp_rdata[31:16]};  // Zero extend
        else if (data_sign_ext_q == 2'b10)
          rdata_h_ext = {16'hffff, resp_rdata[31:16]};  // Sign extend
        else rdata_h_ext = {{16{resp_rdata[31]}}, resp_rdata[31:16]};  // Sign extend
      end

      default: begin
        if (data_sign_ext_q == 2'b00)
          rdata_h_ext = {16'h0000, resp_rdata[7:0], rdata_q[31:24]};  // Zero
        else if (data_sign_ext_q == 2'b10)
          rdata_h_ext = {16'hffff, resp_rdata[7:0], rdata_q[31:24]};  // Sign extend
        else rdata_h_ext = {{16{resp_rdata[7]}}, resp_rdata[7:0], rdata_q[31:24]};  // Sign extend
      end
    endcase
  end

  always_comb begin
    case (rdata_offset_q)  // Extend and align read data for byte access
      2'b00: begin
        if (data_sign_ext_q == 2'b00) rdata_b_ext = {24'h00_0000, resp_rdata[7:0]};  // Zero extend
        else if (data_sign_ext_q == 2'b10)
          rdata_b_ext = {24'hff_ffff, resp_rdata[7:0]};  // Sign extend
        else rdata_b_ext = {{24{resp_rdata[7]}}, resp_rdata[7:0]};  // Sign extend
      end

      2'b01: begin
        if (data_sign_ext_q == 2'b00)
          rdata_b_ext = {24'h00_0000, resp_rdata[15:8]};  // Zero extend
        else if (data_sign_ext_q == 2'b10)
          rdata_b_ext = {24'hff_ffff, resp_rdata[15:8]};  // Sign extend
        else rdata_b_ext = {{24{resp_rdata[15]}}, resp_rdata[15:8]};  // Sign extend
      end

      2'b10: begin
        if (data_sign_ext_q == 2'b00)
          rdata_b_ext = {24'h00_0000, resp_rdata[23:16]};  // Zero extend
        else if (data_sign_ext_q == 2'b10)
          rdata_b_ext = {24'hff_ffff, resp_rdata[23:16]};  // Sign extend
        else rdata_b_ext = {{24{resp_rdata[23]}}, resp_rdata[23:16]};  // Sign extend
      end

      default: begin
        if (data_sign_ext_q == 2'b00)
          rdata_b_ext = {24'h00_0000, resp_rdata[31:24]};  // Zero extend
        else if (data_sign_ext_q == 2'b10)
          rdata_b_ext = {24'hff_ffff, resp_rdata[31:24]};  // Sign extend
        else rdata_b_ext = {{24{resp_rdata[31]}}, resp_rdata[31:24]};  // Sign extend
      end
    endcase
  end

  always_comb begin
    case (data_type_q)  // Select extended read data based on data type
      2'b00:   data_rdata_ext = rdata_w_ext;  // Word
      2'b01:   data_rdata_ext = rdata_h_ext;  // Half-word
      default: data_rdata_ext = rdata_b_ext;  // Byte
    endcase
  end

  always_ff @(posedge clk, negedge rst_n) begin
    if (rst_n == 1'b0) begin
      rdata_q <= '0;  // Reset queued read data
    end else begin
      if (resp_valid && (~data_we_q)) begin  // If response valid and not a write
        if ((data_misaligned_ex_i == 1'b1) || (data_misaligned_o == 1'b1))
          rdata_q <= resp_rdata;  // Misaligned
        else rdata_q <= data_rdata_ext;  // Aligned
      end
    end
  end

  assign data_rdata_ex_o = (resp_valid == 1'b1) ? data_rdata_ext : rdata_q;  // Output read data

  assign misaligned_st   = data_misaligned_ex_i;  // Assign misaligned status

  assign load_err_o      = data_gnt_i && data_err_pmp_i && ~data_we_o;  // Load error condition
  assign store_err_o     = data_gnt_i && data_err_pmp_i && data_we_o;  // Store error condition

  always_comb begin
    data_misaligned_o = 1'b0;  // Default misaligned output

    // If request and not already misaligned
    if ((data_req_ex_i == 1'b1) && (data_misaligned_ex_i == 1'b0)) begin
      case (data_type_ex_i)
        2'b00: begin  // Word access
          if (data_addr_int[1:0] != 2'b00) data_misaligned_o = 1'b1;  // Check word alignment
        end
        2'b01: begin  // Half-word access
          if (data_addr_int[1:0] == 2'b11) data_misaligned_o = 1'b1;  // Check half-word alignment
        end
        default: begin  // Byte access
          // Byte access is always aligned
        end
      endcase
    end
  end

  // Calculate address
  assign data_addr_int = (addr_useincr_ex_i) ? (operand_a_ex_i + operand_b_ex_i) : operand_a_ex_i;

  // LSU is busy if queue is not empty or transaction valid
  assign busy_o = (cnt_q != 2'b00) || trans_valid;

  // Transaction address
  assign trans_addr = data_misaligned_ex_i ? {data_addr_int[31:2], 2'b00} : data_addr_int;
  // Transaction write enable
  assign trans_we = data_we_ex_i;
  // Transaction byte enable
  assign trans_be = data_be;
  // Transaction write data
  assign trans_wdata = data_wdata;
  // Transaction atomic operation type
  assign trans_atop = data_atop_ex_i;

  // Transaction is valid if request and queue not full
  assign trans_valid = data_req_ex_i && (cnt_q < DEPTH);

  // LSU ready for WB if queue empty or response valid
  assign lsu_ready_wb_o = (cnt_q == 2'b00) ? 1'b1 : resp_valid;

  // Ready if no request
  assign lsu_ready_ex_o = (data_req_ex_i == 1'b0) ? 1'b1 :
      // Ready if queue empty
      (cnt_q == 2'b00) ? (trans_valid && trans_ready) :
      // Ready if one in queue
      (cnt_q == 2'b01) ? (resp_valid && trans_valid && trans_ready) :
      // Ready if queue full and response valid
      resp_valid;

  // Update control signals when LSU is ready and request
  assign ctrl_update = lsu_ready_ex_o && data_req_ex_i;

  // Increment counter when transaction starts
  assign count_up = trans_valid && trans_ready;
  // Decrement counter when response received
  assign count_down = resp_valid;

  always_comb begin
    case ({  // Determine next counter value
      count_up, count_down
    })
      2'b00: begin
        next_cnt = cnt_q;  // No change
      end
      2'b01: begin
        next_cnt = cnt_q - 1'b1;  // Decrement
      end
      2'b10: begin
        next_cnt = cnt_q + 1'b1;  // Increment
      end
      default: begin
        next_cnt = cnt_q;  // No change
      end
    endcase
  end

  always_ff @(posedge clk, negedge rst_n) begin
    if (rst_n == 1'b0) begin
      cnt_q <= '0;  // Reset request counter
    end else begin
      cnt_q <= next_cnt;  // Update request counter
    end
  end

  rv32imf_obi_interface #(  // Instantiate OBI interface module
      .TRANS_STABLE(1)
  ) data_obi_i (
      .clk  (clk),
      .rst_n(rst_n),

      .trans_valid_i(trans_valid),
      .trans_ready_o(trans_ready),
      .trans_addr_i (trans_addr),
      .trans_we_i   (trans_we),
      .trans_be_i   (trans_be),
      .trans_wdata_i(trans_wdata),
      .trans_atop_i (trans_atop),

      .resp_valid_o(resp_valid),
      .resp_rdata_o(resp_rdata),
      .resp_err_o  (resp_err),

      .obi_req_o   (data_req_o),
      .obi_gnt_i   (data_gnt_i),
      .obi_addr_o  (data_addr_o),
      .obi_we_o    (data_we_o),
      .obi_be_o    (data_be_o),
      .obi_wdata_o (data_wdata_o),
      .obi_atop_o  (data_atop_o),
      .obi_rdata_i (data_rdata_i),
      .obi_rvalid_i(data_rvalid_i),
      .obi_err_i   (data_err_i)
  );

endmodule
