//任务 亮0.1s 灭0.1s 亮0.4s,灭0.4s 循环

//技巧 使用常数如下,可以以 1.让代码更清晰,也方便修改
//2.尤其是在仿真时,如果需要加快仿真速度,可以将这些常数改小
//3.这些常数和数字相乘,不会占用额外的资源,因为它们在编译时会被替换成具体的数字
// parameter kilo = 1000;
// parameter mega = 1000 * kilo;

module Top(
    input clk,
    input rest_n,
    output  reg led
);
parameter kilo = 1000;
parameter mega = 1000 * kilo;

integer count;
//50MHz 的时钟周期是 20ns,所以 0.1s 是 5 million 个时钟周期
//这里取公因数,也是时序的一个技巧!取最小时间段

parameter on_time = 5 * mega; //0.1s
parameter off_time = 5 * mega; //0.1s
parameter on_time_long = 20 * mega; //0.4s
parameter off_time_long = 20 * mega; //0.4s

always @(posedge clk or negedge rest_n) begin
    if (rest_n == 0) begin
        count <= 0;
        led <= 0;
    end
    //这里也可以不写 count<=某个直,直接写count == x,切换状态也是可以的,
    //但是这样会有一个问题,就是当 count 达到某个值时,状态会切换,但是 count 还会继续增加,直到达到下一个状态的条件,才会切换到下一个状态,这样就会有一个时间差,可能会导致 LED 的状态不稳定
    if (count < on_time) begin
        led <= 1;
    end else if (count < on_time + off_time) begin
        led <= 0;
    end else if (count < on_time + off_time + on_time_long) begin
        led <= 1;
    end else begin
        led <= 0;
    end

    if (count == 50_000_000) begin
        count <= 0; //当 count 达到 50 million 时,重置 count,重新开始循环
    end
    count <= count + 1;
end

endmodule
