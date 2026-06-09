module hdmi_top (
    input  wire       clk_50m,
    input  wire       rst_n,
    output wire       hdmi1_clk_p, hdmi1_clk_n,
    output wire [2:0] hdmi1_data_p, hdmi1_data_n,
    output wire       hdmi1_oe,
    output wire       hdmi2_clk_p, hdmi2_clk_n,
    output wire [2:0] hdmi2_data_p, hdmi2_data_n,
    output wire       hdmi2_oe
);
    wire pixelclk, pixelclk5x, locked;
    wire reset_p = ~locked;
    wire fb_out, fb_in;
    BUFG bufg_fb (.I(fb_out), .O(fb_in));

    MMCME2_BASE #(
        .BANDWIDTH("OPTIMIZED"),
        .CLKOUT0_DIVIDE_F(25),
        .CLKOUT0_DUTY_CYCLE(0.5), .CLKOUT0_PHASE(0),
        .CLKOUT1_DIVIDE(5),
        .CLKOUT1_DUTY_CYCLE(0.5), .CLKOUT1_PHASE(0),
        .CLKFBOUT_MULT_F(12.5),
        .CLKFBOUT_PHASE(0),
        .DIVCLK_DIVIDE(1),
        .REF_JITTER1(0.01),
        .CLKIN1_PERIOD(20.0),
        .STARTUP_WAIT("FALSE")
    ) mmcm_inst (
        .CLKIN1(clk_50m),
        .CLKFBIN(fb_in),
        .RST(~rst_n),
        .PWRDWN(1'b0),
        .CLKOUT0(pixelclk),
        .CLKOUT1(pixelclk5x),
        .CLKFBOUT(fb_out),
        .LOCKED(locked)
    );

    // 640x480@60 timing
    localparam H_TOTAL = 800, H_SYNC = 96, H_BP = 48, H_ACT = 640, H_FP = 16;
    localparam V_TOTAL = 525, V_SYNC = 2,  V_BP = 33, V_ACT = 480, V_FP = 10;

    reg [9:0] hcnt, vcnt;
    wire h_ov = (hcnt == H_TOTAL - 1);
    wire v_ov = (vcnt == V_TOTAL - 1);

    always @(posedge pixelclk or posedge reset_p)
        if (reset_p) hcnt <= 0;
        else if (h_ov) hcnt <= 0;
        else hcnt <= hcnt + 1;

    always @(posedge pixelclk or posedge reset_p)
        if (reset_p) vcnt <= 0;
        else if (h_ov) vcnt <= v_ov ? 0 : vcnt + 1;

    wire hs = (hcnt < H_SYNC);
    wire vs = (vcnt < V_SYNC);
    wire de = (hcnt >= H_SYNC + H_BP && hcnt < H_SYNC + H_BP + H_ACT &&
               vcnt >= V_SYNC + V_BP && vcnt < V_SYNC + V_BP + V_ACT);

    // 8 color bars
    reg [7:0] red, green, blue;
    always @(*) begin
        if (!de) {red, green, blue} = 0;
        else case (hcnt[9:7])
            3'd0: {red, green, blue} = 24'hFF0000;
            3'd1: {red, green, blue} = 24'h00FF00;
            3'd2: {red, green, blue} = 24'h0000FF;
            3'd3: {red, green, blue} = 24'hFFFF00;
            3'd4: {red, green, blue} = 24'hFF00FF;
            3'd5: {red, green, blue} = 24'h00FFFF;
            3'd6: {red, green, blue} = 24'hFFFFFF;
            default: {red, green, blue} = 0;
        endcase
    end

    wire [9:0] tblue, tgreen, tred;

    tmds_encoder encb (.clk(pixelclk), .rst_p(reset_p), .din(blue),  .c0(hs), .c1(vs), .de(de), .dout(tblue));
    tmds_encoder encg (.clk(pixelclk), .rst_p(reset_p), .din(green), .c0(0),  .c1(0),  .de(de), .dout(tgreen));
    tmds_encoder encr (.clk(pixelclk), .rst_p(reset_p), .din(red),   .c0(0),  .c1(0),  .de(de), .dout(tred));

    serdes_4b_10to1 ser1 (
        .clkx5(pixelclk5x),
        .datain_0(tblue), .datain_1(tgreen), .datain_2(tred),
        .datain_3(10'b1111100000),
        .dataout_0_p(hdmi1_data_p[0]), .dataout_0_n(hdmi1_data_n[0]),
        .dataout_1_p(hdmi1_data_p[1]), .dataout_1_n(hdmi1_data_n[1]),
        .dataout_2_p(hdmi1_data_p[2]), .dataout_2_n(hdmi1_data_n[2]),
        .dataout_3_p(hdmi1_clk_p),     .dataout_3_n(hdmi1_clk_n)
    );

    serdes_4b_10to1 ser2 (
        .clkx5(pixelclk5x),
        .datain_0(tblue), .datain_1(tgreen), .datain_2(tred),
        .datain_3(10'b1111100000),
        .dataout_0_p(hdmi2_data_p[0]), .dataout_0_n(hdmi2_data_n[0]),
        .dataout_1_p(hdmi2_data_p[1]), .dataout_1_n(hdmi2_data_n[1]),
        .dataout_2_p(hdmi2_data_p[2]), .dataout_2_n(hdmi2_data_n[2]),
        .dataout_3_p(hdmi2_clk_p),     .dataout_3_n(hdmi2_clk_n)
    );

    assign hdmi1_oe = 1'b1;
    assign hdmi2_oe = 1'b1;

endmodule

module tmds_encoder (
    input            clk, rst_p,
    input      [7:0] din,
    input            c0, c1, de,
    output reg [9:0] dout
);
    parameter CTL0 = 10'b1101010100;
    parameter CTL1 = 10'b0010101011;
    parameter CTL2 = 10'b0101010100;
    parameter CTL3 = 10'b1010101011;

    reg [3:0] n1d;
    reg [7:0] din_q;
    always @(posedge clk) begin
        din_q <= din;
        n1d <= din[0] + din[1] + din[2] + din[3] + din[4] + din[5] + din[6] + din[7];
    end

    wire decision1;
    assign decision1 = (n1d > 4'h4) | ((n1d == 4'h4) & (din_q[0] == 1'b0));

    wire [8:0] q_m;
    assign q_m[0] = din_q[0];
    assign q_m[1] = (decision1) ? ~(q_m[0] ^ din_q[1]) : (q_m[0] ^ din_q[1]);
    assign q_m[2] = (decision1) ? ~(q_m[1] ^ din_q[2]) : (q_m[1] ^ din_q[2]);
    assign q_m[3] = (decision1) ? ~(q_m[2] ^ din_q[3]) : (q_m[2] ^ din_q[3]);
    assign q_m[4] = (decision1) ? ~(q_m[3] ^ din_q[4]) : (q_m[3] ^ din_q[4]);
    assign q_m[5] = (decision1) ? ~(q_m[4] ^ din_q[5]) : (q_m[4] ^ din_q[5]);
    assign q_m[6] = (decision1) ? ~(q_m[5] ^ din_q[6]) : (q_m[5] ^ din_q[6]);
    assign q_m[7] = (decision1) ? ~(q_m[6] ^ din_q[7]) : (q_m[6] ^ din_q[7]);
    assign q_m[8] = (decision1) ? 1'b0 : 1'b1;

    reg [3:0] n1q_m, n0q_m;
    always @(posedge clk) begin
        n1q_m <= q_m[0] + q_m[1] + q_m[2] + q_m[3] + q_m[4] + q_m[5] + q_m[6] + q_m[7];
        n0q_m <= 4'h8 - (q_m[0] + q_m[1] + q_m[2] + q_m[3] + q_m[4] + q_m[5] + q_m[6] + q_m[7]);
    end

    reg [4:0] cnt;
    wire decision2, decision3;
    assign decision2 = (cnt == 5'h0) | (n1q_m == n0q_m);
    assign decision3 = (~cnt[4] & (n1q_m > n0q_m)) | (cnt[4] & (n0q_m > n1q_m));

    reg [1:0] de_reg, c0_reg, c1_reg;
    reg [8:0] q_m_reg;
    always @(posedge clk) begin
        de_reg  <= {de_reg[0], de};
        c0_reg  <= {c0_reg[0], c0};
        c1_reg  <= {c1_reg[0], c1};
        q_m_reg <= q_m;
    end

    always @(posedge clk or posedge rst_p) begin
        if (rst_p) begin
            dout <= 10'h0;
            cnt  <= 5'd0;
        end else begin
            if (de_reg[1]) begin
                if (decision2) begin
                    dout[9]   <= ~q_m_reg[8];
                    dout[8]   <= q_m_reg[8];
                    dout[7:0] <= (q_m_reg[8]) ? q_m_reg[7:0] : ~q_m_reg[7:0];
                    cnt <= (~q_m_reg[8]) ? (cnt + n0q_m - n1q_m) : (cnt + n1q_m - n0q_m);
                end else begin
                    if (decision3) begin
                        dout[9]   <= 1'b1;
                        dout[8]   <= q_m_reg[8];
                        dout[7:0] <= ~q_m_reg[7:0];
                        cnt <= cnt + {q_m_reg[8], 1'b0} + (n0q_m - n1q_m);
                    end else begin
                        dout[9]   <= 1'b0;
                        dout[8]   <= q_m_reg[8];
                        dout[7:0] <= q_m_reg[7:0];
                        cnt <= cnt - {~q_m_reg[8], 1'b0} + (n1q_m - n0q_m);
                    end
                end
            end else begin
                cnt <= 5'd0;
                case ({c1_reg[1], c0_reg[1]})
                    2'b00:   dout <= CTL0;
                    2'b01:   dout <= CTL1;
                    2'b10:   dout <= CTL2;
                    default: dout <= CTL3;
                endcase
            end
        end
    end
endmodule
