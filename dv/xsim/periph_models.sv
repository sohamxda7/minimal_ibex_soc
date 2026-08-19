// ============================================================================
// Behavioral models of the v1.1 external production peripherals
// (docs/PRODUCTION_PERIPHERALS.md). One file, four models:
//
//   spi_psram_model   APS6404-class SPI PSRAM: cmd 0x02 write / 0x03 read,
//                     24-bit address, auto-increment. Mode 0.
//   mcp3202_model     SPI mic ADC: streams {8'h00, 4'h0, sample[11:0]} per
//                     CS session; sample starts at 0x801 and increments per
//                     conversion (deterministic ramp for the checker).
//   esp32_at_model    UART AT-command responder: any received line starting
//                     with "AT" gets "\r\nOK\r\n" back after a short delay.
//   ov7670_fifo_model AL422-style camera FIFO: RRST (active low) resets the
//                     read pointer, each RCLK rising edge advances it, data
//                     bus presents frame[ptr]. Frame = (i*7+3)&0xFF, matching
//                     sw/asm-demo/periph_tests.py's expected checksum.
//
// All SPI models are STRICT mode-0 datasheet slaves (CLAUDE.md Rule 1b):
// sample the RAW MOSI wire on rising SCK, change outputs on falling SCK
// only. Never sample a delayed copy of MOSI - that workaround (removed
// 2026-08-19) forgave zero hold time and MASKED the real spi_host.sv
// mode-0 bug that a physical ST7735 exposed on 2026-08-18. With the fixed
// RTL, MOSI is stable half an SCK period before the sampling edge; if a
// hold-time regression ever returns, these models must fail loudly.
// ============================================================================

`timescale 1ns / 1ps

// ---------------------------------------------------------------------------
module spi_psram_model #(
  parameter int MEM_BYTES = 65536
)(
  input  logic sck,
  input  logic csn,
  input  logic mosi,
  output logic so
);
  logic [7:0]  mem [0:MEM_BYTES-1];
  logic [7:0]  cmd_q, dout_q, shin_q;
  logic [23:0] addr_q;
  int          bit_cnt;
  typedef enum int { P_CMD, P_ADDR, P_WR, P_RD, P_DEAD } pstate_e;
  pstate_e st;

  initial for (int i = 0; i < MEM_BYTES; i++) mem[i] = 8'h00;

  always @(negedge csn) begin
    st = P_CMD; bit_cnt = 0; cmd_q = '0; addr_q = '0; shin_q = '0;
  end

  // sample MOSI on rising SCK
  always @(posedge sck) begin
    if (!csn) begin
      case (st)
        P_CMD: begin
          cmd_q = {cmd_q[6:0], mosi}; bit_cnt++;
          if (bit_cnt == 8) begin
            bit_cnt = 0;
            if (cmd_q == 8'h02)      st = P_ADDR;
            else if (cmd_q == 8'h03) st = P_ADDR;
            else begin
              $display("[%0t] spi_psram_model: unsupported cmd %02h", $time, cmd_q);
              st = P_DEAD;
            end
          end
        end
        P_ADDR: begin
          addr_q = {addr_q[22:0], mosi}; bit_cnt++;
          if (bit_cnt == 24) begin
            bit_cnt = 0;
            st = (cmd_q == 8'h02) ? P_WR : P_RD;
          end
        end
        P_WR: begin
          shin_q = {shin_q[6:0], mosi}; bit_cnt++;
          if (bit_cnt == 8) begin
            mem[addr_q % MEM_BYTES] = shin_q;
            $display("[%0t] psram WR [%06h] = %02h", $time, addr_q, shin_q);
            addr_q++; bit_cnt = 0;
          end
        end
        default: ;
      endcase
    end
  end

  // drive SO on falling SCK (byte boundary: load fresh byte, else shift)
  always @(negedge sck) begin
    if (!csn && st == P_RD) begin
      if (bit_cnt % 8 == 0) begin
        dout_q = mem[addr_q % MEM_BYTES];
        addr_q++;
      end else begin
        dout_q = {dout_q[6:0], 1'b0};
      end
      bit_cnt++;
    end
  end

  assign so = (!csn && st == P_RD) ? dout_q[7] : 1'bz;
endmodule

// ---------------------------------------------------------------------------
module mcp3202_model (
  input  logic sck,
  input  logic csn,
  input  logic mosi,
  output logic dout
);
  logic [11:0] sample_q = 12'h800;
  logic [23:0] stream_q;
  int          idx;

  always @(negedge csn) begin
    sample_q = sample_q + 12'd1;                // new conversion per session
    stream_q = {8'h00, 4'h0, sample_q};
    idx      = 0;
    $display("[%0t] mcp3202: conversion -> %03h", $time, sample_q);
  end

  always @(negedge sck) if (!csn && idx < 23) idx++;

  assign dout = (!csn) ? stream_q[23 - idx] : 1'bz;

  // MOSI content (start/config bits) is accepted but not decoded
  logic unused_mosi;
  assign unused_mosi = mosi;
endmodule

// ---------------------------------------------------------------------------
module esp32_at_model #(
  parameter int BAUD = 2_000_000
)(
  input  logic rx,     // from SoC UART2 TX
  output logic tx      // to SoC UART2 RX
);
  localparam int BitNs = 1_000_000_000 / BAUD;
  byte line [0:63];
  int  len = 0;

  initial tx = 1'b1;

  task automatic send_char(byte b);
    tx = 1'b0; #(BitNs);
    for (int i = 0; i < 8; i++) begin tx = b[i]; #(BitNs); end
    tx = 1'b1; #(BitNs);
  endtask

  initial begin
    forever begin
      byte b;
      @(negedge rx);
      #(BitNs + BitNs/2);
      for (int i = 0; i < 8; i++) begin b[i] = rx; #(BitNs); end
      $display("[%0t] esp32_at_model rx byte %02h len=%0d", $time, b, len);
      if (b == "\n") begin
        if (len >= 2 && line[0] == "A" && line[1] == "T") begin
          $display("[%0t] esp32_at_model: AT command received, replying OK", $time);
          #2000;
          send_char("\r"); send_char("\n");
          send_char("O");  send_char("K");
          send_char("\r"); send_char("\n");
        end
        len = 0;
      end else if (b >= " " && b <= "~" && len < 64) begin
        // printable ASCII only: line noise (e.g. the reset-glitch 0xFF
        // frame) must not poison the command buffer - real ESP-AT
        // firmware tolerates the same
        line[len] = b; len++;
      end
    end
  end
endmodule

// ---------------------------------------------------------------------------
module ov7670_fifo_model (
  input  logic       wen,     // capture enable (accepted, frame is static)
  input  logic       rrst_n,  // read-pointer reset, active low
  input  logic       rclk,    // read clock: posedge advances pointer
  output logic [7:0] d
);
  localparam int FRAME_BYTES = 4096;
  logic [7:0] frame [0:FRAME_BYTES-1];
  int rptr = 0;

  initial for (int i = 0; i < FRAME_BYTES; i++) frame[i] = 8'((i * 7 + 3) & 255);

  always @(negedge rrst_n) begin
    rptr = 0;
    $display("[%0t] ov7670_fifo: read pointer reset", $time);
  end

  always @(posedge rclk) begin
    $display("[%0t] ov7670 rclk edge rrst_n=%b rptr=%0d d=%02h",
             $time, rrst_n, rptr, frame[rptr]);
    if (rrst_n) rptr = (rptr + 1) % FRAME_BYTES;
  end

  assign d = frame[rptr];

  logic unused_wen;
  assign unused_wen = wen;
endmodule
