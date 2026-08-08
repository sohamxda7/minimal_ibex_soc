// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// This is the top level SystemVerilog file that connects the IO on the board to the Ibex Demo System.
module top_artya7 #(
  parameter SRAMInitFile = ""
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
  inout         I2C_SDA
);

  logic clk_sys, rst_sys_n;

  // I2C open-drain pad wiring
  logic i2c_scl_o, i2c_scl_oe, i2c_sda_o, i2c_sda_oe;
  assign I2C_SCL = i2c_scl_oe ? 1'bz : i2c_scl_o;
  assign I2C_SDA = i2c_sda_oe ? 1'bz : i2c_sda_o;

  // Instantiating the Ibex Demo System.
  // ClockFrequency MUST match what clkgen_xil7series produces (20 MHz — the
  // PLL divide was corrected from 50 MHz) or the UART baud will be wrong.
  ibex_demo_system #(
    .GpiWidth       ( 8           ),
    .GpoWidth       ( 8           ),
    .PwmWidth       ( 12          ),
    .ClockFrequency ( 20_000_000  ),
    .BaudRate       ( 115_200     ),
    .SRAMInitFile   ( SRAMInitFile )
  ) u_ibex_demo_system (
    //input
    .clk_sys_i (clk_sys),
    .rst_sys_ni(rst_sys_n),
    .gp_i      ({SW, BTN}),
    .uart_rx_i (UART_RX),

    //output
    .gp_o     ({LED, DISP_CTRL}),
    .pwm_o    (RGB_LED),
    .uart_tx_o(UART_TX),

    .spi_rx_i (SPI_RX),
    .spi_tx_o (SPI_TX),
    .spi_sck_o(SPI_SCK),

    // XIP SPI flash — not wired to board pins yet (QSPI pins are commented
    // out in pins_artya7.xdc and the flash clock needs a STARTUPE2 macro).
    .xip_spi_sck_o  (),
    .xip_spi_csn_o  (),
    .xip_spi_mosi_o (),
    .xip_spi_miso_i (1'b0),

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

  // Generating the system clock and reset for the FPGA.
  clkgen_xil7series clkgen(
    .IO_CLK,
    .IO_RST_N,
    .clk_sys,
    .rst_sys_n
  );

endmodule
