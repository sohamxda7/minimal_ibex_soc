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
 
`ifndef SYNTHESIS
 
    //------------------------------------------------------------------

    // Optional initialization

    //------------------------------------------------------------------

    initial begin

        if (MemInitFile != "") begin

            $display("dffram %m: loading %s", MemInitFile);

            $readmemh(MemInitFile, mem);

        end

    end
 
    
 
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
 
