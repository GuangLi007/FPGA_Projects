# FPGA_Projects

ACX720 (XC7A35T) FPGA 学习项目合集。

## 项目列表

| # | 项目 | 说明 | 状态 |
|---|------|------|------|
| 1 | [Acx720_Led](Acx720_Led) | LED 流水灯 | ✅ v1.00 |
| 2 | [USART_TX](USART_TX) | UART 串口发送 (0x55) | ✅ |
| 3 | [USART_RX](USART_RX) | UART 串口接收 | ✅ |
| 4 | [VIO_Test](VIO_Test) | VIO IP 核调试 | ✅ |
| 5 | [VIO_Test2](VIO_Test2) | VIO IP 核调试 (副本) | ✅ |
| 6 | [USART_Loopback](USART_Loopback) | UART 环回 (RX→TX) | ✅ |
| 7 | [Usart_RTX_MyExample](Usart_RTX_MyExample) | 用户自建 UART 环回 | ✅ |
| 8 | [Line_Ques_1](Line_Ques_1) | LED 亮 0.25s / 灭 0.75s | ✅ |
| 9 | [Line_Quse_2](Line_Quse_2) | 线性序列机 | ✅ |
| 10 | [Line_Quse_3](Line_Quse_3) | 拨码开关控制 LED 多段时序 | ✅ |
| 11 | [Line_Quse_4](Line_Quse_4) | 状态机 2s 动态 + 1s 静态 | ✅ |
| 12 | [Breath_Led](Breath_Led) | 呼吸灯 (PWM) | ✅ |
| 13 | [Key_Debounce](Key_Debounce) | 按键消抖 (连续/延时/状态机) | ✅ |
| 14 | [Segment_Display](Segment_Display) | 数码管显示 (HC595) | ✅ |
| 15 | [Segment_Display_1](Segment_Display_1) | 数码管显示 (HC595 + 段选) | ✅ |
| 16 | [ADC](ADC) | ADC 驱动 (SPI 通信) | ✅ |
| 17 | [RAM_Test](RAM_Test) | RAM IP 核测试 | ✅ |
| 18 | [ROM_Test](ROM_Test) | ROM IP 核测试 / 正弦波 | ✅ |
| 19 | [EMIO_Key](EMIO_Key) | Zynq PS EMIO GPIO 按键控制 LED (Vivado + Vitis) | ✅ |

## 开发环境

- **FPGA 芯片**: XC7A35T-2FGG484 (Artix-7)
- **开发板**: ACX720 (小梅哥)
- **工具**: Vivado 2025.2
- **时钟**: 50MHz (引脚 Y18)

## 目录结构

项目有两种格式:

**Vivado GUI 项目:**
- `*.xpr` — Vivado 工程文件
- `*.srcs/sources_1/new/` — Verilog 源码
- `*.srcs/constrs_1/new/` — 引脚约束 (.xdc)

**YAML 驱动项目 (FPGABuilder):**
- `fpga_project.yaml` — 工程描述
- `src/hdl/` — Verilog 源码
- `src/constraints/` — 引脚约束 (.xdc)

## 使用 FPGABuilder

YAML 驱动项目可使用 [FPGABuilder](https://github.com/anomalyco/FPGABuilder) 工具链构建:

```bash
# 初始化新工程
fpga-init

# 或手动: FPGABuilder init <Name> --vendor xilinx --part xc7a35tfgg484-2 --template basic --path .

# 完整构建 (综合+实现+比特流)
FPGABuilder build

# 仅综合 / 仅实现 / 仅比特流
FPGABuilder synth
FPGABuilder impl
FPGABuilder bitstream
```

## 烧录 (JTAG)

```bash
vivado -mode batch << 'EOF'
open_hw_manager
connect_hw_server
open_hw_target [lindex [get_hw_targets] 0]
set dev [lindex [get_hw_devices] 0]
set_property PROGRAM.FILE {build/bitstreams/<top>_top.bit} $dev
program_hw_devices $dev
close_hw_target [lindex [get_hw_targets] 0]
disconnect_hw_server
close_hw_manager
exit
EOF
```

## 对应笔记

学习笔记见 [FPGA_Notes](https://github.com/GuangLi007/FPGA_Notes) 仓库。
