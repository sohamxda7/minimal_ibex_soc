// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// This is the top level that connects the demo system to the virtual devices.
/*module top_verilator (input logic clk_i, rst_ni);

  localparam ClockFrequency = 20_000_000;
  localparam BaudRate       = 115_200;

  logic uart_sys_rx, uart_sys_tx;
  
  logic scl_i;
  logic scl_o;
  logic scl_oe;
  
  logic sda_i;
  logic sda_o;
  logic sda_oe;
  
  tri1 scl_bus;
  tri1 sda_bus;
  
  // Instantiating the Ibex Demo System.
  ibex_demo_system #(
    .GpiWidth       ( 8                   ),
    .GpoWidth       ( 16                  ),
    .PwmWidth       ( 12                  ),
    .ClockFrequency ( ClockFrequency      ),
    .BaudRate       ( BaudRate            ),
    .RegFile        ( ibex_pkg::RegFileFF )
  ) u_ibex_demo_system (
    //Input
    .clk_sys_i (clk_i),
    .rst_sys_ni(rst_ni),
    .uart_rx_i (uart_sys_rx),

    //Output
    .uart_tx_o(uart_sys_tx),

    // tie off JTAG
    .trst_ni(1'b1),
    .tms_i  (1'b0),
    .tck_i  (1'b0),
    .td_i   (1'b0),
    .td_o   (    ),

    // Remaining IO
    .gp_i      (0),
    .gp_o      ( ),
    .pwm_o     ( ),
    .spi_rx_i  (0),
    .spi_tx_o  ( ),
    .spi_sck_o ( ),
    
    //i2c
    .i2c_scl_i(scl_i),
    .i2c_scl_o(scl_o),
    .i2c_scl_oe_o(scl_oe),
    
    .i2c_sda_i(sda_i),
    .i2c_sda_o(sda_o),
    .i2c_sda_oe_o(sda_oe)
  );

  // Virtual UART
  uartdpi #(
    .BAUD(BaudRate),
    .FREQ(ClockFrequency)
  ) u_uartdpi (
    .clk_i,
    .rst_ni,
    .active (1'b1       ),
    .tx_o   (uart_sys_rx),
    .rx_i   (uart_sys_tx)
  );
endmodule*/

// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// This is the top level that connects the demo system to the virtual devices.
module top_verilator (
    input logic clk_i,
    input logic rst_ni
);

  localparam ClockFrequency = 50_000_000;
  localparam BaudRate       = 115_200;

  //---------------------------------------------------------
  // UART
  //---------------------------------------------------------

  logic uart_sys_rx, uart_sys_tx;

  //---------------------------------------------------------
  // I2C Signals
  //---------------------------------------------------------

  logic scl_i;
  logic scl_o;
  logic scl_oe;

  logic sda_i;
  logic sda_o;
  logic sda_oe;

  //---------------------------------------------------------
  // Open Drain Bus
  //---------------------------------------------------------

  tri1 scl_bus;
  tri1 sda_bus;

  //---------------------------------------------------------
  // Ibex Demo System
  //---------------------------------------------------------

  ibex_demo_system #(
    .GpiWidth       (8),
    .GpoWidth       (16),
    .PwmWidth       (12),
    .ClockFrequency (ClockFrequency),
    .BaudRate       (BaudRate),
    .RegFile        (ibex_pkg::RegFileFF)
  ) u_ibex_demo_system (

    // Clock / Reset
    .clk_sys_i (clk_i),
    .rst_sys_ni(rst_ni),

    // UART
    .uart_rx_i (uart_sys_rx),
    .uart_tx_o (uart_sys_tx),

    // JTAG
    .trst_ni (1'b1),
    .tms_i   (1'b0),
    .tck_i   (1'b0),
    .td_i    (1'b0),
    .td_o    (),

    // GPIO
    .gp_i      (0),
    .gp_o      (),

    // PWM
    .pwm_o     (),

    // SPI
    .spi_rx_i  (0),
    .spi_tx_o  (),
    .spi_sck_o (),

    // XIP SPI flash
    .xip_spi_sck_o  (),
    .xip_spi_csn_o  (),
    .xip_spi_mosi_o (),
    .xip_spi_miso_i (1'b0),

    // I2C
    .i2c_scl_i    (scl_i),
    .i2c_scl_o    (scl_o),
    .i2c_scl_oe_o (scl_oe),

    .i2c_sda_i    (sda_i),
    .i2c_sda_o    (sda_o),
    .i2c_sda_oe_o (sda_oe)
  );

  //---------------------------------------------------------
  // Open-Drain I2C Bus
  //---------------------------------------------------------

  // Master drives low when OE=0, releases when OE=1

  assign scl_bus = (scl_oe) ? 1'bz : 1'b0;
  assign sda_bus = (sda_oe) ? 1'bz : 1'b0;

  // Feed bus back into master

  assign scl_i = scl_bus;
  assign sda_i = sda_bus;

  //---------------------------------------------------------
  // I2C Slave BFM
  //---------------------------------------------------------

  i2c_slave_bfm u_i2c_slave_bfm
  (
       .clk(clk_i),
       .rst_n(rst_ni),
      .scl(scl_bus),
      .sda(sda_bus)
  );

  //---------------------------------------------------------
  // Virtual UART
  //---------------------------------------------------------

  uartdpi #(
    .BAUD(BaudRate),
    .FREQ(ClockFrequency)
  ) u_uartdpi (
    .clk_i,
    .rst_ni,
    .active (1'b1),
    .tx_o   (uart_sys_rx),
    .rx_i   (uart_sys_tx)
  );

endmodule
