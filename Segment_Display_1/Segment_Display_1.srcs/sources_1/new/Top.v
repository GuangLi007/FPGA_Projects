// GPIO直驱8位数码管模板
// 相比HC595方案, 段选和位选各占8个GPIO引脚, 共16个
// 优点: 无需串行驱动, 代码简单直观, 适合初学者理解动态扫描原理
// 缺点: 占用引脚多 (16 vs 3)

module HEX8_GPIO (
    input  wire       clk,        // 系统时钟 50MHz
    input  wire       reset_n,    // 复位, 低电平有效
    input  wire [7:0] sw,         // 拨码开关输入
    output reg  [7:0] seg,        // 段选: {dp,g,f,e,d,c,b,a}, 低电平有效(共阳极)
    output reg  [7:0] sel         // 位选: 高电平选中对应位 (与HC595版一致)
);

//=====================================================================
// 1. 刷新计时: 产生1ms脉冲, 用于动态扫描
//=====================================================================
// 动态扫描原理: 人眼余晖效应约20ms, 8位每1ms切换一位
// 一周期8ms > 125Hz, 无闪烁. 过慢会闪烁, 过快则亮度不均

parameter CLK_FREQ = 50_000_000;    // 50MHz
parameter SCAN_FREQ = 1000;         // 1kHz 扫描频率
parameter SCAN_CNT_MAX = CLK_FREQ / SCAN_FREQ - 1;  // 49999

reg [15:0] scan_cnt;

always @(posedge clk or negedge reset_n) begin
    if (!reset_n)
        scan_cnt <= 0;
    else if (scan_cnt == SCAN_CNT_MAX)
        scan_cnt <= 0;
    else
        scan_cnt <= scan_cnt + 1;
end

wire scan_tick = (scan_cnt == SCAN_CNT_MAX);  // 每1ms脉冲

// 2. 位选轮询: 循环移位, 依次点亮每一位
// 移位寄存器方式: 初始=0000_0001, 每1ms左移一位
// 技巧: 用移位代替case, 综合资源更省, 且扩展方便

always @(posedge clk or negedge reset_n) begin
    if (!reset_n)
        sel <= 8'b0000_0001;               // 从第1位(最右边)开始
    else if (scan_tick) begin
        if (sel == 8'b1000_0000)
            sel <= 8'b0000_0001;            // 循环回第1位
        else
            sel <= sel << 1;                // 左移选下一位
    end
end
// 3. 数据选择: 当前选中的位显示什么数字

// sw[3:0] 控制第1位, sw[7:4] 控制第2位
// 第3~8位固定显示 1~6, 用于直观验证所有位是否正常

reg [3:0] hex_data;  // 当前位要显示的4位十六进制数

always @(*) begin
    case (sel)
        8'b0000_0001: hex_data = sw[3:0];   // 位1: 拨码开关低4位
        8'b0000_0010: hex_data = sw[7:4];   // 位2: 拨码开关高4位
        8'b0000_0100: hex_data = 4'd1;      // 位3: 固定1
        8'b0000_1000: hex_data = 4'd2;      // 位4: 固定2
        8'b0001_0000: hex_data = 4'd3;      // 位5: 固定3
        8'b0010_0000: hex_data = 4'd4;      // 位6: 固定4
        8'b0100_0000: hex_data = 4'd5;      // 位7: 固定5
        8'b1000_0000: hex_data = 4'd6;      // 位8: 固定6
        default:      hex_data = 4'd0;
    endcase
end


// 4. 段码查找表: 将4位 hex 转换为7段码+小数点

// 共阳极: 0=亮, 1=灭   (共阴极则反过来)
// seg[7]=dp, [6]=g, [5]=f, [4]=e, [3]=d, [2]=c, [1]=b, [0]=a
//
// 常见段码速记: "0"=0xC0(1100_0000), "8"=0x80(1000_0000)
// 数字越大段码值越小(亮的段越多)
//
// 【段码表(共阳极)】
//   0: 0xC0   1: 0xF9   2: 0xA4   3: 0xB0
//   4: 0x99   5: 0x92   6: 0x82   7: 0xF8
//   8: 0x80   9: 0x90   A: 0x88   B: 0x83
//   C: 0xC6   D: 0xA1   E: 0x86   F: 0x8E

always @(*) begin
    case (hex_data)
        4'h0: seg = 8'b1100_0000;  // 0
        4'h1: seg = 8'b1111_1001;  // 1
        4'h2: seg = 8'b1010_0100;  // 2
        4'h3: seg = 8'b1011_0000;  // 3
        4'h4: seg = 8'b1001_1001;  // 4
        4'h5: seg = 8'b1001_0010;  // 5
        4'h6: seg = 8'b1000_0010;  // 6
        4'h7: seg = 8'b1111_1000;  // 7
        4'h8: seg = 8'b1000_0000;  // 8
        4'h9: seg = 8'b1001_0000;  // 9
        4'ha: seg = 8'b1000_1000;  // A
        4'hb: seg = 8'b1000_0011;  // B
        4'hc: seg = 8'b1100_0110;  // C
        4'hd: seg = 8'b1010_0001;  // D
        4'he: seg = 8'b1000_0110;  // E
        4'hf: seg = 8'b1000_1110;  // F
        default: seg = 8'b1111_1111;  // 全灭
    endcase
end


// 使用说明:
//   引脚分配 (参考GPIO2扩展口数码管模块):
//     seg[0]→GPIO2_18→M6  (A段)       sel[0]→GPIO2_16→L6  (位1)
//     seg[1]→GPIO2_22→P4  (B段)       sel[1]→GPIO2_17→M5  (位2)
//     seg[2]→GPIO2_25→N3  (C段)       sel[2]→GPIO2_14→J5  (位3)
//     seg[3]→GPIO2_20→N4  (D段)       sel[3]→GPIO2_15→K6  (位4)
//     seg[4]→GPIO2_19→N5  (E段)       sel[4]→GPIO2_12→R16 (位5)
//     seg[5]→GPIO2_21→P6  (F段)       sel[5]→GPIO2_13→R14 (位6)
//     seg[6]→GPIO2_23→P5  (G段)       sel[6]→GPIO2_10→P17 (位7)
//     seg[7]→GPIO2_24→P2  (DP点)      sel[7]→GPIO2_11→R17 (位8)
//
//   共阳极/共阴极适配:
//     如果模块是共阴极, 将段码表取反: seg = ~段码值
//     如果位选是低电平有效, 将sel取反输出


endmodule
