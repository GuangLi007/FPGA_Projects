module Top(
    input       clk,
    input       rst_n,
    input       uart_rx,
    output      uart_tx
);


    //内部连线 + 例化：
    wire clk_bps;
    wire [7:0] rx_data;
    wire       rx_done;
    wire tx_done;
    Div_Clk u_div (
        .clk     (clk),
        .rst_n   (rst_n),
        .clk_bps (clk_bps)
    );
    Usart_Rx u_rx (
        .clk       (clk),
        .rst_n     (rst_n),
        .usart_rx  (uart_rx),
        .data_byte (rx_data),
        .data_valid(rx_done)
    );
    Usart_Tx u_tx (
        .clk       (clk),
        .rst_n     (rst_n),
        .clk_bps   (clk_bps),
        .data_byte (rx_data),
        .send_en   (rx_done),
        .uart_tx   (uart_tx),
        .tx_done   (tx_done)
    );
    
    




    endmodule
