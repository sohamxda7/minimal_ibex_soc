// ============================================================================
// Full-SoC xsim testbench: boots the Ibex from the boot ROM, which jumps to
// the program baked into SRAM (sw/asm-demo/sram_init_sim.vmem), then checks
// every user-visible function including the UART command interface:
//   * UART TX (banner) and RX (echo/ack of every byte)
//   * '3' command -> LED pattern switches to alternating (0xA0/0x50)
//   * 'b' command -> RGB forced to blue (blue PWM active, red PWM silent)
//   * button held -> LEDs mirror switches
//
// Run from the REPO ROOT (paths to boot.mem / sram vmem are relative):
//   xvlog -sv -f dv/xsim/filelist.f dv/xsim/tb_soc.sv dv/xsim/sim_stubs.sv ^
//         -i vendor/lowrisc_ip/ip/prim/rtl -i rtl/system ^
//         -i vendor/lowrisc_ibex/vendor/lowrisc_ip/dv/sv/dv_utils
//   xelab tb_soc -s soc_sim -timescale 1ns/1ps
//   xsim soc_sim -R
// ============================================================================

`timescale 1ns / 1ps

// Set UseDffram=1 (xelab -generic_top / verilator -G) to run the same
// full-SoC checks on the GF180 DFFRAM behavioral model - the ASIC netlist
// SRAM. The console is sb/sh-heavy, so this directly regresses per-byte WE.
module tb_soc #(
  parameter bit UseDffram = 1'b0
);

  // 20 MHz system clock (bypasses the FPGA PLL - we drive clk directly)
  logic clk = 1'b0;
  always #25 clk = ~clk;

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

  // Fast UART for simulation: 2 Mbaud @ 20 MHz -> 10 clocks per bit
  localparam int unsigned SimBaud = 2_000_000;
  localparam int unsigned BitNs   = 500;

  logic [15:0] gp_i = 16'h0000;
  wire  [15:0] gp_o;
  wire [11:0] pwm;
  wire        uart_tx;
  logic       uart_rx = 1'b1;

  ibex_demo_system #(
    .GpiWidth       (16),
    .GpoWidth       (16),
    .PwmWidth       (12),
    .ClockFrequency (20_000_000),
    .BaudRate       (SimBaud),
    .SRAMInitFile   ("sw/asm-demo/sram_init_sim.vmem"),
    .BootInitFile   ("dv/xsim/boot_sram_dv.mem"), // DV-only SRAM boot; real ROM is direct-XIP
    .UseDffram      (UseDffram)
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

  // -------------------------------------------------------------------
  // UART TX decoder - every byte the SoC sends is printed and buffered
  // -------------------------------------------------------------------
  byte rx_buf [0:4095];
  int  rx_cnt = 0;
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
      if (rx_cnt < 4096) begin
        rx_buf[rx_cnt] = b;
        rx_cnt++;
      end
    end
  end

  function automatic bit saw_byte(byte needle);
    for (int i = 0; i < rx_cnt; i++)
      if (rx_buf[i] == needle) return 1;
    return 0;
  endfunction

  task automatic send_byte(input byte b);
    uart_rx = 1'b0;  #(BitNs);
    for (int i = 0; i < 8; i++) begin
      uart_rx = b[i];  #(BitNs);
    end
    uart_rx = 1'b1;  #(BitNs);
  endtask

  // -------------------------------------------------------------------
  // GPIO monitor (first 16 changes logged)
  // -------------------------------------------------------------------
  int led_changes = 0;
  always @(gp_o) begin
    led_changes++;
    if (led_changes <= 16)
      $display("[%0t] LEDs/GPO = %b", $time, gp_o);
  end

  // PWM duty counters, resettable from the sequence below
  int blue_hi = 0, red_hi = 0;
  always @(posedge clk) begin
    if (pwm[0]) blue_hi <= blue_hi + 1;   // pwm[0] = led0_b
    if (pwm[2]) red_hi  <= red_hi  + 1;   // pwm[2] = led0_r
  end

  int pass_cnt = 0, fail_cnt = 0;
  task automatic check(input bit cond, input string name);
    if (cond) begin pass_cnt++; $display("PASS: %s", name); end
    else      begin fail_cnt++; $display("FAIL: %s", name); end
  endtask

  // -------------------------------------------------------------------
  // Test sequence
  // -------------------------------------------------------------------
  initial begin
    int red_before, blue_before;
    $display("=== Ibex SoC UART-command simulation ===");

    // Phase 1: boot, banner, default walking pattern, auto RGB
    #2_000_000;
    check(rx_cnt > 10, "UART TX banner present");
    check(led_changes >= 3, "default walking pattern runs");

    // Phase 2: '3' -> alternating pattern (0xA0 <-> 0x50)
    $display("\n[%0t] >>> command '3' (alternating pattern)", $time);
    send_byte("3");
    #1_000_000;
    check(saw_byte("3"), "'3' command acked (echoed)");
    check(gp_o[7:4] == 4'hA || gp_o[7:4] == 4'h5,
          "pattern 3 active (LEDs alternate A/5)");

    // Phase 3: 'b' -> RGB forced blue; red channel must go silent
    $display("[%0t] >>> command 'b' (force RGB blue)", $time);
    send_byte("b");
    #500_000;                       // let the forced colour take effect
    red_before  = red_hi;
    blue_before = blue_hi;
    #400_000;                       // measure window
    check(saw_byte("b"), "'b' command acked (echoed)");
    check(blue_hi - blue_before > 0,  "blue PWM active after 'b'");
    check(red_hi  - red_before  == 0, "red PWM silent after 'b'");

    // Phase 4: plain echo of a non-command byte
    send_byte("K");
    #300_000;
    check(saw_byte("K"), "non-command byte 'K' echoed");

    // Phase 5: button + switches -> LEDs mirror switches
    $display("[%0t] >>> BTN0 held, SW=0101", $time);
    gp_i = 8'b0101_0001;
    #1_000_000;
    check(gp_o[7:4] == 4'b0101, "LEDs mirror switches while button held");
    gp_i = 8'h00;

    $display("\n=== RESULTS: %0d PASS, %0d FAIL ===", pass_cnt, fail_cnt);
    $finish;
  end

endmodule
