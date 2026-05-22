module Usart_top(
    input       clk,
    input       rst_n,
    output      uart_tx
);
    // 内部连线
    wire bps_clk;
    reg send_en;
    wire tx_done;

    reg [7:0] data_byte;

//     // 实例化 Clk_Div

//     vio_0 u_vio (
//     .clk        (clk),
//     .probe_out0 (data_byte),     // 8bit，从VIO写入
//     .probe_out1 (send_en),       // 1bit，从VIO写入
//     .probe_in0  (uart_tx),       // 1bit，观察串口输出
//     .probe_in1  (tx_done)        // 1bit，观察完成标志
// );



    Clk_Div u_clk_div (
        .Clk_In (clk),
        .rst_n  (rst_n),
        .Clk_Out(bps_clk)
    );
    // 实例化 Uart_Byte_Tx
    Uart_Byte_Tx u_uart_tx (
        .clk      (clk),
        .rst_n    (rst_n),
        .bps_clk  (bps_clk),
        .data_byte(data_byte),
        .send_en  (send_en),
        .uart_tx  (uart_tx),
        .tx_done  (tx_done)
    );
    // 下一步：产生 send_en 和 data_byte
    // 产生 send_en 和 data_byte
    reg [3:0] state;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= 0;
            send_en <= 0;
            data_byte <= 8'h00;
        end 
        else begin
            case (state)
                0: begin
                    send_en <= 1;
                    data_byte <= 8'h55; // 发送 0x55
                    state <= 1;
                end
                1: begin
                    send_en <= 0;
                    if (tx_done) state <= 2;
                end
                2: begin
                    // 可以在这里添加更多的状态来发送不同的数据
                    state <= 2  ; // 保持在这个状态，等待复位
                end
            endcase
        end
    end


endmodule