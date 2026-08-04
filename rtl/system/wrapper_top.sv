// Integrated OBI-to-peripheral wrapper top.
//
// Receives two separate OBI ports from the Ibex core (instruction fetch and
// data), arbitrates them with a 2:1 priority scheme (data > instruction), and
// routes the merged stream through either:
//
//   a) A direct debug-module device port, when the address falls in the
//      debug module window (0x1A11_0000 – 0x1A11_FFFF).
//
//   b) The obi2wb bridge -> wb_interconnect -> peripherals, for all other
//      addresses (Boot ROM, SRAM, UART, GPIO, Timer, I2C, SPI host, XIP).
//
// The 2:1 OBI arbiter ensures at most ONE transaction is in flight at any
// time, which matches the single-outstanding-transaction constraint of obi2wb.

module wrapper_top #(
  parameter int unsigned AW              = 32,
  parameter int unsigned DW              = 32,
  parameter int unsigned BootRomAddrWidth  = 10,
  parameter int unsigned SramWordAddrWidth = 11,
  parameter int unsigned GpiWidth        = 8,
  parameter int unsigned GpoWidth        = 16,
  parameter int unsigned ClockFrequency = 20_000_000,
  parameter int unsigned BaudRate       = 115_200,
  parameter int unsigned PwmWidth     =12
) (
  input  logic             clk_i,
  input  logic             rst_ni,

  // -------------------------------------------------------
  // Instruction fetch OBI port (read-only, lower priority)
  // -------------------------------------------------------
  input  logic             obi_instr_req_i,
  output logic             obi_instr_gnt_o,
  input  logic [AW-1:0]    obi_instr_addr_i,
  output logic             obi_instr_rvalid_o,
  output logic [DW-1:0]    obi_instr_rdata_o,

  // -------------------------------------------------------
  // Data OBI port (read/write, higher priority)
  // -------------------------------------------------------
  input  logic             obi_req_i,
  output logic             obi_gnt_o,
  input  logic [AW-1:0]    obi_addr_i,
  input  logic             obi_we_i,
  input  logic [DW/8-1:0]  obi_be_i,
  input  logic [DW-1:0]    obi_wdata_i,
  output logic             obi_rvalid_o,
  output logic [DW-1:0]    obi_rdata_o,

  // -------------------------------------------------------
  // UART
  // -------------------------------------------------------
  input  logic             uart_rx_i,
  output logic             uart_tx_o,
  output logic             uart_irq_o,

  // -------------------------------------------------------
  // GPIO
  // -------------------------------------------------------
  input  logic [GpiWidth-1:0] gp_i,
  output logic [GpoWidth-1:0] gp_o,

  // -------------------------------------------------------
  // Timer interrupt
  // -------------------------------------------------------
  output logic             timer_intr_o,

  // -------------------------------------------------------
  // SPI host
  // -------------------------------------------------------
  input  logic             spi_rx_i,
  output logic             spi_tx_o,
  output logic             spi_sck_o,
  output logic [7:0]       spi_byte_data_o,

  // -------------------------------------------------------
  // I2C
  // -------------------------------------------------------
  input  logic             i2c_scl_i,
  output logic             i2c_scl_o,
  output logic             i2c_scl_oe_o,
  input  logic             i2c_sda_i,
  output logic             i2c_sda_o,
  output logic             i2c_sda_oe_o,
  output logic             i2c_irq_o,

// -------------------------------------------------------
  // PWM
  // -------------------------------------------------------
  
  output logic [PwmWidth-1:0] pwm_o,
  
  // -------------------------------------------------------
  // SPI FLASH CONTROLLER
  // -------------------------------------------------------
  
  output logic xip_spi_sck_o,
  output logic xip_spi_csn_o,
  output logic xip_spi_mosi_o,
  input logic xip_spi_miso_i,
  
  // -------------------------------------------------------
  // Debug-module device port
  // Decoded from the merged OBI stream before the WB bridge.
  // Connect to dm_top.device_* in ibex_demo_system.sv.
  // -------------------------------------------------------
  output logic             dbg_req_o,
  output logic             dbg_we_o,
  output logic [AW-1:0]    dbg_addr_o,
  output logic [DW-1:0]    dbg_wdata_o,
  output logic [DW/8-1:0]  dbg_be_o,
  input  logic [DW-1:0]    dbg_rdata_i
);

  // ===========================================================
  // Address constants
  // ===========================================================
  localparam logic [AW-1:0] UART_BASE    = 32'h4000_0000;
  localparam logic [AW-1:0] GPIO_BASE    = 32'h4000_0100;
  localparam logic [AW-1:0] TIMER_BASE   = 32'h4000_0200;
  localparam logic [AW-1:0] I2C_BASE     = 32'h4000_0400;
  localparam logic [AW-1:0] SPIHOST_BASE = 32'h4000_0500;
  localparam logic [AW-1:0] PWM_BASE     = 32'h4000_0600;
  localparam logic [AW-1:0] SPI_FLASH_BASE=32'h2000_0000;

  // Debug module window decoded BEFORE the WB bridge
  localparam logic [AW-1:0] DEBUG_BASE = 32'h1A11_0000;
  localparam logic [AW-1:0] DEBUG_SIZE = 32'h0001_0000;  // 64 KiB
  localparam logic [AW-1:0] DEBUG_MASK = ~(DEBUG_SIZE - 32'd1); // 0xFFFF_0000

  // ===========================================================
  // 2:1 OBI Arbiter  (data port = higher priority)
  // ===========================================================
  // After arbitration, at most ONE transaction is in flight.
  // The pending_* registers track which source and which downstream
  // path owns the in-flight slot.

  // Merged OBI signals produced by the arbiter
  logic             arb_req;
  logic             arb_gnt;   // driven back by the pre-decode stage
  logic             arb_rvalid;
  logic             arb_we;
  logic [AW-1:0]    arb_addr;
  logic [DW/8-1:0]  arb_be;
  logic [DW-1:0]    arb_wdata;
  logic [DW-1:0]    arb_rdata;

  // State: which source + which downstream path is in flight
  logic pending;        // 1 → a transaction is in flight
  logic pending_data;   // 1 → the in-flight transaction came from the data port
  logic pending_debug;  // 1 → the in-flight transaction is routed to debug path

  // Priority select: data wins when both request simultaneously
  logic arb_sel_data;
  assign arb_sel_data = obi_req_i;  // data OBI is higher priority

  // Present a request downstream only when the slot is free
  assign arb_req   = !pending && (obi_req_i || obi_instr_req_i);
  assign arb_addr  = arb_sel_data ? obi_addr_i        : obi_instr_addr_i;
  assign arb_we    = arb_sel_data ? obi_we_i           : 1'b0;
  assign arb_be    = arb_sel_data ? obi_be_i           : {(DW/8){1'b0}};
  assign arb_wdata = arb_sel_data ? obi_wdata_i        : {DW{1'b0}};

  // ===========================================================
  // Pre-decode: Debug window vs WB fabric
  // ===========================================================
  // Transactions to 0x1A11_0000–0x1A11_FFFF bypass obi2wb and go
  // directly to the debug module device port.
  // All other transactions are forwarded to obi2wb.

  logic debug_sel;
  assign debug_sel = (arb_addr & DEBUG_MASK) == DEBUG_BASE;

  // Debug path signals
  logic dbg_req_int;
  logic dbg_rvalid_int;

  assign dbg_req_int = arb_req && debug_sel;

  // Debug rvalid: 1 cycle after req — matches dm_top registered read latency
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) dbg_rvalid_int <= 1'b0;
    else         dbg_rvalid_int <= dbg_req_int;
  end

  // WB fabric path signals
  logic wb_obi_req;
  logic wb_obi_gnt;   // grant from obi2wb (registered, 1 cycle after req)
  logic wb_obi_rvalid;
  logic [DW-1:0] wb_obi_rdata;

  assign wb_obi_req = arb_req && !debug_sel;

  // Merged gnt back to the arbiter:
  //   debug → immediate (combinatorial) grant
  //   WB    → registered grant from obi2wb
  assign arb_gnt    = arb_req && (debug_sel ? 1'b1 : wb_obi_gnt);
  assign arb_rvalid = dbg_rvalid_int | wb_obi_rvalid;
  assign arb_rdata  = pending_debug ? dbg_rdata_i : wb_obi_rdata;

  // Pending state tracking (updated on every accepted transaction)
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      pending       <= 1'b0;
      pending_data  <= 1'b0;
      pending_debug <= 1'b0;
    end else if (!pending && arb_gnt) begin
      // Transaction accepted by the downstream
      pending       <= 1'b1;
      pending_data  <= arb_sel_data;
      pending_debug <= debug_sel;
    end else if (pending && arb_rvalid) begin
      // Transaction complete
      pending <= 1'b0;
    end
  end

  // Grant signals back to Ibex OBI ports
  assign obi_gnt_o       = !pending && obi_req_i                           && arb_gnt;
  assign obi_instr_gnt_o = !pending && !obi_req_i && obi_instr_req_i       && arb_gnt;

  // Route the response to the correct Ibex OBI port
  assign obi_rvalid_o       = pending &&  pending_data  && arb_rvalid;
  assign obi_instr_rvalid_o = pending && !pending_data  && arb_rvalid;
  assign obi_rdata_o        = arb_rdata;
  assign obi_instr_rdata_o  = arb_rdata;

  // Drive the debug module device port outputs
  assign dbg_req_o   = dbg_req_int;
  assign dbg_we_o    = arb_we;
  assign dbg_addr_o  = arb_addr;
  assign dbg_wdata_o = arb_wdata;
  assign dbg_be_o    = arb_be;

  // ===========================================================
  // WB bus signals (obi2wb ↔ wb_interconnect)
  // ===========================================================
  logic             wb_cyc;
  logic             wb_stb;
  logic             wb_we;
  logic [AW-1:0]    wb_adr;
  logic [DW-1:0]    wb_m_dat;
  logic [DW/8-1:0]  wb_sel;
  logic             wb_ack;
  logic [DW-1:0]    wb_s_dat;
  logic             wb_stall;

  // ===========================================================
  // obi2wb bridge (serialises the non-debug OBI stream)
  // ===========================================================
  obi2wb #(
    .AW(AW),
    .DW(DW)
  ) u_obi2wb (
    .clk_i,
    .rst_ni,
    .obi_req_i    (wb_obi_req),
    .obi_gnt_o    (wb_obi_gnt),
    .obi_addr_i   (arb_addr),
    .obi_we_i     (arb_we),
    .obi_be_i     (arb_be),
    .obi_wdata_i  (arb_wdata),
    .obi_rvalid_o (wb_obi_rvalid),
    .obi_rdata_o  (wb_obi_rdata),
    .wb_cyc_o     (wb_cyc),
    .wb_stb_o     (wb_stb),
    .wb_we_o      (wb_we),
    .wb_adr_o     (wb_adr),
    .wb_dat_o     (wb_m_dat),
    .wb_sel_o     (wb_sel),
    .wb_ack_i     (wb_ack),
    .wb_dat_i     (wb_s_dat),
    .wb_stall_i   (wb_stall)
  );

  // ===========================================================
  // WB Interconnect (address decode → peripherals)
  // ===========================================================
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
  
  logic             pwm_req;
  logic             pwm_we;
  logic [AW-1:0]    pwm_addr;
  logic [DW-1:0]    pwm_wdata;
  logic [DW/8-1:0]  pwm_be;
  logic             pwm_rvalid;
  logic [DW-1:0]    pwm_rdata;
  
  
  

  wb_interconnect #(
    .AW(AW),
    .DW(DW)
  ) u_wb_interconnect (
    .clk_i,
    .rst_ni,
    .wb_cyc_i   (wb_cyc),
    .wb_stb_i   (wb_stb),
    .wb_we_i    (wb_we),
    .wb_adr_i   (wb_adr),
    .wb_dat_i   (wb_m_dat),
    .wb_sel_i   (wb_sel),
    .wb_ack_o   (wb_ack),
    .wb_dat_o   (wb_s_dat),
    .wb_stall_o (wb_stall),
    .bootrom_req_o    (bootrom_req),
    .bootrom_we_o     (bootrom_we),
    .bootrom_addr_o   (bootrom_addr),
    .bootrom_wdata_o  (bootrom_wdata),
    .bootrom_be_o     (bootrom_be),
    .bootrom_rvalid_i (bootrom_rvalid),
    .bootrom_rdata_i  (bootrom_rdata),
    .sram_req_o    (sram_req),
    .sram_we_o     (sram_we),
    .sram_addr_o   (sram_addr),
    .sram_wdata_o  (sram_wdata),
    .sram_be_o     (sram_be),
    .sram_rvalid_i (sram_rvalid),
    .sram_rdata_i  (sram_rdata),
    .xip_req_o    (xip_req),
    .xip_we_o     (xip_we),
    .xip_addr_o   (xip_addr),
    .xip_wdata_o  (xip_wdata),
    .xip_be_o     (xip_be),
    .xip_rvalid_i (xip_rvalid),
    .xip_rdata_i  (xip_rdata),
    .uart_req_o    (uart_req),
    .uart_we_o     (uart_we),
    .uart_addr_o   (uart_addr),
    .uart_wdata_o  (uart_wdata),
    .uart_be_o     (uart_be),
    .uart_rvalid_i (uart_rvalid),
    .uart_rdata_i  (uart_rdata),
    .gpio_req_o    (gpio_req),
    .gpio_we_o     (gpio_we),
    .gpio_addr_o   (gpio_addr),
    .gpio_wdata_o  (gpio_wdata),
    .gpio_be_o     (gpio_be),
    .gpio_rvalid_i (gpio_rvalid),
    .gpio_rdata_i  (gpio_rdata),
    .timer_req_o    (timer_req),
    .timer_we_o     (timer_we),
    .timer_addr_o   (timer_addr),
    .timer_wdata_o  (timer_wdata),
    .timer_be_o     (timer_be),
    .timer_rvalid_i (timer_rvalid),
    .timer_rdata_i  (timer_rdata),
    .spictrl_req_o    (spictrl_req),
    .spictrl_we_o     (spictrl_we),
    .spictrl_addr_o   (spictrl_addr),
    .spictrl_wdata_o  (spictrl_wdata),
    .spictrl_be_o     (spictrl_be),
    .spictrl_rvalid_i (spictrl_rvalid),
    .spictrl_rdata_i  (spictrl_rdata),
    .i2c_req_o    (i2c_req),
    .i2c_we_o     (i2c_we),
    .i2c_addr_o   (i2c_addr),
    .i2c_wdata_o  (i2c_wdata),
    .i2c_be_o     (i2c_be),
    .i2c_rvalid_i (i2c_rvalid),
    .i2c_rdata_i  (i2c_rdata),
    .spihost_req_o    (spihost_req),
    .spihost_we_o     (spihost_we),
    .spihost_addr_o   (spihost_addr),
    .spihost_wdata_o  (spihost_wdata),
    .spihost_be_o     (spihost_be),
    .spihost_rvalid_i (spihost_rvalid),
    .spihost_rdata_i  (spihost_rdata),
    
    .pwm_req_o (pwm_req),
    .pwm_we_o (pwm_we),
    .pwm_addr_o(pwm_addr),
    .pwm_wdata_o(pwm_wdata),
    .pwm_be_o(pwm_be),
    .pwm_rvalid_i(pwm_rvalid),
    .pwm_rdata_i(pwm_rdata)
  );

  // ===========================================================
  // Boot ROM (4 KiB, synthesised register array)
  // ===========================================================
  boot_rom #(
    .ADDR_WIDTH (BootRomAddrWidth),
    .INIT_FILE  ("/home/ravali/minimal-ibex-soc/rtl/system/boot.mem")
  ) u_boot_rom (
    .clk_i,
    .addr_i  (bootrom_addr[BootRomAddrWidth+1:2]),
    .data_o  (bootrom_rdata)
  );

  // Boot ROM rvalid: 1 cycle after req (registered ROM output)
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) bootrom_rvalid <= 1'b0;
    else         bootrom_rvalid <= bootrom_req;
  end

  // ===========================================================
  // SRAM (8 KiB)
  // sram_controller handles WB handshake and address decode;
  // sram_model is the actual storage array and exports the
  // DPI-C functions (simutil_set_mem / simutil_get_mem /
  // simutil_memload) that let the simulation harness pre-load ELF
  // images.  The sim memory registration path is:
  //   TOP.top_verilator.u_ibex_demo_system.u_wrapper.u_sram_model
  // ===========================================================
  logic [DW/8-1:0]              sram_mem_we;
  logic [SramWordAddrWidth-1:0] sram_mem_addr;
  logic [DW-1:0]                sram_mem_wdata;
  logic [DW-1:0]                sram_mem_rdata;
  logic                         sram_mem_en;

  sram_controller #(
    .AW              (AW),
    .DW              (DW),
    .WORD_ADDR_WIDTH (SramWordAddrWidth)
  ) u_sram_controller (
    .clk_i,
    .rst_ni,
    .sram_req_i    (sram_req),
    .sram_we_i     (sram_we),
    .sram_addr_i   (sram_addr),
    .sram_wdata_i  (sram_wdata),
    .sram_be_i     (sram_be),
    .sram_rdata_o  (sram_rdata),
    .sram_rvalid_o (sram_rvalid),
    .mem_en_o      (sram_mem_en),
    .mem_we_o      (sram_mem_we),
    .mem_addr_o    (sram_mem_addr),
    .mem_wdata_o   (sram_mem_wdata),
    .mem_rdata_i   (sram_mem_rdata)
  );

 /*sram_model #(
    .Width (DW),
    .Depth (1 << SramWordAddrWidth)
  ) u_sram_model (
    .clk_i,
    .req_i    (sram_mem_en),
    .addr_i   (sram_mem_addr),
    .we_i     (sram_mem_we),
    .wdata_i  (sram_mem_wdata),
    .rdata_o  (sram_mem_rdata)
  );
  
  dffram u_dffram (

    .CLK(clk_i),

    .EN  (sram_mem_en),

    .WE  (sram_mem_we),

    .Di  (sram_mem_wdata),

    .Do  (sram_mem_rdata),

    .A   (sram_mem_addr)

);*/

