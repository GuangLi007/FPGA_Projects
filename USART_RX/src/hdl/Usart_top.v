module Usart_top(
    input       clk,
    input       rst_n,
    input       rs232_rx,
    output [7:0] led
);

    wire [7:0] rx_data;
    wire rx_valid;

    Usart_Byte_Rx u_rx (
        .clk        (clk),
        .rst_n      (rst_n),
        .rs232_rx   (rs232_rx),
        .data_byte  (rx_data),
        .data_valid (rx_valid)
    );

    reg [7:0] led_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            led_reg <= 8'b0;
        else if (rx_valid)
            led_reg <= rx_data;
    end

    assign led = led_reg;

endmodule
