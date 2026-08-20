// ============================================================================
// FreeRTOS boot simulation: the boot ROM jumps DIRECTLY into the XIP
// window (rtl/system/boot.mem) and the FreeRTOS image executes in place
// from the behavioral SPI NOR flash. SRAM powers up as DETERMINISTIC
// RANDOM GARBAGE (dv/xsim/sram_powerup_random.vmem, fixed xorshift seed)
// — the silicon condition: boot succeeds only if nothing depends on SRAM
// power-up contents. (X-init, which tb_xip uses, is stricter but floods
// this full-product sim with benign IbexDataRPayloadX asserts whenever a
// byte-built buffer or padded struct is word-read; random garbage keeps
// the log clean while still killing any boot that *depends* on SRAM.)
//
// PASS criteria (UART, 2 Mbaud):
//   1. "FreeRTOS on Ibex"  banner  -> C runtime + XIP fetch + data copy OK
//   2. two "tick=" lines           -> timer interrupt, vectored trap entry,
//                                     context switch, vTaskDelay all OK
//   3. console key test (added 2026-08-20, after a bench find): every key
//      echoes; after '3' the LEDs alternate A/5; after a DOUBLE '1' the
//      walking pattern restarts as a true one-hot walk. Without the
//      per-keypress reseed in main.c, patterns 1-3 share stale state and
//      rotate(0xA)=~0xA=0x5 makes keys 1/2/3 visually identical.
//
// Build the firmware first:  sw\freertos\build.bat sim
// (SIM_BUILD: 200 Hz tick, 1-tick delays, heap in .noinit)
//
// XipClkDiv=1 (SPI = 10 MHz): the S25FL128 on the Arty is rated to 50 MHz
// for command 0x03, so this is hardware-realistic, not a sim cheat. Even so
// a fetch takes 128 system clocks, so expect ~10 ms of simulated time before
// the banner and ~10 min of wall time. Progress lines print each sim-ms.
// ============================================================================

