`timescale 1ns/1ps
`default_nettype none

module instruction_decoder (
    input wire [15:0] instruction,
    input wire [2:0] sideset_cnt,
    input wire sideset_en,
    output wire [7:0] operand,
    output wire is_set,
    output wire is_jmp,
    output wire is_wait,
    output wire legal
);
    wire [2:0] opcode;
    reg [4:0] delay, sideset;
    
    always @(*) begin
        case (sideset_cnt)
            3'd0:    delay = instruction[12:8];
            3'd1:    delay = {1'b0,    instruction[11:8]};
            3'd2:    delay = {2'b00,   instruction[10:8]};
            3'd3:    delay = {3'b000,  instruction[9:8]};
            3'd4:    delay = {4'b0000, instruction[8]};
            default: delay = 5'd0;    // 5 = all side-set; 6 and 7 aren't valid
        endcase
        if(sideset_en) begin
            case (sideset_cnt)
                3'd2: sideset = {4'b0000, instruction[11]};
                3'd3: sideset = {3'b000, instruction[11: 10]};
                3'd4: sideset = {2'b00, instruction[11: 9]};
                3'd5: sideset = {1'b0, instruction[11: 8]};
                default: sideset = 0;
            endcase
        end else begin
            case (sideset_cnt)
                3'd0: sideset = 0;
                3'd1: sideset = {4'b0000, instruction[12]};
                3'd2: sideset = {3'b000, instruction[12: 11]};
                3'd3: sideset = {2'b00, instruction[12: 10]};
                3'd4: sideset = {1'b0, instruction[12: 9]};
                3'd5: sideset = instruction[12: 8];
                default: sideset = 0;
            endcase
        end
    end
    
    assign operand = instruction[7:0];
    assign opcode = instruction[15:13];

    assign is_jmp = (opcode == 3'd0);
    assign is_wait = (opcode == 3'd1);
    assign is_set = (opcode == 3'd7);

    assign legal = (is_set && (operand[7:5] == 3'd0 || operand[7:5] == 3'd1 || operand[7:5] == 3'd2 || operand[7:5] == 3'd4)) || 
                   (is_wait && operand[6:5] != 2'd3) ||
                   (is_jmp);
endmodule