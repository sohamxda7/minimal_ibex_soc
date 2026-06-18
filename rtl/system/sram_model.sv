// Synchronous single-port SRAM model for simulation and FPGA synthesis.
//
// Provides Verilator DPI-C exports (simutil_memload / simutil_set_mem /
// simutil_get_mem) that match the interface expected by the lowRISC
// the MemUtil / MemArea framework, allowing the simulation
// harness to pre-load ELF binaries directly into this memory before the
// simulation clock starts.
//
// Interface:
//   - req_i  : enable (read or write)
//   - addr_i : word address (Depth words addressable)
//   - we_i   : byte-write enable (DW/8 bits); all-zero means read
//   - wdata_i: write data
//   - rdata_o: registered read data (available one cycle after req_i)
//
// The array is named `mem` to match the convention expected by the DPI
// exports (and by prim_util_memload.svh if ever used as an alternative).

module sram_model #(
  parameter int unsigned Width       = 32,    // word width in bits (must be ≤ 312)
  parameter int unsigned Depth       = 2048,  // number of words
  parameter              MemInitFile = ""     // optional $readmemh init file
) (
  input  logic                          clk_i,
  input  logic                          req_i,
  input  logic [$clog2(Depth)-1:0]      addr_i,
  input  logic [Width/8-1:0]            we_i,
  input  logic [Width-1:0]              wdata_i,
  output logic [Width-1:0]              rdata_o
);

  logic [Width-1:0] mem [0:Depth-1];

  // Synchronous read-before-write SRAM
  always_ff @(posedge clk_i) begin
    if (req_i) begin
      for (int b = 0; b < Width / 8; b++) begin
        if (we_i[b]) begin
          mem[addr_i][(b*8)+:8] <= wdata_i[(b*8)+:8];
        end
      end
      rdata_o <= mem[addr_i];
    end
  end

  // =========================================================
  // DPI simulation support (Verilator)
  // Exports exactly the same DPI-C interface as prim_util_memload.svh
  // so VerilatorMemUtil can load ELF images into this SRAM.
  // =========================================================
`ifndef SYNTHESIS
  // Load the entire memory from a hex file (used by the sim harness
  // via --meminit=<name>,<file>).
  export "DPI-C" task simutil_memload;
  task simutil_memload;
    input string file;
    $readmemh(file, mem);
  endtask

  // Write a single word at `index` (word-addressed).
  // Returns 1 on success, 0 if index is out of range.
  export "DPI-C" function simutil_set_mem;
  function int simutil_set_mem(input int index, input bit [311:0] val);
    if (Width > 312 || index < 0 || index >= int'(Depth)) return 0;
    mem[index] = val[Width-1:0];
    return 1;
  endfunction

  // Read a single word at `index` (word-addressed).
  // Returns 1 on success, 0 if index is out of range.
  export "DPI-C" function simutil_get_mem;
  function int simutil_get_mem(input int index, output bit [311:0] val);
    if (Width > 312 || index < 0 || index >= int'(Depth)) return 0;
    val = '0;
    val[Width-1:0] = mem[index];
    return 1;
  endfunction
`endif

  // Optional static initialisation from a hex file at elaboration time.
  initial begin
    if (MemInitFile != "") begin
      $display("sram_model %m: initialising from '%s'", MemInitFile);
      $readmemh(MemInitFile, mem);
    end
  end

endmodule
