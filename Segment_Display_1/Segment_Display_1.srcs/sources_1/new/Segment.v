//数码管显示模块
module Segment(
input clk,
input Reset_n,
input Display,
output reg [7:0] seg,
output reg [7:0] sel
);

parameter Clk_Freq = 50_000_000;
parameter Switch_Freq = 1000;
parameter Switch_Count = Clk_Freq / Switch_Freq; //



//创建 查找表
always @(*) begin
    case (hex)
        4'h0: seg = 7'b1000000;
        4'h1: seg = 7'b1111001;  // b=0,c=0
        4'h2: seg = 7'b0100100;
        4'h3: seg = 7'b0110000;
        4'h4: seg = 7'b0011001;
        4'h5: seg = 7'b0010010;
        4'h6: seg = 7'b0000010;
        4'h7: seg = 7'b1111000;
        4'h8: seg = 7'b0000000;  // 全亮
        4'h9: seg = 7'b0010000;
        4'ha: seg = 7'b0001000;  // A
        4'hb: seg = 7'b0000011;  // b
        4'hc: seg = 7'b1000110;  // C
        4'hd: seg = 7'b0100001;  // d
        4'he: seg = 7'b0000110;  // E
        4'hf: seg = 7'b0001110;  // F
    endcase
end

endmodule
