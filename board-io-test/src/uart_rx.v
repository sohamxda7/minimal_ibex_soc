// ============================================================================
// UART receiver: 8 data bits, no parity, 1 stop bit
// `valid` pulses high for one clock when a byte has been received in `data`.
// ============================================================================

module uart_rx #(
    parameter CLKS_PER_BIT = 868          // clock_freq / baud_rate
) (
    input  wire       clk,
    input  wire       rx,
    output reg  [7:0] data  = 8'd0,
    output reg        valid = 1'b0
);

    // Synchronise the async rx line into our clock domain
    reg rx_d1 = 1'b1, rx_d2 = 1'b1;
    always @(posedge clk) begin
        rx_d1 <= rx;
        rx_d2 <= rx_d1;
    end

    localparam IDLE  = 2'd0,
               START = 2'd1,
               DATA  = 2'd2,
               STOP  = 2'd3;

    reg [1:0]  state   = IDLE;
    reg [15:0] clk_cnt = 16'd0;
    reg [2:0]  bit_idx = 3'd0;

    always @(posedge clk) begin
        valid <= 1'b0;

        case (state)
            IDLE: begin
                clk_cnt <= 16'd0;
                if (!rx_d2)                       // start bit edge
                    state <= START;
            end

            START: begin                          // check middle of start bit
                if (clk_cnt == CLKS_PER_BIT/2 - 1) begin
                    clk_cnt <= 16'd0;
                    bit_idx <= 3'd0;
                    state   <= rx_d2 ? IDLE : DATA;  // glitch if high again
                end
                else
                    clk_cnt <= clk_cnt + 1'b1;
            end

            DATA: begin                           // sample middle of each bit
                if (clk_cnt == CLKS_PER_BIT-1) begin
                    clk_cnt <= 16'd0;
                    data    <= {rx_d2, data[7:1]};  // LSB first
                    if (bit_idx == 3'd7)
                        state <= STOP;
                    else
                        bit_idx <= bit_idx + 1'b1;
                end
                else
                    clk_cnt <= clk_cnt + 1'b1;
            end

            STOP: begin                           // wait through the stop bit
                if (clk_cnt == CLKS_PER_BIT-1) begin
                    valid <= 1'b1;
                    state <= IDLE;
                end
                else
                    clk_cnt <= clk_cnt + 1'b1;
            end
        endcase
    end

endmodule
