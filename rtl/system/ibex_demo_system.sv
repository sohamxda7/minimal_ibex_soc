// Ibex Demo System — clean OBI/WB architecture.

//

// Both the instruction-fetch and data OBI ports of the Ibex core are

// connected to wrapper_top, which contains a 2:1 OBI arbiter (data has

// priority) feeding a single obi2wb bridge and Wishbone interconnect.

//

// The legacy "bus" crossbar, ram_2p, and pwm_wrapper are no longer used.

// All peripherals (Boot ROM 4 KiB, SRAM 128 KiB, UART, GPIO, Timer, I2C,

// SPI Host) are accessed through the WB fabric at 0x4000_xxxx / 0x0010_xxxx.

// The debug module (dm_top) registers live at 0x1A11_0000 and are decoded

// inside wrapper_top before the WB bridge.

//

// Memory map (matches wb_interconnect.sv + wrapper_top.sv pre-decode):

//   0x0010_0000 – 0x0010_0FFF  Boot ROM  4 KiB  (RO, instr + data)

//   0x0010_2000 – 0x0012_1FFF  SRAM    128 KiB  (RW)

//   0x1A11_0000 – 0x1A11_FFFF  Debug module registers

//   0x2000_0000 – 0x2FFF_FFFF  SPI Flash XIP

//   0x4000_0000 – 0x4000_00FF  UART

//   0x4000_0100 – 0x4000_01FF  GPIO

//   0x4000_0200 – 0x4000_02FF  Timer

//   0x4000_0400 – 0x4000_04FF  I2C master

//   0x4000_0500 – 0x4000_05FF  SPI host

//   0x4000_0600 – 0x4000_06FF  PWM

//   0x4000_0700 – 0x4000_07FF  UART2 (ESP32 companion)

