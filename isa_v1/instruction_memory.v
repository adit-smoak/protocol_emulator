// ============================================================================
// instruction_memory.v  --  32 x 16-bit instruction memory for a mini-PIO
//
//   * 1 synchronous write port  (driven by the program loader / host)
//   * NUM_RD asynchronous read ports (one per state machine)
//
// "Shared" means: one storage array, one write port, and a separate
// read mux per state machine. With a flip-flop array, an extra read port
// costs only another 16 x (32:1) mux; the storage is not duplicated.
//
// Reads are COMBINATIONAL: rd_data follows rd_addr in the same cycle.
// That is what lets the SM fetch, decode and execute the instruction at
// PC in a single clock, as on the RP2040.
//
// The array has NO reset on purpose: a non-reset flop is smaller, and
// software always loads a program before enabling a state machine.
// Keep the SM disabled out of reset so it never executes power-up junk.
//
// ============================================================================


`timescale 1ns/1ps
`default_nettype none


module instruction_memory #(
    parameter WIDTH = 16,
    parameter DEPTH = 32,
    parameter ADDR_WIDTH = 5,
    parameter NUM_READ_PORTS = 1
) (
    input wire clk,

    // write port
    input wire wr_en,
    input wire [AW-1:0] wr_addr,
    input wire [WIDTH-1:0] wr_data,

    // read port
    input  wire [NUM_READ_PORTS * ADDR_WIDTH - 1 : 0]  rd_addr,
    output wire  [NUM_READ_PORTS * WIDTH - 1 : 0] rd_data
);

    reg [WIDTH-1:0] mem [0:DEPTH-1];         // storage: DEPTH * WIDTH = 512 f/f


    always @(posedge clk) begin
        if (wr_en)
            mem[wr_addr] <= wr_data;
    end

    genvar i;
    generate
        for (i = 0; i < NUM_RD; i = i + 1) begin: g_rd
            assign rd_data[i * WIDTH +: WIDTH] = mem[rd_addr[i * AW +: AW]];
        end
    endgenerate

endmodule
`default_nettype wire