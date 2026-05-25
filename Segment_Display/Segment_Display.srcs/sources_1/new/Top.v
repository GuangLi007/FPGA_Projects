module Top (
    input  wire       clk,
    input  wire       reset_n,
    input  wire [7:0] sw,
    output wire       ds,
    output wire       sh_cp,
    output wire       st_cp
);

    wire [15:0] hc595_data;

    Seg_Control u_seg (
        .clk     (clk),
        .reset_n (reset_n),
        .sw      (sw),
        .data    (hc595_data)
    );

    Hc595_Driver u_driver (
        .clk     (clk),
        .reset_n (reset_n),
        .data    (hc595_data),
        .s_en    (1'b1),
        .ds      (ds),
        .sh_cp   (sh_cp),
        .st_cp   (st_cp)
    );

endmodule
