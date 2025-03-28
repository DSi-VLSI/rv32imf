// Module definition for the RISC-V compressed instruction decoder
module rv32imf_compressed_decoder #(
) (
    // Input 32-bit instruction word (could be a compressed 16-bit instruction)
    input  logic [31:0] instr_i,
    // Output 32-bit decompressed instruction word
    output logic [31:0] instr_o,
    // Output signal indicating if the input instruction was a compressed instruction (16-bit)
    output logic        is_compressed_o,
    // Output signal indicating if the input compressed instruction was illegal
    output logic        illegal_instr_o
);

  // Import the package containing definitions for opcodes and other constants
  import rv32imf_pkg::*;

  // Combinational logic block for decoding compressed instructions
  always_comb begin
    // Initialize the illegal instruction flag to false
    illegal_instr_o = 1'b0;
    // Initialize the output instruction to zero
    instr_o         = '0;

    // Decode based on the lowest two bits of the input instruction (opcode[1:0])
    unique case (instr_i[1:0])

      // Instructions with opcode[1:0] == 00 (C0 group)
      2'b00: begin
        // Decode based on bits [15:13]
        unique case (instr_i[15:13])
          // C.ADDI4SPN
          3'b000: begin
            // Decompress to ADDI rd', x2, nzuimm
            instr_o = {
              2'b0,
              instr_i[10:7],
              instr_i[12:11],
              instr_i[5],
              instr_i[6],
              2'b00,
              5'h02,  // x2 (sp)
              3'b000,
              2'b01,
              instr_i[4:2],
              OPCODE_OPIMM
            };
            // Immediate cannot be zero
            if (instr_i[12:5] == 8'b0) illegal_instr_o = 1'b1;
          end

          // C.FLD (load double-precision floating-point)
          3'b001: begin
            // Decompress to FLD rd', offset(rs')
            instr_o = {
              4'b0,
              instr_i[6:5],
              instr_i[12:10],
              3'b000,
              2'b01,
              instr_i[9:7],
              3'b011,  // FUNC3 for FLD
              2'b01,
              instr_i[4:2],
              OPCODE_LOAD_FP
            };
          end

          // C.LW (load word)
          3'b010: begin
            // Decompress to LW rd', offset(rs')
            instr_o = {
              5'b0,
              instr_i[5],
              instr_i[12:10],
              instr_i[6],
              2'b00,
              2'b01,
              instr_i[9:7],
              3'b010,  // FUNC3 for LW
              2'b01,
              instr_i[4:2],
              OPCODE_LOAD
            };
          end

          // C.LWSP (load word from stack pointer)
          3'b011: begin
            // Decompress to LW rd, offset(x2)
            instr_o = {
              5'b0,
              instr_i[5],
              instr_i[12:10],
              instr_i[6],
              2'b00,
              2'b01,
              instr_i[9:7],
              3'b010,  // FUNC3 for LW
              2'b01,
              instr_i[4:2],
              OPCODE_LOAD_FP  // Note: This should likely be OPCODE_LOAD.
            //                         assuming it's for integer registers
            };
          end

          // Reserved
          3'b100: begin
            illegal_instr_o = 1'b1;
          end

          // C.FSD (store double-precision floating-point)
          3'b101: begin
            // Decompress to FSD rs2', offset(rs1')
            instr_o = {
              4'b0,
              instr_i[6:5],
              instr_i[12],
              2'b01,
              instr_i[4:2],
              2'b01,
              instr_i[9:7],
              3'b011,  // FUNC3 for FSD
              instr_i[11:10],
              3'b000,
              OPCODE_STORE_FP
            };
          end

          // C.SW (store word)
          3'b110: begin
            // Decompress to SW rs2', offset(rs1')
            instr_o = {
              5'b0,
              instr_i[5],
              instr_i[12],
              2'b01,
              instr_i[4:2],
              2'b01,
              instr_i[9:7],
              3'b010,  // FUNC3 for SW
              instr_i[11:10],
              instr_i[6],
              2'b00,
              OPCODE_STORE
            };
          end

          // C.SWSP (store word to stack pointer)
          3'b111: begin
            // Decompress to SW rs2, offset(x2)
            instr_o = {
              5'b0,
              instr_i[5],
              instr_i[12],
              2'b01,
              instr_i[4:2],
              2'b01,
              instr_i[9:7],
              3'b010,  // FUNC3 for SW
              instr_i[11:10],
              instr_i[6],
              2'b00,
              OPCODE_STORE_FP  // Note: This should likely be OPCODE_STORE.
            //                          assuming it's for integer registers
            };
          end
          default: begin
            illegal_instr_o = 1'b1;
          end
        endcase
      end

      // Instructions with opcode[1:0] == 01 (C1 group)
      2'b01: begin
        // Decode based on bits [15:13]
        unique case (instr_i[15:13])
          // C.ADDI
          3'b000: begin
            // Decompress to ADDI rd, rd, nzimm
            instr_o = {
              {6{instr_i[12]}},  // Sign-extend immediate
              instr_i[12],
              instr_i[6:2],
              instr_i[11:7],
              3'b0,
              instr_i[11:7],
              OPCODE_OPIMM
            };
          end

          // C.JAL (jump and link) or C.ADDW (add word)
          3'b001, 3'b101: begin
            // Decompress to JAL x1, offset (if rd != 0) or ADDW rd, rd, rs2 (if rd != 0 and opcode[15:13] == 101)
            instr_o = {
              instr_i[12],
              instr_i[8],
              instr_i[10:9],
              instr_i[6],
              instr_i[7],
              instr_i[2],
              instr_i[11],
              instr_i[5:3],
              {9{instr_i[12]}},  // Sign-extend immediate
              4'b0,
              ~instr_i[15],  // Invert for JAL immediate calculation
              OPCODE_JAL
            };
          end

          // C.LI (load immediate)
          3'b010: begin
            // Decompress to ADDI rd, x0, imm
            if (instr_i[11:7] == 5'b0) begin
              // rd = x0 is illegal
              illegal_instr_o = 1'b1;
            end else begin
              instr_o = {
                {6{instr_i[12]}},  // Sign-extend immediate
                instr_i[12],
                instr_i[6:2],
                5'b0,  // rs1 = x0
                3'b0,
                instr_i[11:7],
                OPCODE_OPIMM
              };
            end
          end

          // C.LUI (load upper immediate)
          3'b011: begin
            // Decompress to LUI rd, nzimm
            if ({instr_i[12], instr_i[6:2]} == 6'b0) begin
              // Immediate cannot be zero
              illegal_instr_o = 1'b1;
            end else begin
              if (instr_i[11:7] == 5'h02) begin
                // C.ADDI16SP
                instr_o = {
                  {3{instr_i[12]}},
                  instr_i[4:3],
                  instr_i[5],
                  instr_i[2],
                  instr_i[6],
                  4'b0,
                  5'h02,  // rs1 = x2 (sp)
                  3'b000,
                  5'h02,  // rd = x2 (sp)
                  OPCODE_OPIMM
                };
              end else if (instr_i[11:7] == 5'b0) begin
                // Reserved
                illegal_instr_o = 1'b1;
              end else begin
                instr_o = {{15{instr_i[12]}}, instr_i[6:2], instr_i[11:7], OPCODE_LUI};
              end
            end
          end

          // C.SRLI, C.SRAI, C.ANDI
          3'b100: begin
            unique case (instr_i[11:10])
              // C.SRLI
              2'b00, 2'b01: begin
                if (instr_i[12] == 1'b1) begin
                  // Reserved
                  illegal_instr_o = 1'b1;
                end else begin
                  if (instr_i[6:2] == 5'b0) begin
                    // Reserved
                    illegal_instr_o = 1'b1;
                  end else begin
                    instr_o = {
                      1'b0,
                      instr_i[10],
                      5'b0,
                      instr_i[6:2],
                      2'b01,
                      instr_i[9:7],
                      3'b101,  // FUNC3 for SRLI/SRAI
                      2'b01,
                      instr_i[9:7],
                      OPCODE_OPIMM
                    };
                  end
                end
              end

              // C.SRAI
              2'b10: begin
                instr_o = {
                  {6{instr_i[12]}},  // Sign-extend immediate
                  instr_i[12],
                  instr_i[6:2],
                  2'b01,
                  instr_i[9:7],
                  3'b111,  // FUNC3 for SRAI
                  2'b01,
                  instr_i[9:7],
                  OPCODE_OPIMM
                };
              end

              // C.ANDI
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
                      3'b000,  // FUNC3 for AND
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
                      3'b100,  // FUNC3 for SUB
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
                      3'b110,  // FUNC3 for OR
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
                      3'b111,  // FUNC3 for AND
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

          // Reserved
          3'b110, 3'b111: begin
            // C.BEQZ or C.BNEZ
            instr_o = {
              {4{instr_i[12]}},  // Sign-extend immediate
              instr_i[6:5],
              instr_i[2],
              5'b0,  // rs2 = x0
              2'b01,
              instr_i[9:7],
              2'b00,  // BEQZ
              instr_i[13],
              instr_i[11:10],
              instr_i[4:3],
              instr_i[12],
              OPCODE_BRANCH
            };
          end
        endcase
      end

      // Instructions with opcode[1:0] == 10 (C2 group)
      2'b10: begin
        // Decode based on bits [15:13]
        unique case (instr_i[15:13])
          // C.SLLI
          3'b000: begin
            if (instr_i[12] == 1'b1) begin
              illegal_instr_o = 1'b1;
            end else begin
              if ((instr_i[6:2] == 5'b0) || (instr_i[11:7] == 5'b0)) begin
                illegal_instr_o = 1'b1;
              end else begin
                instr_o = {7'b0, instr_i[6:2], instr_i[11:7], 3'b001, instr_i[11:7], OPCODE_OPIMM};
              end
            end
          end

          // C.FLD (load double-precision floating-point)
          3'b001: begin
            instr_o = {
              3'b0,
              instr_i[4:2],
              instr_i[12],
              instr_i[6:5],
              3'b000,
              5'h02,  // rs1 = x2 (sp)
              3'b011,  // FUNC3 for FLD
              instr_i[11:7],
              OPCODE_LOAD_FP
            };
          end

          // C.LW (load word)
          3'b010: begin
            instr_o = {
              4'b0,
              instr_i[3:2],
              instr_i[12],
              instr_i[6:4],
              2'b00,
              5'h02,  // rs1 = x2 (sp)
              3'b010,  // FUNC3 for LW
              instr_i[11:7],
              OPCODE_LOAD
            };
            if (instr_i[11:7] == 5'b0) illegal_instr_o = 1'b1;
          end

          // C.LWSP (load word from stack pointer) - Typo in original module, should likely be C.LW
          3'b011: begin
            instr_o = {
              4'b0,
              instr_i[3:2],
              instr_i[12],
              instr_i[6:4],
              2'b00,
              5'h02,  // rs1 = x2 (sp)
              3'b010,  // FUNC3 for LW
              instr_i[11:7],
              OPCODE_LOAD_FP  // Note: This should likely be OPCODE_LOAD.
            //                         assuming it's for integer registers
            };
          end

          // C.MV or C.ADD
          3'b100: begin
            if (instr_i[12] == 1'b0) begin
              // C.MV
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
              // C.ADD
              if (instr_i[6:2] == 5'b0) begin
                if (instr_i[11:7] == 5'b0) begin
                  instr_o = {32'h00_10_00_73};  // NOP
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

          // C.FSD (store double-precision floating-point)
          3'b101: begin
            instr_o = {
              3'b0,
              instr_i[9:7],
              instr_i[12],
              instr_i[6:2],
              5'h02,  // rs1 = x2 (sp)
              3'b011,  // FUNC3 for FSD
              instr_i[11:10],
              3'b000,
              OPCODE_STORE_FP
            };
          end
          // C.SW (store word)
          3'b110: begin
            instr_o = {
              4'b0,
              instr_i[8:7],
              instr_i[12],
              instr_i[6:2],
              5'h02,  // rs1 = x2 (sp)
              3'b010,  // FUNC3 for SW
              instr_i[11:9],
              2'b00,
              OPCODE_STORE
            };
          end

          // C.SDSP (store double-precision floating-point to stack pointer) - Typo in original module, should likely be C.SWSP
          3'b111: begin
            instr_o = {
              4'b0,
              instr_i[8:7],
              instr_i[12],
              instr_i[6:2],
              5'h02,  // rs1 = x2 (sp)
              3'b010,  // FUNC3 for SW
              instr_i[11:9],
              2'b00,
              OPCODE_STORE_FP  // Note: This should likely be OPCODE_STORE.
            //                          assuming it's for integer registers
            };
          end
        endcase
      end

      // Instructions with opcode[1:0] == 11 are always 32-bit
      default: begin
        // If not a compressed instruction, pass it through unchanged
        instr_o = instr_i;
      end
    endcase
  end

  // Assign the is_compressed_o output based on the lower two bits
  assign is_compressed_o = (instr_i[1:0] != 2'b11);

endmodule
