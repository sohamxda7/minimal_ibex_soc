// Behavioral model of the GF180 DFFRAM macro (the ASIC SRAM). Selected in
// wrapper_top.sv by the UseDffram PARAMETER, not by a simulator ifdef
// (Ravi, 2026-08-19: synthesis must not depend on a simulator define), so
// every engine (xsim, Vivado, and Verilator) can elaborate either SRAM.
// (NB: a comment must never START with the word "verilator" - it parses
// as a metacomment/pragma and errors out as BADVLTPRAGMA.)
// WE is PER-BYTE [3:0] - Ibex issues sb/sh to SRAM, a single-bit WE
// breaks byte stores (review flag (b) on team commit 740d59c9; regressed
// by tb_soc-dffram).
module dffram #(

    parameter string MemInitFile = ""

)(

    input  logic         CLK,

    input  logic [3:0]   WE,

    input  logic         EN,

    input  logic [31:0]  Di,

    output logic [31:0]  Do,

    input  logic [10:0]  A

);
 
    localparam int DEPTH = 2048;

    localparam int WIDTH = 32;
 
   

    logic [WIDTH-1:0] mem [0:DEPTH-1];
 
    // -----------------------------------------------------------------

    // Synchronous read-before-write

    // -----------------------------------------------------------------

    always_ff @(posedge CLK) begin

        if (EN) begin

            Do <= mem[A];
 
            if (WE[0]) mem[A][7:0]   <= Di[7:0];

            if (WE[1]) mem[A][15:8]  <= Di[15:8];

            if (WE[2]) mem[A][23:16] <= Di[23:16];

            if (WE[3]) mem[A][31:24] <= Di[31:24];

        end

        else begin

            Do <= '0;

        end

    end
 
    //------------------------------------------------------------------

    // Optional initialization (no-op with MemInitFile="" - silicon and,
    // since the 2026-08-19 direct-XIP boot, the FPGA both power up with
    // uninitialised SRAM)

    //------------------------------------------------------------------

    initial begin

        if (MemInitFile != "") begin

            $display("dffram %m: loading %s", MemInitFile);

            $readmemh(MemInitFile, mem);

        end

    end

`ifdef VERILATOR
    // DPI exports for the Verilator --meminit harness ONLY. Guarded with
    // VERILATOR, not SYNTHESIS: xsim compiles `ifndef SYNTHESIS` code and
    // its C codegen fails on DPI exports (same fix as sram_model.sv).

    export "DPI-C" task simutil_memload;

    task simutil_memload(input string file);

        begin

            $display("dffram %m: loading %s", file);

            $readmemh(file, mem);

        end

    endtask
 
    export "DPI-C" function simutil_set_mem;

    function int simutil_set_mem(

        input int index,

        input bit [311:0] val

    );

        if (WIDTH > 312 || index < 0 || index >= DEPTH)

            return 0;
 
        mem[index] = val[WIDTH-1:0];

        return 1;

    endfunction
 
    export "DPI-C" function simutil_get_mem;

    function int simutil_get_mem(

        input int index,

        output bit [311:0] val

    );

        if (WIDTH > 312 || index < 0 || index >= DEPTH)

            return 0;
 
        val = '0;

        val[WIDTH-1:0] = mem[index];

        return 1;

    endfunction
 
`endif
 
endmodule
 
