//类似任务3, SW控制led
//但是在这次任务中, 需要在2s的动态变化之间加上1s的静态变化
//即led在2s内动态变化, 在1s内保持不变, 然后再重复这个过程

module Top(
input clk,
input rst_n,
input [7:0] SW,
output reg led
    );

parameter DYNAMIC = 1, STATIC = 2;
parameter T = 6_250_000;

reg [1:0] state;
reg [2:0] Control;
reg [31:0] counter;7
reg [1:0] seg_cnt;   // 记录当前state持续了几个1s

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        counter <= 0;
        Control <= 0;
        state <= DYNAMIC;
        seg_cnt <= 0;
        led <= 0;
    end else begin
        counter <= counter + 1;
        Control <= counter / T;

        if (counter == 50_000_000 - 1) begin
            counter <= 0;
            Control <= 0;
            if (state == DYNAMIC) begin
                if (seg_cnt == 1) begin       // 已持续2s → 切静态
                    state <= STATIC;
                    seg_cnt <= 0;
                end else begin
                    seg_cnt <= seg_cnt + 1;   // 第一个1s结束
                end
            end else begin                     // STATIC
                state <= DYNAMIC;              // 持续1s后切回动态
                seg_cnt <= 0;
            end
        end

        if (state == DYNAMIC) begin
            case (Control)
                0: led <= SW[0];
                1: led <= SW[1];
                2: led <= SW[2];
                3: led <= SW[3];
                4: led <= SW[4];
                5: led <= SW[5];
                6: led <= SW[6];
                7: led <= SW[7];
                default: led <= led;
            endcase
        end
        // STATIC: led保持不动 (不赋值即保持)
    end
end

endmodule
