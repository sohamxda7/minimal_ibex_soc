// SIMULATION-ONLY stubs. Never include this file in a synthesis file list —
// Vivado provides the real Xilinx primitives there.

// BSCANE2: Xilinx JTAG boundary-scan user access. The testbench never uses
// JTAG, so an inert stub is sufficient to elaborate the debug module.
module BSCANE2 #(
  parameter integer JTAG_CHAIN = 1
) (
  output wire CAPTURE,
  output wire DRCK,
  output wire RESET,
  output wire RUNTEST,
  output wire SEL,
  output wire SHIFT,
  output wire TCK,
  output wire TDI,
  output wire TMS,
  output wire UPDATE,
  input  wire TDO
);
  assign CAPTURE = 1'b0;
  assign DRCK    = 1'b0;
  assign RESET   = 1'b1;
  assign RUNTEST = 1'b0;
  assign SEL     = 1'b0;
  assign SHIFT   = 1'b0;
  assign TCK     = 1'b0;
  assign TDI     = 1'b0;
  assign TMS     = 1'b0;
  assign UPDATE  = 1'b0;
endmodule

// STARTUPE2: 7-series configuration-logic access block. Only USRCCLKO is
// meaningful to us (it drives the flash CCLK pin on hardware); in simulation
// the testbench connects the XIP SCK net directly, so the stub is inert.
module STARTUPE2 #(
  parameter PROG_USR      = "FALSE",
  parameter SIM_CCLK_FREQ = 0.0
) (
  output wire CFGCLK,
  output wire CFGMCLK,
  output wire EOS,
  output wire PREQ,
  input  wire CLK,
  input  wire GSR,
  input  wire GTS,
  input  wire KEYCLEARB,
  input  wire PACK,
  input  wire USRCCLKO,
  input  wire USRCCLKTS,
  input  wire USRDONEO,
  input  wire USRDONETS
);
  assign CFGCLK  = 1'b0;
  assign CFGMCLK = 1'b0;
  assign EOS     = 1'b1;
  assign PREQ    = 1'b0;
endmodule
