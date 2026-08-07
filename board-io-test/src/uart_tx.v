// ============================================================================
// UART transmitter: 8 data bits, no parity, 1 stop bit
// Pulse `send` high for one clock with `data` valid; `busy` stays high
// until the whole frame (start + 8 data + stop) has gone out.
// ============================================================================

module uart_tx #(
    parameter CLKS_PER_BIT = 868          // clock_freq / baud_rate
) (
    input  wire       clk,
    input  wire       send,
    input  wire [7:0] data,
    output reg        tx   = 1'b1,       // idle line is high
    output reg        busy = 1'b0
);

    reg [8:0]  shift   = 9'h1FF;         // stop bit + 8 data bits
    reg [3:0]  bit_cnt = 4'd0;
    reg [15:0] clk_cnt = 16'd0;

    always @(posedge clk) begin
        if (!busy) begin
            tx <= 1'b1;
            if (send) begin
                shift   <= {1'b1, data};  // stop bit ahead of MSB
                tx      <= 1'b0;          // start bit
                busy    <= 1'b1;
                bit_cnt <= 4'd0;
                clk_cnt <= 16'd0;
            end
        end
        else begin
            if (clk_cnt == CLKS_PER_BIT-1) begin
                clk_cnt <= 16'd0;
                tx      <= shift[0];
                shift   <= {1'b1, shift[8:1]};
                if (bit_cnt == 4'd9)
                    busy <= 1'b0;
                else
                    bit_cnt <= bit_cnt + 1'b1;
            end
            else
                clk_cnt <= clk_cnt + 1'b1;
        end
    end

endmodule
