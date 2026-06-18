module ibex_demo_system #(
  parameter int GpiWidth = 8,
  parameter int GpoWidth = 16,
   parameter int                 PwmWidth       = 12,
  parameter int unsigned        ClockFrequency = 50_000_000,
  parameter int unsigned        BaudRate       = 115_200,
  parameter ibex_pkg::regfile_e RegFile = ibex_pkg::RegFileFPGA,
  parameter SRAMInitFile = ""
) (
  input  logic clk_sys_i,
  input  logic rst_sys_ni,

  input  logic [GpiWidth-1:0] gp_i,
  output logic [GpoWidth-1:0] gp_o,

  input  logic uart_rx_i,
  output logic uart_tx_o,
 output logic [PwmWidth-1:0] pwm_o,
  input  logic spi_rx_i,
  output logic spi_tx_o,
  output logic spi_sck_o,

  input  logic tck_i,
  input  logic tms_i,
  input  logic trst_ni,
  input  logic td_i,
  output logic td_o
);
  localparam logic [31:0] MEM_SIZE      = 128 * 1024; // 128 KiB
  //localparam logic [31:0] MEM_START     = 32'h00100000;
  //localparam logic [31:0] MEM_MASK      = ~(MEM_SIZE-1);

  /*localparam logic [31:0] GPIO_SIZE     =  4 * 1024; //  4 KiB
  localparam logic [31:0] GPIO_START    = 32'h80000000;
  localparam logic [31:0] GPIO_MASK     = ~(GPIO_SIZE-1);
*/
  localparam logic [31:0] DEBUG_SIZE    = 64 * 1024; // 64 KiB
  localparam logic [31:0] DEBUG_START   = 32'h1a110000;
  localparam logic [31:0] DEBUG_MASK    = ~(DEBUG_SIZE-1);

  /*localparam logic [31:0] UART_SIZE     =  4 * 1024; //  4 KiB
  localparam logic [31:0] UART_START    = 32'h80001000;
  localparam logic [31:0] UART_MASK     = ~(UART_SIZE-1);
*/
  /*localparam logic [31:0] TIMER_SIZE    =  4 * 1024; //  4 KiB
  localparam logic [31:0] TIMER_START   = 32'h80002000;
  localparam logic [31:0] TIMER_MASK    = ~(TIMER_SIZE-1);
*/
   localparam logic [31:0] PWM_SIZE      =  4 * 1024; //  4 KiB
  localparam logic [31:0] PWM_START     = 32'h80003000;
  localparam logic [31:0] PWM_MASK      = ~(PWM_SIZE-1);
  localparam int PwmCtrSize = 8;

