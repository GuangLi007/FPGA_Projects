module serdes_4b_10to1 (
    input         clkx5,
    input  [9:0]  datain_0, datain_1, datain_2, datain_3,
    output        dataout_0_p, dataout_0_n,
    output        dataout_1_p, dataout_1_n,
    output        dataout_2_p, dataout_2_n,
    output        dataout_3_p, dataout_3_n
);
    wire [4:0] h0 = {datain_0[8], datain_0[6], datain_0[4], datain_0[2], datain_0[0]};
    wire [4:0] l0 = {datain_0[9], datain_0[7], datain_0[5], datain_0[3], datain_0[1]};
    wire [4:0] h1 = {datain_1[8], datain_1[6], datain_1[4], datain_1[2], datain_1[0]};
    wire [4:0] l1 = {datain_1[9], datain_1[7], datain_1[5], datain_1[3], datain_1[1]};
    wire [4:0] h2 = {datain_2[8], datain_2[6], datain_2[4], datain_2[2], datain_2[0]};
    wire [4:0] l2 = {datain_2[9], datain_2[7], datain_2[5], datain_2[3], datain_2[1]};
    wire [4:0] h3 = {datain_3[8], datain_3[6], datain_3[4], datain_3[2], datain_3[0]};
    wire [4:0] l3 = {datain_3[9], datain_3[7], datain_3[5], datain_3[3], datain_3[1]};

    reg [2:0] mod5;
    reg [4:0] sh0h, sh0l, sh1h, sh1l, sh2h, sh2l, sh3h, sh3l;

    always @(posedge clkx5) begin
        mod5 <= (mod5 == 3'd4) ? 3'd0 : mod5 + 3'd1;
        {sh0h, sh0l, sh1h, sh1l, sh2h, sh2l, sh3h, sh3l} <=
            (mod5 == 3'd4) ? {h0, l0, h1, l1, h2, l2, h3, l3} :
            {sh0h[3:0], 1'b0, sh0l[3:0], 1'b0,
             sh1h[3:0], 1'b0, sh1l[3:0], 1'b0,
             sh2h[3:0], 1'b0, sh2l[3:0], 1'b0,
             sh3h[3:0], 1'b0, sh3l[3:0], 1'b0};
    end

    wire d0, d1, d2, d3;
    ODDR #(.DDR_CLK_EDGE("SAME_EDGE"), .INIT(1'b0), .SRTYPE("SYNC")) oddr0 (.Q(d0), .C(clkx5), .CE(1'b1), .D1(sh0h[0]), .D2(sh0l[0]), .R(1'b0), .S(1'b0));
    ODDR #(.DDR_CLK_EDGE("SAME_EDGE"), .INIT(1'b0), .SRTYPE("SYNC")) oddr1 (.Q(d1), .C(clkx5), .CE(1'b1), .D1(sh1h[0]), .D2(sh1l[0]), .R(1'b0), .S(1'b0));
    ODDR #(.DDR_CLK_EDGE("SAME_EDGE"), .INIT(1'b0), .SRTYPE("SYNC")) oddr2 (.Q(d2), .C(clkx5), .CE(1'b1), .D1(sh2h[0]), .D2(sh2l[0]), .R(1'b0), .S(1'b0));
    ODDR #(.DDR_CLK_EDGE("SAME_EDGE"), .INIT(1'b0), .SRTYPE("SYNC")) oddr3 (.Q(d3), .C(clkx5), .CE(1'b1), .D1(sh3h[0]), .D2(sh3l[0]), .R(1'b0), .S(1'b0));

    OBUFDS #(.IOSTANDARD("DEFAULT"), .SLEW("SLOW")) obuf0 (.O(dataout_0_p), .OB(dataout_0_n), .I(d0));
    OBUFDS #(.IOSTANDARD("DEFAULT"), .SLEW("SLOW")) obuf1 (.O(dataout_1_p), .OB(dataout_1_n), .I(d1));
    OBUFDS #(.IOSTANDARD("DEFAULT"), .SLEW("SLOW")) obuf2 (.O(dataout_2_p), .OB(dataout_2_n), .I(d2));
    OBUFDS #(.IOSTANDARD("DEFAULT"), .SLEW("SLOW")) obuf3 (.O(dataout_3_p), .OB(dataout_3_n), .I(d3));
endmodule
