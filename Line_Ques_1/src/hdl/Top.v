//任务: LED亮0.25s,熄灭0.75s,循环

// 点
// 1 计数器 尺子,可以在计数的中间值做一些事情
// 2 计数器可 取中间值,在任意时刻操作


module Top(
    input clk,
    input rst_n,
    output reg led
);
// 50MHz 25_000_000 0.5s

reg [25:0] Count;

//1 在不同的阶段做不同的事情
//2 注意 计数-1的问题!!


always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        Count <= 0;
        led <= 0;
    end

    else if (Count < 12_500_000-1) begin
        led <= 1;
        Count <= Count + 1;
    end 

    else if (Count < 50_000_000) begin
        led <= 0;
        Count <= Count + 1;
    end

    else begin
        Count <= 0;
    end 

end


endmodule