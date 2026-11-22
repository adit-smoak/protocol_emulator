module scratch_register #(
    parameter WIDTH = 32
) (
    input wire clk,
    input wire rst_n,

    input wire exec,
    input wire [15:0] instr,

    input wire [WIDTH - 1: 0] out_data,
    input wire [WIDTH - 1: 0] mov_data,
    input wire jmp_pin,
    input wire osr_not_empty,

    output reg [WIDTH - 1: 0] x,
    output reg [WIDTH - 1: 0] y,
    output reg jump_condn
);
    localparam OP_JUMP = 3'b000, OP_OUT = 3'b011, OP_MOV = 3'b101, OP_SET = 3'b111;

    localparam DST_X = 3'b001, DST_Y = 3'010;

    localparam C_ALWAYS = 3'b000, C_NOTX = 3'b001, C_XDEC = 3'b010,
               C_NOTY   = 3'b011, C_YDEC = 3'b100, C_XNEY = 3'b101,
               C_PIN    = 3'b110, C_OSRE = 3'b111;

    wire [2:0] opcode = instr[15:13];
    wire [2:0] field  = instr[7:5];     // JMP: condition / SET,OUT,MOV: destination
    wire [4:0] imm5   = instr[4:0];     // SET data

    wire x_zero = (x == {W{1'b0}});
    wire y_zero = (y == {W{1'b0}});
    wire x_ne_y = (x != y);

    always @(*) begin
        case (field)
            C_ALWAYS: jump_condn = 1'b1;
            C_NOTX: jump_condn = x_zero;
            C_XDEC: jump_condn = ~x_zero;
            C_NOTY: jump_condn = y_zero;
            C_YDEC: jump_condn = ~y_zero;
            C_XNEY: jump_condn = x_ne_y;
            C_PIN: jump_condn: jmp_pin;
            default: jump_condn: osr_not_empty;
        endcase
    end

    reg x_wr_en, y_wr_en, x_dec, y_dec;
    reg [WIDTH - 1: 0] wr_data;

    always @(*) begin
        x_wr_en = 1'b0;
        y_wr_en = 1'b0;
        wr_data = {WIDTH{1'b0}};

        if (exec) begin
            case (opcode)
                OP_JUMP: begin
                    x_dec = (field == C_XDEC);
                    y_dec = (field == C_YDEC);
                end
                OP_SET: begin
                    wdata = {{(WIDTH-5){1'b0}}, imm5};
                    x_wr_en  = (field == DST_X);
                    y_wr_en  = (field == DST_Y);
                end
                OP_OUT: begin
                    wdata = out_data;
                    x_wr_en  = (field == DST_X);
                    y_wr_en  = (field == DST_Y);
                end
                OP_MOV: begin
                    wdata = mov_data;
                    x_wr_en  = (field == DST_X);
                    y_wr_en  = (field == DST_Y);
                end
                default: ;
            endcase
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x <= {W{1'b0}};
            y <= {W{1'b0}};
        end else begin
            if (x_wr_en)
                x <= wdata;
            else if (x_dec) 
                x <= x - 1'b1;
            
            if (y_wr_en)       
                y <= wdata;
            else if (y_dec) 
                y <= y - 1'b1;
        end
    end

endmodule

`default_nettype wire