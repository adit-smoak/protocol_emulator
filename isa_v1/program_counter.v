`timescale 1ns/1ps
`default_nettype none

module program_counter (
    input wire clk,
    input wire rst,
    input wire advance,
    input wire jump,
    input wire [3:0] jump_addr,
    output reg [3:0] pc
);
    always @(posedge clk) begin
        if (rst)
            pc <= 4'd0;
        else if (jump)
            pc <= jump_addr;
        else if (advance)
            pc <= pc + 4'd1;
        else
            pc <= pc;
    end
endmodule
`default_nettype wire