/*parameter logic [31:0] SPI_SIZE       =  1 * 1024; //  1 KiB
  parameter logic [31:0] SPI_START      = 32'h80004000;
  parameter logic [31:0] SPI_MASK       = ~(SPI_SIZE-1);

  parameter logic [31:0] SIM_CTRL_SIZE  =  1 * 1024; //  1 KiB
  parameter logic [31:0] SIM_CTRL_START = 32'h20000;
  parameter logic [31:0] SIM_CTRL_MASK  = ~(SIM_CTRL_SIZE-1);
*/
   // Debug functionality is optional.
  localparam bit DBG = 1;
  localparam int unsigned DbgHwBreakNum = (DBG == 1) ?    2 :    0;
  //localparam bit          DbgTriggerEn  = (DBG == 1) ? 1'b1 : 1'b0;

 localparam int NrDevices = DBG ? 8 : 7;
  localparam int NrHosts   = DBG ? 2 : 1;

 typedef enum int {
    CoreD,
    DbgHost
  } bus_host_e;
 typedef enum int {
    Ram,
    Gpio,
    Pwm,
    Uart,
    Timer,
    Spi,
    SimCtrl,
    DbgDev
  } bus_device_e;
  // =========================================================
  // INTERRUPTS
  // =========================================================
  logic uart_irq;
  logic timer_irq;

   // Host signals.
  logic        host_req      [NrHosts];
  logic        host_gnt      [NrHosts];
  logic [31:0] host_addr     [NrHosts];
  logic        host_we       [NrHosts];
  logic [ 3:0] host_be       [NrHosts];
  logic [31:0] host_wdata    [NrHosts];
  logic        host_rvalid   [NrHosts];
  logic [31:0] host_rdata    [NrHosts];
  logic        host_err      [NrHosts];

  // Device signals.
  logic        device_req    [NrDevices];
  logic [31:0] device_addr   [NrDevices];
  logic        device_we     [NrDevices];
  logic [ 3:0] device_be     [NrDevices];
  logic [31:0] device_wdata  [NrDevices];
  logic        device_rvalid [NrDevices];
  logic [31:0] device_rdata  [NrDevices];
  logic        device_err    [NrDevices];

  // Instruction fetch signals.
  logic        core_instr_req;
 logic        core_instr_gnt;
  logic        core_instr_rvalid;
  logic [31:0] core_instr_addr;
 logic [31:0] core_instr_rdata;
 logic        core_instr_sel_dbg;

  logic        mem_instr_req;
  logic [31:0] mem_instr_rdata;
  logic        dbg_instr_req;

  logic        dbg_device_req;
  logic [31:0] dbg_device_addr;
  logic        dbg_device_we;
  logic [ 3:0] dbg_device_be;
  logic [31:0] dbg_device_wdata;
  logic        dbg_device_rvalid;
  logic [31:0] dbg_device_rdata;

  // =========================================================
  // INSTRUCTION PATH
  // =========================================================
  logic        instr_req;
  logic        instr_gnt;
  logic        instr_rvalid;
  logic [31:0] instr_addr;
  logic [31:0] instr_rdata;

  logic        instr_mem_req;
  logic [31:0] instr_mem_rdata;

  assign instr_mem_req = instr_req;
  assign instr_gnt     = instr_mem_req;

  always_ff @(posedge clk_sys_i or negedge rst_sys_ni) begin
    if (!rst_sys_ni)
      instr_rvalid <= 1'b0;
    else
      instr_rvalid <= instr_gnt;
  end

  //assign instr_rdata = instr_mem_rdata;

  // =========================================================
  // DATA OBI -> WRAPPER
  // =========================================================
  logic        data_req;
  logic        data_gnt;
  logic        data_rvalid;
  logic        data_we;
  logic [3:0]  data_be;
  logic [31:0] data_addr;
  logic [31:0] data_wdata;
  logic [31:0] data_rdata;

    // Internally generated resets cause IMPERFECTSCH warnings
  /* verilator lint_off IMPERFECTSCH */
  logic rst_core_n;
  logic ndmreset_req;
  logic dm_debug_req;

  // Device address mapping.
  logic [31:0] cfg_device_addr_base [NrDevices];
  logic [31:0] cfg_device_addr_mask [NrDevices];

  assign cfg_device_addr_base[Pwm]     = PWM_START;
  assign cfg_device_addr_mask[Pwm]     = PWM_MASK;

  if (DBG) begin : g_dbg_device_cfg
    assign cfg_device_addr_base[DbgDev] = DEBUG_START;
    assign cfg_device_addr_mask[DbgDev] = DEBUG_MASK;
    assign device_err[DbgDev] = 1'b0;
  end

  // Tie-off unused error signals.
  assign device_err[Ram]     = 1'b0;
  assign device_err[Gpio]    = 1'b0;
  assign device_err[Pwm]     = 1'b0;
  assign device_err[Uart]    = 1'b0;
  assign device_err[Spi]     = 1'b0;
  assign device_err[SimCtrl] = 1'b0;

   bus #(
    .NrDevices    ( NrDevices ),
    .NrHosts      ( NrHosts   ),
    .DataWidth    ( 32        ),
    .AddressWidth ( 32        )
  ) u_bus (
    .clk_i (clk_sys_i),
    .rst_ni(rst_sys_ni),

    .host_req_i   (host_req     ),
    .host_gnt_o   (host_gnt     ),
    .host_addr_i  (host_addr    ),
    .host_we_i    (host_we      ),
    .host_be_i    (host_be      ),
    .host_wdata_i (host_wdata   ),
    .host_rvalid_o(host_rvalid  ),
    .host_rdata_o (host_rdata   ),
  .host_err_o   (host_err     ),

    .device_req_o   (device_req   ),
    .device_addr_o  (device_addr  ),
    .device_we_o    (device_we    ),
    .device_be_o    (device_be    ),
    .device_wdata_o (device_wdata ),
    .device_rvalid_i(device_rvalid),
    .device_rdata_i (device_rdata ),
    .device_err_i   (device_err   ),

    .cfg_device_addr_base,
    .cfg_device_addr_mask
  );

  assign mem_instr_req =
      core_instr_req & ((core_instr_addr & cfg_device_addr_mask[Ram]) == cfg_device_addr_base[Ram]);

  assign dbg_instr_req =
      core_instr_req & ((core_instr_addr & cfg_device_addr_mask[DbgDev]) == cfg_device_addr_base[DbgDev]);

  //assign core_instr_gnt = mem_instr_req | (dbg_instr_req & ~device_req[DbgDev]);

  always @(posedge clk_sys_i or negedge rst_sys_ni) begin
    if (!rst_sys_ni) begin
      core_instr_rvalid  <= 1'b0;
     core_instr_sel_dbg <= 1'b0;
    end 
   else begin
  core_instr_rvalid  <= core_instr_gnt;
  core_instr_sel_dbg <= dbg_instr_req;
  end
  end

  /*assign core_instr_rdata = core_instr_sel_dbg ? dbg_device_rdata : mem_instr_rdata;
assign instr_rdata = instr_mem_rdata;
  assign instr_rdata =
    (instr_addr >= 32'h00100000 && instr_addr < 32'h00101000)
        ? boot_rom_rdata
        : mem_instr_rdata;*/
