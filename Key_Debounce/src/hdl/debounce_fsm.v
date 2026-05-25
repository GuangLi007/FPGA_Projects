module debounce_fsm (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       key_in,
    output reg        key_press
);
    parameter T_20MS = 1_000_000;

    reg        key_sync1, key_sync2;
    reg [19:0] cnt;
    reg [1:0]  state;

    localparam IDLE          = 0;
    localparam DEBOUNCE      = 1;
    localparam PRESSED       = 2;
    localparam RELEASE       = 3;

    wire key_fall;
    wire key_rise;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            key_sync1 <= 1'b1;
            key_sync2 <= 1'b1;
        end else begin
            key_sync1 <= key_in;
            key_sync2 <= key_sync1;
        end
    end

    assign key_fall =  key_sync2 & ~key_sync1;
    assign key_rise = ~key_sync2 &  key_sync1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state     <= IDLE;
            cnt       <= 0;
            key_press <= 1'b0;
        end else begin
            key_press <= 1'b0;
            case (state)
                IDLE: begin
                    if (key_fall) begin
                        key_press <= 1'b1;
                        state     <= DEBOUNCE;
                        cnt       <= 0;
                    end
                end
                DEBOUNCE: begin
                    if (cnt == T_20MS - 1) begin
                        state <= PRESSED;
                        cnt   <= 0;
                    end else
                        cnt <= cnt + 1;
                end
                PRESSED: begin
                    if (key_rise)
                        state <= RELEASE;
                        cnt   <= 0;
                end
                RELEASE: begin
                    if (cnt == T_20MS - 1)
                        state <= IDLE;
                    else
                        cnt <= cnt + 1;
                end
                default: state <= IDLE;
            endcase
        end
    end

endmodule
