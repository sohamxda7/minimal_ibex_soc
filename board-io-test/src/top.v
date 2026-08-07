// ============================================================================
// Arty A7 IO Test - Top Level
// ----------------------------------------------------------------------------
// Exercises every basic IO on the board at the same time:
//
//   * 4 green LEDs   : run a "chase" pattern. Flip any switch up and the LEDs
//                      show the switch positions instead (tests LEDs + switches).
//   * 4 push buttons : hold a button and the RGB LED next to it cycles
//                      Red -> Green -> Blue -> White (tests buttons + RGB LEDs).
//   * UART @ 115200  : prints "SW=xxxx BTN=xxxx" whenever a switch or button
//                      changes, and echoes back any character you type
//                      (tests both UART directions).
//   * Pmod JA/JB/JC/JD : every pin outputs a square wave. Pin 1 of each header
//                      toggles at ~0.37 Hz (slow blink you can see on a
//                      multimeter or LED), each next pin is 2x faster.
//   * Pmod touch test : flip ALL four switches up and the Pmod pins become
//                      inputs with pull-ups instead; grounding a signal pin
//                      (paperclip to a GND pin) lights that connector's LED
//                      (JA->LD4 .. JD->LD7) and the UART prints the full pin
//                      map. Tests every Pmod pin with no instruments.
// ============================================================================

