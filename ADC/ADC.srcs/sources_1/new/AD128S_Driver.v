`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: AD128S_Driver
// Description: ADC128S102 SPI 主机驱动 (线性序列机实现)
// 时序: SPI Mode 0 (CPOL=0, CPHA=0), 帧长 16 SCLK
// 时钟: 50MHz → SCLK 可配 (默认 5MHz)
//////////////////////////////////////////////////////////////////////////////////

module AD128S_Driver(
    input  clk,          // 系统时钟 50MHz
    input  rst_n,        // 异步复位，低有效
    input  Conv_En,      // 启动转换（脉冲）
    input  [2:0] Addr,   // 通道地址 0~7
    input  SPI_Out,      // ADC DOUT (FPGA 输入)

    output reg Done,     // 转换完成（脉冲）
    output reg [11:0] data,  // 12位转换结果
    output reg SPI_Cs,   // ADC CS (FPGA 输出)
    output reg SPI_Clk,  // ADC SCLK (FPGA 输出)
    output reg SPI_Din   // ADC DIN (FPGA 输出)
);
    
    //━━━━━━━━━━━━━━━━━ 参数 ━━━━━━━━━━━━━━━━━
    parameter  Clk_Freq  = 50_000_000;
    parameter  SCLK_Freq = 5_000_000;          // SCLK 频率
    localparam Max_Cnt   = Clk_Freq / (SCLK_Freq * 2) - 1;  // 半周期 clk 数
    localparam LSM_MAX   = 34;                  // 线性序列机最大状态

    //━━━━━━━━━━━━━━━━━ 内部寄存器 ━━━━━━━━━━━━━━━━━
    reg  [7:0] Div_Cnt;          // 分频计数器
    reg  [5:0] LSM_Cnt;          // 线性序列机计数器 (0~34)
    reg        tx_busy;          // 发送中标志
    reg [15:0] tx_data;          // DIN 移位寄存器 (控制字)
    reg [15:0] rx_data;          // DOUT 移位寄存器 (接收数据)
    
    //━━━━━━━━━━━━━━━━━ 分频计数器 ━━━━━━━━━━━━━━━━━
    // Div_Cnt 从 0 计到 Max_Cnt, 每 Max_Cnt+1 个 clk 为一个半周期
    // 只在 tx_busy 时计数, 帧结束后停振以省功耗
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            Div_Cnt <= 0;
        else if (tx_busy) begin
            if (Div_Cnt == Max_Cnt)
                Div_Cnt <= 0;
            else
                Div_Cnt <= Div_Cnt + 1;
        end else
            Div_Cnt <= 0;
    end

    //━━━━━━━━━━━━━━━━━ 线性序列机计数器 ━━━━━━━━━━━━━━━━━
    // LSM_Cnt 在每个半周期末 (Div_Cnt == Max_Cnt) 递增
    // 范围 0~34, 共 35 个状态:
    //   0     : IDLE   (CS=1, SCLK=0)
    //   1     : START  (CS=0, 输出 DIN 首位)
    //   2~33  : 16 个 SCLK 周期 (2~33 = 32 半周期)
    //         偶数 (2,4...32): SCLK=1 (上升沿)
    //         奇数 (3,5...33): SCLK=0 (下降沿)
    //   34    : STOP   (CS=1, Done=1)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            LSM_Cnt <= 0;
        else if (tx_busy && Div_Cnt == Max_Cnt) begin
            if (LSM_Cnt == LSM_MAX)
                LSM_Cnt <= 0;
            else
                LSM_Cnt <= LSM_Cnt + 1;
        end
    end
    
    //━━━━━━━━━━━━━━━━━ 主状态逻辑 ━━━━━━━━━━━━━━━━━
    // 每个半周期输出 SPI 信号，同时完成 DIN 移位和 DOUT 捕获
    //
    // SPI Mode 0 时序说明:
    //   [CS=0] → [SCLK↑] ADC 捕获 DIN → [SCLK↓] ADC 更新 DOUT → 循环
    //   DIN: 状态 1 输出首位, 之后每次 SCLK↓ 更新下一位
    //   DOUT: 在 SCLK↑ 时刻捕获 (此时 DOUT 从上一次 ↓ 后已稳定)
    //
    // 捕获策略:
    //   DOUT 在 SCLK 下降沿被 ADC 更新, 经过 1 个半周期后 (Max_Cnt+1 clk)
    //   信号已稳定, 在下一个 SCLK 上升沿捕获
    //   捕获状态: 4,6,8...34 (共 16 次捕获 = 16 SCLK 周期)
    //   rx_data 左移入, 首次捕获 → MSB, 末次捕获 → LSB
    //
    // 数据格式:
    //   DIN 控制字: {Addr[2:0], 13'b0} (16 位, 地址在前 3 位)
    //   结果: rx_data[15:4] = {D11, D10, ..., D0} (12 位, MSB 对齐)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            SPI_Cs   <= 1;
            SPI_Clk  <= 0;
            SPI_Din  <= 0;
            Done     <= 0;
            data     <= 0;
            tx_busy  <= 0;
            tx_data  <= 0;
            rx_data  <= 0;
        end else begin
            //── 启动一次转换 ──
            if (Conv_En && !tx_busy) begin
                tx_busy <= 1;
                tx_data <= {Addr, 13'b0};  // 加载控制字
                LSM_Cnt <= 0;
            end

            //── 帧内时序 (每半周期触发) ──
            if (tx_busy && Div_Cnt == Max_Cnt) begin
                case (LSM_Cnt)
                    0: begin  //── IDLE ──
                        SPI_Cs  <= 1;
                        SPI_Clk <= 0;
                    end

                    1: begin  //── START: CS 拉低，输出 DIN 首位 ──
                        SPI_Cs  <= 0;
                        SPI_Din <= tx_data[15];
                    end

                    //── 2~33: 16 个 SCLK 周期 ──
                    //  偶数状态 (LSM_Cnt[0]=0): SCLK 上升沿
                    //  奇数状态 (LSM_Cnt[0]=1): SCLK 下降沿 + 移位
                    //
                    //  从状态 4 开始, 每两个 SCLK 周期捕获一次 DOUT
                    //  (因为状态 2 的上升沿时, ADC 还未产生有效 DOUT 数据)
                    //  状态 34 也捕获, 确保 16 次完整捕获

                    34: begin  //── STOP: 帧结束 (最后一次捕获 + 输出结果) ──
                        rx_data <= {rx_data[14:0], SPI_Out};
                        SPI_Cs  <= 1;
                        Done    <= 1;
                        data    <= rx_data[15:4];
                        tx_busy <= 0;
                    end

                    default: begin
                        if (LSM_Cnt >= 2 && LSM_Cnt <= 33) begin
                            if (LSM_Cnt[0]) begin
                                //── 奇数: SCLK 下降沿 ──
                                // ADC 在此沿更新 DOUT
                                // 同时移位 DIN, 准备下一位
                                SPI_Clk <= 0;
                                tx_data <= {tx_data[14:0], 1'b0};
                                SPI_Din <= tx_data[14];
                            end else begin
                                //── 偶数: SCLK 上升沿 ──
                                // ADC 在此沿捕获 DIN
                                // 同时捕获 DOUT (从上一次下降沿起已稳定)
                                SPI_Clk <= 1;
                                if (LSM_Cnt >= 4)
                                    rx_data <= {rx_data[14:0], SPI_Out};
                            end
                        end
                    end
                endcase

            //── 空闲时清除 Done 脉冲 ──
            end else if (!tx_busy) begin
                Done <= 0;
            end
        end
    end

endmodule

//
