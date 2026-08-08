#!/usr/bin/env python3
"""
I2C master test program (Tier-2 "toy interfacing", simulation phase).

Drives the OpenCores I2C master @ 0x4000_0400 through the wb wrapper
(register word offsets: PRERlo +0x00, PRERhi +0x04, CTR +0x08,
TXR/RXR +0x0C, CR/SR +0x10) to perform a standard register read from the
slave at 0x50 (the team's i2c_slave_bfm, an EEPROM-style model with
mem[i] = i):

    START, addr 0x50+W, write reg pointer 0x42,
    repeated START, addr 0x50+R, read 1 byte with NACK, STOP.

Expected byte: 0x42. Prints "I2C OK" or "I2C ER" over the UART.
The exact same driver sequence later reads the BME280 chip-ID register
(0xD0 -> 0x60) on real hardware — only the slave address and register
change.

CR bits: STA=0x80 STO=0x40 RD=0x20 WR=0x10 NACK=0x08.
SR bits: RxACK=0x80 Busy=0x40 TIP=0x02.
Prescale for 100 kHz @ 20 MHz: 20e6/(5*100e3) - 1 = 39.

    python i2c_test.py         -> i2c_test.vmem
"""

import os

from assemble import assemble

UART = "s0"
I2C  = "s3"


def wait_tip(tag):
    return [
        f"{tag}:",
        f"lw   t0, 0x10({I2C})",     # SR
        "andi t0, t0, 2",            # TIP
        f"bne  t0, zero, {tag}",
    ]


def program():
    prog = [
        "_start:",
        "lui  s0, 0x40000",          # UART 0x4000_0000
        "lui  s3, 0x40000",
        "addi s3, s3, 0x400",        # I2C  0x4000_0400

        # prescale = 39 (100 kHz @ 20 MHz), enable core
        "addi t0, zero, 39",
        "sw   t0, 0x00(s3)",         # PRERlo
        "sw   zero, 0x04(s3)",       # PRERhi
        "addi t0, zero, 0x80",
        "sw   t0, 0x08(s3)",         # CTR: EN

        # START + slave addr 0x50 write (0xA0)
        "addi t0, zero, 0xA0",
        "sw   t0, 0x0C(s3)",         # TXR
        "addi t0, zero, 0x90",       # STA | WR
        "sw   t0, 0x10(s3)",         # CR
    ] + wait_tip("w_addr") + [
        # register pointer 0x42
        "addi t0, zero, 0x42",
        "sw   t0, 0x0C(s3)",
        "addi t0, zero, 0x10",       # WR
        "sw   t0, 0x10(s3)",
    ] + wait_tip("w_reg") + [
        # repeated START + slave addr 0x50 read (0xA1)
        "addi t0, zero, 0xA1",
        "sw   t0, 0x0C(s3)",
        "addi t0, zero, 0x90",       # STA | WR
        "sw   t0, 0x10(s3)",
    ] + wait_tip("w_addr2") + [
        # read one byte, NACK it
        "addi t0, zero, 0x28",       # RD | NACK
        "sw   t0, 0x10(s3)",
    ] + wait_tip("w_read") + [
        "lw   s4, 0x0C(s3)",         # RXR -> s4
        "andi s4, s4, 0xFF",
        # STOP
        "addi t0, zero, 0x40",
        "sw   t0, 0x10(s3)",

        # verdict
        "addi t1, zero, 0x42",
        "bne  s4, t1, bad",
    ]
    for ch in "I2C OK\r\n":
        prog += [f"addi t0, zero, {ord(ch)}", "sw   t0, 4(s0)"]
    prog += ["jal zero, forever", "bad:"]
    for ch in "I2C ER\r\n":
        prog += [f"addi t0, zero, {ord(ch)}", "sw   t0, 4(s0)"]
    prog += [
        "forever:",
        "jal  zero, forever",
    ]
    return prog


def main():
    words = assemble(program(), base_addr=0x80)
    image = [0] * 32768
    for i, w in enumerate(words):
        image[0x80 // 4 + i] = w
    path = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                        "i2c_test.vmem")
    with open(path, "w") as f:
        for w in image:
            f.write(f"{w:08X}\n")
    print(f"assembled {len(words)} instructions -> {path}")


if __name__ == "__main__":
    main()
