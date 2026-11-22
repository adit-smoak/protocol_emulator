module program_loader #(parameter ADDR_WIDTH = 5) (
    input wire clk,
    input wire rst_n,
    input wire spi_sclk,
    input wire spi_mosi,
    input wire spi_cs_n,


    output reg imem_wr_en,    
    output reg cfg_wr_en,
    output reg [ADDR_WIDTH - 1:0] wr_addr,
    output reg [15:0] wr_data,
    output wire loading                     // high while loading: hold SM in reset
);
    localparam CMD_IMEM = 8'h01, CMD_CFG = 8'h02;

    localparam S_CMD = 2'd0, S_ADDR = 2'd1, S_HI = 2'd2, S_LO = 2'd3;

    reg [2:0] sclk_s;
    reg [1:0] mosi_s;
    reg [1:0] cs_s;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            sclk_s <= 3'b000;
            mosi_s <= 2'b00;
            cs_s <= 2'b11;
        end else begin
            sclk_s <= {sclk_s[1:0], spi_sclk};
            mosi_s <= {mosi_s[0], spi_mosi};
            cs_s <= {cs_s[0], spi_cs_n};
        end
    end

    wire active = ~cs_s[1];
    wire sclk_rise = sclk_s[1] & ~sclk_s[2];
    wire mosi = mosi_s[1];

    reg [2:0] bit_cnt;
    reg [6:0] shreg;
    wire [7:0] rx_byte = {shreg, mosi};
    wire byte_done = active & sclk_rise & (bit_cnt == 3'd7);

    reg [1:0] state;
    reg [7:0] cmd;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            bit_cnt <= 3'd0;
            state <= S_CMD;
            cmd <= 8'h00;
            imem_wr_en <= 1'b0;
            cfg_wr_en <= 1'b0;
        end else begin
            imem_wr_en <= 1'b0;
            cfg_wr_en <= 1'b0;
            if(!active) begin
                bit_cnt <= 3'd0;
                state <= S_CMD;
                cmd = 8'h00;
            end else if (sclk_rise) begin
                bit_cnt <= bit_cnt + 1'b1;
                ig (bit_cnt == 3'd7) begin
                    case (state)
                        S_CMD: begin cmd <= rx_byte; state <= S_ADDR; end
                        S_ADDR: state <= S_HI;
                        S_HI: state <= S_LO;
                        S_LO: begin
                            imem_wr_en <= (cmd == CMD_IMEM);
                            cfg_wr_en <= (cmd == CMD_CFG);
                            state <= S_HI
                        end
                    endcase
                end
            end
        end
    end
    assign loading = active & (cmd == CMD_IMEM);

    reg [7:0] hi_byte;
    reg [ADDR_WIDTH-1:0] addr;

    always @(posedge clk) begin
        if(active & sclk_rise)
            shreg <= {shreg[5:0], mosi};
        if(byte_done) begin
            case(state)
                S_ADDR: addr <= rx_byte[ADDR_WIDTH-1:0];
                S_HI: hi_byte <= rx_byte;
                S_LO: begin
                    wr_data <= {hi_byte, rx_byte};
                    wr_addr <= addr;
                    addr <= addr + 1'b1;
                end
            endcase
        end
    end

endmodule
`default_nettype wire