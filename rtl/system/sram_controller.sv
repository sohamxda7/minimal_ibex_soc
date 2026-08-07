// NOTE: SRAM_BASE and SRAM_SIZE here MUST stay consistent with the decode
// parameters in wb_interconnect.sv (SRAM_BASE / SRAM_MASK).  If the
// interconnect routes a different address range to this controller the
// internal addr_valid check will suppress all responses, hanging the bus.
module sram_controller #(
  parameter int AW = 32,
  parameter int DW = 32,
  // Number of word-address bits: 2^WORD_ADDR_WIDTH words × (DW/8) bytes = SRAM bytes.
  // Default 15 → 32768 words × 4 B = 128 KiB (grown from 8 KiB for the
  // Zephyr RTOS port — see docs/RTOS_RESEARCH.md Phase A).
  parameter int WORD_ADDR_WIDTH = 15,
  parameter ECC_ENABLE = 0,           // Set to 1 for SECDED ECC
  parameter logic [31:0] SRAM_BASE = 32'h0010_2000,
  parameter int          SRAM_SIZE = 32'd131072      // bytes (must equal 2^WORD_ADDR_WIDTH * DW/8)
)(
  input  logic              clk_i,
  input  logic              rst_ni,

  // Wishbone slave interface
  input  logic              sram_req_i,
  input  logic              sram_we_i,
  input  logic [AW-1:0]     sram_addr_i,
  input  logic [DW-1:0]     sram_wdata_i,
  input  logic [DW/8-1:0]   sram_be_i,
  output logic [DW-1:0]     sram_rdata_o,
  output logic              sram_rvalid_o,

  // DFFRAM interface
  output logic                  mem_en_o,
  output logic [DW/8-1:0]       mem_we_o,
  output logic [WORD_ADDR_WIDTH-1:0] mem_addr_o,
  output logic [DW-1:0]         mem_wdata_o,
  input  logic [DW-1:0]         mem_rdata_i
);

  logic            addr_valid;
  logic [AW-1:0]   local_addr;

  // Secondary address range check (wb_interconnect is the primary decoder).
  // This guards against mis-routed transactions if decoder parameters drift.
  assign addr_valid = (sram_addr_i >= SRAM_BASE) &&
                      (sram_addr_i <  (SRAM_BASE + SRAM_SIZE[AW-1:0]));

  assign local_addr = sram_addr_i - SRAM_BASE;


  // One-cycle Wishbone response
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
     sram_rvalid_o <= 1'b0;
    end else begin
      sram_rvalid_o <= sram_req_i && addr_valid;
    end
  end
  /*
This assumes:

Cycle N   : req_i asserted
Cycle N+1 : mem_rdata_i valid
Cycle N+1 : rvalid_o asserted

If your DFFRAM behaves like a synchronous SRAM (1-cycle read latency), this is correct.
  */

  // DFFRAM connections
  assign mem_en_o    = sram_req_i && addr_valid;
  assign mem_we_o    = (sram_req_i && addr_valid && sram_we_i) ? sram_be_i : '0;
  assign mem_addr_o  = local_addr[WORD_ADDR_WIDTH+1:2]; // Word-aligned
  assign mem_wdata_o = sram_wdata_i;
  assign sram_rdata_o = mem_rdata_i;

endmodule
