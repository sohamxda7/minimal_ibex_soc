module boot_rom_wrapper (
  input  logic        clk_i,
  input  logic        rst_ni,

  // =========================================================
  // Interconnect Interface
  // =========================================================
  input  logic        req_i,
  input  logic        we_i,
  input  logic [31:0] addr_i,
  input  logic [31:0] wdata_i,   // Ignored (ROM)
  input  logic [3:0]  be_i,      // Ignored (ROM)

  output logic        rvalid_o,
  output logic [31:0] rdata_o
);

  // 1. Address Translation 
  // We extract bits [11:2] from the byte address to get the 10-bit word index.
  logic [9:0] rom_word_addr;
  assign rom_word_addr = addr_i[11:2];

  // 2. Handshake Generation (1-cycle latency)
  // The ROM takes 1 clock cycle to output data. 
  // We delay the read request by 1 cycle to generate rvalid_o.
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      rvalid_o <= 1'b0;
    end else begin
      // Assert rvalid_o only if it's a valid READ request
      rvalid_o <= req_i & ~we_i;
    end
  end

  // 3. Instantiate the raw ROM
  boot_rom #(
    .ADDR_WIDTH(10),
    .INIT_FILE("/rtl/system/boot.mem")
  ) u_boot_rom_macro (
    .clk_i  (clk_i),
    .addr_i (rom_word_addr),
    .data_o (rdata_o)
  );

endmodule
