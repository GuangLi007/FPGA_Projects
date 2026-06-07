`timescale 1ns / 1ps

module IIC_Bit_Shift(
    input clk,
    input Go,
    input        [5:0]  CMD,
    input rst_n,

    output  reg  [7:0]  Rx_Data,
    input        [7:0]  Tx_Data,
    output  reg         IIC_Sclk,
    inout               IIC_Sda,
    output  reg         Ack_o,
    output  reg         Trans_Done
);

 // ====== SDA 三态门控制 ======
    reg i2c_sdat_o;     // SDA 输出数据
    reg i2c_sdat_oe;    // SDA 输出使能（1=驱动，0=释放）

    // 开漏输出：只拉低不放高，释放时由上拉电阻拉高
    assign IIC_Sda = !i2c_sdat_o && i2c_sdat_oe ? 1'b0 : 1'bz;

    // ====== 时钟分频 ======
    parameter SYS_CLOCK = 50_000_000;   // 系统时钟 50MHz
    parameter SCL_CLOCK = 400_000;      // I2C SCL 频率 400kHz
    localparam SCL_CNT_M = SYS_CLOCK / SCL_CLOCK / 4 - 1;

    reg  [19:0]  div_cnt;       // 分频计数器（20位）
    reg          en_div_cnt;    // 分频计数器使能
    wire         sclk_plus;     // 分频脉冲

    assign sclk_plus = (div_cnt == SCL_CNT_M);

    // ====== 命令编码（独热码）======
    localparam 
        WR   = 6'b000001,   // 写操作
        STA  = 6'b000010,   // 产生起始条件
        RD   = 6'b000100,   // 读操作
        STO  = 6'b001000,   // 产生停止条件
        ACK  = 6'b010000,   // 产生应答
        NACK = 6'b100000;   // 产生非应答

    // ====== 状态机状态编码（独热码）======
    localparam
        IDLE      = 8'b00000001,
        GEN_STA   = 8'b00000010,
        WR_DATA   = 8'b00000100,
        RD_DATA   = 8'b00001000,
        CHECK_ACK = 8'b00010000,
        GEN_ACK   = 8'b00100000,
        GEN_STO   = 8'b01000000;

    reg [7:0]  state;      // 状态寄存器
    reg [4:0]  cnt;        // 位计数器（0~31，每bit 4个时钟周期）

    // ====== 分频计数器 ======
    always@(posedge clk or negedge rst_n)
        if(!rst_n)
            div_cnt <= 0;
        else if(en_div_cnt) begin
            if(sclk_plus)
                div_cnt <= 0;
            else
                div_cnt <= div_cnt + 1'b1;
        end
        else
            div_cnt <= 0;

    // ====== 主状态机 ======
    always@(posedge clk or negedge rst_n)
        if(!rst_n) begin
            state       <= IDLE;
            cnt         <= 0;
            IIC_Sclk    <= 1;
            Rx_Data     <= 0;
            i2c_sdat_o  <= 1;
            i2c_sdat_oe <= 0;
            Ack_o       <= 0;
            en_div_cnt  <= 0;
            Trans_Done  <= 0;
        end
        else begin
            case(state)

                // ────────────────── IDLE ──────────────────
                IDLE: begin
                    Trans_Done   <= 1'b0;
                    i2c_sdat_oe  <= 1'b1;
                    i2c_sdat_o   <= 1'b1;
                    IIC_Sclk     <= 1'b1;
                    if(Go) begin
                        en_div_cnt <= 1'b1;
                        if(CMD & STA)          state <= GEN_STA;
                        else if(CMD & WR)      state <= WR_DATA;
                        else if(CMD & RD)      state <= RD_DATA;
                    end
                    else begin
                        en_div_cnt <= 1'b0;
                        cnt  <= 0;
                        state <= IDLE;
                    end
                end

                // ────────────────── GEN_STA ──────────────────
                GEN_STA: begin
                    if(sclk_plus) begin
                        case(cnt)
                            0: begin i2c_sdat_o  <= 1'b1; i2c_sdat_oe <= 1'b1; IIC_Sclk <= 1'b1; cnt <= cnt + 1'b1; end
                            1: begin IIC_Sclk    <= 1'b1;                                        cnt <= cnt + 1'b1; end
                            2: begin i2c_sdat_o  <= 1'b0; IIC_Sclk <= 1'b1;                      cnt <= cnt + 1'b1; end  // SCL高时SDA↓ = START
                            3: begin IIC_Sclk    <= 1'b0;                                        cnt <= 0;
                                    if(CMD & WR)      state <= WR_DATA;
                                    else if(CMD & RD) state <= RD_DATA;
                                    else               state <= IDLE;
                               end
                        endcase
                    end
                end

                // ────────────────── WR_DATA ──────────────────
                WR_DATA: begin
                    i2c_sdat_oe <= 1'b1;
                    if(sclk_plus) begin
                        case(cnt[1:0])  // 每4步一个循环
                            2'b00: begin i2c_sdat_o  <= Tx_Data[7 - cnt[4:2]]; IIC_Sclk <= 1'b0; cnt <= cnt + 1'b1; end  // 设置SDA
                            2'b01: begin IIC_Sclk    <= 1'b1;                                        cnt <= cnt + 1'b1; end  // SCL↑
                            2'b10: begin IIC_Sclk    <= 1'b1;                                        cnt <= cnt + 1'b1; end  // 保持
                            2'b11: begin IIC_Sclk    <= 1'b0;                                        cnt <= cnt + 1'b1; end  // SCL↓
                        endcase
                        if(cnt == 5'd31) begin cnt <= 0; state <= CHECK_ACK; end
                    end
                end

                // ────────────────── RD_DATA ──────────────────
                RD_DATA: begin
                    i2c_sdat_oe <= 1'b0;  // 释放SDA，让从设备驱动
                    if(sclk_plus) begin
                        case(cnt[1:0])
                            2'b00: begin IIC_Sclk    <= 1'b0;                                        cnt <= cnt + 1'b1; end  // SCL↓
                            2'b01: begin IIC_Sclk    <= 1'b1;                                        cnt <= cnt + 1'b1; end  // SCL↑
                            2'b10: begin IIC_Sclk    <= 1'b1; Rx_Data <= {Rx_Data[6:0], IIC_Sda};    cnt <= cnt + 1'b1; end  // SCL高时采样
                            2'b11: begin IIC_Sclk    <= 1'b0;                                        cnt <= cnt + 1'b1; end  // SCL↓
                        endcase
                        if(cnt == 5'd31) begin cnt <= 0; state <= GEN_ACK; end
                    end
                end

                // ────────────────── CHECK_ACK ──────────────────
                CHECK_ACK: begin
                    i2c_sdat_oe <= 1'b0;  // 释放SDA，让从设备拉低应答
                    if(sclk_plus) begin
                        case(cnt)
                            0: begin IIC_Sclk   <= 1'b0;                         cnt <= cnt + 1'b1; end
                            1: begin IIC_Sclk   <= 1'b1;                         cnt <= cnt + 1'b1; end
                            2: begin IIC_Sclk   <= 1'b1; Ack_o <= IIC_Sda;      cnt <= cnt + 1'b1; end  // 采样SDA
                            3: begin IIC_Sclk   <= 1'b0;                         cnt <= 0;
                                    if(CMD & STO)  state <= GEN_STO;
                                    else begin     state <= IDLE; Trans_Done <= 1'b1; end
                               end
                        endcase
                    end
                end

                // ────────────────── GEN_ACK ──────────────────
                GEN_ACK: begin
                    i2c_sdat_oe <= 1'b1;
                    if(sclk_plus) begin
                        case(cnt)
                            0: begin i2c_sdat_o <= (CMD & NACK) ? 1'b1 : 1'b0; IIC_Sclk <= 1'b0; cnt <= cnt + 1'b1; end
                            1: begin IIC_Sclk   <= 1'b1;                                               cnt <= cnt + 1'b1; end
                            2: begin IIC_Sclk   <= 1'b1;                                               cnt <= cnt + 1'b1; end
                            3: begin IIC_Sclk   <= 1'b0;                                               cnt <= 0;
                                    if(CMD & STO)  state <= GEN_STO;
                                    else begin     state <= IDLE; Trans_Done <= 1'b1; end
                               end
                        endcase
                    end
                end

                // ────────────────── GEN_STO ──────────────────
                GEN_STO: begin
                    i2c_sdat_oe <= 1'b1;
                    if(sclk_plus) begin
                        case(cnt)
                            0: begin i2c_sdat_o <= 1'b0;  IIC_Sclk <= 1'b0;                           cnt <= cnt + 1'b1; end
                            1: begin IIC_Sclk   <= 1'b1;                                            cnt <= cnt + 1'b1; end
                            2: begin i2c_sdat_o <= 1'b1;  IIC_Sclk <= 1'b1;                           cnt <= cnt + 1'b1; end  // SCL高时SDA↑ = STOP
                            3: begin IIC_Sclk   <= 1'b1;                                            cnt <= 0;
                                    state <= IDLE; Trans_Done <= 1'b1;
                               end
                        endcase
                    end
                end

                default: begin
                    state <= IDLE;
                    en_div_cnt <= 1'b0;
                end

            endcase
        end

endmodule
