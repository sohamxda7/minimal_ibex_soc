#!/usr/bin/env python3
"""Convert a raw firmware .bin into a flash-window vmem for XIP.

Unlike bin2vmem.py (which produces the fixed-size 8 KiB SRAM image with the
boot offset), this produces a plain little-endian word list, one word per
line, starting at the beginning of the XIP firmware region. Consumers:

  * dv/xsim/spi_nor_flash_model.sv ($readmemh into its flash window, which
    starts at flash byte offset 0x40_0000 by default)
  * scripts that build the hardware flash image (write_cfgmem data file)

Usage:  python sw/tools/bin2flashvmem.py firmware.bin firmware_flash.vmem
"""

import argparse


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("bin_in")
    ap.add_argument("vmem_out")
    args = ap.parse_args()

    with open(args.bin_in, "rb") as f:
        data = f.read()

    if len(data) % 4:
        data += b"\xff" * (4 - len(data) % 4)

    with open(args.vmem_out, "w") as f:
        for i in range(0, len(data), 4):
            f.write(f"{int.from_bytes(data[i:i+4], 'little'):08X}\n")

    print(f"{args.bin_in}: {len(data)} bytes -> {args.vmem_out} ({len(data)//4} words)")


if __name__ == "__main__":
    main()
