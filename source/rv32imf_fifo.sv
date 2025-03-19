module rv32imf_fifo #(
    parameter bit FALL_THROUGH = 1'b0,
    parameter int unsigned DATA_WIDTH = 32,
    parameter int unsigned DEPTH = 8,

    parameter int unsigned ADDR_DEPTH = (DEPTH > 1) ? $clog2(DEPTH) : 1
) (
    input logic clk_i,
    input logic rst_ni,
    input logic flush_i,
    input logic flush_but_first_i,
    input logic testmode_i,

    output logic full_o,
    output logic empty_o,
    output logic [ADDR_DEPTH:0] cnt_o,

    input logic [DATA_WIDTH-1:0] data_i,
    input logic push_i,

    output logic [DATA_WIDTH-1:0] data_o,
    input logic pop_i
);


  localparam int unsigned FIFO_DEPTH = (DEPTH > 0) ? DEPTH : 1;

  logic gate_clock;

  logic [ADDR_DEPTH - 1:0] read_pointer_n, read_pointer_q, write_pointer_n, write_pointer_q;

  logic [ADDR_DEPTH:0]
      status_cnt_n, status_cnt_q;

  logic [FIFO_DEPTH - 1:0][DATA_WIDTH-1:0] mem_n, mem_q;

  assign cnt_o = status_cnt_q;


  generate
    if (DEPTH == 0) begin : gen_zero_depth
      assign empty_o = ~push_i;
      assign full_o  = ~pop_i;
    end else begin : gen_non_zero_depth
      assign full_o  = (status_cnt_q == FIFO_DEPTH[ADDR_DEPTH:0]);
      assign empty_o = (status_cnt_q == 0) & ~(FALL_THROUGH & push_i);
    end
  endgenerate


  always_comb begin : read_write_comb

    read_pointer_n  = read_pointer_q;
    write_pointer_n = write_pointer_q;
    status_cnt_n    = status_cnt_q;
    data_o          = (DEPTH == 0) ? data_i : mem_q[read_pointer_q];
    mem_n           = mem_q;
    gate_clock      = 1'b1;


    if (push_i && ~full_o) begin

      mem_n[write_pointer_q] = data_i;

      gate_clock = 1'b0;

      if (write_pointer_q == FIFO_DEPTH[ADDR_DEPTH-1:0] - 1) write_pointer_n = '0;
      else write_pointer_n = write_pointer_q + 1;

      status_cnt_n = status_cnt_q + 1;
    end

    if (pop_i && ~empty_o) begin


      if (read_pointer_n == FIFO_DEPTH[ADDR_DEPTH-1:0] - 1) read_pointer_n = '0;
      else read_pointer_n = read_pointer_q + 1;

      status_cnt_n = status_cnt_q - 1;
    end


    if (push_i && pop_i && ~full_o && ~empty_o) status_cnt_n = status_cnt_q;


    if (FALL_THROUGH && (status_cnt_q == 0) && push_i) begin
      data_o = data_i;
      if (pop_i) begin
        status_cnt_n = status_cnt_q;
        read_pointer_n = read_pointer_q;
        write_pointer_n = write_pointer_q;
      end
    end
  end


  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
      read_pointer_q  <= '0;
      write_pointer_q <= '0;
      status_cnt_q    <= '0;
    end else begin
      unique case (1'b1)

        flush_i: begin
          read_pointer_q  <= '0;
          write_pointer_q <= '0;
          status_cnt_q    <= '0;
        end

        flush_but_first_i: begin
          read_pointer_q  <= (status_cnt_q > 0) ? read_pointer_q : '0;
          write_pointer_q <= (status_cnt_q > 0) ? read_pointer_q + 1 : '0;
          status_cnt_q    <= (status_cnt_q > 0) ? 1'b1 : '0;
        end

        default: begin
          read_pointer_q  <= read_pointer_n;
          write_pointer_q <= write_pointer_n;
          status_cnt_q    <= status_cnt_n;
        end
      endcase
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
      mem_q <= '0;
    end else if (!gate_clock) begin
      mem_q <= mem_n;
    end
  end

endmodule
