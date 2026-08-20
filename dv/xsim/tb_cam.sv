// ============================================================================
// Camera path: OV7670-FIFO byte readout over gp_i[15:8] + checksum
// Auto-structured from the shared v1.1 peripheral-tb template; program:
// sw/asm-demo/cam_test.vmem (see periph_tests.py). PASS = "CAM OK" on console UART.
// ============================================================================

`timescale 1ns / 1ps

module tb_cam;

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

  wire [7:0] cam_d;
  wire [15:0] gp_i = {cam_d, 8'h00};

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
    .SRAMInitFile   ("sw/asm-demo/cam_test.vmem"),
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
    .spi_rx_i   (1'b0),
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


  // OV7670 + AL422 FIFO module: ctrl on gp_o[12:10], data on gp_i[15:8].
  // Explicit intermediate nets: xsim edge events through bit-select port
  // connections proved unreliable (RCLK posedges never reached the model).
  wire cam_wen    = gp_o[10];
  wire cam_rrst_n = gp_o[11];
  wire cam_rclk   = gp_o[12];

  ov7670_fifo_model u_cam (
    .wen    (cam_wen),
    .rrst_n (cam_rrst_n),
    .rclk   (cam_rclk),
    .d      (cam_d)
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
    $display("=== Camera path: OV7670-FIFO byte readout over gp_i[15:8] + checksum ===");
    for (int t = 0; t < 40; t++) begin
      #100_000;                       // 100 us steps, 4 ms cap
      if (saw("OK") || saw("ER")) break;
    end
    #50_000;


    if (saw("OK"))
      $display("\nPASS: 16-byte frame window read via FIFO handshake, checksum correct");
    else if (saw("ER"))
      $display("\nFAIL: program detected wrong data (CAM ER)");
    else
      $display("\nFAIL: no verdict - camera FIFO path hung (bytes=%0d)", un);
    $finish;
  end

endmodule