/*  assign core_instr_rdata =
    core_instr_sel_dbg
        ? dbg_device_rdata
        : ((instr_addr >= 32'h00100000 && instr_addr < 32'h00101000)
            ? boot_rom_rdata
            : mem_instr_rdata);
  
  assign instr_rdata =
    (instr_addr >= 32'h00100000 && instr_addr < 32'h00101000)
        ? boot_rom_rdata
        : mem_instr_rdata;

assign core_instr_rdata =
    core_instr_sel_dbg ? dbg_device_rdata : instr_rdata;*/
  /* wire [31:0] instr_addr_aligned;
assign instr_addr_aligned = instr_addr & 32'hFFFF_FFFC;
assign rom_word_addr = instr_addr_aligned[11:2];

assign instr_rdata = boot_rom_rdata;*

assign core_instr_rdata =
    core_instr_sel_dbg ? dbg_device_rdata : instr_rdata;


  // =========================================================
  // DEBUG MODULE SIGNALS (FIXED PROPERLY)
  // =========================================================
  /*logic dm_debug_req;
  logic ndmreset_req;

  logic dbg_device_req;
  logic dbg_device_we;
  logic [31:0] dbg_device_addr;
  logic [3:0]  dbg_device_be;
  logic [31:0] dbg_device_wdata;
  logic [31:0] dbg_device_rdata;
  logic        dbg_device_rvalid;
 */
  // =========================================================
  // IBEX CORE
  // =========================================================
  ibex_top #(
  .PMPEnable        (1'b0),       // No PMP (see security appendix)
  .PMPGranularity   (0),
  .PMPNumRegions    (1),
  .MHPMCounterNum   (0),          // No perf counters (saves area)
  .MHPMCounterWidth (40),
  .RV32E            (1'b0),       // Full 32 registers
  .RV32M            (ibex_pkg::RV32MSingleCycle),
  .RV32B            (ibex_pkg::RV32BNone),  // No bitmanip
  .WritebackStage   (1'b0),       // 2-stage pipeline (area)
  .ICache           (1'b0),       // No ICache
  .ICacheECC        (1'b0),
  .BranchPredictor (1'b0),       // No branch prediction
  .DbgTriggerEn     (1'b0),       // No debug triggers
  .SecureIbex       (1'b0),       // No security features
  .ICacheScramble   (1'b0),
  .DmHaltAddr       (32'h00100000),
  .DmExceptionAddr  (32'h00100000)
  ) u_top (
    .clk_i(clk_sys_i),
    .rst_ni(rst_sys_ni),

    .test_en_i(1'b0),
    .scan_rst_ni(1'b1),
 .ram_cfg_i  ('b0),

    .hart_id_i(32'b0),
   .boot_addr_i(32'h0010_0000),

    // INSTRUCTION
    .instr_req_o(instr_req),
    .instr_gnt_i(instr_gnt),
    .instr_rvalid_i(instr_rvalid),
    .instr_addr_o(instr_addr),
    .instr_rdata_i(instr_rdata),
    .instr_rdata_intg_i('0),
    .instr_err_i('0),

    // DATA
    .data_req_o(data_req),
    .data_gnt_i(data_gnt),
    .data_rvalid_i(data_rvalid),
    .data_we_o(data_we),
    .data_be_o(data_be),
    .data_addr_o(data_addr),
    .data_wdata_o(data_wdata),
    .data_rdata_i(data_rdata),
    .data_rdata_intg_i('0),
    .data_err_i(1'b0),
 .data_wdata_intg_o(),
    // INTERRUPTS
    .irq_software_i(1'b0),
    .irq_timer_i(timer_irq),
    .irq_external_i(1'b0),
    .irq_fast_i({14'b0, uart_irq}),
    .irq_nm_i(1'b0),
 .scramble_key_valid_i('0),
    .scramble_key_i      ('0),
    .scramble_nonce_i    ('0),
    .scramble_req_o      (),

    // DEBUG
    .debug_req_i(dm_debug_req),
     .crash_dump_o       (),
    .double_fault_seen_o(),
      .fetch_enable_i        ('1),
    .alert_minor_o         (),
    .alert_major_internal_o(),
    .alert_major_bus_o     (),
    .core_sleep_o          ()
  );

  pwm_wrapper #(
    .PwmWidth     ( PwmWidth   ),
    .PwmCtrSize   ( PwmCtrSize ),
    .BusAddrWidth ( 32         )
  ) u_pwm (
    .clk_i (clk_sys_i),
    .rst_ni(rst_sys_ni),

    .device_req_i   (device_req[Pwm]),
    .device_addr_i  (device_addr[Pwm]),
    .device_we_i    (device_we[Pwm]),
    .device_be_i    (device_be[Pwm]),
    .device_wdata_i (device_wdata[Pwm]),
    .device_rvalid_o(device_rvalid[Pwm]),
    .device_rdata_o (device_rdata[Pwm]),

    .pwm_o
  );

  ram_2p #(
      .Depth       ( MEM_SIZE / 4 ),
      .MemInitFile ( SRAMInitFile )
  ) u_ram (
    .clk_i (clk_sys_i),
    .rst_ni(rst_sys_ni),

    .a_req_i   (device_req[Ram]),
    .a_we_i    (device_we[Ram]),
    .a_be_i    (device_be[Ram]),
    .a_addr_i  (device_addr[Ram]),
    .a_wdata_i (device_wdata[Ram]),
    .a_rvalid_o(device_rvalid[Ram]),
    .a_rdata_o (device_rdata[Ram]),

    .b_req_i   (mem_instr_req),
    .b_we_i    (1'b0),
    .b_be_i    (4'b0),
    .b_addr_i  (core_instr_addr),
    .b_wdata_i (32'b0),
    .b_rvalid_o(),
    .b_rdata_o (mem_instr_rdata)
  );

  boot_rom_wrapper u_boot_rom (
  .clk_i   (clk_sys_i),
  .rst_ni  (rst_sys_ni),
  .req_i   (instr_req),
  .we_i    (1'b0),
  .addr_i  (instr_addr - 32'h00100000), // 🔥 IMPORTANT FIX
  .wdata_i (32'b0),
  .be_i    (4'b0),
  .rvalid_o(),
  .rdata_o (boot_rom_rdata)
);
  // =========================================================
  // WRAPPER (OBI -> WB SOC)
  // =========================================================
  wrapper_top u_wrapper (
    .clk_i(clk_sys_i),
    .rst_ni(rst_sys_ni),

    .obi_req_i(data_req),
    .obi_gnt_o(data_gnt),
    .obi_addr_i(data_addr),
    .obi_we_i(data_we),
    .obi_be_i(data_be),
    .obi_wdata_i(data_wdata),
    .obi_rvalid_o(data_rvalid),
    .obi_rdata_o(data_rdata),

    .uart_rx_i(uart_rx_i),
    .uart_tx_o(uart_tx_o),
    .uart_irq_o(uart_irq),

    .gp_i(gp_i),
    .gp_o(gp_o),

    .timer_intr_o(timer_irq),

    .spi_rx_i(spi_rx_i),
    .spi_tx_o(spi_tx_o),
    .spi_sck_o(spi_sck_o),
    .spi_byte_data_o(),

    .i2c_scl_i(1'b0),
    .i2c_scl_o(),
    .i2c_scl_oe_o(),
    .i2c_sda_i(1'b0),
    .i2c_sda_o(),
    .i2c_sda_oe_o(),
    .i2c_irq_o()
  );
  
  // =========================================================
  // DEBUG MODULE (YOUR ORIGINAL, FIXED INTEGRATION)
  // =========================================================
 assign dbg_device_req        = device_req[DbgDev] | dbg_instr_req;
  assign dbg_device_we         = device_req[DbgDev] & device_we[DbgDev];
  assign dbg_device_addr       = device_req[DbgDev] ? device_addr[DbgDev] : core_instr_addr;
  assign dbg_device_be         = device_be[DbgDev];
  assign dbg_device_wdata      = device_wdata[DbgDev];
  assign device_rvalid[DbgDev] = dbg_device_rvalid;
  assign device_rdata[DbgDev]  = dbg_device_rdata;

  always @(posedge clk_sys_i or negedge rst_sys_ni) begin
    if (!rst_sys_ni) begin
      dbg_device_rvalid <= 1'b0;
    end else begin
      dbg_device_rvalid <= device_req[DbgDev];
    end
  end
 if (DBG) begin : gen_dm_top
    dm_top #(
      .NrHarts(1),
      .IdcodeValue(jtag_id_pkg::RV_DM_JTAG_IDCODE)
    ) u_dm_top (
      .clk_i(clk_sys_i),
      .rst_ni(rst_sys_ni),
      .testmode_i(1'b0),

      .ndmreset_o(ndmreset_req),
      .dmactive_o(),
      .debug_req_o(dm_debug_req),
      .unavailable_i(1'b0),

      .device_req_i(dbg_device_req),
      .device_we_i(dbg_device_we),
      .device_addr_i(dbg_device_addr),
      .device_be_i(dbg_device_be),
      .device_wdata_i(dbg_device_wdata),
      .device_rdata_o(dbg_device_rdata),

      .host_req_o(host_req[DbgHost]),
      .host_add_o(host_addr[DbgHost]),
      .host_we_o(host_we[DbgHost]),
      .host_wdata_o(host_wdata[DbgHost]),
      .host_be_o(host_be[DbgHost]),
      .host_gnt_i(host_gnt[DbgHost]),
      .host_r_valid_i(host_rvalid[DbgHost]),
      .host_r_rdata_i(host_rdata[DbgHost]),

      .tck_i(tck_i),
      .tms_i(tms_i),
      .trst_ni(trst_ni),
      .td_i(td_i),
      .td_o(td_o)
    );
  end 
 else begin
    assign dm_debug_req = 1'b0;
    assign ndmreset_req = 1'b0;
    assign td_o = 1'b0;
  end

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