module ibex_demo_system #(

  parameter int                 GpiWidth       = 8,

  parameter int                 GpoWidth       = 16,

  parameter int                 PwmWidth       = 12,  // kept for port compat; PWM not wired

  parameter int unsigned        ClockFrequency = 20_000_000,

  parameter int unsigned        BaudRate       = 115_200,

  parameter int unsigned        Uart2BaudRate  = 115_200,

  parameter ibex_pkg::regfile_e RegFile        = ibex_pkg::RegFileFPGA,

  parameter                     SRAMInitFile   = "", // .vmem image baked into the SRAM (passed down to wrapper_top/sram_model)

  parameter                     BootInitFile   = "rtl/system/boot.mem", // boot ROM image; default = direct XIP boot (no SRAM dependency)

  // SPI clock divider for the XIP flash controller: SCK = clk/(2*XipClkDiv).
  // Spec default 4 (2.5 MHz at 20 MHz). The Arty's S25FL128 flash is rated
  // to 50 MHz for cmd 0x03, so 1 (10 MHz) is valid on hardware and is what
  // the FreeRTOS sim uses to keep XIP fetch time bounded.
  parameter int unsigned        XipClkDiv      = 4

) (

  input  logic clk_sys_i,

  input  logic rst_sys_ni,

  input  logic [GpiWidth-1:0]  gp_i,

  output logic [GpoWidth-1:0]  gp_o,

  // PWM output tied to 0 — PWM is not part of the new WB architecture

  output logic [PwmWidth-1:0]  pwm_o,

  input  logic uart_rx_i,

  input  logic uart2_rx_i,   // v1.1: ESP32 companion UART

  output logic uart_tx_o,

  output logic uart2_tx_o,

  input  logic spi_rx_i,

  output logic spi_tx_o,

  output logic spi_sck_o,

  output logic xip_spi_sck_o,

  output logic xip_spi_csn_o,

  output logic xip_spi_mosi_o,

  input  logic xip_spi_miso_i,

  // I2C

  input  logic i2c_scl_i,

  output logic i2c_scl_o,

  output logic i2c_scl_oe_o,
 
  input  logic i2c_sda_i,

  output logic i2c_sda_o,

  output logic i2c_sda_oe_o,

  // JTAG debug

  input  logic tck_i,

  input  logic tms_i,

  input  logic trst_ni,

  input  logic td_i,

  output logic td_o

);

  // PWM not connected in new architecture

  //assign pwm_o = '0;

  // =========================================================

  // CONSTANTS

  // =========================================================

  localparam bit DBG = 1;

  // =========================================================

  // INTERRUPTS

  // =========================================================

  logic uart_irq;

  logic uart2_irq;   // v1.1: ESP32 companion UART RX (fast IRQ 1)

  logic timer_irq;

  // =========================================================

  // RESET / DEBUG CONTROL

  // =========================================================

  /* verilator lint_off IMPERFECTSCH */

  logic rst_core_n;

  /* verilator lint_on IMPERFECTSCH */

  logic ndmreset_req;

  logic dm_debug_req;

  // Debug Non-Debug-Module reset: only resets the CPU core, not peripherals.

  assign rst_core_n = rst_sys_ni & ~ndmreset_req;

  // =========================================================

  // IBEX INSTRUCTION OBI

  // =========================================================

  logic        instr_req;

  logic        instr_gnt;

  logic        instr_rvalid;

  logic [31:0] instr_addr;

  logic [31:0] instr_rdata;

  // =========================================================

  // IBEX DATA OBI

  // =========================================================

  logic        data_req;

  logic        data_gnt;

  logic        data_rvalid;

  logic        data_we;

  logic [3:0]  data_be;

  logic [31:0] data_addr;

  logic [31:0] data_wdata;

  logic [31:0] data_rdata;

  // =========================================================

  // DEBUG MODULE DEVICE INTERFACE

  // (driven from wrapper_top WB pre-decode at 0x1A11_0000)

  // =========================================================

  logic        dbg_req;

  logic        dbg_we;

  logic [31:0] dbg_addr;

  logic [31:0] dbg_wdata;

  logic [3:0]  dbg_be;

  logic [31:0] dbg_rdata;

  // =========================================================

  // IBEX CORE

  // =========================================================

  ibex_top #(

    .PMPEnable         (1'b0),

    .PMPGranularity    (0),

    .PMPNumRegions     (1),

    .MHPMCounterNum    (0),

    .MHPMCounterWidth  (40),

    .RV32E             (1'b0),

    .RV32M             (ibex_pkg::RV32MSingleCycle),

    .RV32B             (ibex_pkg::RV32BNone),

    .WritebackStage    (1'b0),

    .ICache            (1'b0),

    .ICacheECC         (1'b0),

    .BranchPredictor   (1'b0),

    .DbgTriggerEn      (1'b0),

    .SecureIbex        (1'b0),

    .ICacheScramble    (1'b0),

    // DmHaltAddr points into the debug module's address window so that when

    // the CPU halts for debug it fetches the debug ROM via the WB bus.

    .DmHaltAddr        (32'h1A11_0800),

    .DmExceptionAddr   (32'h1A11_0808)

  ) u_top (

    .clk_i  (clk_sys_i),

    .rst_ni (rst_core_n),

    .test_en_i   (1'b0),

    .scan_rst_ni (1'b1),

    .ram_cfg_i   ('b0),

    .hart_id_i   (32'b0),

    .boot_addr_i (32'h0010_0000),

    // Instruction OBI — read-only, lower priority in arbiter

    .instr_req_o        (instr_req),

    .instr_gnt_i        (instr_gnt),

    .instr_rvalid_i     (instr_rvalid),

    .instr_addr_o       (instr_addr),

    .instr_rdata_i      (instr_rdata),

    .instr_rdata_intg_i ('0),

    .instr_err_i        (1'b0),

    // Data OBI — higher priority in arbiter

    .data_req_o        (data_req),

    .data_gnt_i        (data_gnt),

    .data_rvalid_i     (data_rvalid),

    .data_we_o         (data_we),

    .data_be_o         (data_be),

    .data_addr_o       (data_addr),

    .data_wdata_o      (data_wdata),

    .data_rdata_i      (data_rdata),

    .data_rdata_intg_i ('0),

    .data_err_i        (1'b0),

    .data_wdata_intg_o (),

    // Interrupts

    .irq_software_i (1'b0),

    .irq_timer_i    (timer_irq),

    .irq_external_i (1'b0),

    .irq_fast_i     ({13'b0, uart2_irq, uart_irq}),

    .irq_nm_i       (1'b0),

    .scramble_key_valid_i ('0),

    .scramble_key_i       ('0),

    .scramble_nonce_i     ('0),

    .scramble_req_o       (),

    // Debug

    .debug_req_i           (dm_debug_req),

    .crash_dump_o          (),

    .double_fault_seen_o   (),

    .fetch_enable_i        ('1),

    .alert_minor_o         (),

    .alert_major_internal_o(),

    .alert_major_bus_o     (),

    .core_sleep_o          ()

  );

  // =========================================================

  // SOC WRAPPER  (2:1 OBI arbiter → obi2wb → WB interconnect)

  // =========================================================

  wrapper_top #(

    .GpiWidth (GpiWidth),

    .GpoWidth (GpoWidth),

    .ClockFrequency (ClockFrequency),

    .BaudRate       (BaudRate),

    .Uart2BaudRate  (Uart2BaudRate),

    .SRAMInitFile   (SRAMInitFile),

    .BootInitFile   (BootInitFile),

    .XipClkDiv      (XipClkDiv)

  ) u_wrapper (

    .clk_i  (clk_sys_i),

    .rst_ni (rst_sys_ni),

    // Instruction OBI (lower priority)

    .obi_instr_req_i    (instr_req),

    .obi_instr_gnt_o    (instr_gnt),

    .obi_instr_addr_i   (instr_addr),

    .obi_instr_rvalid_o (instr_rvalid),

    .obi_instr_rdata_o  (instr_rdata),

    // Data OBI (higher priority)

    .obi_req_i    (data_req),

    .obi_gnt_o    (data_gnt),

    .obi_addr_i   (data_addr),

    .obi_we_i     (data_we),

    .obi_be_i     (data_be),

    .obi_wdata_i  (data_wdata),

    .obi_rvalid_o (data_rvalid),

    .obi_rdata_o  (data_rdata),

    // UART

    .uart_rx_i  (uart_rx_i),

    .uart2_rx_i (uart2_rx_i),

    .uart_tx_o  (uart_tx_o),

    .uart2_tx_o (uart2_tx_o),

    .uart_irq_o (uart_irq),

    .uart2_irq_o (uart2_irq),

    // GPIO

    .gp_i (gp_i),

    .gp_o (gp_o),

    // Timer

    .timer_intr_o (timer_irq),

    // SPI

    .spi_rx_i        (spi_rx_i),

    .spi_tx_o        (spi_tx_o),

    .spi_sck_o       (spi_sck_o),

    .spi_byte_data_o (),

      .xip_spi_sck_o  (xip_spi_sck_o),

      .xip_spi_csn_o  (xip_spi_csn_o),

      .xip_spi_mosi_o (xip_spi_mosi_o),

      .xip_spi_miso_i (xip_spi_miso_i),

    // I2C (not wired to top-level pins; use open-drain GPIO if needed)

    // I2C

    .i2c_scl_i    (i2c_scl_i),

    .i2c_scl_o    (i2c_scl_o),

    .i2c_scl_oe_o (i2c_scl_oe_o),

    .i2c_sda_i    (i2c_sda_i),

    .i2c_sda_o    (i2c_sda_o),

    .i2c_sda_oe_o (i2c_sda_oe_o),

    .i2c_irq_o    (),

    //PWM

    .pwm_o (pwm_o),

    // Debug device port (decoded from WB address space at 0x1A11_0000)

    .dbg_req_o    (dbg_req),

    .dbg_we_o     (dbg_we),

    .dbg_addr_o   (dbg_addr),

    .dbg_wdata_o  (dbg_wdata),

    .dbg_be_o     (dbg_be),

    .dbg_rdata_i  (dbg_rdata)

  );

  // =========================================================

  // DEBUG MODULE (dm_top)

  // =========================================================

  if (DBG) begin : gen_dm_top

    dm_top #(

      .NrHarts     (1),

      .IdcodeValue (jtag_id_pkg::RV_DM_JTAG_IDCODE)

    ) u_dm_top (

      .clk_i      (clk_sys_i),

      .rst_ni     (rst_sys_ni),

      .testmode_i (1'b0),

      .ndmreset_o    (ndmreset_req),

      .dmactive_o    (),

      .debug_req_o   (dm_debug_req),

      .unavailable_i (1'b0),

      // Device port — register access from the CPU via WB pre-decode

      .device_req_i   (dbg_req),

      .device_we_i    (dbg_we),

      .device_addr_i  (dbg_addr),

      .device_be_i    (dbg_be),

      .device_wdata_i (dbg_wdata),

      .device_rdata_o (dbg_rdata),

      // Host / SBA port — not connected in this design (tie off).

      // To enable System Bus Access (memory inspection via JTAG), wire

      // these to a third arbiter port in wrapper_top.

      .host_req_o     (),

      .host_add_o     (),

      .host_we_o      (),

      .host_wdata_o   (),

      .host_be_o      (),

      .host_gnt_i     (1'b0),

      .host_r_valid_i (1'b0),

      .host_r_rdata_i ('0),

      // JTAG

      .tck_i   (tck_i),

      .tms_i   (tms_i),

      .trst_ni (trst_ni),

      .td_i    (td_i),

      .td_o    (td_o)

    );

  end else begin : gen_no_dm

    assign ndmreset_req = 1'b0;

    assign dm_debug_req = 1'b0;

    assign td_o         = 1'b0;

    assign dbg_rdata    = 32'b0;

  end

  // =========================================================

  // VERILATOR DPI EXPORTS (performance counters)

  // =========================================================

  `ifdef VERILATOR

    export "DPI-C" function mhpmcounter_num;

    function automatic int unsigned mhpmcounter_num();

      return u_top.u_ibex_core.cs_registers_i.MHPMCounterNum;

    endfunction

    export "DPI-C" function mhpmcounter_get;

    function automatic longint unsigned mhpmcounter_get(int index);

      return u_top.u_ibex_core.cs_registers_i.mhpmcounter[index];

    endfunction

  `endif

endmodule
