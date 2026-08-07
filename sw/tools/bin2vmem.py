#!/usr/bin/env python3
"""
Convert a raw binary (e.g. objcopy -O binary output of a Zephyr/C ELF) into
the .vmem format consumed by the SoC's SRAMInitFile parameter.

Usage:
    python bin2vmem.py input.bin output.vmem [--offset BYTES]

The SRAM is 128 KiB (32768 x 32-bit words) based at 0x0010_2000. The output
always contains exactly 32768 lines (missing tail zero-filled) so simulation
never reads X.

--offset places the image at a byte offset inside the SRAM (default 0x80,
matching the boot ROM's jump target 0x0010_2080; use 0 for images linked
directly at the SRAM base).

Words are emitted little-endian-as-stored: the first 4 bytes of the .bin
become word 0's value b3b2b1b0 -> "B3B2B1B0" hex — i.e. standard RISC-V
little-endian memory layout, matching $readmemh into a 32-bit array.
"""

import argparse
import sys

SRAM_WORDS = 32768          # 128 KiB / 4
SRAM_BYTES = SRAM_WORDS * 4


def bin2vmem(data: bytes, offset: int) -> list:
    if offset % 4:
        sys.exit(f"error: offset {offset:#x} is not word-aligned")
    if offset + len(data) > SRAM_BYTES:
        sys.exit(f"error: image ({len(data)} B at {offset:#x}) exceeds "
                 f"{SRAM_BYTES} B SRAM")

    image = bytearray(SRAM_BYTES)
    image[offset:offset + len(data)] = data

    words = []
    for w in range(SRAM_WORDS):
        b = image[w * 4:w * 4 + 4]
        words.append(f"{int.from_bytes(b, 'little'):08X}")
    return words


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("input")
    ap.add_argument("output")
    ap.add_argument("--offset", type=lambda x: int(x, 0), default=0x80,
                    help="byte offset inside SRAM (default 0x80 = boot entry)")
    args = ap.parse_args()

    with open(args.input, "rb") as f:
        data = f.read()
    words = bin2vmem(data, args.offset)
    with open(args.output, "w") as f:
        f.write("\n".join(words) + "\n")
    print(f"{args.input}: {len(data)} bytes -> {args.output} "
          f"({SRAM_WORDS} words, image at SRAM+{args.offset:#x})")


# self-test: python bin2vmem.py --selftest
if __name__ == "__main__":
    if "--selftest" in sys.argv:
        w = bin2vmem(bytes([0x93, 0x00, 0x00, 0x00, 0xEF, 0xBE, 0xAD, 0xDE]), 0x80)
        assert w[0x80 // 4] == "00000093", w[0x80 // 4]      # addi x1,x0,0
        assert w[0x80 // 4 + 1] == "DEADBEEF", w[0x80 // 4 + 1]
        assert w[0] == "00000000" and len(w) == SRAM_WORDS
        print("selftest PASS")
        sys.exit(0)
    main()
