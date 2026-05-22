# FPGA_Projects

ACX720 (XC7A35T) FPGA 学习项目合集。

## 项目列表

| # | 项目 | 说明 | 状态 |
|---|------|------|------|
| 1 | [Acx720_Led](Acx720_Led) | LED 流水灯 | ✅ v1.00 |
| 2 | [USART_TX](USART_TX) | UART 串口发送 (0x55) | ✅ |
| 3 | [USART_RX](USART_RX) | UART 串口接收 | ✅ |
| 4 | [VIO_Test](VIO_Test) | VIO IP 核调试 | ✅ |
| 5 | [USART_Loopback](USART_Loopback) | UART 环回 (RX→TX) | ✅ |
| 6 | [Usart_RTX_MyExample](Usart_RTX_MyExample) | 用户自建 UART 环回 | ✅ |
| 7 | [Line_Quse_3](Line_Quse_3) | 拨码开关控制 LED 多段时序 | ✅ |
| 8 | [Line_Quse_4](Line_Quse_4) | 状态机 2s 动态 + 1s 静态 | ✅ |
| 9 | [Breath_Led](Breath_Led) | 呼吸灯 (PWM) | ✅ |

## 开发环境

- **FPGA 芯片**: XC7A35T-2FGG484 (Artix-7)
- **开发板**: ACX720 (小梅哥)
- **工具**: Vivado 2025.2
- **时钟**: 50MHz (引脚 Y18)

## 目录结构

每个项目包含:
- `*.xpr` — Vivado 工程文件
- `*.srcs/sources_1/new/` — Verilog 源码
- `*.srcs/constrs_1/new/` — 引脚约束 (.xdc)

## 对应笔记

学习笔记见 [FPGA_Notes](https://github.com/GuangLi007/FPGA_Notes) 仓库。
