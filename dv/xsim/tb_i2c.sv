// ============================================================================
// Tier-2 "toy interfacing" simulation: the SoC's OpenCores I2C master talks
// to the team's i2c_slave_bfm (EEPROM-style slave at 0x50, mem[i]=i) over a
// modelled open-drain bus. The CPU runs sw/asm-demo/i2c_test.vmem, which
// reads register 0x42 and prints "I2C OK" if the byte matches.
//
// The open-drain wiring here mirrors top_artya7.sv exactly (OpenCores
// pad-enable is ACTIVE LOW). `tri1` nets model the bus pull-ups.
//
// Run from the repo root after the usual filelist compile:
//   xvlog -sv rtl/system/i2c_slave_bfm.sv dv/xsim/tb_i2c.sv
//   xelab tb_i2c -s i2c_sim -timescale 1ns/1ps
//   xsim i2c_sim -R
// ============================================================================

`timescale 1ns / 1ps

module tb_i2c;

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

  // Open-drain I2C bus with pull-ups (tri1 = pulled high when undriven)
  tri1 scl, sda;
  wire scl_o, scl_oe, sda_o, sda_oe;
  assign scl = scl_oe ? 1'bz : scl_o;    // oe active low: 0 = drive
  assign sda = sda_oe ? 1'bz : sda_o;

  ibex_demo_system #(
    .GpiWidth       (16),
    .GpoWidth       (16),
    .PwmWidth       (12),
    .ClockFrequency (20_000_000),
    .BaudRate       (2_000_000),
    .SRAMInitFile   ("sw/asm-demo/i2c_test.vmem")
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
    .xip_spi_sck_o  (),
    .xip_spi_csn_o  (),
    .xip_spi_mosi_o (),
    .xip_spi_miso_i (1'b0),
    .i2c_scl_i    (scl),
    .i2c_scl_o    (scl_o),
    .i2c_scl_oe_o (scl_oe),
    .i2c_sda_i    (sda),
    .i2c_sda_o    (sda_o),
    .i2c_sda_oe_o (sda_oe),
    .tck_i   (1'b0),
    .tms_i   (1'b0),
    .trst_ni (1'b1),
    .td_i    (1'b0),
    .td_o    ()
  );

  // The simulated sensor: team-authored I2C slave BFM at address 0x50
  i2c_slave_bfm #(
    .SLAVE_ADDR (7'h50)
  ) u_sensor (
    .clk   (clk),
    .rst_n (rst_n),
    .scl   (scl),
    .sda   (sda)
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
    $display("=== I2C master <-> slave BFM simulation ===");
    // 100 kHz transaction (~4 bytes) finishes well inside 5 ms
    for (int ms = 0; ms < 20; ms++) begin
      #1_000_000;
      if (un >= 6) break;
    end
    #500_000;

    if (saw("OK")) $display("\nPASS: register 0x42 read correctly over I2C");
    else if (saw("ER")) $display("\nFAIL: transaction completed but data wrong");
    else $display("\nFAIL: no verdict from program (bus hung?) uart bytes=%0d", un);
    $finish;
  end

endmodule
