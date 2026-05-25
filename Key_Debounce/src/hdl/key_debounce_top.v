module key_debounce_top (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       key_in,
    output reg        led_out
);

    wire key_press;

    debounce_delay u_debounce (
        .clk      (clk),
        .rst_n    (rst_n),
        .key_in   (key_in),
        .key_press(key_press)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            led_out <= 1'b0;
        else if (key_press)
            led_out <= ~led_out;
    end

endmodule
