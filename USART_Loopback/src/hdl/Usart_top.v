module Usart_top(
    input       clk,
    input       rst_n,
    input       uart_rx,
    output      uart_tx
);

    wire bps_clk;
    wire [7:0] rx_data;
    wire       rx_done;

    Clk_Div u_clk_div (
        .Clk_In (clk),
        .rst_n  (rst_n),
        .Clk_Out(bps_clk)
    );

    Usart_Byte_Rx u_rx (
        .clk       (clk),
        .rst_n     (rst_n),
        .rs232_rx  (uart_rx),
        .data_byte (rx_data),
        .data_valid(rx_done)
    );

    Uart_Byte_Tx u_tx (
        .clk       (clk),
        .rst_n     (rst_n),
        .bps_clk   (bps_clk),
        .data_byte (rx_data),
        .send_en   (rx_done),
        .uart_tx   (uart_tx),
        .tx_done   ()
    );

endmodule
