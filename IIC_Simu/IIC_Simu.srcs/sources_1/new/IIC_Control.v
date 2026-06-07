`timescale 1ns / 1ps

module IIC_Control(
    input               clk,
    input               rst_n,

    // 用户接口
    input               wrreg_req,
    input               rdreg_req,
    input        [15:0] addr,
    input               addr_mode,   // 0: 单字节地址(24C02), 1: 双字节地址
    input        [7:0]  wrdata,
    output  reg  [7:0]  rddata,
    input        [7:0]  device_id,
    output  reg         RW_Done,

    // 应答状态（给上层指示）
    output  reg         ack_o,

    // I2C 总线（直连到底层）
    output              IIC_Sclk,
    inout               IIC_Sda
);

    // ====== 内部连线 ======
    reg  [5:0]  CMD;
    reg  [7:0]  Tx_Data;
    wire        Trans_Done;
    wire        Ack_i;           // 底层返回的应答信号
    reg         Go;
    wire [15:0] reg_addr;

    assign reg_addr = addr_mode ? addr : {addr[7:0], addr[15:8]};

    wire [7:0] Rx_Data;

    // ====== 命令编码（与底层一致）======
    localparam 
        WR   = 6'b000001,
        STA  = 6'b000010,
        RD   = 6'b000100,
        STO  = 6'b001000,
        ACK  = 6'b010000,
        NACK = 6'b100000;

    // ====== 实例化底层位操作模块 ======
    IIC_Bit_Shift u_IIC_Bit_Shift(
        .clk        (clk),
        .rst_n      (rst_n),
        .CMD        (CMD),
        .Go         (Go),
        .Rx_Data    (Rx_Data),
        .Tx_Data    (Tx_Data),
        .Trans_Done (Trans_Done),
        .Ack_o      (Ack_i),
        .IIC_Sclk   (IIC_Sclk),
        .IIC_Sda    (IIC_Sda)
    );

    // ====== 状态机编码 ======
    localparam
        IDLE         = 7'b0000001,
        WR_REG       = 7'b0000010,
        WAIT_WR_DONE = 7'b0000100,
        WR_REG_DONE  = 7'b0001000,
        RD_REG       = 7'b0010000,
        WAIT_RD_DONE = 7'b0100000,
        RD_REG_DONE  = 7'b1000000;

    reg [6:0] state;
    reg [7:0] cnt;      // 步骤计数器（记录当前传输到第几步）

    // ====== 状态机 ======
    always@(posedge clk or negedge rst_n)
        if(!rst_n) begin
            CMD     <= 6'd0;
            Tx_Data <= 8'd0;
            Go      <= 1'b0;
            rddata  <= 8'd0;
            state   <= IDLE;
            ack_o   <= 1'b0;
        end
        else begin
            case(state)

                // ──────────── IDLE ────────────
                IDLE: begin
                    cnt    <= 8'd0;
                    ack_o  <= 1'b0;
                    RW_Done <= 1'b0;
                    if(wrreg_req)
                        state <= WR_REG;
                    else if(rdreg_req)
                        state <= RD_REG;
                    else
                        state <= IDLE;
                end

                // ──────────── WR_REG ────────────
                // 在此状态设置各步骤的命令和数据
                WR_REG: begin
                    state <= WAIT_WR_DONE;
                    case(cnt)
                        0: write_byte(WR | STA, device_id);
                        1: write_byte(WR,       reg_addr[15:8]);
                        2: write_byte(WR,       reg_addr[7:0]);
                        3: write_byte(WR | STO, wrdata);
                        default: ;
                    endcase
                end

                // ──────────── WAIT_WR_DONE ────────────
                WAIT_WR_DONE: begin
                    Go <= 1'b0;
                    if(Trans_Done) begin
                        ack_o <= ack_o | Ack_i;   // 累积应答状态
                        case(cnt)
                            0: begin cnt <= 8'd1;       state <= WR_REG; end
                            1: begin state <= WR_REG;
                                    if(addr_mode)  cnt <= 8'd2;
                                    else           cnt <= 8'd3; end
                            2: begin cnt <= 8'd3;       state <= WR_REG; end
                            3:                         state <= WR_REG_DONE;
                            default:                    state <= IDLE;
                        endcase
                    end
                end

                // ──────────── WR_REG_DONE ────────────
                WR_REG_DONE: begin
                    RW_Done <= 1'b1;
                    state   <= IDLE;
                end

                // ──────────── RD_REG ────────────
                RD_REG: begin
                    state <= WAIT_RD_DONE;
                    case(cnt)
                        0: write_byte(WR | STA,          device_id);
                        1: write_byte(WR,                reg_addr[15:8]);
                        2: write_byte(WR,                reg_addr[7:0]);
                        3: write_byte(WR | STA,          device_id | 8'd1);
                        4: read_byte (RD | NACK | STO);
                        default: ;
                    endcase
                end

                // ──────────── WAIT_RD_DONE ────────────
                WAIT_RD_DONE: begin
                    Go <= 1'b0;
                    if(Trans_Done) begin
                        if(cnt <= 8'd3)
                            ack_o <= ack_o | Ack_i;
                        case(cnt)
                            0: begin cnt <= 8'd1;       state <= RD_REG; end
                            1: begin state <= RD_REG;
                                    if(addr_mode)  cnt <= 8'd2;
                                    else           cnt <= 8'd3; end
                            2: begin cnt <= 8'd3;       state <= RD_REG; end
                            3: begin cnt <= 8'd4;       state <= RD_REG; end
                            4:                         state <= RD_REG_DONE;
                            default:                    state <= IDLE;
                        endcase
                    end
                end

                // ──────────── RD_REG_DONE ────────────
                RD_REG_DONE: begin
                    RW_Done <= 1'b1;
                    rddata  <= Rx_Data;
                    state   <= IDLE;
                end

                default: state <= IDLE;

            endcase
        end

    // ====== 任务封装 ======
    task write_byte;
        input [5:0] Ctrl_Cmd;
        input [7:0] Wr_Byte_Data;
        begin
            CMD     <= Ctrl_Cmd;
            Tx_Data <= Wr_Byte_Data;
            Go      <= 1'b1;
        end
    endtask

    task read_byte;
        input [5:0] Ctrl_Cmd;
        begin
            CMD <= Ctrl_Cmd;
            Go  <= 1'b1;
        end
    endtask

endmodule