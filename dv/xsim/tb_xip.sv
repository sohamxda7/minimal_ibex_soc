// ============================================================================
// XIP execute-in-place simulation: the CPU boots from a 2-instruction SRAM
// trampoline (sw/asm-demo/xip_stub.vmem) and then runs ENTIRELY from a
// behavioral SPI NOR flash (dv/xsim/spi_nor_flash_model.sv) through the
// spi_flash_xip controller at 0x2000_0000.
//
// The flash program (sw/asm-demo/xip_test.py) prints "XIP OK" if both the
// instruction-fetch and data-load paths return correct (little-endian) words,
// "XIP ER" if a data load mismatches, nothing at all if fetch is broken.
//
// Timing: one 32-bit XIP read = 64 SPI clocks = 512 system clocks at
// CLK_DIV=4, i.e. ~25.6 us per fetch at 20 MHz. The ~40-instruction program
// plus prefetch overshoot needs a few ms of simulated time.
//
// Run from the repo root after the usual filelist compile:
//   xelab tb_xip -s xip_sim -timescale 1ns/1ps
//   xsim xip_sim -R
// ============================================================================

`timescale 1ns / 1ps

module tb_xip;

  logic clk = 1'b0;
  always #25 clk = ~clk;                 // 20 MHz

  logic rst_n = 1'b0;
  initial begin
    repeat (20) @(posedge clk);
    rst_n = 1'b1;
  end

  logic [15:0] gp_i = 16'h0000;
  wire  [15:0] gp_o;
  wire [11:0] pwm;
  wire        uart_tx;

  wire flash_sck, flash_csn, flash_mosi, flash_miso;

  ibex_demo_system #(
    .GpiWidth       (16),
    .GpoWidth       (16),
    .PwmWidth       (12),
    .ClockFrequency (20_000_000),
    .BaudRate       (2_000_000),
    .SRAMInitFile   ("sw/asm-demo/xip_stub.vmem")
  ) dut (
    .clk_sys_i  (clk),
    .rst_sys_ni (rst_n),
    .gp_i       (gp_i),
    .gp_o       (gp_o),
    .pwm_o      (pwm),
    .uart_rx_i  (1'b1),
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

  // Behavioral SPI NOR flash: firmware at flash offset 0x40_0000, exactly
  // where it will live on hardware (behind the A7-100T bitstream).
  spi_nor_flash_model #(
    .WINDOW_BYTES (65536),
    .BASE_OFFSET  (24'h40_0000),
    .INIT_FILE    ("sw/asm-demo/xip_test_flash.vmem")
  ) u_flash (
    .sck  (flash_sck),
    .csn  (flash_csn),
    .mosi (flash_mosi),
    .miso (flash_miso)
  );

  // UART decoder (2 Mbaud)
  localparam int BitNs = 500;
  byte ubuf [0:63];
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
      if (un < 64) begin ubuf[un] = b; un++; end
    end
  end

  function automatic bit saw(string needle);
    for (int i = 0; i + 1 < un; i++)
      if (ubuf[i] == needle[0] && ubuf[i+1] == needle[1]) return 1;
    return 0;
  endfunction

  initial begin
    $display("=== SPI flash XIP simulation (CPU executing from flash) ===");
    for (int ms = 0; ms < 40; ms++) begin
      #1_000_000;
      if (un >= 7) break;                // "XIP OK\r" = 7 bytes
    end
    #1_000_000;

    if (saw("OK"))
      $display("\nPASS: CPU executed from SPI flash, data loads correct");
    else if (saw("ER"))
      $display("\nFAIL: XIP data load returned wrong word (byte order?)");
    else
      $display("\nFAIL: no UART output - XIP instruction fetch broken (bytes=%0d)", un);
    $finish;
  end

endmodule
