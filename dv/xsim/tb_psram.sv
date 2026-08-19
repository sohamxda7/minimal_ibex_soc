// ============================================================================
// SPI PSRAM (external memory) write+readback via SPI host RX register
// Auto-structured from the shared v1.1 peripheral-tb template; program:
// sw/asm-demo/psram_test.vmem (see periph_tests.py). PASS = "PSR OK" on console UART.
// ============================================================================

`timescale 1ns / 1ps

module tb_psram;

  logic clk = 1'b0;
  always #25 clk = ~clk;                 // 20 MHz

  logic rst_n = 1'b0;
  initial begin
    repeat (20) @(posedge clk);
    rst_n = 1'b1;
  end

  logic [15:0] gp_i = 16'h0000;
  tri0 psram_so;

  wire spi_mosi, spi_sck;
  wire [15:0] gp_o;
  wire [11:0] pwm;
  wire        uart_tx;

  ibex_demo_system #(
    .GpiWidth       (16),
    .GpoWidth       (16),
    .PwmWidth       (12),
    .ClockFrequency (20_000_000),
    .BaudRate       (2_000_000),
    .Uart2BaudRate  (2_000_000),
    .SRAMInitFile   ("sw/asm-demo/psram_test.vmem"),
    .BootInitFile   ("dv/xsim/boot_sram_dv.mem") // DV-only SRAM boot; real ROM is direct-XIP
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
    .spi_rx_i   (psram_so),
    .spi_tx_o   (spi_mosi),
    .spi_sck_o  (spi_sck),
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


  // External 8 MB PSRAM on the shared SPI-host bus, CS = gp_o[8]
  spi_psram_model u_psram (
    .sck  (spi_sck),
    .csn  (gp_o[8]),
    .mosi (spi_mosi),
    .so   (psram_so)
  );

  // Console UART decoder (2 Mbaud)
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
    $display("=== SPI PSRAM (external memory) write+readback via SPI host RX register ===");
    for (int t = 0; t < 40; t++) begin
      #100_000;                       // 100 us steps, 4 ms cap
      if (saw("OK") || saw("ER")) break;
    end
    #50_000;


    if (saw("OK"))
      $display("\nPASS: PSRAM write + readback correct over SPI host (RX register works)");
    else if (saw("ER"))
      $display("\nFAIL: program detected wrong data (PSR ER)");
    else
      $display("\nFAIL: no verdict - SPI/PSRAM path hung (bytes=%0d)", un);
    $finish;
  end

endmodule
