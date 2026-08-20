// ============================================================================
// UART2 RX interrupt regression (lead-requested, 2026-08-17). Covers, in one
// run, the whole matrix Ravi asked Shivanee for at RTL level:
//   - interrupt handling: UART2 RX -> Ibex fast IRQ 1 (vector 17), level
//   - unsolicited ESP-AT event ("WIFI DISCONNECT") delivered with NO polling
//   - RX FIFO burst/overflow: 160 bytes into a masked 128-deep FIFO,
//     exactly 128 kept / 32 dropped
//   - simultaneous UART1 console + UART2 traffic: 'X' echoed MID-burst
//   - error/recovery: a fresh line received intact after the overflow
// Program: sw/asm-demo/uart2_irq_test.vmem (see uart2_irq_test.py for the
// full protocol). PASS = EVT OK + OVF OK + RCV OK + X/G echoes on console.
// ============================================================================

`timescale 1ns / 1ps

module tb_uart2_irq;

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
  wire  [11:0] pwm;
  wire         uart_tx;
  logic        uart_rx = 1'b1;           // console keyboard (tb drives)
  logic        u2_rx   = 1'b1;           // ESP32 side of UART2 (tb drives)

  ibex_demo_system #(
    .GpiWidth       (16),
    .GpoWidth       (16),
    .PwmWidth       (12),
    .ClockFrequency (20_000_000),
    .BaudRate       (2_000_000),
    .Uart2BaudRate  (2_000_000),
    .SRAMInitFile   ("sw/asm-demo/uart2_irq_test.vmem"),
    .BootInitFile   ("dv/xsim/boot_sram_dv.mem") // DV-only SRAM boot; real ROM is direct-XIP
  ) dut (
    .clk_sys_i  (clk),
    .rst_sys_ni (rst_n),
    .gp_i       (gp_i),
    .gp_o       (gp_o),
    .pwm_o      (pwm),
    .uart_rx_i  (uart_rx),
    .uart_tx_o  (uart_tx),
    .uart2_rx_i (u2_rx),
    .uart2_tx_o (),
    .spi_rx_i   (1'b0),
    .spi_tx_o   (),
    .spi_sck_o  (),
    .xip_spi_sck_o  (),
    .xip_spi_csn_o  (),
    .xip_spi_mosi_o (),
    .xip_spi_miso_i (1'b0),
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

  localparam int BitNs = 500;            // 2 Mbaud

  // ---- console decoder ------------------------------------------------------
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

  function automatic bit saw(string s);
    bit found = 0;
    for (int i = 0; i + s.len() <= un; i++) begin
      bit hit = 1;
      for (int j = 0; j < s.len(); j++)
        if (ubuf[i + j] != s[j]) hit = 0;
      if (hit) found = 1;
    end
    return found;
  endfunction

  // wait until the console printed s; 0 = timeout
  // (no early return inside the timed loop - xsim's kernel dies on it)
  task automatic wait_for(string s, int us_max, output bit ok);
    ok = 0;
    for (int t = 0; (t < us_max) && !ok; t++) begin
      #1000;
      if (saw(s)) ok = 1;
    end
  endtask

  // ---- byte senders ---------------------------------------------------------
  task automatic u1_send(byte b);        // keyboard -> console UART1
    uart_rx = 1'b0; #(BitNs);
    for (int i = 0; i < 8; i++) begin uart_rx = b[i]; #(BitNs); end
    uart_rx = 1'b1; #(BitNs);
  endtask

  task automatic u2_send(byte b);        // ESP32 -> UART2
    u2_rx = 1'b0; #(BitNs);
    for (int i = 0; i < 8; i++) begin u2_rx = b[i]; #(BitNs); end
    u2_rx = 1'b1; #(BitNs);
  endtask

  task automatic u2_puts(string s);
    for (int i = 0; i < s.len(); i++) u2_send(byte'(s[i]));
  endtask

  // ---- the sequence ---------------------------------------------------------
  initial begin
    bit ok;
    $display("=== UART2 RX interrupt: event / burst-overflow / recovery ===");

    wait_for("IRQ2", 2000, ok);
    if (!ok) begin $display("\nFAIL: no IRQ2 banner (boot/mtvec broke)"); $finish; end

    // 1. unsolicited event: 17 bytes, ISR-only delivery
    u2_puts("WIFI DISCONNECT\r\n");
    wait_for("EVT OK", 2000, ok);
    if (!ok) begin $display("\nFAIL: event line not counted by ISR (IRQ dead?)"); $finish; end

    wait_for("MASK", 1000, ok);
    if (!ok) begin $display("\nFAIL: no MASK marker"); $finish; end

    // 2. 160-byte burst into the masked FIFO, console 'X' MID-burst
    fork
      begin
        for (int i = 0; i < 160; i++) u2_send(byte'(i));
      end
      begin
        #(80 * 10 * BitNs);              // ~half way through the burst
        u1_send("X");
      end
    join
    u1_send("G");                        // go: program unmasks + checks

    wait_for("OVF OK", 3000, ok);
    if (!ok) begin
      $display("\nFAIL: overflow accounting wrong (expect exactly 128 kept) saw_er=%0d",
               saw("OVF ER"));
      $finish;
    end

    // 3. recovery: a fresh unsolicited line after the overflow
    u2_puts("+IPD,4:ping\r\n");
    wait_for("RCV OK", 3000, ok);
    if (!ok) begin $display("\nFAIL: link dead after overflow (no recovery)"); $finish; end

    if (saw("X") && saw("G"))
      $display("\nPASS: UART2 IRQ + 128-byte FIFO overflow + recovery, console alive throughout");
    else
      $display("\nFAIL: console echo lost during UART2 burst");
    $finish;
  end

  // global watchdog
  initial begin
    #20_000_000;                         // 20 ms sim cap
    $display("\nFAIL: watchdog timeout");
    $finish;
  end

endmodule
