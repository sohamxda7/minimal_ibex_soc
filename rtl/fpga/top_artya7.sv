// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// This is the top level SystemVerilog file that connects the IO on the board to the Ibex Demo System.
module top_artya7 #(
  parameter SRAMInitFile = "",
  // XIP SPI clock divider: SCK = 20MHz/(2*div). The onboard S25FL128 is
  // rated 50 MHz for cmd 0x03, so 1 (10 MHz) is safe; spec default is 4.
  parameter int unsigned XipClkDiv = 1
) (
  // These inputs are defined in data/pins_artya7.xdc
  input         IO_CLK,
  input         IO_RST_N,
  input  [ 3:0] SW,
  input  [ 3:0] BTN,
  output [ 3:0] LED,
  output [11:0] RGB_LED,
  output [ 3:0] DISP_CTRL,
  input         UART_RX,
  output        UART_TX,
  input         SPI_RX,
  output        SPI_TX,
  output        SPI_SCK,
  // I2C bus on Pmod JA pins 1/2 (open-drain, internal + module pull-ups)
  inout         I2C_SCL,
  inout         I2C_SDA,
  // Onboard 16 MB QSPI config flash, used single-bit for XIP.
  // NOTE: no SCK port here — the flash clock is the FPGA's dedicated CCLK
  // configuration pin, which user logic can only reach through the
  // STARTUPE2 primitive below.
  output        QSPI_CS,
  output        QSPI_DQ0,   // MOSI
  input         QSPI_DQ1,   // MISO
  // v1.1 production peripherals (docs/PRODUCTION_PERIPHERALS.md):
  // ESP32 companion UART (WiFi/TCP-IP offload) - Pmod JC1/JC2
  output        UART2_TX,
  input         UART2_RX,
  // Chip selects for external SPI devices sharing the SPI host bus
  output        PSRAM_CS,   // APS6404 8MB PSRAM   - Pmod JC3
  output        ADC_CS,     // MCP3202 mic ADC     - Pmod JC4
  // OV7670-FIFO camera: control on JC, 8-bit data bus on Pmod JB
  output        CAM_WEN,    // FIFO write enable   - Pmod JC7
  output        CAM_RRST,   // FIFO read reset     - Pmod JC8
  output        CAM_RCLK,   // FIFO read clock     - Pmod JC9
  input  [7:0]  CAM_D,      // FIFO data out       - Pmod JB
  // Speaker: PWM channel 3 through an external amplifier - Pmod JC10
  output        SPKR
);

  logic clk_sys, rst_sys_n;
  logic xip_sck;
  logic [15:0] gp_out;
  logic [11:0] pwm_out;

  // GPO map (v1.1): [3:0] DISP_CTRL, [7:4] LED, [8] PSRAM_CS, [9] ADC_CS,
  // [10] CAM_WEN, [11] CAM_RRST, [12] CAM_RCLK, [15:13] spare.
  // CS lines idle high: board pull-ups cover the reset window, software
  // drives them high first thing (drivers do read-modify-write only).
  assign DISP_CTRL = gp_out[3:0];
  assign LED       = gp_out[7:4];
  assign PSRAM_CS  = gp_out[8];
  assign ADC_CS    = gp_out[9];
  assign CAM_WEN   = gp_out[10];
  assign CAM_RRST  = gp_out[11];
  assign CAM_RCLK  = gp_out[12];
  assign SPKR      = pwm_out[3];   // PWM ch3 = speaker (chip pin plan: dedicated pad)
  assign RGB_LED   = pwm_out;

  // I2C open-drain pad wiring
  logic i2c_scl_o, i2c_scl_oe, i2c_sda_o, i2c_sda_oe;
  assign I2C_SCL = i2c_scl_oe ? 1'bz : i2c_scl_o;
  assign I2C_SDA = i2c_sda_oe ? 1'bz : i2c_sda_o;

  // Instantiating the Ibex Demo System.
  // ClockFrequency MUST match what clkgen_xil7series produces (20 MHz — the
  // PLL divide was corrected from 50 MHz) or the UART baud will be wrong.
  ibex_demo_system #(
    .GpiWidth       ( 16          ),
    .GpoWidth       ( 16          ),
    .PwmWidth       ( 12          ),
    .ClockFrequency ( 20_000_000  ),
    .BaudRate       ( 115_200     ),
    .SRAMInitFile   ( SRAMInitFile ),
    .XipClkDiv      ( XipClkDiv   )
  ) u_ibex_demo_system (
    //input
    .clk_sys_i (clk_sys),
    .rst_sys_ni(rst_sys_n),
    .gp_i      ({CAM_D, SW, BTN}),
    .uart_rx_i (UART_RX),

    //output
    .gp_o     (gp_out),
    .pwm_o    (pwm_out),
    .uart_tx_o(UART_TX),

    .uart2_rx_i(UART2_RX),
    .uart2_tx_o(UART2_TX),

    .spi_rx_i (SPI_RX),
    .spi_tx_o (SPI_TX),
    .spi_sck_o(SPI_SCK),

    // XIP SPI flash: onboard 16 MB QSPI flash, single-bit mode.
    // Firmware lives at flash offset 0x40_0000 (behind the bitstream),
    // memory-mapped at 0x2040_0000. See docs/ASIC_SPEC.md section 4.
    .xip_spi_sck_o  (xip_sck),
    .xip_spi_csn_o  (QSPI_CS),
    .xip_spi_mosi_o (QSPI_DQ0),
    .xip_spi_miso_i (QSPI_DQ1),

    // I2C — routed to Pmod JA pins 1/2 as an open-drain bus.
    // OpenCores pad-enable is ACTIVE LOW: oe=0 -> drive (pad_o is 0),
    // oe=1 -> release (pull-ups make the 1).
    .i2c_scl_i    (I2C_SCL),
    .i2c_scl_o    (i2c_scl_o),
    .i2c_scl_oe_o (i2c_scl_oe),
    .i2c_sda_i    (I2C_SDA),
    .i2c_sda_o    (i2c_sda_o),
    .i2c_sda_oe_o (i2c_sda_oe),

    .trst_ni(1'b1),
    .tms_i  (1'b0),
    .tck_i  (1'b0),
    .td_i   (1'b0),
    .td_o   ()
  );

  // The flash SCK pin is the FPGA's dedicated CCLK configuration pin: after
  // configuration it is only reachable through STARTUPE2.USRCCLKO. All other
  // STARTUPE2 functions are unused/tied off per UG470.
  STARTUPE2 #(
    .PROG_USR      ("FALSE"),
    .SIM_CCLK_FREQ (10.0)
  ) u_startupe2 (
    .CFGCLK    (),
    .CFGMCLK   (),
    .EOS       (),
    .PREQ      (),
    .CLK       (1'b0),
    .GSR       (1'b0),
    .GTS       (1'b0),
    .KEYCLEARB (1'b0),
    .PACK      (1'b0),
    .USRCCLKO  (xip_sck),
    .USRCCLKTS (1'b0),
    .USRDONEO  (1'b1),
    .USRDONETS (1'b1)
  );

  // Generating the system clock and reset for the FPGA.
  clkgen_xil7series clkgen(
    .IO_CLK,
    .IO_RST_N,
    .clk_sys,
    .rst_sys_n
  );

endmodule
