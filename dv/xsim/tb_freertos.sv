// ============================================================================
// FreeRTOS boot simulation: the CPU boots via the SRAM trampoline into the
// FreeRTOS image executing in place from the behavioral SPI NOR flash.
//
// PASS criteria (UART, 2 Mbaud):
//   1. "FreeRTOS on Ibex"  banner  -> C runtime + XIP fetch + data copy OK
//   2. two "tick=" lines           -> timer interrupt, vectored trap entry,
//                                     context switch, vTaskDelay all OK
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

  logic rst_n = 1'b0;
  initial begin
    repeat (20) @(posedge clk);
    rst_n = 1'b1;
  end

  logic [7:0] gp_i = 8'h00;
  wire  [7:0] gp_o;
  wire [11:0] pwm;
  wire        uart_tx;

  wire flash_sck, flash_csn, flash_mosi, flash_miso;

  ibex_demo_system #(
    .GpiWidth       (8),
    .GpoWidth       (8),
    .PwmWidth       (12),
    .ClockFrequency (20_000_000),
    .BaudRate       (2_000_000),
    .SRAMInitFile   ("sw/asm-demo/xip_stub.vmem"),
    .XipClkDiv      (1)
  ) dut (
    .clk_sys_i  (clk),
    .rst_sys_ni (rst_n),
    .gp_i       (gp_i),
    .gp_o       (gp_o),
    .pwm_o      (pwm),
    .uart_rx_i  (1'b1),
    .uart_tx_o  (uart_tx),
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

  initial begin
    $display("=== FreeRTOS XIP boot simulation ===");
    for (int ms = 0; ms < 150; ms++) begin
      #1_000_000;
      if (ms % 10 == 9)
        $display("[tb] %0d ms simulated, %0d uart bytes", ms + 1, un);
      if (count_str("tick=") >= 2) break;
    end

    if (count_str("tick=") >= 2)
      $display("\nPASS: FreeRTOS scheduler running (banner=%0d ticks=%0d)",
               saw_banner(), count_str("tick="));
    else if (saw_banner())
      $display("\nFAIL: banner only - scheduler/tick never ran (bytes=%0d)", un);
    else
      $display("\nFAIL: no UART output at all (bytes=%0d)", un);
    $finish;
  end

endmodule
