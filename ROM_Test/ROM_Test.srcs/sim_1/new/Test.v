`timescale 1ns / 1ps

module tb_rom;

    reg         clk;
    reg         ena;
    reg  [9:0]  addr;
    wire [15:0] douta;

    // 时钟生成: 50MHz -> 20ns 周期
    initial clk = 1;
    always #10 clk = ~clk;

    // 例化 ROM IP
    blk_mem_gen_0 u_rom (
        .clka   (clk),
        .ena    (ena),
        .addra  (addr),
        .douta  (douta)
    );



    // 测试序列
    integer i;
    initial begin
        // 初始化
        ena  = 0;
        addr = 0;

        // 等待复位稳定
        #100;
        ena = 1;

        // 遍历所有地址 0~1023，每个地址读一次
        for (i = 0; i < 1024; i = i + 1) begin
            addr = i;
            #20;  // 等待 2 个时钟周期（1 clk 读出 + 稳定）
        end

        // 特定地址检查
        addr = 0;      #20;  // 应输出 32768 (sin 0)
        addr = 256;    #20;  // 应输出 65535 (sin 90°)
        addr = 512;    #20;  // 应输出 32768 (sin 180°)
        addr = 768;    #20;  // 应输出 1     (sin 270°)
        addr = 1023;   #20;  // 应输出 ~32768 (sin 359.6°)

        // 步进测试: 每 8 个地址读一次，观察波形变化
        ena = 0; #40;
        ena = 1;
        for (i = 0; i < 1024; i = i + 8) begin
            addr = i;
            #20;
        end

        #100;
        $finish;
    end

    // 打印信息
    initial begin
        $monitor("t=%0t  addr=%3d  douta=%5d (0x%04h)", $time, addr, douta, douta);
    end

    // 生成 .vcd 文件供 gtkwave 查看
    initial begin
        $dumpfile("tb_rom.vcd");
        $dumpvars(0, tb_rom);
    end

endmodule
