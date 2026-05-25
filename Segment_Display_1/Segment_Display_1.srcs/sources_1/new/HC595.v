// 74HC595 Shift Register Module
//这个是模拟HC595的行为
//还有一个版本是直接驱动板上的HC595芯片的，那个版本需要连接实际的引脚

module HC595(
input wire sclk,        // Clock signal
input wire rclk,        // Latch signal
input wire DIO, // 4-bit data input
output reg [7:0] data_out // 8-bit data output
    );

// - 每来一个 SCLK 上升沿，所有 bit 向右移动一位，新的 bit 从 DIO 进入第 0 格
// - 最早进去的 bit 一路往右移

// - 只有 一根线，每次只传 1 bit（0 或 1）
// - 在 SCLK 上升沿被"拍"进移位寄存器
// - 要传 8 bit 就需要 8 个 SCLK 脉冲

// 1. 设 DIO → 放当前要发送的 bit
// 2. 脉冲 SCLK → 把 bit 移进去（0→1→0）
// 3. 重复 1~2 共 8 次（或 16 次）
// 4. 脉冲 RCLK → 锁存输出，数码管亮

always @(posedge sclk ) begin
    data_out <= {data_out[6:0], DIO}; // Shift right and insert new bit from DIO




end



endmodule
