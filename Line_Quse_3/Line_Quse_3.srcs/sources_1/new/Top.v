//设计 通过开关控制LED的亮灭
//8位开关对应LED在1s内的亮灭状态 每一位控制 0.125s

module Top(
input clk,
input rst_n,
input [7:0] SW,
output reg led
    );

    //50MHz时钟, 0.125s = 6,250,000 cycles
    parameter T = 6_250_000;

    integer cnt;
    reg [2:0] Control;

    always @(posedge clk or negedge rst_n) begin
        if (rst_n == 0) begin
            cnt <= 0;
            led <= 0;
            Control <= 0;
        end else begin
            cnt <= cnt + 1;
            Control <= cnt / T;

            if (cnt == 50_000_000 - 1) begin
                cnt <= 0;
                Control <= 0;
            end

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
    end



endmodule
