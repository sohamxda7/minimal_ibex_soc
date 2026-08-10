#!/usr/bin/env python3
"""XIP proof-of-life test: the CPU executes code fetched over SPI from flash.

Generates two images (see docs/ASIC_SPEC.md section 4 for the XIP contract):

  xip_stub.vmem       2048-word SRAM image. A two-instruction trampoline at
                      the boot entry point (SRAM+0x80) that jumps into the
                      XIP window at 0x2040_0000. This mirrors the hardware
                      boot flow where firmware sits at flash offset
                      0x0040_0000, behind the A7-100T bitstream.

  xip_test_flash.vmem Flash window image (word-vmem consumed by
                      dv/xsim/spi_nor_flash_model.sv). The program runs
                      ENTIRELY from flash: prints "XIP " over the UART, then
                      reads back its own first instruction word via a data
                      load from the XIP window and prints "OK" if it matches
                      the expected encoding (0x40000537 = lui a0,0x40000),
                      "ER" otherwise. Both instruction fetch and data load
                      paths through spi_flash_xip.sv are therefore covered,
                      including byte order.

Run:  python sw/asm-demo/xip_test.py
"""

import os
from assemble import assemble

XIP_ENTRY = 0x20400000   # XIP window + 0x400000 flash offset

# putc: wait until UART TX not full, then write the char in a1.
# UART base in a0: RX+0 TX+4 STATUS+8 (bit1 = tx_full).
PROGRAM = [
    "start:",
    "  lui a0, 0x40000",        # first word = 0x40000537, read back below
    "  addi a1, zero, 88",      # 'X'
    "  jal ra, putc",
    "  addi a1, zero, 73",      # 'I'
    "  jal ra, putc",
    "  addi a1, zero, 80",      # 'P'
    "  jal ra, putc",
    "  addi a1, zero, 32",      # ' '
    "  jal ra, putc",
    # Data-load check: word at XIP_ENTRY must be the lui encoding above
    "  lui t2, 0x20400",
    "  lw a2, 0(t2)",
    "  lui t3, 0x40000",
    "  addi t3, t3, 0x537",
    "  addi a1, zero, 79",      # 'O'
    "  beq a2, t3, first_ok",
    "  addi a1, zero, 69",      # 'E'
    "first_ok:",
    "  jal ra, putc",
    "  addi a1, zero, 75",      # 'K'
    "  beq a2, t3, second_ok",
    "  addi a1, zero, 82",      # 'R'
    "second_ok:",
    "  jal ra, putc",
    "  addi a1, zero, 13",      # CR
    "  jal ra, putc",
    "  addi a1, zero, 10",      # LF
    "  jal ra, putc",
    "done:",
    "  jal zero, done",
    "putc:",
    "  lw t1, 8(a0)",
    "  andi t1, t1, 2",
    "  bne t1, zero, putc",
    "  sw a1, 4(a0)",
    "  jalr zero, ra, 0",
]

STUB = [
    "  lui t0, 0x20400",        # jump to XIP entry 0x2040_0000
    "  jalr zero, t0, 0",
]


def main():
    here = os.path.dirname(os.path.abspath(__file__))

    flash_words = assemble(PROGRAM, base_addr=XIP_ENTRY)
    with open(os.path.join(here, "xip_test_flash.vmem"), "w") as f:
        for w in flash_words:
            f.write(f"{w:08X}\n")

    stub_words = assemble(STUB, base_addr=0x80)
    image = [0] * 2048   # 8 KiB SRAM (ASIC spec)
    for i, w in enumerate(stub_words):
        image[0x80 // 4 + i] = w
    with open(os.path.join(here, "xip_stub.vmem"), "w") as f:
        for w in image:
            f.write(f"{w:08X}\n")

    print(f"assembled {len(flash_words)} flash instructions -> xip_test_flash.vmem")
    print(f"assembled {len(stub_words)}-instruction SRAM trampoline -> xip_stub.vmem")


if __name__ == "__main__":
    main()
