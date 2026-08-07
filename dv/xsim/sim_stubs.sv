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
