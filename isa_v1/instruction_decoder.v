`timescale 1ns/1ps
`default_nettype none

module instruction_decoder (
    input wire [15:0] instruction,
    output wire [11:0] operand,
    output wire is_set,
    output wire is_jmp,
    output wire is_wait,
    output wire legal
);
    wire [3:0] opcode;
    assign operand = instruction[11:0];
    assign opcode = instruction[15:12];
    assign is_set = (opcode == 4'd1);
    assign is_wait = (opcode == 4'd2);
    assign is_jmp = (opcode == 4'd3);

    assign legal = (is_set && operand[11:1] == 11'd0) || 
                   (is_wait && operand == 12'd0) ||
                   (is_jmp && operand[11:4] == 8'd0);
endmodule