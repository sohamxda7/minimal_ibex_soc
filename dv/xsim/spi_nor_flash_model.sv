// ============================================================================
// Behavioral SPI NOR flash model (read-only, command 0x03) for XIP simulation.
//
// Models the subset of a standard SPI NOR flash (e.g. the Arty A7's onboard
// 16 MB S25FL128) that the SoC's spi_flash_xip controller uses:
//   * SPI Mode 0 (CPOL=0, CPHA=0): samples MOSI on rising SCK, drives MISO
//     on falling SCK (and immediately after CS falls, for the first bit)
//   * Command 0x03 (READ) + 24-bit address, then streams data bytes MSB-first
//     with auto-incrementing address until CS rises
//   * Any other command: drives 1'bx and complains (catches controller bugs)
//
// Backing store: a WINDOW_BYTES window starting at flash byte offset
// BASE_OFFSET, initialised from a word-vmem file (little-endian: word[i]
// bits [7:0] = flash byte BASE_OFFSET + 4*i). Reads outside the window
// return 8'hFF like blank flash, with a warning.
//
// BASE_OFFSET defaults to 0x0040_0000 — mirroring the hardware layout where
// firmware lives behind the ~3.7 MB A7-100T bitstream in the config flash.
// ============================================================================

`timescale 1ns / 1ps

module spi_nor_flash_model #(
  parameter int          WINDOW_BYTES = 65536,
  parameter logic [23:0] BASE_OFFSET  = 24'h40_0000,
  parameter              INIT_FILE    = ""
)(
  input  logic sck,
  input  logic csn,
  input  logic mosi,
  output logic miso
);

  logic [7:0] mem [0:WINDOW_BYTES-1];

  initial begin
    logic [31:0] words [0:WINDOW_BYTES/4-1];
    for (int i = 0; i < WINDOW_BYTES; i++) mem[i] = 8'hFF;
    if (INIT_FILE != "") begin
      for (int i = 0; i < WINDOW_BYTES/4; i++) words[i] = 32'hFFFF_FFFF;
      $readmemh(INIT_FILE, words);
      for (int i = 0; i < WINDOW_BYTES/4; i++) begin
        mem[4*i + 0] = words[i][7:0];
        mem[4*i + 1] = words[i][15:8];
        mem[4*i + 2] = words[i][23:16];
        mem[4*i + 3] = words[i][31:24];
      end
      $display("spi_nor_flash_model: loaded '%s' at flash offset 0x%06h",
               INIT_FILE, BASE_OFFSET);
    end
  end

  // ---- bit-level protocol engine -------------------------------------------
  logic [7:0]  cmd_q;
  logic [23:0] addr_q;
  logic [7:0]  dout_q;
  int          bit_cnt;

  typedef enum int { F_CMD, F_ADDR, F_DATA, F_DEAD } fstate_e;
  fstate_e fstate;

  function automatic logic [7:0] flash_byte(logic [23:0] a);
    if (a >= BASE_OFFSET && a < BASE_OFFSET + WINDOW_BYTES)
      return mem[a - BASE_OFFSET];
    $display("[%0t] spi_nor_flash_model: WARNING read outside window (0x%06h)",
             $time, a);
    return 8'hFF;
  endfunction

  always @(negedge csn) begin
    fstate  = F_CMD;
    bit_cnt = 0;
    cmd_q   = '0;
    addr_q  = '0;
  end

  // Sample MOSI on rising SCK
  always @(posedge sck) begin
    if (!csn) begin
      case (fstate)
        F_CMD: begin
          cmd_q = {cmd_q[6:0], mosi};
          bit_cnt++;
          if (bit_cnt == 8) begin
            if (cmd_q == 8'h03) begin
              fstate  = F_ADDR;
              bit_cnt = 0;
            end else begin
              $display("[%0t] spi_nor_flash_model: unsupported cmd 0x%02h",
                       $time, cmd_q);
              fstate = F_DEAD;
            end
          end
        end
        F_ADDR: begin
          addr_q = {addr_q[22:0], mosi};
          bit_cnt++;
          if (bit_cnt == 24) begin
            fstate  = F_DATA;
            bit_cnt = 0;
          end
        end
        default: ;
      endcase
    end
  end

  // Drive MISO on falling SCK (shift out MSB-first). Mode 0: data changes on
  // the falling edge and is stable across the next rising (sampling) edge.
  // bit_cnt%8 == 0 marks a byte boundary: load a fresh byte and present its
  // MSB; otherwise shift. The address increments as each byte is consumed.
  always @(negedge sck) begin
    if (!csn && fstate == F_DATA) begin
      if (bit_cnt % 8 == 0) begin
        dout_q = flash_byte(addr_q);
        addr_q = addr_q + 24'd1;
      end else begin
        dout_q = {dout_q[6:0], 1'b0};
      end
      bit_cnt++;
    end
  end

  assign miso = (!csn && fstate == F_DATA) ? dout_q[7] :
                (!csn && fstate == F_DEAD) ? 1'bx     : 1'bz;

endmodule
