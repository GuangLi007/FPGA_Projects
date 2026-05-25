module Seg_Control (
    input  wire       clk,
    input  wire       reset_n,
    input  wire [7:0] sw,
    output reg  [15:0] data
);

    reg [15:0] scan_cnt;
    reg [7:0]  sel;
    reg [6:0]  seg;
    reg [3:0]  hex;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n)
            scan_cnt <= 0;
        else if (scan_cnt == 49999)
            scan_cnt <= 0;
        else
            scan_cnt <= scan_cnt + 1;
    end

    wire scan_tick = (scan_cnt == 49999);

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n)
            sel <= 8'b0000_0001;
        else if (scan_tick) begin
            if (sel == 8'b1000_0000)
                sel <= 8'b0000_0001;
            else
                sel <= sel << 1;
        end
    end

    always @(*) begin
        case (sel)
            8'b0000_0001: hex = sw[3:0];
            8'b0000_0010: hex = sw[7:4];
            8'b0000_0100: hex = 4'd1;
            8'b0000_1000: hex = 4'd2;
            8'b0001_0000: hex = 4'd3;
            8'b0010_0000: hex = 4'd4;
            8'b0100_0000: hex = 4'd5;
            8'b1000_0000: hex = 4'd6;
            default:      hex = 4'd0;
        endcase
    end

    always @(*) begin
        case (hex)
            4'h0: seg = 7'b1000000;
            4'h1: seg = 7'b1111001;
            4'h2: seg = 7'b0100100;
            4'h3: seg = 7'b0110000;
            4'h4: seg = 7'b0011001;
            4'h5: seg = 7'b0010010;
            4'h6: seg = 7'b0000010;
            4'h7: seg = 7'b1111000;
            4'h8: seg = 7'b0000000;
            4'h9: seg = 7'b0010000;
            4'ha: seg = 7'b0001000;
            4'hb: seg = 7'b0000011;
            4'hc: seg = 7'b1000110;
            4'hd: seg = 7'b0100001;
            4'he: seg = 7'b0000110;
            4'hf: seg = 7'b0001110;
            default: seg = 7'b1000000;
        endcase
    end

    always @(*) begin
        data = {1'b0, seg, sel};
    end

endmodule
