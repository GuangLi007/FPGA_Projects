//呼吸灯: LED 亮度在 1s 内从暗→亮→暗循环
//原理: PWM 占空比随时间变化 (0% → 100% → 0%)

module Top(
input clk,
input rst_n,
output reg led
    );

//50MHz时钟
parameter T_1MS = 50_000;      // 1ms 计数值
parameter T_1S  = 1000;        // 1000个1ms = 1s

//====== 1ms 定时器 ======
reg [15:0] cnt_1ms;
wire       en_1ms;             // 每1ms脉冲

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cnt_1ms <= 0;
    end else if (cnt_1ms == T_1MS - 1) begin
        cnt_1ms <= 0;
    end else begin
        cnt_1ms <= cnt_1ms + 1;
    end
end

assign en_1ms = (cnt_1ms == T_1MS - 1);

//====== 占空比计数器: 每1ms变化一次 ======
// 0 → 999 上升, 999 → 0 下降, 周期 2s
// duty 范围: 0~999, 对应占空比 0%~99.9%
reg [9:0] duty;
reg       up;                  // 1=增亮, 0=减暗

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        duty <= 0;
        up   <= 1;
    end else if (en_1ms) begin
        if (up) begin
            if (duty == T_1S - 1) begin
                duty <= duty - 1;
                up   <= 0;
            end else begin
                duty <= duty + 1;
            end
        end else begin
            if (duty == 0) begin
                duty <= duty + 1;
                up   <= 1;
            end else begin
                duty <= duty - 1;
            end
        end
    end
end

//====== PWM 发生器 ======
// 每1ms内, pwm_cnt 从 0 数到 49999
// LED亮: pwm_cnt < duty * 50
// 阈值 = duty * 50 (因为 50000/1000 = 50)
reg [15:0] pwm_cnt;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        pwm_cnt <= 0;
    end else if (pwm_cnt == T_1MS - 1) begin
        pwm_cnt <= 0;
    end else begin
        pwm_cnt <= pwm_cnt + 1;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        led <= 0;
    end else begin
        led <= (pwm_cnt < duty * 50);
    end
end

endmodule
