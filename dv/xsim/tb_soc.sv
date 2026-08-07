// ============================================================================
// Full-SoC xsim testbench: boots the Ibex from the boot ROM, which jumps to
// the program baked into SRAM (sw/asm-demo/sram_init_sim.vmem), then checks
// every user-visible function:
//   * UART TX (banner), UART RX (echo)
//   * GPIO out (LED walking pattern), GPIO in (buttons/switches)
//   * PWM/RGB breathing (duty cycle is sampled and printed over time)
//
// Run from the REPO ROOT (paths to boot.mem / sram vmem are relative):
//   xvlog -sv -f dv/xsim/filelist.f
//   xelab tb_soc -s soc_sim -timescale 1ns/1ps
//   xsim soc_sim -R
// ============================================================================

`timescale 1ns / 1ps

module tb_soc;

  // 20 MHz system clock (bypasses the FPGA PLL — we drive clk directly)
  logic clk = 1'b0;
  always #25 clk = ~clk;

  logic rst_n = 1'b0;
  initial begin
    repeat (20) @(posedge clk);
    rst_n = 1'b1;
  end

  // Fast UART for simulation: 2 Mbaud @ 20 MHz -> 10 clocks per bit
  localparam int unsigned SimBaud  = 2_000_000;
  localparam int unsigned BitNs    = 500;        // 10 clk * 50 ns

  logic [7:0] gp_i = 8'h00;
  wire  [7:0] gp_o;
  wire [11:0] pwm;
  wire        uart_tx;
  logic       uart_rx = 1'b1;

  ibex_demo_system #(
    .GpiWidth       (8),
    .GpoWidth       (8),
    .PwmWidth       (12),
    .ClockFrequency (20_000_000),
    .BaudRate       (SimBaud),
    .SRAMInitFile   ("sw/asm-demo/sram_init_sim.vmem")
  ) dut (
    .clk_sys_i  (clk),
    .rst_sys_ni (rst_n),

    .gp_i       (gp_i),
    .gp_o       (gp_o),
    .pwm_o      (pwm),

    .uart_rx_i  (uart_rx),
    .uart_tx_o  (uart_tx),

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
  // UART TX decoder — every byte the SoC sends is printed to the console
  // -------------------------------------------------------------------
  byte rx_buf [0:4095];
  int  rx_cnt = 0;
  initial begin
    forever begin
      byte b;
      @(negedge uart_tx);              // start bit
      #(BitNs + BitNs/2);              // centre of data bit 0
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

  // PC types a byte
  task automatic send_byte(input byte b);
    uart_rx = 1'b0;  #(BitNs);
    for (int i = 0; i < 8; i++) begin
      uart_rx = b[i];  #(BitNs);
    end
    uart_rx = 1'b1;  #(BitNs);
  endtask

  // -------------------------------------------------------------------
  // GPIO monitor — log LED changes (first 12 only, to keep output short)
  // -------------------------------------------------------------------
  int led_changes = 0;
  always @(gp_o) begin
    led_changes++;
    if (led_changes <= 12)
      $display("[%0t ns] LEDs/GPO = %b", $time, gp_o);
  end

  // -------------------------------------------------------------------
  // PWM duty sampler — measure duty of the red channel of RGB LED0
  // (pwm[2] = led0_r per pins_artya7.xdc) every 100 us
  // -------------------------------------------------------------------
  int hi_cnt = 0, tot_cnt = 0;
  always @(posedge clk) begin
    tot_cnt <= tot_cnt + 1;
    if (pwm[2]) hi_cnt <= hi_cnt + 1;
    if (tot_cnt == 2000) begin  // every 100 us
      $display("[%0t ns] RGB0 red duty = %0d/2000", $time, hi_cnt);
      hi_cnt  <= 0;
      tot_cnt <= 0;
    end
  end

  // -------------------------------------------------------------------
  // Test sequence
  // -------------------------------------------------------------------
  initial begin
    $display("=== Ibex SoC bring-up simulation ===");

    // Phase 1: boot + banner + LED walk + RGB ramp (nothing driven)
    #3_000_000;   // 3 ms

    // Phase 2: UART echo
    $display("\n[%0t ns] >>> sending 'K' over UART RX", $time);
    send_byte("K");
    #300_000;

    // Phase 3: button + switches -> LEDs must mirror switches.
    // The program refreshes LEDs every 32nd main loop (~2.5 ms of sim time),
    // so hold the button for over 3 ms before checking.
    $display("[%0t] >>> BTN0 held, SW=0101", $time);
    gp_i = 8'b0101_0001;   // {SW=0101, BTN=0001}
    #3_200_000;
    if (gp_o[7:4] == 4'b0101)
      $display("PASS: LEDs mirror switches while button held (gp_o=%b)", gp_o);
    else
      $display("FAIL: LEDs did not mirror switches (gp_o=%b)", gp_o);
    gp_i = 8'h00;
    #500_000;

    // Verdict
    $display("\n=== RESULTS ===");
    if (rx_cnt > 10)  $display("PASS: UART TX produced %0d bytes", rx_cnt);
    else              $display("FAIL: UART TX produced almost nothing");
    begin
      bit got_echo = 0;
      for (int i = 0; i < rx_cnt; i++)
        if (rx_buf[i] == "K") got_echo = 1;
      if (got_echo) $display("PASS: UART RX echo ('K' came back)");
      else          $display("FAIL: UART RX echo missing");
    end
    if (led_changes >= 3)   $display("PASS: LEDs changed %0d times", led_changes);
    else                    $display("FAIL: LEDs static");
    $display("(RGB duty progression printed above = breathing proof)");
    $finish;
  end

endmodule
