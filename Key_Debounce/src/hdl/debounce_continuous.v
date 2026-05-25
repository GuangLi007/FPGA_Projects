module debounce_continuous (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       key_in,
    output wire       key_press
);
    parameter T_1MS   =   50_000;
    parameter CNT_NUM =       20;

    reg        key_sync1, key_sync2;
    reg [15:0] cnt_1ms;
    reg [CNT_NUM-1:0] shift_reg;
    reg        key_stable;
    reg        key_stable_r1;
    wire       all_same;
    integer    i;

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
            cnt_1ms <= 0;
        else if (cnt_1ms == T_1MS - 1)
            cnt_1ms <= 0;
        else
            cnt_1ms <= cnt_1ms + 1;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            shift_reg <= {CNT_NUM{1'b1}};
        else if (cnt_1ms == T_1MS - 1)
            shift_reg <= {shift_reg[CNT_NUM-2:0], key_sync2};
    end

    always @(*) begin
        all_same = 1'b1;
        for (i = 1; i < CNT_NUM; i = i + 1) begin
            if (shift_reg[i] != shift_reg[0])
                all_same = 1'b0;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            key_stable <= 1'b1;
        else if (all_same)
            key_stable <= shift_reg[0];
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            key_stable_r1 <= 1'b1;
        else
            key_stable_r1 <= key_stable;
    end

    assign key_press = key_stable_r1 & ~key_stable;

endmodule
