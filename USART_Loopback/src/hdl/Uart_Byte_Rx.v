
module Usart_Byte_Rx(
input  clk	,
input  rst_n	,
input rs232_rx,	
output reg [7:0] data_byte,
output reg data_valid	

);


//1. 异步信号同步：rs232_rx 是外部信号（来自 PC），进 FPGA 前要先过两级寄存器防亚稳态
// 2. 下降沿检测：空闲时 rx = 1，检测到 1→0 跳变 → 起始位来了
// 3. 重新计时：在下降沿时刻复位你自己的位计数器
// 4. 中间采样：等 217 个时钟（半个位时间）到达起始位中间 → 确认仍为低（防止毛刺误触发）
// 5. 逐位采样：之后每等 434 个时钟（一个位时间），在 data bit 正中采样
// 6. 停止位验证：收到 8 个数据位后，检查停止位是否为高

reg rx_sync1;  // 第一级打拍
reg rx_sync2;  // 第二级打拍（稳定的同步信号）
reg rx_sync3;  // 边沿检测延迟一拍

reg [7:0] rx_shift; // 数据移位寄存器

reg rx_negedge; // 下降沿检测信号

//状态机
parameter IDLE = 0, START = 1, DATA = 2, STOP = 3;
reg [1:0] state; // 状态寄存器  
reg [3:0] bit_cnt;  // 缺这行会导致 bit_cnt 无法使用，编译器会报错

// D 触发器
// 同步输入信号，防止亚稳态
// 这里使用三级寄存器同步，确保信号稳定

// 一般情况要考虑 reset的情况
// 这里我们假设 rst_n (_n低有效)是低有效的，
//所以在 rst_n 失效时，寄存器被复位到初始状态


always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rx_sync1 <= 1'b1; // 初始状态为高（空闲）
        rx_sync2 <= 1'b1;
        rx_sync3 <= 1'b1;
    end else begin
        rx_sync1 <= rs232_rx; // 同步输入信号
        rx_sync2 <= rx_sync1; // 二级同步
        rx_sync3 <= rx_sync2; // 三级同步
        rx_negedge <= ~rx_sync2 & rx_sync3;//下降沿脉冲 遇到下降沿为1
    end
    end


//改用 div_cnt 自己计数：

reg [8:0] div_cnt;  // 0~433


// 把状态机改成干净的 case 结构，每个状态一个分支，不会漏 end：
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= IDLE;
        div_cnt <= 0;
        bit_cnt <= 0;
        data_valid <= 0;
    end else begin
        case (state)
            IDLE: begin
                div_cnt <= 0;
                bit_cnt <= 0;
                data_valid <= 0;
                if (rx_negedge) state <= START;
            end
            START: begin
                div_cnt <= (div_cnt == 433) ? 0 : div_cnt + 1;
                if (div_cnt == 216) begin
                    if (rx_sync2 == 0)
                        state <= DATA;
                    else
                        state <= IDLE;
                end
            end
            DATA: begin
                div_cnt <= (div_cnt == 433) ? 0 : div_cnt + 1;
                if (div_cnt == 216) begin
                    rx_shift <= {rx_sync2, rx_shift[7:1]};
                    if (bit_cnt == 7) begin
                        bit_cnt <= 0;
                        state <= STOP;
                    end else begin
                        bit_cnt <= bit_cnt + 1;
                    end
                end
            end
            STOP: begin
                div_cnt <= (div_cnt == 433) ? 0 : div_cnt + 1;
                if (div_cnt == 216) begin
                    if (rx_sync2 == 1) begin
                        data_byte <= rx_shift;
                        data_valid <= 1;
                    end
                    state <= IDLE;
                end
            end
        endcase
    end
end

endmodule 

