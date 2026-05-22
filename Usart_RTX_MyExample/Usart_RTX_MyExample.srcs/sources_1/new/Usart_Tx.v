`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/21/2026 10:16:07 PM
// Design Name: 
// Module Name: Usart_Tx
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


module Usart_Tx(
    input clk,
    input rst_n,
    input [7:0] data_byte,
    input send_en, //
    input clk_bps,
    output reg uart_tx,
    output reg tx_done

    );

    reg [3:0] bit_cnt;
    reg tx_busy;

    //发送部分
    always @(posedge clk or negedge rst_n) begin
        if (rst_n == 0) begin
            // 复位所有
            bit_cnt <= 0;
            tx_done <= 0;
            uart_tx <= 1;
            tx_busy <= 1'b0;
        end
        else if (send_en == 1 && tx_busy == 0) begin //发送且不繁忙,开始发送

            tx_busy <=1;
            bit_cnt <= 0;
            uart_tx <= 0; //起始位 ,拉低TX线,表示开始传输BIT

        end
        else if (tx_busy == 1) begin
            if (clk_bps == 1) begin
                if (bit_cnt == 9) begin
                    tx_done <= 1;
                    tx_busy <= 0;
                    bit_cnt <= 0;
                end else begin
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
                        8: uart_tx <= 1;
                    endcase
                end
            end
        end

    end

endmodule