`timescale 1ns / 1ps

module tb_freertos;

  logic clk = 1'b0;
  always #25 clk = ~clk;                 // 20 MHz

  // rst_n must make a real FALLING edge: async-reset flops behind Ibex's
  // internal clock gate get no clock during reset, so in event-driven sim
  // only the negedge fires their reset branch. Starting at 0 from time zero
  // left priv_lvl_q at the simulator's init value (U-mode!) and the first
  // M-mode CSR write trapped (see BRINGUP_TEST_REPORT sec. 12b). Real
  // async-reset cells are LEVEL-sensitive, so silicon/FPGA are unaffected.
  logic rst_n = 1'b1;
  initial begin
    @(negedge clk);
    rst_n = 1'b0;
    repeat (20) @(posedge clk);
    rst_n = 1'b1;
  end

  logic [15:0] gp_i = 16'h0000;
  wire  [15:0] gp_o;
  wire [11:0] pwm;
  wire        uart_tx;
  logic       uart_rx = 1'b1;

  wire flash_sck, flash_csn, flash_mosi, flash_miso;

  ibex_demo_system #(
    .GpiWidth       (16),
    .GpoWidth       (16),
    .PwmWidth       (12),
    .ClockFrequency (20_000_000),
    .BaudRate       (2_000_000),
    .SRAMInitFile   ("dv/xsim/sram_powerup_random.vmem"),  // silicon-like random power-up
    .XipClkDiv      (1)
  ) dut (
    .clk_sys_i  (clk),
    .rst_sys_ni (rst_n),
    .gp_i       (gp_i),
    .gp_o       (gp_o),
    .pwm_o      (pwm),
    .uart_rx_i  (uart_rx),
    .uart_tx_o  (uart_tx),
    .uart2_rx_i (1'b1),
    .uart2_tx_o (),
    .spi_rx_i   (1'b0),
    .spi_tx_o   (),
    .spi_sck_o  (),
    .xip_spi_sck_o  (flash_sck),
    .xip_spi_csn_o  (flash_csn),
    .xip_spi_mosi_o (flash_mosi),
    .xip_spi_miso_i (flash_miso),
    .i2c_scl_i    (1'b1),
    .i2c_scl_o    (),
    .i2c_scl_oe_o (),
    .i2c_sda_i    (1'b1),
    .i2c_sda_o    (),
    .i2c_sda_oe_o (),
    .tck_i   (1'b0),
    .tms_i   (1'b0),
    .trst_ni (1'b1),
    .td_i    (1'b0),
    .td_o    ()
  );

  spi_nor_flash_model #(
    .WINDOW_BYTES (65536),
    .BASE_OFFSET  (24'h40_0000),
    .INIT_FILE    ("sw/freertos/build/freertos_demo_sim_flash.vmem")
  ) u_flash (
    .sck  (flash_sck),
    .csn  (flash_csn),
    .mosi (flash_mosi),
    .miso (flash_miso)
  );

  // UART decoder (2 Mbaud)
  localparam int BitNs = 500;
  byte ubuf [0:255];
  int  un = 0;
  initial begin
    forever begin
      byte b;
      @(negedge uart_tx);
      #(BitNs + BitNs/2);
      for (int i = 0; i < 8; i++) begin
        b[i] = uart_tx;
        #(BitNs);
      end
      $write("%c", b);
      if (un < 256) begin ubuf[un] = b; un++; end
    end
  end

  function automatic int count_str(string needle);
    int n = 0;
    for (int i = 0; i + 4 < un; i++)
      if (ubuf[i] == needle[0] && ubuf[i+1] == needle[1] &&
          ubuf[i+2] == needle[2] && ubuf[i+3] == needle[3] &&
          ubuf[i+4] == needle[4]) n++;
    return n;
  endfunction

  function automatic bit saw_banner();
    for (int i = 0; i + 7 < un; i++)
      if (ubuf[i]=="F" && ubuf[i+1]=="r" && ubuf[i+2]=="e" && ubuf[i+3]=="e" &&
          ubuf[i+4]=="R" && ubuf[i+5]=="T" && ubuf[i+6]=="O" && ubuf[i+7]=="S")
        return 1;
    return 0;
  endfunction

  // ---- console key test infrastructure (2026-08-20) ------------------------
  // 2 Mbaud key injection into the DUT's UART RX
  task automatic send_key(input byte b);
    uart_rx = 1'b0;  #(BitNs);                      // start
    for (int i = 0; i < 8; i++) begin
      uart_rx = b[i];  #(BitNs);
    end
    uart_rx = 1'b1;  #(2*BitNs);                    // stop + idle
  endtask

  // send a key and require its echo-ack on uart_tx within 20 ms
  task automatic send_and_expect_echo(input byte b, output bit ok);
    int un0 = un;
    send_key(b);
    ok = 0;
    for (int w = 0; w < 200; w++) begin
      #100_000;                                      // 0.1 ms
      if (un > un0 && ubuf[un-1] == b) begin ok = 1; break; end
    end
  endtask

  // record every distinct LED-nibble value (gp_o[7:4]) into a queue
  logic [3:0] led_q [$];
  logic [3:0] led_prev = 4'hx;
  always @(gp_o) begin
    if (gp_o[7:4] !== led_prev) begin
      led_prev = gp_o[7:4];
      led_q.push_back(gp_o[7:4]);
    end
  end

  function automatic bit is_onehot(input logic [3:0] v);
    return (v == 4'h1) || (v == 4'h2) || (v == 4'h4) || (v == 4'h8);
  endfunction

  initial begin
    int  n_pass = 0, n_fail = 0;
    bit  ok;
    logic [3:0] a, b2;

    $display("=== FreeRTOS XIP boot simulation ===");
    for (int ms = 0; ms < 150; ms++) begin
      #1_000_000;
      if (ms % 10 == 9)
        $display("[tb] %0d ms simulated, %0d uart bytes", ms + 1, un);
      if (count_str("tick=") >= 2) break;
    end

    if (count_str("tick=") < 2) begin
      if (saw_banner())
        $display("\nFAIL: banner only - scheduler/tick never ran (bytes=%0d)", un);
      else
        $display("\nFAIL: no UART output at all (bytes=%0d)", un);
      $finish;
    end

    // ---- console key test: echo + pattern reseed (the bench bug) ----------
    // 't' first: silences the every-tick report prints - the prio-2 report
    // task otherwise eats most of the (XIP-slow) CPU and starves blinky.
    send_and_expect_echo("t", ok);
    if (ok) n_pass++; else begin n_fail++; $display("FAIL: no echo for 't'"); end
    send_and_expect_echo("f", ok);                  // fast steps (1 tick each)
    if (ok) n_pass++; else begin n_fail++; $display("FAIL: no echo for 'f'"); end

    send_and_expect_echo("3", ok);                  // pattern 3: A/5
    if (ok) n_pass++; else begin n_fail++; $display("FAIL: no echo for '3'"); end
    #30_000_000;                                    // let pattern 3 settle
    led_q.delete();
    for (int w = 0; w < 150 && led_q.size() < 4; w++) #1_000_000;  // adaptive, cap 150 ms
    ok = (led_q.size() >= 3);
    foreach (led_q[i])
      if (led_q[i] != 4'hA && led_q[i] != 4'h5) ok = 0;
    if (ok) begin n_pass++; $display("PASS: pattern 3 alternates A/5 (%0d samples)", led_q.size()); end
    else    begin n_fail++; $display("FAIL: pattern 3 wrong (%0d samples)", led_q.size()); end

    // DOUBLE-press '1': the second press must still act (visible restart),
    // and the walk must be a true one-hot walk, not a recycled A/5 pair.
    send_and_expect_echo("1", ok);
    if (ok) n_pass++; else begin n_fail++; $display("FAIL: no echo for 1st '1'"); end
    send_and_expect_echo("1", ok);
    if (ok) n_pass++; else begin n_fail++; $display("FAIL: no echo for 2nd '1'"); end
    #30_000_000;
    led_q.delete();
    for (int w = 0; w < 150 && led_q.size() < 4; w++) #1_000_000;  // adaptive, cap 150 ms
    ok = (led_q.size() >= 3);
    foreach (led_q[i]) if (!is_onehot(led_q[i])) ok = 0;
    for (int i = 1; i < led_q.size(); i++) begin
      a  = led_q[i-1];
      b2 = led_q[i];
      if (b2 != {a[2:0], a[3]}) ok = 0;             // must rotate left by 1
    end
    if (ok) begin n_pass++; $display("PASS: double '1' -> clean one-hot walk (%0d samples)", led_q.size()); end
    else    begin n_fail++; $display("FAIL: walk after double '1' not one-hot/rotating (%0d samples)", led_q.size()); end

    if (n_fail == 0)
      $display("\nPASS: FreeRTOS scheduler running (banner=%0d ticks=%0d, key checks %0d/%0d)",
               saw_banner(), count_str("tick="), n_pass, n_pass);
    else
      $display("\nFAIL: %0d key/pattern checks failed (%0d passed)", n_fail, n_pass);
    $finish;
  end

endmodule
