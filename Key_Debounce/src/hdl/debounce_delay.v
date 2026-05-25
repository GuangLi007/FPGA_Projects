module debounce_delay (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       key_in,
    output wire       key_press
);
    parameter T_20MS = 1_000_000;

    reg        key_sync1, key_sync2;
    reg [19:0] cnt;
    reg        key_sampled;
    reg        key_sampled_r1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            key_sync1 <= 1'b1;
            key_sync2 <= 1'b1;
        end else begin
            key_sync1 <= key_in;
            key_sync2 <= key_sync1;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            cnt <= 0;
        else
            cnt <= cnt + 1;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            key_sampled <= 1'b1;
        else if (cnt == T_20MS - 1)
            key_sampled <= key_sync2;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            key_sampled_r1 <= 1'b1;
        else
            key_sampled_r1 <= key_sampled;
    end

    assign key_press = key_sampled_r1 & ~key_sampled;

endmodule
