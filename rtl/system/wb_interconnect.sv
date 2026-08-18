// Code your design here

module wb_interconnect #(

  parameter int AW = 32,

  parameter int DW = 32

)(

  input  logic clk_i,

  input  logic rst_ni,
 
  // =========================================================

  // Wishbone Master Interface

  // =========================================================
 
  input  logic             wb_cyc_i,

  input  logic             wb_stb_i,

  input  logic             wb_we_i,

  input  logic [AW-1:0]    wb_adr_i,

  input  logic [DW-1:0]    wb_dat_i,

  input  logic [DW/8-1:0]  wb_sel_i,
 
  output logic             wb_ack_o,

  output logic [DW-1:0]    wb_dat_o,

  output logic             wb_stall_o,
 
  // =========================================================

  // BOOT ROM Interface

  // =========================================================
 
  output logic             bootrom_req_o,

  output logic             bootrom_we_o,

  output logic [AW-1:0]    bootrom_addr_o,

  output logic [DW-1:0]    bootrom_wdata_o,

  output logic [DW/8-1:0]  bootrom_be_o,
 
  input  logic             bootrom_rvalid_i,

  input  logic [DW-1:0]    bootrom_rdata_i,
 
  // =========================================================

  // SRAM Interface

  // =========================================================
 
  output logic             sram_req_o,

  output logic             sram_we_o,

  output logic [AW-1:0]    sram_addr_o,

  output logic [DW-1:0]    sram_wdata_o,

  output logic [DW/8-1:0]  sram_be_o,
 
  input  logic             sram_rvalid_i,

  input  logic [DW-1:0]    sram_rdata_i,
 
  // =========================================================

  // SPI FLASH XIP Interface

  // =========================================================
 
  output logic             xip_req_o,

  output logic             xip_we_o,

  output logic [AW-1:0]    xip_addr_o,

  output logic [DW-1:0]    xip_wdata_o,

  output logic [DW/8-1:0]  xip_be_o,
 
  input  logic             xip_rvalid_i,

  input  logic [DW-1:0]    xip_rdata_i,
 
  // =========================================================

  // UART Interface

  // =========================================================
 
  output logic             uart_req_o,

  output logic             uart_we_o,

  output logic [AW-1:0]    uart_addr_o,

  output logic [DW-1:0]    uart_wdata_o,

  output logic [DW/8-1:0]  uart_be_o,
 
  input  logic             uart_rvalid_i,

  input  logic [DW-1:0]    uart_rdata_i,
 
  // =========================================================

  // UART2 Interface (v1.1 - ESP32 companion link)

  // =========================================================
 
  output logic             uart2_req_o,

  output logic             uart2_we_o,

  output logic [AW-1:0]    uart2_addr_o,

  output logic [DW-1:0]    uart2_wdata_o,

  output logic [DW/8-1:0]  uart2_be_o,
 
  input  logic             uart2_rvalid_i,

  input  logic [DW-1:0]    uart2_rdata_i,
 
  // =========================================================

  // GPIO Interface

  // =========================================================
 
  output logic             gpio_req_o,

  output logic             gpio_we_o,

  output logic [AW-1:0]    gpio_addr_o,

  output logic [DW-1:0]    gpio_wdata_o,

  output logic [DW/8-1:0]  gpio_be_o,
 
  input  logic             gpio_rvalid_i,

  input  logic [DW-1:0]    gpio_rdata_i,
 
  // =========================================================

  // TIMER Interface

  // =========================================================
 
  output logic             timer_req_o,

  output logic             timer_we_o,

  output logic [AW-1:0]    timer_addr_o,

  output logic [DW-1:0]    timer_wdata_o,

  output logic [DW/8-1:0]  timer_be_o,
 
  input  logic             timer_rvalid_i,

  input  logic [DW-1:0]    timer_rdata_i,
 
  // =========================================================

  // I2C Interface

  // =========================================================
 
  output logic             i2c_req_o,

  output logic             i2c_we_o,

  output logic [AW-1:0]    i2c_addr_o,

  output logic [DW-1:0]    i2c_wdata_o,

  output logic [DW/8-1:0]  i2c_be_o,
 
  input  logic             i2c_rvalid_i,

  input  logic [DW-1:0]    i2c_rdata_i,
 
  // =========================================================

  // SPI HOST Interface

  // =========================================================
 
  output logic             spihost_req_o,

  output logic             spihost_we_o,

  output logic [AW-1:0]    spihost_addr_o,

  output logic [DW-1:0]    spihost_wdata_o,

  output logic [DW/8-1:0]  spihost_be_o,
 
  input  logic             spihost_rvalid_i,

  input  logic [DW-1:0]    spihost_rdata_i,
 
  // =========================================================

  // PWM Interface

  // =========================================================
 
  output logic             pwm_req_o,

  output logic             pwm_we_o,

  output logic [AW-1:0]    pwm_addr_o,

  output logic [DW-1:0]    pwm_wdata_o,

  output logic [DW/8-1:0]  pwm_be_o,
 
  input  logic             pwm_rvalid_i,

  input  logic [DW-1:0]    pwm_rdata_i

);
 
  // =========================================================

  // Device Enumeration

  // =========================================================
 
  typedef enum logic [3:0] {

    DEV_BOOTROM = 4'd0,

    DEV_SRAM    = 4'd1,

    DEV_XIP     = 4'd2,

    DEV_UART    = 4'd3,

    DEV_GPIO    = 4'd4,

    DEV_TIMER   = 4'd5,

    // DEV 6 was the SPI-control stub at 0x4000_0300: dead decode returning
    // zeros, removed 2026-08-18 to match the PD tree (team commit 8ed494d).

    DEV_I2C     = 4'd7,

    DEV_SPIHOST = 4'd8,

    DEV_PWM     = 4'd9,

    DEV_UART2   = 4'd10

} device_e;
 
  // =========================================================

  // Address Map

  // =========================================================
 
  localparam logic [31:0] BOOTROM_BASE = 32'h0010_0000;

  localparam logic [31:0] BOOTROM_MASK = 32'hFFFF_F000;
 
  localparam logic [31:0] SRAM_BASE    = 32'h0010_2000;

  // 8 KiB SRAM (0x0010_2000 .. 0x0010_3FFF) per ASIC spec (docs/ASIC_SPEC.md).
  // The base is not aligned to the size, so the decode uses a range compare
  // instead of a mask. Must stay consistent with SramWordAddrWidth in
  // wrapper_top.sv. Base 0x0010_2000 TEAM-CONFIRMED 2026-08-10 (the spec
  // sheet's printed 0x0010_1000 is stale); boot entry = SRAM+0x80.
  localparam logic [31:0] SRAM_SIZE    = 32'h0000_2000;
 
  localparam logic [31:0] XIP_BASE     = 32'h2000_0000;

  localparam logic [31:0] XIP_MASK     = 32'hF000_0000;
 
  localparam logic [31:0] UART_BASE    = 32'h4000_0000;

  localparam logic [31:0] UART_MASK    = 32'hFFFF_FF00;
 
  localparam logic [31:0] GPIO_BASE    = 32'h4000_0100;

  localparam logic [31:0] GPIO_MASK    = 32'hFFFF_FF00;
 
  localparam logic [31:0] TIMER_BASE   = 32'h4000_0200;

  localparam logic [31:0] TIMER_MASK   = 32'hFFFF_FF00;
 
  localparam logic [31:0] I2C_BASE     = 32'h4000_0400;

  localparam logic [31:0] I2C_MASK     = 32'hFFFF_FF00;
 
  localparam logic [31:0] SPIHOST_BASE = 32'h4000_0500;

  localparam logic [31:0] SPIHOST_MASK = 32'hFFFF_FF00;

  localparam PWM_BASE = 32'h4000_0600;

  localparam UART2_BASE = 32'h4000_0700;   // v1.1: ESP32 companion UART
 
  // =========================================================

  // Decode Signals 

  // =========================================================
 
  logic bootrom_sel; //If any of these signals is 1, then we can say

  logic sram_sel;    //  that particular peripheral is matched according

  logic xip_sel;     // to wb_addr_i value

  logic uart_sel;

  logic uart2_sel;

  logic gpio_sel;

  logic timer_sel;

  logic i2c_sel;

  logic spihost_sel;

  logic pwm_sel;
 
  device_e device_sel_resp;
 
  logic decode_err_resp; //if 1 -> device matched, if 0 -> no device matched

                         //so give this error resp, or else cpu will wait forever

  // =========================================================

  // Address Decode

  // =========================================================
 
  always_comb begin      // This block checks the wb_addr_i, and decides which 

                         //device or peipheral is matched with the wb_addr_i value

    bootrom_sel =

      ((wb_adr_i & BOOTROM_MASK) == BOOTROM_BASE);
 
    sram_sel =

      (wb_adr_i >= SRAM_BASE) && (wb_adr_i < (SRAM_BASE + SRAM_SIZE));
 
    xip_sel =

      ((wb_adr_i & XIP_MASK) == XIP_BASE);
 
    uart_sel =

      ((wb_adr_i & UART_MASK) == UART_BASE);
 
    gpio_sel =

      ((wb_adr_i & GPIO_MASK) == GPIO_BASE);
 
    timer_sel =

      ((wb_adr_i & TIMER_MASK) == TIMER_BASE);

    i2c_sel =

      ((wb_adr_i & I2C_MASK) == I2C_BASE);
 
    spihost_sel =

      ((wb_adr_i & SPIHOST_MASK) == SPIHOST_BASE);

    pwm_sel =

      ((wb_adr_i & 32'hFFFF_FF00) == PWM_BASE);

    uart2_sel =

      ((wb_adr_i & 32'hFFFF_FF00) == UART2_BASE);
 
  end
 
  // =========================================================

  // Response Pipeline

  // =========================================================
 
  //This block does 2 things 

  //  1. assigns the device name to resp signal, so that later the resp can 

  //     decide which device/peripheral needs to respond for this request

  //  2. decode_err_resp this signals value represents the wb_addr_i, is actually

  //     matched with any of the available peripherals. if not a single device matches

  //     the wb_addr_i this we need to give this response to cpu

  // NOTE: Why are we using non-blocking for response?

  //       because responses comes in the next cycles, so this response information should 

  //       be written in timing/clocks related block(always block)

  always_ff @(posedge clk_i or negedge rst_ni) begin
 
    if (!rst_ni) begin                          
 
      device_sel_resp <= DEV_BOOTROM;

      decode_err_resp <= 1'b0;
 
    end else begin
 
      if      (bootrom_sel) device_sel_resp <= DEV_BOOTROM;

      else if (sram_sel)    device_sel_resp <= DEV_SRAM;

      else if (xip_sel)     device_sel_resp <= DEV_XIP;

      else if (uart_sel)    device_sel_resp <= DEV_UART;

      else if (gpio_sel)    device_sel_resp <= DEV_GPIO;

      else if (timer_sel)   device_sel_resp <= DEV_TIMER;

      else if (i2c_sel)     device_sel_resp <= DEV_I2C;

      else if (spihost_sel) device_sel_resp <= DEV_SPIHOST;

      else if (pwm_sel)     device_sel_resp <= DEV_PWM;

      else if (uart2_sel)   device_sel_resp <= DEV_UART2;
 
      decode_err_resp <=

        wb_cyc_i &

        wb_stb_i &

       !(bootrom_sel |

  	sram_sel |

  	xip_sel |

  	uart_sel |

  	gpio_sel |

  	timer_sel |

  	i2c_sel |

  	spihost_sel |

  	uart2_sel |

  	pwm_sel);
 
    end

  end
 
  // =========================================================

  // Request Routing

  // =========================================================
 
  //simple signal to signal assignment to only one peripheral at a time

  //which is matched the wb_addr_i value

  always_comb begin
 
    // Default outputs
 
    bootrom_req_o   = '0;

    bootrom_we_o    = '0;

    bootrom_addr_o  = '0;

    bootrom_wdata_o = '0;

    bootrom_be_o    = '0;

    sram_req_o      = '0;

    sram_we_o       = '0;

    sram_addr_o     = '0;

    sram_wdata_o    = '0;

    sram_be_o       = '0;

    xip_req_o       = '0;

    xip_we_o        = '0;

    xip_addr_o      = '0;

    xip_wdata_o     = '0;

    xip_be_o        = '0;

    uart_req_o      = '0;

    uart_we_o       = '0;

    uart_addr_o     = '0;

    uart_wdata_o    = '0;

    uart_be_o       = '0;

    gpio_req_o      = '0;

    gpio_we_o       = '0;

    gpio_addr_o     = '0;

    gpio_wdata_o    = '0;

    gpio_be_o       = '0;

    timer_req_o     = '0;

    timer_we_o      = '0;

    timer_addr_o    = '0;

    timer_wdata_o   = '0;

    timer_be_o      = '0;

    i2c_req_o       = '0;

    i2c_we_o        = '0;

    i2c_addr_o      = '0;

    i2c_wdata_o     = '0;

    i2c_be_o        = '0;

    spihost_req_o   = '0;

    spihost_we_o    = '0;

    spihost_addr_o  = '0;

    spihost_wdata_o = '0;

    spihost_be_o    = '0;

    uart2_req_o   = '0;

    uart2_we_o    = '0;

    uart2_addr_o  = '0;

    uart2_wdata_o = '0;

    uart2_be_o    = '0;

    pwm_req_o   = '0;

    pwm_we_o    = '0;

    pwm_addr_o  = '0;

    pwm_wdata_o = '0;

    pwm_be_o    = '0;
 
    //Check which peripheral is matched, then route the addr,data,etc only to that periperal

    if (bootrom_sel) begin

      bootrom_req_o   = wb_cyc_i & wb_stb_i;

      bootrom_we_o    = wb_we_i;

      bootrom_addr_o  = wb_adr_i;

      bootrom_wdata_o = wb_dat_i;

      bootrom_be_o    = wb_sel_i;

    end
 
    if (sram_sel) begin

      sram_req_o   = wb_cyc_i & wb_stb_i;

      sram_we_o    = wb_we_i;

      sram_addr_o  = wb_adr_i;

      sram_wdata_o = wb_dat_i;

      sram_be_o    = wb_sel_i;

    end
 
    if (xip_sel) begin

      xip_req_o   = wb_cyc_i & wb_stb_i;

      xip_we_o    = wb_we_i;

      xip_addr_o  = wb_adr_i;

      xip_wdata_o = wb_dat_i;

      xip_be_o    = wb_sel_i;

    end
 
    if (uart_sel) begin

      uart_req_o   = wb_cyc_i & wb_stb_i;

      uart_we_o    = wb_we_i;

      uart_addr_o  = wb_adr_i;

      uart_wdata_o = wb_dat_i;

      uart_be_o    = wb_sel_i;

    end

    if (uart2_sel) begin

      uart2_req_o   = wb_cyc_i & wb_stb_i;

      uart2_we_o    = wb_we_i;

      uart2_addr_o  = wb_adr_i;

      uart2_wdata_o = wb_dat_i;

      uart2_be_o    = wb_sel_i;

    end
 
    if (gpio_sel) begin

      gpio_req_o = wb_cyc_i & wb_stb_i;

      gpio_we_o    = wb_we_i;

      gpio_addr_o  = wb_adr_i;

      gpio_wdata_o = wb_dat_i;

      gpio_be_o    = wb_sel_i;

    end
 
    if (timer_sel) begin

      timer_req_o   = wb_cyc_i & wb_stb_i;

      timer_we_o    = wb_we_i;

      timer_addr_o  = wb_adr_i;

      timer_wdata_o = wb_dat_i;

      timer_be_o    = wb_sel_i;

    end
 
    if (i2c_sel) begin

      i2c_req_o   = wb_cyc_i & wb_stb_i;

      i2c_we_o    = wb_we_i;

      i2c_addr_o  = wb_adr_i;

      i2c_wdata_o = wb_dat_i;

      i2c_be_o    = wb_sel_i;

    end
 
 
    if (spihost_sel) begin

      spihost_req_o   = wb_cyc_i & wb_stb_i;

      spihost_we_o    = wb_we_i;

      spihost_addr_o  = wb_adr_i;

      spihost_wdata_o = wb_dat_i;

      spihost_be_o    = wb_sel_i;

    end

    if (pwm_sel) begin

      pwm_req_o   = wb_cyc_i & wb_stb_i;

      pwm_we_o    = wb_we_i;

      pwm_addr_o  = wb_adr_i;

      pwm_wdata_o = wb_dat_i;

      pwm_be_o    = wb_sel_i;

    end
 
  end
 
  // =========================================================

  // Response Mux

  // =========================================================
 
  always_comb begin
 
    wb_ack_o = 1'b0;

    wb_dat_o = '0;
 
    if (decode_err_resp) begin
 
      wb_ack_o = 1'b1;

      wb_dat_o = '0;
 
    end else begin
 
      case (device_sel_resp)
 
        DEV_BOOTROM: begin

          wb_ack_o = bootrom_rvalid_i;

          wb_dat_o = bootrom_rdata_i;

        end
 
        DEV_SRAM: begin

          wb_ack_o = sram_rvalid_i;

          wb_dat_o = sram_rdata_i;

        end
 
        DEV_XIP: begin

          wb_ack_o = xip_rvalid_i;

          wb_dat_o = xip_rdata_i;

        end
 
        DEV_UART: begin

          wb_ack_o = uart_rvalid_i;

          wb_dat_o = uart_rdata_i;

        end

        DEV_UART2: begin

          wb_ack_o = uart2_rvalid_i;

          wb_dat_o = uart2_rdata_i;

        end
 
        DEV_GPIO: begin

          wb_ack_o = gpio_rvalid_i;

          wb_dat_o = gpio_rdata_i;

        end
 
        DEV_TIMER: begin

          wb_ack_o = timer_rvalid_i;

          wb_dat_o = timer_rdata_i;

        end
 
 
        DEV_I2C: begin

          wb_ack_o = i2c_rvalid_i;

          wb_dat_o = i2c_rdata_i;

        end
 
        DEV_SPIHOST: begin

          wb_ack_o = spihost_rvalid_i;

          wb_dat_o = spihost_rdata_i;

        end

        DEV_PWM: begin

    	  wb_ack_o = pwm_rvalid_i;

    	  wb_dat_o = pwm_rdata_i;

	end
 
        default: begin

          wb_ack_o = 1'b0;

          wb_dat_o = '0;

        end
 
      endcase

    end

  end
 
  // =========================================================

  // No Stall Support

  // =========================================================
 
  assign wb_stall_o = 1'b0;
 
endmodule

 
