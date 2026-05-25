module Hc595_Driver (
    input  wire       clk,
    input  wire       reset_n,
    input  wire [15:0] data,
    input  wire       s_en,
    output reg        ds,
    output reg        sh_cp,
    output reg        st_cp
);

    reg [15:0] r_data;
    reg [5:0]  cnt;
    reg        active;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            active <= 1'b0;
            cnt    <= 0;
            ds     <= 1'b0;
            sh_cp  <= 1'b0;
            st_cp  <= 1'b0;
            r_data <= 16'd0;
        end else if (!active) begin
            sh_cp <= 1'b0;
            st_cp <= 1'b0;
            if (s_en) begin
                active <= 1'b1;
                cnt    <= 1;
                r_data <= data;
                ds     <= data[15];
            end
        end else begin
            if (cnt == 33) begin
                st_cp  <= 1'b1;
                active <= 1'b0;
                cnt    <= 0;
            end else if (cnt[0]) begin
                sh_cp <= 1'b1;
                cnt   <= cnt + 1;
            end else begin
                sh_cp <= 1'b0;
                if (cnt < 31) begin
                    ds     <= r_data[14];
                    r_data <= {r_data[14:0], 1'b0};
                end
                cnt <= cnt + 1;
            end
        end
    end

endmodule