module top #(
    // SPEEDUP = 0 for real hardware (do not change for the board build!).
    // A simulation testbench sets e.g. 12, which makes the slow human-visible
    // effects (LED chase, colour cycle) ~4000x faster so they show up in a
    // waveform viewer. See sim\tb_top.v and README "Simulating" section.
    parameter SPEEDUP      = 0,
    // 100 MHz / 115200 baud. The testbench passes a smaller value so UART
    // frames don't take forever to simulate.
    parameter CLKS_PER_BIT = 868
) (
    input  wire       clk100,        // 100 MHz board clock

    input  wire [3:0] sw,            // slide switches
    input  wire [3:0] btn,           // push buttons

    output wire [3:0] led,           // green LEDs

    output wire       led0_r, led0_g, led0_b,   // RGB LEDs
    output wire       led1_r, led1_g, led1_b,
    output wire       led2_r, led2_g, led2_b,
    output wire       led3_r, led3_g, led3_b,

    input  wire       uart_txd_in,   // PC -> FPGA
    output wire       uart_rxd_out,  // FPGA -> PC

    inout  wire [7:0] ja,            // Pmod headers: square-wave outputs
    inout  wire [7:0] jb,            // normally; inputs with pull-ups in
    inout  wire [7:0] jc,            // touch-test mode (all switches up)
    inout  wire [7:0] jd
);

    // ------------------------------------------------------------------
    // Free-running counter: the time base for everything below
    // ------------------------------------------------------------------
    reg [31:0] tick = 32'd0;
    always @(posedge clk100)
        tick <= tick + 1'b1;

    // "t" is the time base for all the slow, human-visible effects.
    // On hardware (SPEEDUP=0) it is simply the counter itself; in simulation
    // the shift makes those effects 2^SPEEDUP times faster.
    wire [31:0] t = tick << SPEEDUP;

    // Register the switch/button inputs (avoids metastability issues)
    reg [3:0] sw_s  = 4'd0;
    reg [3:0] btn_s = 4'd0;
    always @(posedge clk100) begin
        sw_s  <= sw;
        btn_s <= btn;
    end

    // Pmod touch-test mode: active while all four switches are up.
    // (Declared here because the LED logic below uses these signals.)
    wire pmod_test_mode = (sw_s == 4'b1111);

    // Synchronised read-back of the Pmod pins
    reg [7:0] ja_s = 8'hFF, jb_s = 8'hFF, jc_s = 8'hFF, jd_s = 8'hFF;
    always @(posedge clk100) begin
        ja_s <= ja;  jb_s <= jb;  jc_s <= jc;  jd_s <= jd;
    end

    // ------------------------------------------------------------------
    // Green LEDs: chase pattern, or mirror the switches if any is up
    // ------------------------------------------------------------------
    wire [3:0] chase = 4'b0001 << t[25:24];      // moves every ~0.17 s

    // In Pmod touch-test mode each LED means "a pin of this connector is
    // grounded right now": JA->LD4, JB->LD5, JC->LD6, JD->LD7.
    assign led = pmod_test_mode ? { ~&jd_s, ~&jc_s, ~&jb_s, ~&ja_s }
               : (|sw_s)        ? sw_s
               :                  chase;

    // ------------------------------------------------------------------
    // RGB LEDs: hold a button, its RGB LED cycles R -> G -> B -> White.
    // PWM keeps brightness low - these LEDs are painfully bright at 100%.
    // ------------------------------------------------------------------
    localparam [7:0] BRIGHT = 8'd16;             // duty 16/256 = ~6%
    wire [7:0] pwm_cnt = tick[7:0];
    wire [1:0] phase   = t[27:26];               // new colour every ~0.67 s

    wire r_on = (pwm_cnt < ((phase == 2'd0 || phase == 2'd3) ? BRIGHT : 8'd0));
    wire g_on = (pwm_cnt < ((phase == 2'd1 || phase == 2'd3) ? BRIGHT : 8'd0));
    wire b_on = (pwm_cnt < ((phase == 2'd2 || phase == 2'd3) ? BRIGHT : 8'd0));

    assign {led0_r, led0_g, led0_b} = btn_s[0] ? {r_on, g_on, b_on} : 3'b000;
    assign {led1_r, led1_g, led1_b} = btn_s[1] ? {r_on, g_on, b_on} : 3'b000;
    assign {led2_r, led2_g, led2_b} = btn_s[2] ? {r_on, g_on, b_on} : 3'b000;
    assign {led3_r, led3_g, led3_b} = btn_s[3] ? {r_on, g_on, b_on} : 3'b000;

    // ------------------------------------------------------------------
    // Pmod headers.
    // Normal mode: square waves. Index 0 (physical pin 1) is slowest:
    //   pin 1: ~0.37 Hz   pin 2: ~0.75 Hz   ... pin 10: ~47.7 Hz
    // Touch-test mode (all four switches up): pins release to inputs,
    // pulled high by internal pull-ups (enabled in the XDC). Grounding a
    // pin is shown on the green LEDs and reported over UART.
    // ------------------------------------------------------------------
    wire [7:0] pmod_pattern = { t[20], t[21], t[22], t[23],
                                t[24], t[25], t[26], t[27] };
    assign ja = pmod_test_mode ? 8'hzz : pmod_pattern;
    assign jb = pmod_test_mode ? 8'hzz : pmod_pattern;
    assign jc = pmod_test_mode ? 8'hzz : pmod_pattern;
    assign jd = pmod_test_mode ? 8'hzz : pmod_pattern;

    // ------------------------------------------------------------------
    // UART: 115200 baud, 8 data bits, no parity, 1 stop bit
    // (CLKS_PER_BIT = 868 = 100 MHz / 115200, set in the parameter list)
    // ------------------------------------------------------------------
    wire       rx_valid;
    wire [7:0] rx_data;
    wire       tx_busy;
    reg        tx_send = 1'b0;
    reg  [7:0] tx_data = 8'd0;

    uart_rx #(.CLKS_PER_BIT(CLKS_PER_BIT)) u_rx (
        .clk   (clk100),
        .rx    (uart_txd_in),
        .data  (rx_data),
        .valid (rx_valid)
    );

    uart_tx #(.CLKS_PER_BIT(CLKS_PER_BIT)) u_tx (
        .clk  (clk100),
        .send (tx_send),
        .data (tx_data),
        .tx   (uart_rxd_out),
        .busy (tx_busy)
    );

    // Message type 0: "SW=xxxx BTN=xxxx\r\n"                       (18 chars)
    // Message type 1: "JA=xxxxxxxx JB=xxxxxxxx JC=xxxxxxxx JD=xxxxxxxx\r\n"
    //                 (49 chars; digits are pins 1,2,3,4,7,8,9,10 of each
    //                 connector, left to right; 0 = pin grounded)
    localparam MSG_LEN  = 18;
    localparam PMSG_LEN = 49;

    reg        msg_is_pmod = 1'b0;
    reg [7:0]  msg_state;                // {sw, btn} latched at message start
    reg [31:0] pmod_snap;                // {jd, jc, jb, ja} latched likewise
    reg [5:0]  msg_idx = 6'd0;
    reg [7:0]  msg_char;

    // The Pmod message is four 12-char groups ("JA=xxxxxxxx ") + \r\n
    wire [5:0] grp = msg_idx / 12;
    wire [5:0] off = msg_idx % 12;

    always @* begin
        if (msg_is_pmod) begin
            if      (msg_idx == PMSG_LEN-2) msg_char = 8'h0D;        // \r
            else if (msg_idx == PMSG_LEN-1) msg_char = 8'h0A;        // \n
            else case (off)
                6'd0:  msg_char = "J";
                6'd1:  msg_char = (grp == 0) ? "A" :
                                  (grp == 1) ? "B" :
                                  (grp == 2) ? "C" : "D";
                6'd2:  msg_char = "=";
                6'd11: msg_char = " ";
                default:  // off 3..10 -> the 8 signal pins of connector grp
                    msg_char = pmod_snap[{grp[1:0], 3'b000} + (off - 6'd3)]
                               ? "1" : "0";
            endcase
        end
        else begin
            case (msg_idx)
                0:  msg_char = "S";
                1:  msg_char = "W";
                2:  msg_char = "=";
                3:  msg_char = msg_state[7] ? "1" : "0";
                4:  msg_char = msg_state[6] ? "1" : "0";
                5:  msg_char = msg_state[5] ? "1" : "0";
                6:  msg_char = msg_state[4] ? "1" : "0";
                7:  msg_char = " ";
                8:  msg_char = "B";
                9:  msg_char = "T";
                10: msg_char = "N";
                11: msg_char = "=";
                12: msg_char = msg_state[3] ? "1" : "0";
                13: msg_char = msg_state[2] ? "1" : "0";
                14: msg_char = msg_state[1] ? "1" : "0";
                15: msg_char = msg_state[0] ? "1" : "0";
                16: msg_char = 8'h0D;    // \r
                default: msg_char = 8'h0A;   // \n
            endcase
        end
    end

    wire [7:0] cur_state  = {sw_s, btn_s};
    wire       sample_en  = (t[21:0] == 22'd0);      // check ~24x per second

    reg [7:0] last_state   = 8'hFF;    // 0xFF is impossible-ish -> forces one
                                       // message right after programming
    reg [31:0] last_pmod   = 32'd0;    // 0 forces a pin-map report whenever
                                       // touch-test mode is entered
    reg       sending_msg  = 1'b0;
    reg       pending_echo = 1'b0;
    reg [7:0] echo_byte    = 8'd0;

    always @(posedge clk100) begin
        tx_send <= 1'b0;

        if (rx_valid) begin
            pending_echo <= 1'b1;
            echo_byte    <= rx_data;
        end

        if (!sending_msg) begin
            if (pending_echo && !tx_busy && !tx_send) begin
                tx_data      <= echo_byte;
                tx_send      <= 1'b1;
                pending_echo <= 1'b0;
            end
            else if (sample_en && cur_state != last_state
                     && !tx_busy && !tx_send) begin
                sending_msg <= 1'b1;
                msg_is_pmod <= 1'b0;
                msg_state   <= cur_state;
                last_state  <= cur_state;
                msg_idx     <= 6'd0;
            end
            else if (sample_en && pmod_test_mode
                     && {jd_s, jc_s, jb_s, ja_s} != last_pmod
                     && !tx_busy && !tx_send) begin
                sending_msg <= 1'b1;
                msg_is_pmod <= 1'b1;
                pmod_snap   <= {jd_s, jc_s, jb_s, ja_s};
                last_pmod   <= {jd_s, jc_s, jb_s, ja_s};
                msg_idx     <= 6'd0;
            end
            if (!pmod_test_mode)
                last_pmod <= 32'd0;
        end
        else begin
            if (!tx_busy && !tx_send) begin
                tx_data <= msg_char;
                tx_send <= 1'b1;
                if (msg_idx == (msg_is_pmod ? PMSG_LEN-1 : MSG_LEN-1))
                    sending_msg <= 1'b0;
                else
                    msg_idx <= msg_idx + 1'b1;
            end
        end
    end

endmodule
