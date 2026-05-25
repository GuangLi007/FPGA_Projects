`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/19/2026 11:01:08 PM
// Design Name: 
// Module Name: Clk_Div
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


module Clk_Div(
input Clk_In,
input rst_n,
output reg  Clk_Out
    );
//50_000_000 / 115200 = 434.02777777777777
integer Count;
always @(posedge Clk_In or negedge rst_n )
begin
    if(rst_n == 0)
    begin
        Count <= 0;
        Clk_Out <= 0;
    end
    else if(Count == 433)
    begin
        Count <= 0;
        Clk_Out <= 1;
    end
    else
    begin
        Count <= Count + 1;
        Clk_Out <= 0;

    end 

end



endmodule
