#!/usr/bin/env python3
"""
ST7735 LCD SPI test program (Tier-1 "toy interfacing" final test).

Reuses the RV32IM mini-assembler from assemble.py. The program drives the
LCD exactly like the upstream C demo does at the pin level:

  GPIO_OUT bits (= DISP_CTRL[3:0] on the ChipKit header, per lcd_st7735):
    bit0 = CS (kept low = selected)   bit1 = RST (reset pulse at start)
    bit2 = DC (0 = command, 1 = data) bit3 = Backlight (on)
  SPI host @ 0x4000_0500: TX byte at +0, STATUS at +4 (bit1 = FIFO empty),
    mode 0, MSB first, SCK = 5 MHz.

Sequence sent (subset of the ST7735 datasheet init + a pixel burst):
  HW reset pulse -> SWRESET(01) -> SLPOUT(11) -> COLMOD(3A)+05(=RGB565)
  -> DISPON(29) -> CASET(2A)+00,00,00,04 -> RASET(2B)+00,00,00,04
  -> RAMWR(2C)+5 red pixels (F8 00 x5)  -> "LCD OK" on the UART.

    python lcd_spi_test.py         -> lcd_spi_test.vmem      (real delays)
    python lcd_spi_test.py --sim   -> lcd_spi_test_sim.vmem  (short delays)

The same image drives the behavioural LCD model in dv/xsim/tb_lcd.sv and,
later, the real panel.
"""

import argparse
import os

from assemble import assemble


def program(short_delay, long_delay):
    """short/long_delay = (imm, shift): iterations = imm << shift."""

    def load_delay(reg, pair):
        imm, sh = pair
        out = [f"addi {reg}, zero, {imm}"]
        if sh:
            out.append(f"slli {reg}, {reg}, {sh}")
        return out

    prog = [
        "_start:",
        "lui  s0, 0x40000",            # UART  0x4000_0000
        "lui  s1, 0x40000",
        "addi s1, s1, 0x100",          # GPIO  0x4000_0100
        "lui  s2, 0x40000",
        "addi s2, s2, 0x500",          # SPI   0x4000_0500

        # Initial pins: BL=1 DC=0 RST=1 CS=0  -> 0b1010
        "addi t1, zero, 0x0A",
        "sw   t1, 0(s1)",
        "jal  ra, delay_short",
        # Hardware reset pulse: RST low, wait, high, wait
        "addi t1, zero, 0x08",
        "sw   t1, 0(s1)",
        "jal  ra, delay_long",
        "addi t1, zero, 0x0A",
        "sw   t1, 0(s1)",
        "jal  ra, delay_long",

        # SWRESET + 120 ms
        "addi a0, zero, 0x01",
        "jal  ra, send_cmd",
        "jal  ra, delay_long",
        # SLPOUT + 120 ms
        "addi a0, zero, 0x11",
        "jal  ra, send_cmd",
        "jal  ra, delay_long",
        # COLMOD = 0x05 (16-bit RGB565)
        "addi a0, zero, 0x3A",
        "jal  ra, send_cmd",
        "addi a0, zero, 0x05",
        "jal  ra, send_dat",
        # DISPON
        "addi a0, zero, 0x29",
        "jal  ra, send_cmd",
        "jal  ra, delay_short",

        # CASET: columns 0..4
        "addi a0, zero, 0x2A",
        "jal  ra, send_cmd",
        "addi a0, zero, 0x00",
        "jal  ra, send_dat",
        "addi a0, zero, 0x00",
        "jal  ra, send_dat",
        "addi a0, zero, 0x00",
        "jal  ra, send_dat",
        "addi a0, zero, 0x04",
        "jal  ra, send_dat",
        # RASET: rows 0..4
        "addi a0, zero, 0x2B",
        "jal  ra, send_cmd",
        "addi a0, zero, 0x00",
        "jal  ra, send_dat",
        "addi a0, zero, 0x00",
        "jal  ra, send_dat",
        "addi a0, zero, 0x00",
        "jal  ra, send_dat",
        "addi a0, zero, 0x04",
        "jal  ra, send_dat",

        # RAMWR + 5 red RGB565 pixels (0xF800)
        "addi a0, zero, 0x2C",
        "jal  ra, send_cmd",
    ]
    for _ in range(5):
        prog += [
            "addi a0, zero, 0xF8",
            "jal  ra, send_dat",
            "addi a0, zero, 0x00",
            "jal  ra, send_dat",
        ]

    # "LCD OK\r\n" over the UART, then idle
    for ch in "LCD OK\r\n":
        prog += [f"addi t0, zero, {ord(ch)}", "sw   t0, 4(s0)"]
    prog += [
        "forever:",
        "jal  zero, forever",

        # ---- send_cmd: DC=0 then transmit a0 ----
        "send_cmd:",
        "addi t1, zero, 0x0A",         # BL=1 DC=0 RST=1 CS=0
        "sw   t1, 0(s1)",
        "jal  zero, spi_send",
        # ---- send_dat: DC=1 then transmit a0 ----
        "send_dat:",
        "addi t1, zero, 0x0E",         # BL=1 DC=1 RST=1 CS=0
        "sw   t1, 0(s1)",
        # ---- spi_send: push byte, wait FIFO empty + shifter drain ----
        "spi_send:",
        "sw   a0, 0(s2)",
        "spi_wait:",
        "lw   t0, 4(s2)",
        "andi t0, t0, 2",              # bit1 = FIFO empty
        "beq  t0, zero, spi_wait",
        "addi t0, zero, 24",           # drain the shift register (~32 clks)
        "spi_drain:",
        "addi t0, t0, -1",
        "bne  t0, zero, spi_drain",
        "jalr zero, ra, 0",

        # ---- delays (t2 counter; no nesting with send_*) ----
        "delay_short:",
    ] + load_delay("t2", short_delay) + [
        "ds_loop:",
        "addi t2, t2, -1",
        "bne  t2, zero, ds_loop",
        "jalr zero, ra, 0",
        "delay_long:",
    ] + load_delay("t2", long_delay) + [
        "dl_loop:",
        "addi t2, t2, -1",
        "bne  t2, zero, dl_loop",
        "jalr zero, ra, 0",
    ]
    return prog


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--sim", action="store_true")
    args = ap.parse_args()

    if args.sim:
        short, long_ = (8, 0), (16, 0)
        out = "lcd_spi_test_sim.vmem"
    else:
        # ~10 cycles per iteration at 20 MHz:
        # short = 4000 it ~ 2 ms; long = 260096 it ~ 130 ms (datasheet: >=120)
        short, long_ = (125, 5), (254, 10)
        out = "lcd_spi_test.vmem"

    words = assemble(program(short, long_), base_addr=0x80)
    image = [0] * 2048   # 8 KiB SRAM (ASIC spec)
    for i, w in enumerate(words):
        image[0x80 // 4 + i] = w
    path = os.path.join(os.path.dirname(os.path.abspath(__file__)), out)
    with open(path, "w") as f:
        for w in image:
            f.write(f"{w:08X}\n")
    print(f"assembled {len(words)} instructions -> {path}")


if __name__ == "__main__":
    main()
