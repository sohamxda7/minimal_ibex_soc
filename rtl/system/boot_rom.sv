module boot_rom #(
  parameter int ADDR_WIDTH = 10,  // 1024 words = 4 KB
  parameter     INIT_FILE  = "boot.mem"
)(
  input  logic              clk_i,
  input  logic [ADDR_WIDTH-1:0] addr_i,
  output logic [31:0]       data_o
);

  logic [31:0] mem [0:2**ADDR_WIDTH-1];

  initial begin
    $readmemh(INIT_FILE, mem);
  end

  always_ff @(posedge clk_i) begin
    data_o <= mem[addr_i];
  end

endmodule
