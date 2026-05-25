`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/19/2026 11:18:54 PM
// Design Name: 
// Module Name: Uart_Byte_Tx
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
module Uart_Byte_Tx(
    input clk,
    input rst_n,
    input bps_clk,
    input [7:0] data_byte,
    input send_en,
    output reg uart_tx,
    output reg tx_done
);
    // 位计数器 0~10
    reg [3:0] bit_cnt;
    // 发送中标志
    reg tx_busy;
    always @(posedge clk or negedge rst_n) begin
        // rst_n → 复位所有
        if (!rst_n) begin
            // 复位所有
            bit_cnt <= 0;
            tx_done <= 0;
            uart_tx <= 1;
            tx_busy <= 1'b0;
        end else begin
            // send_en → 启动发送
            // 发送过程中，bps_clk → 位计数器 + 输出对应bit
            if (send_en && !tx_busy) begin
                tx_busy <= 1;
                bit_cnt <= 0;
                uart_tx <= 0; // 起始位

                // 发送数据位在后续的bps_clk中处理
            end else if (tx_busy) begin
            
                if (bps_clk) begin
                    bit_cnt <= bit_cnt + 1;
                    case (bit_cnt)
                        0: uart_tx <= data_byte[0];
                        1: uart_tx <= data_byte[1];
                        2: uart_tx <= data_byte[2];
                        3: uart_tx <= data_byte[3];
                        4: uart_tx <= data_byte[4];
                        5: uart_tx <= data_byte[5];
                        6: uart_tx <= data_byte[6];
                        7: uart_tx <= data_byte[7];
                        8: uart_tx <= 1; // 停止位
                        9: begin
                            tx_done <= 1;
                            tx_busy <= 0;
                            bit_cnt <= 0;
                        end
                    endcase
                end
            end else begin
                tx_done <= 0; // 等待下一次发送
            end
            // bps_clk → 位计数器 + 输出对应bit
        end
    end
endmodule
