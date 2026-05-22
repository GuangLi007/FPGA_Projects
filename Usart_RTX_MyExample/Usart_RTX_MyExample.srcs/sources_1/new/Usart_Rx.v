`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/21/2026 10:15:55 PM
// Design Name: 
// Module Name: Usart_Rx
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Usart_Rx(
input clk,
input rst_n,
input usart_rx,
output reg [7:0] data_byte,
output reg data_valid
    );

    parameter IDLE = 0, START = 1, DATA = 2, STOP = 3;
    reg [1:0] state; // 状态寄存器
    reg [3:0] bit_cnt;  // 位计数器
    reg [8:0] div_cnt;  // 波特率分频计数器
    reg [7:0] rx_shift; // 数据移位寄存器
    reg rx_sync1, rx_sync2, rx_sync3; // 同步寄存器
    reg rx_negedge; // 下降沿检测信号

    // 同步输入信号，防止亚稳态
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_sync1 <= 1'b1; // 初始状态为高（空闲）
            rx_sync2 <= 1'b1;
            rx_sync3 <= 1'b1;
        end else begin
            rx_sync1 <= usart_rx; // 同步输入信号
            rx_sync2 <= rx_sync1; // 二级同步       
            rx_sync3 <= rx_sync2; // 三级同步
            rx_negedge <= ~rx_sync2 & rx_sync3; // 下降沿
            //外部信号闲置是低电平，当检测到下降沿时，rx_negedge会变为1
            //当 usart_rx 从高变低时，rx_sync3 仍为高，而 rx_sync2 已经变为低，因此 ~rx_sync2 & rx_sync3 就会产生一个短暂的高电平脉冲，表示检测到下降沿
        end
    end
    
    // 状态机
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            bit_cnt <= 0;
            div_cnt <=0;
            data_byte <= 0;
            data_valid <= 0;
        end else begin
            case (state)
                IDLE: begin
                    data_valid <= 0; // 数据无效
                    if (rx_negedge) begin // 检测到起始位
                        state <= START;
                        bit_cnt <= 0;
                        div_cnt <= 0;
                    end
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