/*`ifdef SIMULATION_RAM
 
  dffram u_dffram (
    .CLK(clk_i),
    .EN  (sram_mem_en),
    .WE  (sram_mem_we),
    .Di  (sram_mem_wdata),
    .Do  (sram_mem_rdata),
    .A   (sram_mem_addr)
  );
 
`else
 
  sram_model #(
    .Width (DW),
    .Depth (1 << SramWordAddrWidth)
  ) u_sram_model (
    .clk_i,
    .req_i    (sram_mem_en),
    .addr_i   (sram_mem_addr),
    .we_i     (sram_mem_we),
    .wdata_i  (sram_mem_wdata),
    .rdata_o  (sram_mem_rdata)
  );
 
`endif*/

`ifdef verilator

 dffram u_dffram (
    .CLK(clk_i),
    .EN  (sram_mem_en),
    .WE  (sram_mem_we),
    .Di  (sram_mem_wdata),
    .Do  (sram_mem_rdata),
    .A   (sram_mem_addr)
  );
  
  `else
  
  sram_model #(
    .Width (DW),
    .Depth (1 << SramWordAddrWidth)
  ) u_sram_model (
    .clk_i,
    .req_i    (sram_mem_en),
    .addr_i   (sram_mem_addr),
    .we_i     (sram_mem_we),
    .wdata_i  (sram_mem_wdata),
    .rdata_o  (sram_mem_rdata)
  );
 `endif
  

  // ===========================================================
  // UART
  // ===========================================================
  uart #(
  .ClockFrequency(ClockFrequency),
  .BaudRate(BaudRate)
  )u_uart (
    .clk_i,
    .rst_ni,
    .device_req_i   (uart_req),
    .device_addr_i  (uart_addr - UART_BASE),
    .device_we_i    (uart_we),
    .device_be_i    (uart_be),
    .device_wdata_i (uart_wdata),
    .device_rvalid_o(uart_rvalid),
    .device_rdata_o (uart_rdata),
    .uart_rx_i,
    .uart_irq_o,
    .uart_tx_o
  );

  // ===========================================================
  // GPIO
  // ===========================================================
  gpio #(
    .GpiWidth  (GpiWidth),
    .GpoWidth  (GpoWidth),
    .AddrWidth (AW),
    .DataWidth (DW)
  ) u_gpio (
    .clk_i,
    .rst_ni,
    .device_req_i   (gpio_req),
    .device_addr_i  (gpio_addr - GPIO_BASE),
    .device_we_i    (gpio_we),
    .device_be_i    (gpio_be),
    .device_wdata_i (gpio_wdata),
    .device_rvalid_o(gpio_rvalid),
    .device_rdata_o (gpio_rdata),
    .gp_i,
    .gp_o
  );

  // ===========================================================
  // Timer
  // ===========================================================
  timer u_timer (
    .clk_i,
    .rst_ni,
    .timer_req_i    (timer_req),
    .timer_addr_i   (timer_addr - TIMER_BASE),
    .timer_we_i     (timer_we),
    .timer_be_i     (timer_be),
    .timer_wdata_i  (timer_wdata),
    .timer_rvalid_o (timer_rvalid),
    .timer_rdata_o  (timer_rdata),
    .timer_err_o    (timer_err),
    .timer_intr_o
  );

  // ===========================================================
  // SPI Host
  // ===========================================================
  spi_top u_spi_top (
    .clk_i,
    .rst_ni,
    .device_req_i   (spihost_req),
    .device_addr_i  (spihost_addr - SPIHOST_BASE),
    .device_we_i    (spihost_we),
    .device_be_i    (spihost_be),
    .device_wdata_i (spihost_wdata),
    .device_rvalid_o(spihost_rvalid),
    .device_rdata_o (spihost_rdata),
    .spi_rx_i,
    .spi_tx_o,
    .sck_o          (spi_sck_o),
    .byte_data_o    (spi_byte_data_o)
  );

  // ===========================================================
  // I2C Master (OpenCores)
  // ===========================================================
  i2c_wb_wrapper #(
    .AW(AW),
    .DW(DW)
  ) u_i2c_wb_wrapper (
    .clk_i,
    .rst_i          (~rst_ni),
    .i2c_req_o      (i2c_req),
    .i2c_we_o       (i2c_we),
    .i2c_addr_o     (i2c_addr - I2C_BASE),
    .i2c_wdata_o    (i2c_wdata),
    .i2c_be_o       (i2c_be),
    .i2c_rvalid_i   (i2c_rvalid),
    .i2c_rdata_i    (i2c_rdata),
    .scl_pad_i      (i2c_scl_i),
    .scl_pad_o      (i2c_scl_o),
    .scl_padoen_o   (i2c_scl_oe_o),
    .sda_pad_i      (i2c_sda_i),
    .sda_pad_o      (i2c_sda_o),
    .sda_padoen_o   (i2c_sda_oe_o),
    .wb_inta_o      (i2c_irq_o)
  );

// ===========================================================
  // PWM
  // ===========================================================
  
  pwm_wrapper #(.BusAddrWidth(AW),
  		.BusDataWidth(DW)
  		) u_pwm ( .clk_i(clk_i),
  		           .rst_ni(rst_ni),
  		           .device_req_i(pwm_req),
  		           .device_addr_i(pwm_addr-PWM_BASE),
  		           .device_we_i(pwm_we),
  		           .device_be_i(pwm_be),
  		           .device_wdata_i(pwm_wdata),
  		           .device_rvalid_o(pwm_rvalid),
  		           .device_rdata_o(pwm_rdata),
  		           
  		           .pwm_o(pwm_o)
  		           
  		   );
  		   
  		    
  // ===========================================================
  // XIP and SPI-control stubs
  
  
  
  spi_flash_xip #(
    .AW(24),
    .DW(DW),
    .CLK_DIV(4)
) u_spi_flash_xip (
    .clk_i          (clk_i),
    .rst_ni         (rst_ni),
 
    // XIP Interface
    .xip_req_i      (xip_req),
    .xip_we_i       (xip_we),
    .xip_addr_i     (xip_addr[23:0]),
    .xip_wdata_i    (xip_wdata),
    .xip_be_i       (xip_be),
    .xip_rvalid_o   (xip_rvalid),
    .xip_rdata_o    (xip_rdata),
 
    // SPI Flash Interface
    .spi_sck_o      (xip_spi_sck_o),
    .spi_csn_o      (xip_spi_csn_o),
    .spi_mosi_o     (xip_spi_mosi_o),
    .spi_miso_i     (xip_spi_miso_i)
);
  // Acknowledge with zero data so a probe cannot hang the bus.
  // ===========================================================
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

  // ===========================================================
  // Unused-signal sinks (silence lint warnings)
  // ===========================================================
  logic unused_bootrom_sideband;
  logic unused_timer_err;
  logic unused_xip_sideband;
  logic unused_spictrl_sideband;

  assign unused_bootrom_sideband = ^{bootrom_we, bootrom_wdata, bootrom_be};
  assign unused_timer_err        = timer_err;
  assign unused_xip_sideband     = ^{xip_we, xip_addr, xip_wdata, xip_be};
  assign unused_spictrl_sideband = ^{spictrl_we, spictrl_addr, spictrl_wdata, spictrl_be};

endmodule
