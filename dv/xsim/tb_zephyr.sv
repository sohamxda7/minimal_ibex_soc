// ============================================================================
// Zephyr boot testbench: loads the Zephyr image (built by west, converted by
// sw/tools/bin2vmem.py into build/zephyr_sram.vmem) into the SoC's SRAM and
// watches the UART for the boot banner + "Hello World! ibex_arty".
//
// Run from the REPO ROOT (after the usual xvlog of filelist.f + stubs):
//   xvlog -sv dv/xsim/tb_zephyr.sv
//   xelab tb_zephyr -s zephyr_sim -timescale 1ns/1ps
//   xsim zephyr_sim -R
//
// The UART runs at 2 Mbaud in simulation (the RTL BaudRate parameter);
// Zephyr never programs a divisor, so this only affects the testbench clock
// budget, not the software.
// ============================================================================

`timescale 1ns / 1ps

module tb_zephyr;

  logic clk = 1'b0;
  always #25 clk = ~clk;                 // 20 MHz

  logic rst_n = 1'b0;
  initial begin
    repeat (20) @(posedge clk);
    rst_n = 1'b1;
  end

  localparam int unsigned SimBaud = 2_000_000;
  localparam int unsigned BitNs   = 500;

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
    .SRAMInitFile   ("build/zephyr_sram.vmem")
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

  // UART decoder + rolling match for "Hello World"
  byte match [0:10];
  initial begin
    match[0]="H"; match[1]="e"; match[2]="l"; match[3]="l"; match[4]="o";
    match[5]=" "; match[6]="W"; match[7]="o"; match[8]="r"; match[9]="l";
    match[10]="d";
  end

  byte win [0:10];
  int  rx_cnt = 0;
  bit  got_hello = 0;

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
      rx_cnt++;
      for (int i = 0; i < 10; i++) win[i] = win[i+1];
      win[10] = b;
      begin
        bit m = 1;
        for (int i = 0; i < 11; i++)
          if (win[i] != match[i]) m = 0;
        if (m) got_hello = 1;
      end
    end
  end

  initial begin
    $display("=== Zephyr boot simulation on the ARF Ibex SoC ===");
    // Poll for success every 1 ms of sim time, give up after 60 ms
    for (int ms = 0; ms < 60; ms++) begin
      #1_000_000;
      if (got_hello) begin
        #2_000_000;   // let the line finish printing
        $display("\n\nPASS: Zephyr booted and printed Hello World (%0d UART bytes, %0d us sim time)",
                 rx_cnt, (ms + 3) * 1000);
        $finish;
      end
    end
    $display("\n\nFAIL: no 'Hello World' within 60 ms sim time (%0d UART bytes seen)", rx_cnt);
    $finish;
  end

endmodule
