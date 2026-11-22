module fifo #(
    parameter WIDTH = 32,
    parameter DEPTH = 4                                  // must be a power of 2 and >= 2
) (
    input wire clk,
    input wire rst_n,
    input wire wr_en,
    input wire [WIDTH - 1: 0] wr_data,
    input wire rd_en,
    input wire flush,
    output wire [WIDTH - 1: 0] rd_data,
    output wire full,
    output wire empty,
    output wire [$clog2(DEPTH): 0] level,
    output wire overflow,
    output wire underflow 
);
    localparam AW = $clog2(DEPTH);
    reg [AW: 0] wptr, rptr;

    reg [WIDTH - 1: 0] fifo [0: DEPTH - 1];

    always @(posedge clk) begin
        if (wr_en & !full & !flush) begin
            fifo[wptr[AW - 1: 0]] <= wr_data;
        end

    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            wptr <= 0;
        else if (flush) 
            wptr <= 0;
        else if (wr_en & !full & !flush) 
            wptr <= wptr + 1;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            rptr <= 0;
        else if (flush) 
            rptr <= 0;
        else begin
            if(!empty & rd_en) 
                rptr <= rptr + 1;
        end
    end

    assign level = wptr - rptr;
    assign rd_data = fifo[rptr[AW - 1: 0]];                                          // only check when not empty, else garbage value will be output
    assign full = (wptr[AW] != rptr[AW]) && (wptr[AW - 1: 0] == rptr[AW - 1: 0]);
    assign empty = (wptr == rptr);
    assign overflow = (wr_en && full);
    assign underflow = (rd_en && empty);

endmodule