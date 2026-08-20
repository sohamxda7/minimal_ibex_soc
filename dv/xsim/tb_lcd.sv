// ============================================================================
// Tier-1 "toy interfacing" simulation: a behavioural ST7735 LCD model hangs
// on the SoC's SPI + DISP_CTRL pins while the CPU runs the hand-assembled
// init/pixel sequence (sw/asm-demo/lcd_spi_test_sim.vmem).
//
// The model:
//   * samples MOSI on rising SCK edges (SPI mode 0, MSB first) while CS=0
//   * classifies each completed byte as command/data via the DC line
//   * decodes and prints known ST7735 commands
//   * checks the exact sequence the program must produce:
//       SWRESET SLPOUT COLMOD(05) DISPON CASET(00 00 00 04)
//       RASET(00 00 00 04) RAMWR(10 pixel bytes F8 00 x5)
//
// Run from the repo root after the usual filelist compile:
//   xvlog -sv dv/xsim/tb_lcd.sv
//   xelab tb_lcd -s lcd_sim -timescale 1ns/1ps
//   xsim lcd_sim -R
// ============================================================================

`timescale 1ns / 1ps

module tb_lcd;

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
  wire        spi_tx, spi_sck;

  // LCD control pins (= DISP_CTRL[3:0] = gp_o[3:0], per lcd_st7735 demo)
  wire lcd_cs  = gp_o[0];
  wire lcd_rst = gp_o[1];
  wire lcd_dc  = gp_o[2];
  wire lcd_bl  = gp_o[3];

  ibex_demo_system #(
    .GpiWidth       (16),
    .GpoWidth       (16),
    .PwmWidth       (12),
    .ClockFrequency (20_000_000),
    .BaudRate       (2_000_000),
    .SRAMInitFile   ("sw/asm-demo/lcd_spi_test_sim.vmem"),
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
    .spi_tx_o   (spi_tx),
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

  // -------------------------------------------------------------------
  // Behavioural ST7735 receiver
  // -------------------------------------------------------------------
  byte  rx_bytes [0:255];
  bit   rx_is_cmd [0:255];
  int   rx_n = 0;

  logic [7:0] shreg = '0;
  int         bitcnt = 0;
  bit         seen_reset_pulse = 0;

  // History: this SPI host used to update MOSI on the rising SCK edge, and
  // a delayed-copy MOSI sample was the workaround that made the model decode
  // it - which MASKED a real mode-0 hold-time bug that a physical ST7735
  // then exposed (white screen, 2026-08-18; fixed in spi_host.sv - TX now
  // launches on the falling edge). The workaround was REMOVED 2026-08-19
  // (CLAUDE.md Rule 1b): a datasheet mode-0 slave samples the wire AT the
  // rising edge, and this model must do the same so any hold-time
  // regression fails here in simulation instead of on a panel.

  always @(negedge lcd_rst) if (rst_n) begin
    seen_reset_pulse = 1;
    $display("[%0t] ST7735: hardware RESET asserted", $time);
  end

  // byte assembly: sample the RAW MOSI wire on rising SCK while selected
  always @(posedge spi_sck) begin
    if (!lcd_cs) begin
      shreg  = {shreg[6:0], spi_tx};     // MSB first, strict mode 0
      bitcnt = bitcnt + 1;
      if (bitcnt == 8) begin
        if (rx_n < 256) begin
          rx_bytes[rx_n]  = shreg;
          rx_is_cmd[rx_n] = (lcd_dc == 1'b0);
          if (lcd_dc == 1'b0) begin
            case (shreg)
              8'h01: $display("[%0t] ST7735 cmd: SWRESET", $time);
              8'h11: $display("[%0t] ST7735 cmd: SLPOUT",  $time);
              8'h3A: $display("[%0t] ST7735 cmd: COLMOD",  $time);
              8'h29: $display("[%0t] ST7735 cmd: DISPON",  $time);
              8'h2A: $display("[%0t] ST7735 cmd: CASET",   $time);
              8'h2B: $display("[%0t] ST7735 cmd: RASET",   $time);
              8'h2C: $display("[%0t] ST7735 cmd: RAMWR",   $time);
              default: $display("[%0t] ST7735 cmd: 0x%02x (unknown)", $time, shreg);
            endcase
          end
          rx_n = rx_n + 1;
        end
        bitcnt = 0;
      end
    end
  end

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

  // -------------------------------------------------------------------
  // Expected transaction list and checking
  // -------------------------------------------------------------------
  //   index: 0    1    2    3    4    5..8         9    10..13       14   15..24
  //   byte : 01   11   3A   05   29   2A 0 0 0 4   2B   0 0 0 4     2C   F8 00 x5
  byte expect_b [0:24];
  bit  expect_c [0:24];
  initial begin
    expect_b[0]=8'h01; expect_c[0]=1;
    expect_b[1]=8'h11; expect_c[1]=1;
    expect_b[2]=8'h3A; expect_c[2]=1;
    expect_b[3]=8'h05; expect_c[3]=0;
    expect_b[4]=8'h29; expect_c[4]=1;
    expect_b[5]=8'h2A; expect_c[5]=1;
    expect_b[6]=8'h00; expect_c[6]=0;
    expect_b[7]=8'h00; expect_c[7]=0;
    expect_b[8]=8'h00; expect_c[8]=0;
    expect_b[9]=8'h04; expect_c[9]=0;
    expect_b[10]=8'h2B; expect_c[10]=1;
    expect_b[11]=8'h00; expect_c[11]=0;
    expect_b[12]=8'h00; expect_c[12]=0;
    expect_b[13]=8'h00; expect_c[13]=0;
    expect_b[14]=8'h04; expect_c[14]=0;
    expect_b[15]=8'h2C; expect_c[15]=1;
    for (int i = 0; i < 5; i++) begin
      expect_b[16+2*i]=8'hF8; expect_c[16+2*i]=0;
      expect_b[17+2*i]=8'h00; expect_c[17+2*i]=0;
    end
  end

  int pass_cnt = 0, fail_cnt = 0;
  task automatic check(input bit cond, input string name);
    if (cond) begin pass_cnt++; $display("PASS: %s", name); end
    else      begin fail_cnt++; $display("FAIL: %s", name); end
  endtask

  initial begin
    $display("=== ST7735 LCD interface simulation ===");
    // Wait for the full sequence (26 bytes) or time out
    for (int ms = 0; ms < 40; ms++) begin
      #1_000_000;
      if (rx_n >= 26) break;
    end
    #200_000;

    check(seen_reset_pulse, "hardware reset pulse seen");
    check(rx_n == 26, $sformatf("received 26 SPI bytes (got %0d)", rx_n));
    if (rx_n >= 26) begin
      bit all_ok = 1;
      for (int i = 0; i < 26; i++) begin
        if (rx_bytes[i] !== expect_b[i] || rx_is_cmd[i] !== expect_c[i]) begin
          all_ok = 0;
          $display("  mismatch at byte %0d: got 0x%02x (%s), expected 0x%02x (%s)",
                   i, rx_bytes[i], rx_is_cmd[i] ? "cmd" : "data",
                   expect_b[i], expect_c[i] ? "cmd" : "data");
        end
      end
      check(all_ok, "full init + pixel sequence matches, incl. cmd/data DC phases");
    end
    begin
      bit got_ok = 0;
      for (int i = 0; i + 1 < un; i++)
        if (ubuf[i] == "O" && ubuf[i+1] == "K") got_ok = 1;
      check(got_ok, "program reported 'LCD OK' over UART");
    end
    check(gp_o[3] == 1'b1, "backlight left on");

    $display("\n=== RESULTS: %0d PASS, %0d FAIL ===", pass_cnt, fail_cnt);
    $finish;
  end

endmodule
