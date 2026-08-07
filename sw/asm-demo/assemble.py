#!/usr/bin/env python3
"""
Self-contained RV32IM mini-assembler + FPGA bring-up demo program.

WHY THIS EXISTS
---------------
The SoC boots from boot ROM (0x0010_0000) and jumps to SRAM (0x0010_2080).
On FPGA the SRAM content must be baked into the bitstream via the
SRAMInitFile parameter. Building the C software requires a riscv32-gcc
toolchain, which is not always available (e.g. on Windows lab PCs).

This script needs ONLY stock Python 3. It assembles a small polled-IO
demo program and writes the .vmem SRAM image that the FPGA build consumes:

    python assemble.py            -> sram_init.vmem      (hardware timing)
    python assemble.py --sim      -> sram_init_sim.vmem  (short delays, for xsim)

DEMO PROGRAM BEHAVIOUR (hardware timing)
----------------------------------------
* UART 115200: prints "IBEX-SOC UP <n>" every ~2 s, echoes every RX byte.
* Green LEDs: walking pattern; while any button is held, LEDs show switches.
* RGB LEDs: all four breathe smoothly, cycling red -> green -> blue.
  (pwm index%3: 0 = blue, 1 = green, 2 = red  -- per pins_artya7.xdc)

Memory map used (must match wb_interconnect.sv):
  UART 0x4000_0000 (+0 RX, +4 TX, +8 status)  GPIO 0x4000_0100 (+0 out, +8 in-debounced)
  PWM  0x4000_0600 (pwm i: +8i pulse width, +8i+4 max counter)
"""

import argparse

# ---------------------------------------------------------------------------
# Tiny RV32IM assembler (only the opcodes the demo needs)
# ---------------------------------------------------------------------------

REGS = {f"x{i}": i for i in range(32)}
REGS.update({
    "zero": 0, "ra": 1, "sp": 2, "gp": 3, "tp": 4,
    "t0": 5, "t1": 6, "t2": 7, "s0": 8, "s1": 9,
    "a0": 10, "a1": 11, "a2": 12, "a3": 13, "a4": 14, "a5": 15,
    "a6": 16, "a7": 17, "s2": 18, "s3": 19, "s4": 20, "s5": 21,
    "s6": 22, "s7": 23, "s8": 24, "s9": 25, "s10": 26, "s11": 27,
    "t3": 28, "t4": 29, "t5": 30, "t6": 31,
})


def enc_r(f7, rs2, rs1, f3, rd, op):
    return (f7 << 25) | (rs2 << 20) | (rs1 << 15) | (f3 << 12) | (rd << 7) | op


def enc_i(imm, rs1, f3, rd, op):
    assert -2048 <= imm <= 2047, f"I-imm out of range: {imm}"
    return ((imm & 0xFFF) << 20) | (rs1 << 15) | (f3 << 12) | (rd << 7) | op


def enc_s(imm, rs2, rs1, f3):
    assert -2048 <= imm <= 2047, f"S-imm out of range: {imm}"
    imm &= 0xFFF
    return ((imm >> 5) << 25) | (rs2 << 20) | (rs1 << 15) | (f3 << 12) | \
           ((imm & 0x1F) << 7) | 0b0100011


def enc_b(imm, rs2, rs1, f3):
    assert -4096 <= imm <= 4094 and imm % 2 == 0, f"B-imm out of range: {imm}"
    imm &= 0x1FFF
    return (((imm >> 12) & 1) << 31) | (((imm >> 5) & 0x3F) << 25) | \
           (rs2 << 20) | (rs1 << 15) | (f3 << 12) | \
           (((imm >> 1) & 0xF) << 8) | (((imm >> 11) & 1) << 7) | 0b1100011


def enc_u(imm20, rd, op):
    return ((imm20 & 0xFFFFF) << 12) | (rd << 7) | op


def enc_j(imm, rd):
    assert -(1 << 20) <= imm <= (1 << 20) - 2 and imm % 2 == 0, \
        f"J-imm out of range: {imm}"
    imm &= 0x1FFFFF
    return (((imm >> 20) & 1) << 31) | (((imm >> 1) & 0x3FF) << 21) | \
           (((imm >> 11) & 1) << 20) | (((imm >> 12) & 0xFF) << 12) | \
           (rd << 7) | 0b1101111


