// ============================================================================
// Hand-written replacements for the FuseSoC-generated "abstract primitives".
//
// In the stock lowRISC flow, dispatcher modules like prim_clock_gating are
// GENERATED at build time by fusesoc+primgen and select a generic or Xilinx
// implementation. These small behavioural equivalents let the design build
// in plain Vivado / xsim with no FuseSoC or Python environment at all.
//
//   * `define FPGA_XILINX  -> clock gate uses a real BUFGCE (synthesis)
//   * otherwise            -> latch-based behavioural gate (simulation)
//
// The other leaf cells (buf/flop/and2/...) are technology-neutral: writing
// them behaviourally is exactly what prim_generic_* does anyway, and Vivado
// synthesises them to the same LUTs/FFs.
// ============================================================================

module prim_clock_gating #(
  parameter bit NoFpgaGate    = 1'b0,
  parameter bit FpgaBufGlobal = 1'b1
) (
  input  logic clk_i,
  input  logic en_i,
  input  logic test_en_i,
  output logic clk_o
);
`ifdef FPGA_XILINX
  BUFGCE u_bufgce (
    .I  (clk_i),
    .CE (en_i | test_en_i),
    .O  (clk_o)
  );
`else
  logic en_latch /* verilator lint_off LATCH */;
  always_latch begin
    if (!clk_i) en_latch = en_i | test_en_i;
  end
  assign clk_o = clk_i & en_latch;
`endif
endmodule

module prim_clock_inv #(
  parameter bit HasScanMode = 1'b1,
  parameter bit NoFpgaBufG  = 1'b0
) (
  input  logic clk_i,
  input  logic scanmode_i,
  output logic clk_no
);
  assign clk_no = ~clk_i;
  logic unused_scan;
  assign unused_scan = scanmode_i;
endmodule

module prim_buf #(
  parameter int Width = 1
) (
  input  logic [Width-1:0] in_i,
  output logic [Width-1:0] out_o
);
  assign out_o = in_i;
endmodule

module prim_clock_buf #(
  parameter bit NoFpgaBuf = 1'b0,
  parameter bit RegionSel = 1'b0
) (
  input  logic clk_i,
  output logic clk_o
);
  assign clk_o = clk_i;
endmodule

module prim_clock_mux2 #(
  parameter bit NoFpgaBufG = 1'b0
) (
  input  logic clk0_i,
  input  logic clk1_i,
  input  logic sel_i,
  output logic clk_o
);
  assign clk_o = sel_i ? clk1_i : clk0_i;
endmodule

module prim_flop #(
  parameter int               Width      = 1,
  parameter logic [Width-1:0] ResetValue = '0
) (
  input  logic             clk_i,
  input  logic             rst_ni,
  input  logic [Width-1:0] d_i,
  output logic [Width-1:0] q_o
);
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) q_o <= ResetValue;
    else         q_o <= d_i;
  end
endmodule

module prim_flop_en #(
  parameter int               Width      = 1,
  parameter bit               EnSecBuf   = 1'b0,
  parameter logic [Width-1:0] ResetValue = '0
) (
  input  logic             clk_i,
  input  logic             rst_ni,
  input  logic             en_i,
  input  logic [Width-1:0] d_i,
  output logic [Width-1:0] q_o
);
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni)    q_o <= ResetValue;
    else if (en_i)  q_o <= d_i;
  end
endmodule

module prim_and2 #(
  parameter int Width = 1
) (
  input  logic [Width-1:0] in0_i,
  input  logic [Width-1:0] in1_i,
  output logic [Width-1:0] out_o
);
  assign out_o = in0_i & in1_i;
endmodule

module prim_xor2 #(
  parameter int Width = 1
) (
  input  logic [Width-1:0] in0_i,
  input  logic [Width-1:0] in1_i,
  output logic [Width-1:0] out_o
);
  assign out_o = in0_i ^ in1_i;
endmodule
