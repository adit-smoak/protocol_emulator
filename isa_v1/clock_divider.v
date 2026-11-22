// clock_divider slows down the SM w/o creating a new clock
// avg rate = clk / (div_int + div_frac / 256)
// SM only advances when tick = 1
// divided clock is not created so no clock tree and CDC issue, also fractional rates are possible with the "tick" method
// SMs speed is set by this clock
// 

`default_nettype none

module clock_divider #(
    parameter INT_W = 16,
    parameter FRAC_W = 8
) (
    input wire clk,
    input wire rst_n,
    input wire en,
    input wire restart,
    input wire [INT_W - 1: 0] div_int,
    input wire [FRAC_W - 1: 0] div_frac,

    output wire tick
);
    reg [INT_W - 1: 0] cnt;         // holds the number of cycles left in the current period - 1
    reg [FRAC_W - 1: 0] acc;        // decides whether next period is 1 cycle longer

    wire [FRAC_W: 0] acc_sum = {1'b0, acc} + {1'b0, div_frac}
    wire carry = acc_sum[FRAC_W];

    wire [INT_W - 1: 0] reload = div_int - 1'b1 + carry;

    assign tick = en & (cnt == {INT_W{1'b0}});

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt <= {INT_W{1'b0}};
            acc <= {FRAC_W{1'b0}};
        end else if (!en || restart) begin
            cnt <= {INT_W{1'b0}};       
            acc <= {FRAC_W{1'b0}};
        end else if (tick) begin
            cnt <= reload;
            acc <= acc_sum[FRAC_W - 1: 0];
        end else begin
            cnt <= cnt - 1'b0;
        end
    end

endmodule
`default_nettype wire
 