def assemble(program, base_addr):
    """Two-pass assembly. program = list of strings ('label:' or instruction)."""
    # Pass 1: label addresses
    labels, pc = {}, base_addr
    for line in program:
        line = line.split("#")[0].strip()
        if not line:
            continue
        if line.endswith(":"):
            labels[line[:-1]] = pc
        else:
            pc += 4

    # Pass 2: encode
    words, pc = [], base_addr

    def r(name):
        return REGS[name]

    def imm_or_label(tok, rel=False):
        if tok in labels:
            return labels[tok] - pc if rel else labels[tok]
        return int(tok, 0)

    for line in program:
        line = line.split("#")[0].strip()
        if not line or line.endswith(":"):
            continue
        parts = line.replace(",", " ").split()
        op, args = parts[0], parts[1:]

        if op == "lui":
            w = enc_u(int(args[1], 0), r(args[0]), 0b0110111)
        elif op == "addi":
            w = enc_i(imm_or_label(args[2]), r(args[1]), 0b000, r(args[0]), 0b0010011)
        elif op == "andi":
            w = enc_i(imm_or_label(args[2]), r(args[1]), 0b111, r(args[0]), 0b0010011)
        elif op == "slli":
            w = enc_i(int(args[2], 0), r(args[1]), 0b001, r(args[0]), 0b0010011)
        elif op == "add":
            w = enc_r(0, r(args[2]), r(args[1]), 0b000, r(args[0]), 0b0110011)
        elif op == "remu":                                   # RV32M
            w = enc_r(0b0000001, r(args[2]), r(args[1]), 0b111, r(args[0]), 0b0110011)
        elif op == "lw":                                     # lw rd, imm(rs1)
            off, rs1 = args[1].split("(")
            w = enc_i(int(off, 0), r(rs1[:-1]), 0b010, r(args[0]), 0b0000011)
        elif op == "sw":                                     # sw rs2, imm(rs1)
            off, rs1 = args[1].split("(")
            w = enc_s(int(off, 0), r(args[0]), r(rs1[:-1]), 0b010)
        elif op == "beq":
            w = enc_b(imm_or_label(args[2], rel=True), r(args[1]), r(args[0]), 0b000)
        elif op == "bne":
            w = enc_b(imm_or_label(args[2], rel=True), r(args[1]), r(args[0]), 0b001)
        elif op == "blt":
            w = enc_b(imm_or_label(args[2], rel=True), r(args[1]), r(args[0]), 0b100)
        elif op == "jal":                                    # jal rd, label
            w = enc_j(imm_or_label(args[1], rel=True), r(args[0]))
        elif op == "jalr":                                   # jalr rd, rs1, imm
            w = enc_i(int(args[2], 0), r(args[1]), 0b000, r(args[0]), 0b1100111)
        else:
            raise ValueError(f"unknown opcode: {line}")
        words.append(w)
        pc += 4
    return words


# Self-check: the boot ROM's known-good word is 'jal x0, +0x2000' = 0x0000206F.
assert enc_j(0x2000, 0) == 0x0000206F, "assembler self-check failed (jal)"
# nop (addi x0,x0,0) must be 0x00000013.
assert enc_i(0, 0, 0, 0, 0b0010011) == 0x00000013, "assembler self-check failed (nop)"


# ---------------------------------------------------------------------------
# The demo program
# ---------------------------------------------------------------------------

