module rv32imf_compressed_decoder #(
) (
    input  logic [31:0] instr_i,
    output logic [31:0] instr_o,
    output logic        is_compressed_o,
    output logic        illegal_instr_o
);

  import rv32imf_pkg::*;










  always_comb begin
    illegal_instr_o = 1'b0;
    instr_o         = '0;

    unique case (instr_i[1:0])

      2'b00: begin
        unique case (instr_i[15:13])
          3'b000: begin

            instr_o = {
              2'b0,
              instr_i[10:7],
              instr_i[12:11],
              instr_i[5],
              instr_i[6],
              2'b00,
              5'h02,
              3'b000,
              2'b01,
              instr_i[4:2],
              OPCODE_OPIMM
            };
            if (instr_i[12:5] == 8'b0) illegal_instr_o = 1'b1;
          end

          3'b001: begin
            instr_o = {
              4'b0,
              instr_i[6:5],
              instr_i[12:10],
              3'b000,
              2'b01,
              instr_i[9:7],
              3'b011,
              2'b01,
              instr_i[4:2],
              OPCODE_LOAD_FP
            };
          end

          3'b010: begin

            instr_o = {
              5'b0,
              instr_i[5],
              instr_i[12:10],
              instr_i[6],
              2'b00,
              2'b01,
              instr_i[9:7],
              3'b010,
              2'b01,
              instr_i[4:2],
              OPCODE_LOAD
            };
          end

          3'b011: begin
            instr_o = {
              5'b0,
              instr_i[5],
              instr_i[12:10],
              instr_i[6],
              2'b00,
              2'b01,
              instr_i[9:7],
              3'b010,
              2'b01,
              instr_i[4:2],
              OPCODE_LOAD_FP
            };
          end

          3'b101: begin
            instr_o = {
              4'b0,
              instr_i[6:5],
              instr_i[12],
              2'b01,
              instr_i[4:2],
              2'b01,
              instr_i[9:7],
              3'b011,
              instr_i[11:10],
              3'b000,
              OPCODE_STORE_FP
            };
          end

          3'b110: begin
            instr_o = {
              5'b0,
              instr_i[5],
              instr_i[12],
              2'b01,
              instr_i[4:2],
              2'b01,
              instr_i[9:7],
              3'b010,
              instr_i[11:10],
              instr_i[6],
              2'b00,
              OPCODE_STORE
            };
          end

          3'b111: begin
            instr_o = {
              5'b0,
              instr_i[5],
              instr_i[12],
              2'b01,
              instr_i[4:2],
              2'b01,
              instr_i[9:7],
              3'b010,
              instr_i[11:10],
              instr_i[6],
              2'b00,
              OPCODE_STORE_FP
            };
          end
          default: begin
            illegal_instr_o = 1'b1;
          end
        endcase
      end



      2'b01: begin
        unique case (instr_i[15:13])
          3'b000: begin


            instr_o = {
              {6{instr_i[12]}},
              instr_i[12],
              instr_i[6:2],
              instr_i[11:7],
              3'b0,
              instr_i[11:7],
              OPCODE_OPIMM
            };
          end

          3'b001, 3'b101: begin


            instr_o = {
              instr_i[12],
              instr_i[8],
              instr_i[10:9],
              instr_i[6],
              instr_i[7],
              instr_i[2],
              instr_i[11],
              instr_i[5:3],
              {9{instr_i[12]}},
              4'b0,
              ~instr_i[15],
              OPCODE_JAL
            };
          end

          3'b010: begin
            if (instr_i[11:7] == 5'b0) begin

              instr_o = {
                {6{instr_i[12]}}, instr_i[12], instr_i[6:2], 5'b0, 3'b0, instr_i[11:7], OPCODE_OPIMM
              };
            end else begin

              instr_o = {
                {6{instr_i[12]}}, instr_i[12], instr_i[6:2], 5'b0, 3'b0, instr_i[11:7], OPCODE_OPIMM
              };
            end
          end

          3'b011: begin
            if ({instr_i[12], instr_i[6:2]} == 6'b0) begin
              illegal_instr_o = 1'b1;
            end else begin
              if (instr_i[11:7] == 5'h02) begin

                instr_o = {
                  {3{instr_i[12]}},
                  instr_i[4:3],
                  instr_i[5],
                  instr_i[2],
                  instr_i[6],
                  4'b0,
                  5'h02,
                  3'b000,
                  5'h02,
                  OPCODE_OPIMM
                };
              end else if (instr_i[11:7] == 5'b0) begin

                instr_o = {{15{instr_i[12]}}, instr_i[6:2], instr_i[11:7], OPCODE_LUI};
              end else begin

                instr_o = {{15{instr_i[12]}}, instr_i[6:2], instr_i[11:7], OPCODE_LUI};
              end
            end
          end

          3'b100: begin
            unique case (instr_i[11:10])
              2'b00, 2'b01: begin


                if (instr_i[12] == 1'b1) begin

                  instr_o = {
                    1'b0,
                    instr_i[10],
                    5'b0,
                    instr_i[6:2],
                    2'b01,
                    instr_i[9:7],
                    3'b101,
                    2'b01,
                    instr_i[9:7],
                    OPCODE_OPIMM
                  };
                  illegal_instr_o = 1'b1;
                end else begin
                  if (instr_i[6:2] == 5'b0) begin

                    instr_o = {
                      1'b0,
                      instr_i[10],
                      5'b0,
                      instr_i[6:2],
                      2'b01,
                      instr_i[9:7],
                      3'b101,
                      2'b01,
                      instr_i[9:7],
                      OPCODE_OPIMM
                    };
                  end else begin
                    instr_o = {
                      1'b0,
                      instr_i[10],
                      5'b0,
                      instr_i[6:2],
                      2'b01,
                      instr_i[9:7],
                      3'b101,
                      2'b01,
                      instr_i[9:7],
                      OPCODE_OPIMM
                    };
                  end
                end
              end

              2'b10: begin

                instr_o = {
                  {6{instr_i[12]}},
                  instr_i[12],
                  instr_i[6:2],
                  2'b01,
                  instr_i[9:7],
                  3'b111,
                  2'b01,
                  instr_i[9:7],
                  OPCODE_OPIMM
                };
              end

              2'b11: begin
                unique case ({
                  instr_i[12], instr_i[6:5]
                })
                  3'b000: begin

                    instr_o = {
                      2'b01,
                      5'b0,
                      2'b01,
                      instr_i[4:2],
                      2'b01,
                      instr_i[9:7],
                      3'b000,
                      2'b01,
                      instr_i[9:7],
                      OPCODE_OP
                    };
                  end

                  3'b001: begin

                    instr_o = {
                      7'b0,
                      2'b01,
                      instr_i[4:2],
                      2'b01,
                      instr_i[9:7],
                      3'b100,
                      2'b01,
                      instr_i[9:7],
                      OPCODE_OP
                    };
                  end

                  3'b010: begin

                    instr_o = {
                      7'b0,
                      2'b01,
                      instr_i[4:2],
                      2'b01,
                      instr_i[9:7],
                      3'b110,
                      2'b01,
                      instr_i[9:7],
                      OPCODE_OP
                    };
                  end

                  3'b011: begin

                    instr_o = {
                      7'b0,
                      2'b01,
                      instr_i[4:2],
                      2'b01,
                      instr_i[9:7],
                      3'b111,
                      2'b01,
                      instr_i[9:7],
                      OPCODE_OP
                    };
                  end

                  3'b100, 3'b101, 3'b110, 3'b111: begin


                    illegal_instr_o = 1'b1;
                  end
                endcase
              end
            endcase
          end

          3'b110, 3'b111: begin


            instr_o = {
              {4{instr_i[12]}},
              instr_i[6:5],
              instr_i[2],
              5'b0,
              2'b01,
              instr_i[9:7],
              2'b00,
              instr_i[13],
              instr_i[11:10],
              instr_i[4:3],
              instr_i[12],
              OPCODE_BRANCH
            };
          end
        endcase
      end


      2'b10: begin
        unique case (instr_i[15:13])
          3'b000: begin
            if (instr_i[12] == 1'b1) begin

              instr_o = {7'b0, instr_i[6:2], instr_i[11:7], 3'b001, instr_i[11:7], OPCODE_OPIMM};
              illegal_instr_o = 1'b1;
            end else begin
              if ((instr_i[6:2] == 5'b0) || (instr_i[11:7] == 5'b0)) begin

                instr_o = {7'b0, instr_i[6:2], instr_i[11:7], 3'b001, instr_i[11:7], OPCODE_OPIMM};
              end else begin

                instr_o = {7'b0, instr_i[6:2], instr_i[11:7], 3'b001, instr_i[11:7], OPCODE_OPIMM};
              end
            end
          end

          3'b001: begin
              instr_o = {
                3'b0,
                instr_i[4:2],
                instr_i[12],
                instr_i[6:5],
                3'b000,
                5'h02,
                3'b011,
                instr_i[11:7],
                OPCODE_LOAD_FP
              };
          end

          3'b010: begin
            instr_o = {
              4'b0,
              instr_i[3:2],
              instr_i[12],
              instr_i[6:4],
              2'b00,
              5'h02,
              3'b010,
              instr_i[11:7],
              OPCODE_LOAD
            };
            if (instr_i[11:7] == 5'b0) illegal_instr_o = 1'b1;
          end

          3'b011: begin
              instr_o = {
                4'b0,
                instr_i[3:2],
                instr_i[12],
                instr_i[6:4],
                2'b00,
                5'h02,
                3'b010,
                instr_i[11:7],
                OPCODE_LOAD_FP
              };
          end

          3'b100: begin
            if (instr_i[12] == 1'b0) begin
              if (instr_i[6:2] == 5'b0) begin

                instr_o = {12'b0, instr_i[11:7], 3'b0, 5'b0, OPCODE_JALR};

                if (instr_i[11:7] == 5'b0) illegal_instr_o = 1'b1;
              end else begin
                if (instr_i[11:7] == 5'b0) begin

                  instr_o = {7'b0, instr_i[6:2], 5'b0, 3'b0, instr_i[11:7], OPCODE_OP};
                end else begin

                  instr_o = {7'b0, instr_i[6:2], 5'b0, 3'b0, instr_i[11:7], OPCODE_OP};
                end
              end
            end else begin
              if (instr_i[6:2] == 5'b0) begin
                if (instr_i[11:7] == 5'b0) begin

                  instr_o = {32'h00_10_00_73};
                end else begin

                  instr_o = {12'b0, instr_i[11:7], 3'b000, 5'b00001, OPCODE_JALR};
                end
              end else begin
                if (instr_i[11:7] == 5'b0) begin

                  instr_o = {7'b0, instr_i[6:2], instr_i[11:7], 3'b0, instr_i[11:7], OPCODE_OP};
                end else begin

                  instr_o = {7'b0, instr_i[6:2], instr_i[11:7], 3'b0, instr_i[11:7], OPCODE_OP};
                end
              end
            end
          end

          3'b101: begin
              instr_o = {
                3'b0,
                instr_i[9:7],
                instr_i[12],
                instr_i[6:2],
                5'h02,
                3'b011,
                instr_i[11:10],
                3'b000,
                OPCODE_STORE_FP
              };
          end
          3'b110: begin

            instr_o = {
              4'b0,
              instr_i[8:7],
              instr_i[12],
              instr_i[6:2],
              5'h02,
              3'b010,
              instr_i[11:9],
              2'b00,
              OPCODE_STORE
            };
          end

          3'b111: begin
              instr_o = {
                4'b0,
                instr_i[8:7],
                instr_i[12],
                instr_i[6:2],
                5'h02,
                3'b010,
                instr_i[11:9],
                2'b00,
                OPCODE_STORE_FP
              };
          end
        endcase
      end

      default: begin

        instr_o = instr_i;
      end
    endcase
  end

  assign is_compressed_o = (instr_i[1:0] != 2'b11);

endmodule
