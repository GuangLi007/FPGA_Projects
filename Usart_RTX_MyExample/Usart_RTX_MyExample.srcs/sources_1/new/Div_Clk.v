module Div_Clk(
    input clk,
    input rst_n,
    output reg clk_bps
);

    // 50MHz / 115200 = 434
    reg [8:0] cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt <= 0;
            clk_bps <= 0;
        end else if (cnt == 433) begin
            cnt <= 0;
            clk_bps <= 1;
        end else begin
            cnt <= cnt + 1;
            clk_bps <= 0;
        end
    end

endmodule