def demo_program(delay_shift):
    """delay_shift: brightness-step busy-wait = 40 << delay_shift iterations."""
    banner = "IBEX-SOC UP "

    prog = [
        "_start:",
        "lui  s0, 0x40000",        # UART base  0x4000_0000
        "lui  s1, 0x40000",
        "addi s1, s1, 0x100",      # GPIO base  0x4000_0100
        "lui  s2, 0x40000",
        "addi s2, s2, 0x600",      # PWM base   0x4000_0600
        "addi s3, zero, 0x10",     # LED walking state (bits 7:4)
        "addi s4, zero, 0",        # RGB brightness
        "addi s5, zero, 2",        # brightness direction (+2 / -2)
        "addi s6, zero, 2",        # active colour channel (2 = red first)
        "addi s7, zero, 48",       # heartbeat digit '0'
        "addi s8, zero, 0",        # main-loop counter
        "addi s9, zero, 255",      # PWM max_counter constant
        "jal  ra, print_banner",

        "main_loop:",
        # ---- UART echo: drain the RX FIFO ----
        "echo:",
        "lw   t0, 8(s0)",          # status: bit0 = rx_empty
        "andi t1, t0, 1",
        "bne  t1, zero, echo_done",
        "lw   t2, 0(s0)",          # read RX byte
        "sw   t2, 4(s0)",          # write TX (echo)
        "jal  zero, echo",
        "echo_done:",

        # ---- every 32nd loop: LED walk / switch display ----
        "andi t0, s8, 31",
        "bne  t0, zero, skip_led",
        "lw   t1, 8(s1)",          # debounced inputs {SW[7:4], BTN[3:0]}
        "andi t2, t1, 15",         # any button held?
        "beq  t2, zero, led_walk",
        "andi t3, t1, 0xF0",       # yes -> LEDs mirror the switches
        "sw   t3, 0(s1)",
        "jal  zero, skip_led",
        "led_walk:",
        "sw   s3, 0(s1)",          # no -> walking LED
        "slli s3, s3, 1",
        "addi t4, zero, 0x100",
        "bne  s3, t4, skip_led",
        "addi s3, zero, 0x10",
        "skip_led:",

        # ---- every 256th loop: heartbeat banner ----
        "andi t0, s8, 255",
        "bne  t0, zero, skip_banner",
        "jal  ra, print_banner",
        "skip_banner:",

        # ---- RGB PWM update: 12 channels, one colour active ----
        "addi t0, zero, 0",        # pwm index
        "addi t5, zero, 3",
        "pwm_loop:",
        "remu t4, t0, t5",         # channel = index % 3 (0=B 1=G 2=R)
        "slli t1, t0, 3",
        "add  t1, t1, s2",
        "sw   s9, 4(t1)",          # max_counter = 255
        "beq  t4, s6, pwm_on",
        "sw   zero, 0(t1)",        # inactive colour -> pulse width 0
        "jal  zero, pwm_next",
        "pwm_on:",
        "sw   s4, 0(t1)",          # active colour -> brightness
        "pwm_next:",
        "addi t0, t0, 1",
        "addi t6, zero, 12",
        "blt  t0, t6, pwm_loop",

        # ---- breathing ramp ----
        "add  s4, s4, s5",
        "addi t0, zero, 250",
        "blt  s4, t0, chk_low",
        "addi s5, zero, -2",       # top reached: dim
        "chk_low:",
        "blt  zero, s4, ramp_done",
        "addi s5, zero, 2",        # bottom reached: brighten, next colour
        "addi s4, zero, 0",
        "addi s6, s6, 1",
        "addi t0, zero, 3",
        "blt  s6, t0, ramp_done",
        "addi s6, zero, 0",
        "ramp_done:",

        # ---- delay: 40 << delay_shift busy-wait iterations ----
        "addi t0, zero, 40",
        f"slli t0, t0, {delay_shift}",
        "delay:",
        "addi t0, t0, -1",
        "bne  t0, zero, delay",

        "addi s8, s8, 1",
        "jal  zero, main_loop",

        # ---- subroutine: print banner + digit + CRLF ----
        "print_banner:",
    ]
    for ch in banner:
        prog += [f"addi t0, zero, {ord(ch)}", "sw   t0, 4(s0)"]
    prog += [
        "sw   s7, 4(s0)",          # the cycling digit
        "addi s7, s7, 1",
        "addi t0, zero, 58",       # past '9'?
        "bne  s7, t0, banner_crlf",
        "addi s7, zero, 48",
        "banner_crlf:",
        "addi t0, zero, 13",
        "sw   t0, 4(s0)",
        "addi t0, zero, 10",
        "sw   t0, 4(s0)",
        "jalr zero, ra, 0",
    ]
    return prog


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--sim", action="store_true",
                    help="short delays + tiny loop periods for simulation")
    args = ap.parse_args()

    # Hardware: 40<<10 = 40960 iterations/step (~8 ms) -> ~2 s per colour ramp.
    # Sim:      40<<0  = 40 iterations/step so xsim reaches everything quickly.
    delay_shift = 0 if args.sim else 10
    out = "sram_init_sim.vmem" if args.sim else "sram_init.vmem"

    words = assemble(demo_program(delay_shift), base_addr=0x80)

    sram_words = 2048                       # 8 KiB
    image = [0] * sram_words
    entry_word = 0x80 // 4                  # program entry at SRAM + 0x80
    for i, w in enumerate(words):
        image[entry_word + i] = w

    import os
    out_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), out)
    with open(out_path, "w") as f:
        for w in image:
            f.write(f"{w:08X}\n")

    print(f"assembled {len(words)} instructions "
          f"({len(words)*4} bytes) -> {out_path}")
    print(f"entry point: SRAM+0x80 (0x00102080), delay = 40<<{delay_shift}")


if __name__ == "__main__":
    main()
