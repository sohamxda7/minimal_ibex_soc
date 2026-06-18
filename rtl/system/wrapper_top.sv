// Integrated OBI-to-peripheral wrapper top.
module wrapper_top #(
  parameter int unsigned AW = 32,
  parameter int unsigned DW = 32,
  parameter int unsigned BootRomAddrWidth = 10,
  parameter int unsigned SramWordAddrWidth = 11,
  parameter int unsigned GpiWidth = 8,
  parameter int unsigned GpoWidth = 16
) (
  input  logic             clk_i,
  input  logic             rst_ni,

  // OBI slave port from the CPU/core side.
  input  logic             obi_req_i,
  output logic             obi_gnt_o,
  input  logic [AW-1:0]    obi_addr_i,
  input  logic             obi_we_i,
  input  logic [DW/8-1:0]  obi_be_i,
  input  logic [DW-1:0]    obi_wdata_i,
  output logic             obi_rvalid_o,
  output logic [DW-1:0]    obi_rdata_o,

  // UART pins and interrupt.
  input  logic             uart_rx_i,
  output logic             uart_tx_o,
  output logic             uart_irq_o,

  // GPIO pins.
  input  logic [GpiWidth-1:0] gp_i,
  output logic [GpoWidth-1:0] gp_o,

  // Timer interrupt.
  output logic             timer_intr_o,

  // SPI host pins.
  input  logic             spi_rx_i,
  output logic             spi_tx_o,
  output logic             spi_sck_o,
  output logic [7:0]       spi_byte_data_o,

  // I2C pins and interrupt.
  input  logic             i2c_scl_i,
  output logic             i2c_scl_o,
  output logic             i2c_scl_oe_o,
  input  logic             i2c_sda_i,
  output logic             i2c_sda_o,
  output logic             i2c_sda_oe_o,
  output logic             i2c_irq_o
);

  logic             wb_cyc;
  logic             wb_stb;
  logic             wb_we;
  logic [AW-1:0]    wb_adr;
  logic [DW-1:0]    wb_m_dat;
  logic [DW/8-1:0]  wb_sel;
  logic             wb_ack;
  logic [DW-1:0]    wb_s_dat;
  logic             wb_stall;

  localparam logic [AW-1:0] UART_BASE    = 32'h4000_0000;
  localparam logic [AW-1:0] GPIO_BASE    = 32'h4000_0100;
  localparam logic [AW-1:0] TIMER_BASE   = 32'h4000_0200;
  localparam logic [AW-1:0] I2C_BASE     = 32'h4000_0400;
  localparam logic [AW-1:0] SPIHOST_BASE = 32'h4000_0500;

  logic             bootrom_req;
  logic             bootrom_we;
  logic [AW-1:0]    bootrom_addr;
  logic [DW-1:0]    bootrom_wdata;
  logic [DW/8-1:0]  bootrom_be;
  logic             bootrom_rvalid;
  logic [DW-1:0]    bootrom_rdata;

  logic             sram_req;
  logic             sram_we;
  logic [AW-1:0]    sram_addr;
  logic [DW-1:0]    sram_wdata;
  logic [DW/8-1:0]  sram_be;
  logic             sram_rvalid;
  logic [DW-1:0]    sram_rdata;

  logic             xip_req;
  logic             xip_we;
  logic [AW-1:0]    xip_addr;
  logic [DW-1:0]    xip_wdata;
  logic [DW/8-1:0]  xip_be;
  logic             xip_rvalid;
  logic [DW-1:0]    xip_rdata;

  logic             uart_req;
  logic             uart_we;
  logic [AW-1:0]    uart_addr;
  logic [DW-1:0]    uart_wdata;
  logic [DW/8-1:0]  uart_be;
  logic             uart_rvalid;
  logic [DW-1:0]    uart_rdata;

  logic             gpio_req;
  logic             gpio_we;
  logic [AW-1:0]    gpio_addr;
  logic [DW-1:0]    gpio_wdata;
  logic [DW/8-1:0]  gpio_be;
  logic             gpio_rvalid;
  logic [DW-1:0]    gpio_rdata;

  logic             timer_req;
  logic             timer_we;
  logic [AW-1:0]    timer_addr;
  logic [DW-1:0]    timer_wdata;
  logic [DW/8-1:0]  timer_be;
  logic             timer_rvalid;
  logic [DW-1:0]    timer_rdata;
  logic             timer_err;

  logic             spictrl_req;
  logic             spictrl_we;
  logic [AW-1:0]    spictrl_addr;
  logic [DW-1:0]    spictrl_wdata;
  logic [DW/8-1:0]  spictrl_be;
  logic             spictrl_rvalid;
  logic [DW-1:0]    spictrl_rdata;

  logic             i2c_req;
  logic             i2c_we;
  logic [AW-1:0]    i2c_addr;
  logic [DW-1:0]    i2c_wdata;
  logic [DW/8-1:0]  i2c_be;
  logic             i2c_rvalid;
  logic [DW-1:0]    i2c_rdata;

  logic             spihost_req;
  logic             spihost_we;
  logic [AW-1:0]    spihost_addr;
  logic [DW-1:0]    spihost_wdata;
  logic [DW/8-1:0]  spihost_be;
  logic             spihost_rvalid;
  logic [DW-1:0]    spihost_rdata;

  obi2wb #(
    .AW(AW),
    .DW(DW)
  ) u_obi2wb (
    .clk_i,
    .rst_ni,
    .obi_req_i,
    .obi_gnt_o,
    .obi_addr_i,
    .obi_we_i,
    .obi_be_i,
    .obi_wdata_i,
    .obi_rvalid_o,
    .obi_rdata_o,
    .wb_cyc_o(wb_cyc),
    .wb_stb_o(wb_stb),
    .wb_we_o(wb_we),
    .wb_adr_o(wb_adr),
    .wb_dat_o(wb_m_dat),
    .wb_sel_o(wb_sel),
    .wb_ack_i(wb_ack),
    .wb_dat_i(wb_s_dat),
    .wb_stall_i(wb_stall)
  );

  wb_interconnect #(
    .AW(AW),
    .DW(DW)
  ) u_wb_interconnect (
    .clk_i,
    .rst_ni,
    .wb_cyc_i(wb_cyc),
    .wb_stb_i(wb_stb),
    .wb_we_i(wb_we),
    .wb_adr_i(wb_adr),
    .wb_dat_i(wb_m_dat),
    .wb_sel_i(wb_sel),
    .wb_ack_o(wb_ack),
    .wb_dat_o(wb_s_dat),
    .wb_stall_o(wb_stall),
    .bootrom_req_o(bootrom_req),
    .bootrom_we_o(bootrom_we),
    .bootrom_addr_o(bootrom_addr),
    .bootrom_wdata_o(bootrom_wdata),
    .bootrom_be_o(bootrom_be),
    .bootrom_rvalid_i(bootrom_rvalid),
    .bootrom_rdata_i(bootrom_rdata),
    .sram_req_o(sram_req),
    .sram_we_o(sram_we),
    .sram_addr_o(sram_addr),
    .sram_wdata_o(sram_wdata),
    .sram_be_o(sram_be),
    .sram_rvalid_i(sram_rvalid),
    .sram_rdata_i(sram_rdata),
    .xip_req_o(xip_req),
    .xip_we_o(xip_we),
    .xip_addr_o(xip_addr),
    .xip_wdata_o(xip_wdata),
    .xip_be_o(xip_be),
    .xip_rvalid_i(xip_rvalid),
    .xip_rdata_i(xip_rdata),
    .uart_req_o(uart_req),
    .uart_we_o(uart_we),
    .uart_addr_o(uart_addr),
    .uart_wdata_o(uart_wdata),
    .uart_be_o(uart_be),
    .uart_rvalid_i(uart_rvalid),
    .uart_rdata_i(uart_rdata),
    .gpio_req_o(gpio_req),
    .gpio_we_o(gpio_we),
    .gpio_addr_o(gpio_addr),
    .gpio_wdata_o(gpio_wdata),
    .gpio_be_o(gpio_be),
    .gpio_rvalid_i(gpio_rvalid),
    .gpio_rdata_i(gpio_rdata),
    .timer_req_o(timer_req),
    .timer_we_o(timer_we),
    .timer_addr_o(timer_addr),
    .timer_wdata_o(timer_wdata),
    .timer_be_o(timer_be),
    .timer_rvalid_i(timer_rvalid),
    .timer_rdata_i(timer_rdata),
    .spictrl_req_o(spictrl_req),
    .spictrl_we_o(spictrl_we),
    .spictrl_addr_o(spictrl_addr),
    .spictrl_wdata_o(spictrl_wdata),
    .spictrl_be_o(spictrl_be),
    .spictrl_rvalid_i(spictrl_rvalid),
    .spictrl_rdata_i(spictrl_rdata),
    .i2c_req_o(i2c_req),
    .i2c_we_o(i2c_we),
    .i2c_addr_o(i2c_addr),
    .i2c_wdata_o(i2c_wdata),
    .i2c_be_o(i2c_be),
    .i2c_rvalid_i(i2c_rvalid),
    .i2c_rdata_i(i2c_rdata),
    .spihost_req_o(spihost_req),
    .spihost_we_o(spihost_we),
    .spihost_addr_o(spihost_addr),
    .spihost_wdata_o(spihost_wdata),
    .spihost_be_o(spihost_be),
    .spihost_rvalid_i(spihost_rvalid),
    .spihost_rdata_i(spihost_rdata)
  );

  boot_rom #(
    .ADDR_WIDTH(BootRomAddrWidth),
    .INIT_FILE("rtl/system/boot.mem")
  ) u_boot_rom (
    .clk_i,
    .addr_i(bootrom_addr[BootRomAddrWidth+1:2]),
    .data_o(bootrom_rdata)
  );

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      bootrom_rvalid <= 1'b0;
    end else begin
      bootrom_rvalid <= bootrom_req;
    end
  end

  logic [DW/8-1:0] sram_mem_we;
  logic [SramWordAddrWidth-1:0] sram_mem_addr;
  logic [DW-1:0] sram_mem_wdata;
  logic [DW-1:0] sram_mem_rdata;
  logic sram_mem_en;
  logic [DW-1:0] sram_mem [0:(1 << SramWordAddrWidth)-1];

  sram_controller #(
    .AW(AW),
    .DW(DW),
    .WORD_ADDR_WIDTH(SramWordAddrWidth)
  ) u_sram_controller (
    .clk_i,
    .rst_ni,
    .sram_req_i(sram_req),
    .sram_we_i(sram_we),
    .sram_addr_i(sram_addr),
    .sram_wdata_i(sram_wdata),
    .sram_be_i(sram_be),
    .sram_rdata_o(sram_rdata),
    .sram_rvalid_o(sram_rvalid),
    .mem_en_o(sram_mem_en),
    .mem_we_o(sram_mem_we),
    .mem_addr_o(sram_mem_addr),
    .mem_wdata_o(sram_mem_wdata),
    .mem_rdata_i(sram_mem_rdata)
  );

  always_ff @(posedge clk_i) begin
    if (sram_mem_en) begin
      for (int b = 0; b < DW / 8; b++) begin
        if (sram_mem_we[b]) begin
          sram_mem[sram_mem_addr][(b*8)+:8] <= sram_mem_wdata[(b*8)+:8];
        end
      end
      sram_mem_rdata <= sram_mem[sram_mem_addr];
    end
  end

  uart u_uart (
    .clk_i,
    .rst_ni,
    .device_req_i(uart_req),
    .device_addr_i(uart_addr - UART_BASE),
    .device_we_i(uart_we),
    .device_be_i(uart_be),
    .device_wdata_i(uart_wdata),
    .device_rvalid_o(uart_rvalid),
    .device_rdata_o(uart_rdata),
    .uart_rx_i,
    .uart_irq_o,
    .uart_tx_o
  );

  gpio #(
    .GpiWidth(GpiWidth),
    .GpoWidth(GpoWidth),
    .AddrWidth(AW),
    .DataWidth(DW)
  ) u_gpio (
    .clk_i,
    .rst_ni,
    .device_req_i(gpio_req),
    .device_addr_i(gpio_addr - GPIO_BASE),
    .device_we_i(gpio_we),
    .device_be_i(gpio_be),
    .device_wdata_i(gpio_wdata),
    .device_rvalid_o(gpio_rvalid),
    .device_rdata_o(gpio_rdata),
    .gp_i,
    .gp_o
  );

  timer u_timer (
    .clk_i,
    .rst_ni,
    .timer_req_i(timer_req),
    .timer_addr_i(timer_addr - TIMER_BASE),
    .timer_we_i(timer_we),
    .timer_be_i(timer_be),
    .timer_wdata_i(timer_wdata),
    .timer_rvalid_o(timer_rvalid),
    .timer_rdata_o(timer_rdata),
    .timer_err_o(timer_err),
    .timer_intr_o
  );

  spi_top u_spi_top (
    .clk_i,
    .rst_ni,
    .device_req_i(spihost_req),
    .device_addr_i(spihost_addr - SPIHOST_BASE),
    .device_we_i(spihost_we),
    .device_be_i(spihost_be),
    .device_wdata_i(spihost_wdata),
    .device_rvalid_o(spihost_rvalid),
    .device_rdata_o(spihost_rdata),
    .spi_rx_i,
    .spi_tx_o,
    .sck_o(spi_sck_o),
    .byte_data_o(spi_byte_data_o)
  );

  i2c_wb_wrapper #(
    .AW(AW),
    .DW(DW)
  ) u_i2c_wb_wrapper (
    .clk_i,
    .rst_i(~rst_ni),
    .i2c_req_o(i2c_req),
    .i2c_we_o(i2c_we),
    .i2c_addr_o(i2c_addr - I2C_BASE),
    .i2c_wdata_o(i2c_wdata),
    .i2c_be_o(i2c_be),
    .i2c_rvalid_i(i2c_rvalid),
    .i2c_rdata_i(i2c_rdata),
    .scl_pad_i(i2c_scl_i),
    .scl_pad_o(i2c_scl_o),
    .scl_padoen_o(i2c_scl_oe_o),
    .sda_pad_i(i2c_sda_i),
    .sda_pad_o(i2c_sda_o),
    .sda_padoen_o(i2c_sda_oe_o),
    .wb_inta_o(i2c_irq_o)
  );

  // XIP and SPI-control decode slots are reserved but not implemented in this wrapper.
  // Acknowledge them with zero data so software probing cannot hang the bus.
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      xip_rvalid     <= 1'b0;
      spictrl_rvalid <= 1'b0;
    end else begin
      xip_rvalid     <= xip_req;
      spictrl_rvalid <= spictrl_req;
    end
  end

  assign xip_rdata     = '0;
  assign spictrl_rdata = '0;

  logic unused_bootrom_sideband;
  logic unused_timer_err;
  logic unused_xip_sideband;
  logic unused_spictrl_sideband;

  assign unused_bootrom_sideband = ^{bootrom_we, bootrom_wdata, bootrom_be};
  assign unused_timer_err        = timer_err;
  assign unused_xip_sideband     = ^{xip_we, xip_addr, xip_wdata, xip_be};
  assign unused_spictrl_sideband = ^{spictrl_we, spictrl_addr, spictrl_wdata, spictrl_be};

endmodule
