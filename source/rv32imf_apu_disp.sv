module rv32imf_apu_disp (
    input logic clk_i,  // Clock input signal
    input logic rst_ni, // Asynchronous reset input signal (active low)


    input logic       enable_i,    // Enable signal for the APU dispatcher
    input logic [1:0] apu_lat_i,   // APU latency input (number of cycles)
    input logic [5:0] apu_waddr_i, // APU write address input


    output logic [5:0] apu_waddr_o,       // APU write address output
    output logic       apu_multicycle_o,  // Indicates if the APU operation is multi-cycle
    output logic       apu_singlecycle_o, // Indicates if the APU operation is single-cycle


    output logic active_o,  // Indicates if there is an active APU request


    output logic stall_o,  // Stall signal to the pipeline


    input  logic            is_decoding_i,       // Indicates if the instruction is being decoded
    input  logic [2:0][5:0] read_regs_i,         // Input array of read register addresses
    input  logic [2:0]      read_regs_valid_i,   // Input array of read register valid flags
    output logic            read_dep_o,          // Output indicating a read dependency
    output logic            read_dep_for_jalr_o, // Output indicating a read dependency for JALR


    input  logic [1:0][5:0] write_regs_i,        // Input array of write register addresses
    input  logic [1:0]      write_regs_valid_i,  // Input array of write register valid flags
    output logic            write_dep_o,         // Output indicating a write dependency


    output logic perf_type_o,  // Performance type output (related to stall type)
    output logic perf_cont_o,  // Performance contention output (related to stall nack)



    output logic apu_req_o,  // Request signal to the APU
    input  logic apu_gnt_i,  // Grant signal from the APU


    input logic apu_rvalid_i  // Response valid signal from the APU

);

  logic [5:0] addr_req, addr_inflight, addr_waiting;  // Addresses for request, inflight, waiting
  logic [5:0] addr_inflight_dn, addr_waiting_dn;  // Next state of inflight and waiting addresses
  logic valid_req, valid_inflight, valid_waiting;  // Validity flags for request, inflight, waiting
  logic valid_inflight_dn, valid_waiting_dn;  // Next state of inflight and waiting validity
  logic returned_req, returned_inflight, returned_waiting;  // Flags for returned request types

  logic       req_accepted;  // Flag indicating if the request was accepted
  logic       active;  // Flag indicating if the APU is active
  logic [1:0] apu_lat;  // Internal storage for APU latency


  logic [2:0]
      read_deps_req, read_deps_inflight, read_deps_waiting;  // Read dependencies for each state
  logic [1:0]
      write_deps_req,
      write_deps_inflight,
      write_deps_waiting;  // Write dependencies for each state
  logic read_dep_req, read_dep_inflight, read_dep_waiting;  // Combined read dependency flags
  logic write_dep_req, write_dep_inflight, write_dep_waiting;  // Combined write dependency flags

  logic stall_full, stall_type, stall_nack;  // Different types of stall signals


  // Request is valid if enabled and no stall
  assign valid_req = enable_i & !(stall_full | stall_type);
  // Assign the input write address to the request address
  assign addr_req = apu_waddr_i;

  assign req_accepted = valid_req & apu_gnt_i;  // Request is accepted if valid and APU grants


  // Request returned
  assign returned_req = valid_req & apu_rvalid_i & !valid_inflight & !valid_waiting;
  // Inflight returned
  assign returned_inflight = valid_inflight & (apu_rvalid_i) & !valid_waiting;
  // Waiting returned
  assign returned_waiting = valid_waiting & (apu_rvalid_i);


  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
      valid_inflight <= 1'b0;  // Reset inflight valid flag
      valid_waiting  <= 1'b0;  // Reset waiting valid flag
      addr_inflight  <= '0;  // Reset inflight address
      addr_waiting   <= '0;  // Reset waiting address
    end else begin
      valid_inflight <= valid_inflight_dn;  // Update inflight valid flag
      valid_waiting  <= valid_waiting_dn;  // Update waiting valid flag
      addr_inflight  <= addr_inflight_dn;  // Update inflight address
      addr_waiting   <= addr_waiting_dn;  // Update waiting address
    end
  end

  always_comb begin
    valid_inflight_dn = valid_inflight;  // Default next state for inflight valid
    valid_waiting_dn  = valid_waiting;  // Default next state for waiting valid
    addr_inflight_dn  = addr_inflight;  // Default next state for inflight address
    addr_waiting_dn   = addr_waiting;  // Default next state for waiting address

    if (req_accepted & !returned_req) begin
      valid_inflight_dn = 1'b1;  // Mark as inflight if request accepted and not returned
      addr_inflight_dn  = addr_req;  // Store the requested address
      if (valid_inflight & !(returned_inflight)) begin
        valid_waiting_dn = 1'b1;  // If already inflight and not returned, move to waiting
        addr_waiting_dn  = addr_inflight;  // Store the inflight address in waiting
      end
      if (returned_waiting) begin
        valid_waiting_dn = 1'b1;  // If waiting returned, a new request can go to waiting
        addr_waiting_dn  = addr_inflight;  // Store the inflight address in waiting
      end
    end else if (returned_inflight) begin
      valid_inflight_dn = '0;  // Reset inflight state
      valid_waiting_dn  = '0;  // Reset waiting state
      addr_inflight_dn  = '0;  // Reset inflight address
      addr_waiting_dn   = '0;  // Reset waiting address
    end else if (returned_waiting) begin
      valid_waiting_dn = '0;  // Reset waiting state
      addr_waiting_dn  = '0;  // Reset waiting address
    end
  end


  // APU is active if there's an inflight or waiting request
  assign active = valid_inflight | valid_waiting;


  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
      apu_lat <= '0;  // Reset APU latency
    end else begin
      if (valid_req) begin
        // Update APU latency when a valid request arrives
        apu_lat <= apu_lat_i;
      end
    end
  end


  generate
    for (genvar i = 0; i < 3; i++) begin : gen_read_deps
      // Read dep on request
      assign read_deps_req[i]      = (read_regs_i[i] == addr_req) & read_regs_valid_i[i];
      // Read dep on inflight
      assign read_deps_inflight[i] = (read_regs_i[i] == addr_inflight) & read_regs_valid_i[i];
      // Read dep on waiting
      assign read_deps_waiting[i]  = (read_regs_i[i] == addr_waiting) & read_regs_valid_i[i];
    end
  endgenerate

  generate
    for (genvar i = 0; i < 2; i++) begin : gen_write_deps
      // Write dep on request
      assign write_deps_req[i]      = (write_regs_i[i] == addr_req) & write_regs_valid_i[i];
      // Write dep on inflight
      assign write_deps_inflight[i] = (write_regs_i[i] == addr_inflight) & write_regs_valid_i[i];
      // Write dep on waiting
      assign write_deps_waiting[i]  = (write_regs_i[i] == addr_waiting) & write_regs_valid_i[i];
    end
  endgenerate


  // Any read dependency in request state
  assign read_dep_req = |read_deps_req & valid_req & !returned_req;
  // Any read dependency in inflight
  assign read_dep_inflight = |read_deps_inflight & valid_inflight & !returned_inflight;
  // Any read dependency in waiting
  assign read_dep_waiting = |read_deps_waiting & valid_waiting & !returned_waiting;
  // Any write dependency in request state
  assign write_dep_req = |write_deps_req & valid_req & !returned_req;
  // Any write dependency in inflight
  assign write_dep_inflight = |write_deps_inflight & valid_inflight & !returned_inflight;
  // Any write dependency in waiting
  assign write_dep_waiting = |write_deps_waiting & valid_waiting & !returned_waiting;

  // Output read dependency
  assign read_dep_o = (read_dep_req | read_dep_inflight | read_dep_waiting) & is_decoding_i;
  // Output write dependency
  assign write_dep_o = (write_dep_req | write_dep_inflight | write_dep_waiting) & is_decoding_i;

  // Read dep for JALR
  assign read_dep_for_jalr_o = is_decoding_i & ((|read_deps_req & enable_i) |
                                               (|read_deps_inflight & valid_inflight) |
                                               (|read_deps_waiting & valid_waiting));

  // Stall if both inflight and waiting are full
  assign stall_full = valid_inflight & valid_waiting;

  // Stall based on latency
  assign stall_type = enable_i  & active & ((apu_lat_i==2'h1) |
                      ((apu_lat_i==2'h2) & (apu_lat==2'h3)) | (apu_lat_i==2'h3));
  // Stall if request is valid but not granted
  assign stall_nack = valid_req & !apu_gnt_i;
  // Combine all stall conditions
  assign stall_o = stall_full | stall_type | stall_nack;


  // Output the request signal to the APU
  assign apu_req_o = valid_req;


  always_comb begin
    // Default output write address
    apu_waddr_o = '0;
    // Output request address if returned
    if (returned_req) apu_waddr_o = addr_req;
    // Output inflight address if returned
    if (returned_inflight) apu_waddr_o = addr_inflight;
    // Output waiting address if returned
    if (returned_waiting) apu_waddr_o = addr_waiting;
  end


  // Output the active signal
  assign active_o = active;


  // Output for performance type
  assign perf_type_o = stall_type;
  // Output for performance contention
  assign perf_cont_o = stall_nack;

  // Indicate multi-cycle operation based on latency
  assign apu_multicycle_o = (apu_lat == 2'h3);
  // Indicate single-cycle if no inflight/waiting
  assign apu_singlecycle_o = ~(valid_inflight | valid_waiting);

endmodule
