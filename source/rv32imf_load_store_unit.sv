


module rv32imf_load_store_unit #(
) (
    input logic clk,
    input logic rst_n,


    output logic data_req_o,
    input  logic data_gnt_i,
    input  logic data_rvalid_i,
    input  logic data_err_i,
    input  logic data_err_pmp_i,

    output logic [31:0] data_addr_o,
    output logic        data_we_o,
    output logic [ 3:0] data_be_o,
    output logic [31:0] data_wdata_o,
    input  logic [31:0] data_rdata_i,


    input logic        data_we_ex_i,
    input logic [ 1:0] data_type_ex_i,
    input logic [31:0] data_wdata_ex_i,
    input logic [ 1:0] data_reg_offset_ex_i,
    input logic        data_load_event_ex_i,
    input logic [ 1:0] data_sign_ext_ex_i,

    output logic [31:0] data_rdata_ex_o,
    input  logic        data_req_ex_i,
    input  logic [31:0] operand_a_ex_i,
    input  logic [31:0] operand_b_ex_i,
    input  logic        addr_useincr_ex_i,

    input  logic data_misaligned_ex_i,
    output logic data_misaligned_o,

    input  logic [5:0] data_atop_ex_i,
    output logic [5:0] data_atop_o,


    output logic p_elw_start_o,
    output logic p_elw_finish_o,


    output logic lsu_ready_ex_o,
    output logic lsu_ready_wb_o,


    output logic busy_o
);

  localparam int DEPTH = 2;


  logic        trans_valid;
  logic        trans_ready;
  logic [31:0] trans_addr;
  logic        trans_we;
  logic [ 3:0] trans_be;
  logic [31:0] trans_wdata;
  logic [ 5:0] trans_atop;

  logic        resp_valid;
  logic [31:0] resp_rdata;
  logic        resp_err;

  logic [ 1:0] cnt_q;
  logic [ 1:0] next_cnt;
  logic        count_up;
  logic        count_down;

  logic        ctrl_update;

  logic [31:0] data_addr_int;

  logic [ 1:0] data_type_q;
  logic [ 1:0] rdata_offset_q;
  logic [ 1:0] data_sign_ext_q;
  logic        data_we_q;
  logic        data_load_event_q;

  logic [ 1:0] wdata_offset;

  logic [ 3:0] data_be;
  logic [31:0] data_wdata;

  logic        misaligned_st;
  logic load_err_o, store_err_o;

  logic [31:0] rdata_q;


  always_comb begin
    case (data_type_ex_i)
      2'b00: begin
        if (misaligned_st == 1'b0) begin
          case (data_addr_int[1:0])
            2'b00:   data_be = 4'b1111;
            2'b01:   data_be = 4'b1110;
            2'b10:   data_be = 4'b1100;
            default: data_be = 4'b1000;
          endcase
        end else begin
          case (data_addr_int[1:0])
            2'b01:   data_be = 4'b0001;
            2'b10:   data_be = 4'b0011;
            2'b11:   data_be = 4'b0111;
            default: data_be = 4'b0000;
          endcase
        end
      end

      2'b01: begin
        if (misaligned_st == 1'b0) begin
          case (data_addr_int[1:0])
            2'b00:   data_be = 4'b0011;
            2'b01:   data_be = 4'b0110;
            2'b10:   data_be = 4'b1100;
            default: data_be = 4'b1000;
          endcase
        end else begin
          data_be = 4'b0001;
        end
      end

      default: begin
        case (data_addr_int[1:0])
          2'b00:   data_be = 4'b0001;
          2'b01:   data_be = 4'b0010;
          2'b10:   data_be = 4'b0100;
          default: data_be = 4'b1000;
        endcase
      end
    endcase
  end


  assign wdata_offset = data_addr_int[1:0] - data_reg_offset_ex_i[1:0];
  always_comb begin
    case (wdata_offset)
      2'b00:   data_wdata = data_wdata_ex_i[31:0];
      2'b01:   data_wdata = {data_wdata_ex_i[23:0], data_wdata_ex_i[31:24]};
      2'b10:   data_wdata = {data_wdata_ex_i[15:0], data_wdata_ex_i[31:16]};
      default: data_wdata = {data_wdata_ex_i[7:0], data_wdata_ex_i[31:8]};
    endcase
  end


  always_ff @(posedge clk, negedge rst_n) begin
    if (rst_n == 1'b0) begin
      data_type_q       <= '0;
      rdata_offset_q    <= '0;
      data_sign_ext_q   <= '0;
      data_we_q         <= 1'b0;
      data_load_event_q <= 1'b0;
    end else if (ctrl_update) begin
      data_type_q       <= data_type_ex_i;
      rdata_offset_q    <= data_addr_int[1:0];
      data_sign_ext_q   <= data_sign_ext_ex_i;
      data_we_q         <= data_we_ex_i;
      data_load_event_q <= data_load_event_ex_i;
    end
  end


  assign p_elw_start_o  = data_load_event_ex_i && data_req_o;
  assign p_elw_finish_o = data_load_event_q && data_rvalid_i && !data_misaligned_ex_i;


  logic [31:0] data_rdata_ext;
  logic [31:0] rdata_w_ext;
  logic [31:0] rdata_h_ext;
  logic [31:0] rdata_b_ext;

  always_comb begin
    case (rdata_offset_q)
      2'b00:   rdata_w_ext = resp_rdata[31:0];
      2'b01:   rdata_w_ext = {resp_rdata[7:0], rdata_q[31:8]};
      2'b10:   rdata_w_ext = {resp_rdata[15:0], rdata_q[31:16]};
      default: rdata_w_ext = {resp_rdata[23:0], rdata_q[31:24]};
    endcase
  end

  always_comb begin
    case (rdata_offset_q)
      2'b00: begin
        if (data_sign_ext_q == 2'b00) rdata_h_ext = {16'h0000, resp_rdata[15:0]};
        else if (data_sign_ext_q == 2'b10) rdata_h_ext = {16'hffff, resp_rdata[15:0]};
        else rdata_h_ext = {{16{resp_rdata[15]}}, resp_rdata[15:0]};
      end

      2'b01: begin
        if (data_sign_ext_q == 2'b00) rdata_h_ext = {16'h0000, resp_rdata[23:8]};
        else if (data_sign_ext_q == 2'b10) rdata_h_ext = {16'hffff, resp_rdata[23:8]};
        else rdata_h_ext = {{16{resp_rdata[23]}}, resp_rdata[23:8]};
      end

      2'b10: begin
        if (data_sign_ext_q == 2'b00) rdata_h_ext = {16'h0000, resp_rdata[31:16]};
        else if (data_sign_ext_q == 2'b10) rdata_h_ext = {16'hffff, resp_rdata[31:16]};
        else rdata_h_ext = {{16{resp_rdata[31]}}, resp_rdata[31:16]};
      end

      default: begin
        if (data_sign_ext_q == 2'b00) rdata_h_ext = {16'h0000, resp_rdata[7:0], rdata_q[31:24]};
        else if (data_sign_ext_q == 2'b10)
          rdata_h_ext = {16'hffff, resp_rdata[7:0], rdata_q[31:24]};
        else rdata_h_ext = {{16{resp_rdata[7]}}, resp_rdata[7:0], rdata_q[31:24]};
      end
    endcase
  end

  always_comb begin
    case (rdata_offset_q)
      2'b00: begin
        if (data_sign_ext_q == 2'b00) rdata_b_ext = {24'h00_0000, resp_rdata[7:0]};
        else if (data_sign_ext_q == 2'b10) rdata_b_ext = {24'hff_ffff, resp_rdata[7:0]};
        else rdata_b_ext = {{24{resp_rdata[7]}}, resp_rdata[7:0]};
      end

      2'b01: begin
        if (data_sign_ext_q == 2'b00) rdata_b_ext = {24'h00_0000, resp_rdata[15:8]};
        else if (data_sign_ext_q == 2'b10) rdata_b_ext = {24'hff_ffff, resp_rdata[15:8]};
        else rdata_b_ext = {{24{resp_rdata[15]}}, resp_rdata[15:8]};
      end

      2'b10: begin
        if (data_sign_ext_q == 2'b00) rdata_b_ext = {24'h00_0000, resp_rdata[23:16]};
        else if (data_sign_ext_q == 2'b10) rdata_b_ext = {24'hff_ffff, resp_rdata[23:16]};
        else rdata_b_ext = {{24{resp_rdata[23]}}, resp_rdata[23:16]};
      end

      default: begin
        if (data_sign_ext_q == 2'b00) rdata_b_ext = {24'h00_0000, resp_rdata[31:24]};
        else if (data_sign_ext_q == 2'b10) rdata_b_ext = {24'hff_ffff, resp_rdata[31:24]};
        else rdata_b_ext = {{24{resp_rdata[31]}}, resp_rdata[31:24]};
      end
    endcase
  end

  always_comb begin
    case (data_type_q)
      2'b00:   data_rdata_ext = rdata_w_ext;
      2'b01:   data_rdata_ext = rdata_h_ext;
      default: data_rdata_ext = rdata_b_ext;
    endcase
  end


  always_ff @(posedge clk, negedge rst_n) begin
    if (rst_n == 1'b0) begin
      rdata_q <= '0;
    end else begin
      if (resp_valid && (~data_we_q)) begin
        if ((data_misaligned_ex_i == 1'b1) || (data_misaligned_o == 1'b1)) rdata_q <= resp_rdata;
        else rdata_q <= data_rdata_ext;
      end
    end
  end


  assign data_rdata_ex_o = (resp_valid == 1'b1) ? data_rdata_ext : rdata_q;


  assign misaligned_st   = data_misaligned_ex_i;


  assign load_err_o      = data_gnt_i && data_err_pmp_i && ~data_we_o;
  assign store_err_o     = data_gnt_i && data_err_pmp_i && data_we_o;


  always_comb begin
    data_misaligned_o = 1'b0;

    if ((data_req_ex_i == 1'b1) && (data_misaligned_ex_i == 1'b0)) begin
      case (data_type_ex_i)
        2'b00: begin
          if (data_addr_int[1:0] != 2'b00) data_misaligned_o = 1'b1;
        end
        2'b01: begin
          if (data_addr_int[1:0] == 2'b11) data_misaligned_o = 1'b1;
        end
        default: begin

        end
      endcase
    end
  end


  assign data_addr_int = (addr_useincr_ex_i) ? (operand_a_ex_i + operand_b_ex_i) : operand_a_ex_i;


  assign busy_o = (cnt_q != 2'b00) || trans_valid;


  assign trans_addr = data_misaligned_ex_i ? {data_addr_int[31:2], 2'b00} : data_addr_int;
  assign trans_we = data_we_ex_i;
  assign trans_be = data_be;
  assign trans_wdata = data_wdata;
  assign trans_atop = data_atop_ex_i;


  assign trans_valid = data_req_ex_i && (cnt_q < DEPTH);


  assign lsu_ready_wb_o = (cnt_q == 2'b00) ? 1'b1 : resp_valid;

  assign lsu_ready_ex_o = (data_req_ex_i == 1'b0) ? 1'b1 :
                          (cnt_q == 2'b00) ? (              trans_valid && trans_ready) :
                          (cnt_q == 2'b01) ? (resp_valid && trans_valid && trans_ready) :
                                              resp_valid;


  assign ctrl_update = lsu_ready_ex_o && data_req_ex_i;


  assign count_up = trans_valid && trans_ready;
  assign count_down = resp_valid;

  always_comb begin
    case ({
      count_up, count_down
    })
      2'b00: begin
        next_cnt = cnt_q;
      end
      2'b01: begin
        next_cnt = cnt_q - 1'b1;
      end
      2'b10: begin
        next_cnt = cnt_q + 1'b1;
      end
      default: begin
        next_cnt = cnt_q;
      end
    endcase
  end


  always_ff @(posedge clk, negedge rst_n) begin
    if (rst_n == 1'b0) begin
      cnt_q <= '0;
    end else begin
      cnt_q <= next_cnt;
    end
  end


  rv32imf_obi_interface #(
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
