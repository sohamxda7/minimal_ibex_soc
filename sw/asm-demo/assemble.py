#!/usr/bin/env python3
"""
Self-contained RV32IM mini-assembler + UART-interactive FPGA demo program.

WHY THIS EXISTS
---------------
The SoC boots from boot ROM (0x0010_0000) and jumps to SRAM (0x0010_2080).
On FPGA the SRAM content must be baked into the bitstream via the
SRAMInitFile parameter. Building the C software requires a riscv32-gcc
toolchain, which is not always available (e.g. on Windows lab PCs).

This script needs ONLY stock Python 3. It assembles the demo program and
writes the .vmem SRAM image that the FPGA build consumes:

    python assemble.py            -> sram_init.vmem      (hardware timing)
    python assemble.py --sim      -> sram_init_sim.vmem  (short delays, for xsim)

DEMO PROGRAM (mirrors sw/c/demo/hello_world/main.c)
---------------------------------------------------
UART 115200 8N1, single-character commands:
    1..4  green-LED pattern: walking / nibble flip / alternating / count
    f m s pattern speed: fast (~50 ms) / medium (~150 ms) / slow (~400 ms)
    r g b force RGB colour (breathing continues)   w white   a auto-cycle
Every received command (and any other byte) is echoed back as the ack.
"IBEX-SOC UP <n>" heartbeat every few seconds. While a button is held the
LEDs show the switch positions instead of the pattern.

Memory map used (must match wb_interconnect.sv):
  UART 0x4000_0000 (+0 RX, +4 TX, +8 status)  GPIO 0x4000_0100 (+0 out, +8 in-dbnc)
  PWM  0x4000_0600 (pwm i: +8i pulse width, +8i+4 max counter)
  RGB channel = pwm index % 3: 0=Blue, 1=Green, 2=Red (per pins_artya7.xdc)
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
    labels, pc = {}, base_addr
    for line in program:
        line = line.split("#")[0].strip()
        if not line:
            continue
        if line.endswith(":"):
            labels[line[:-1]] = pc
        else:
            pc += 4

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
        elif op == "xori":
            w = enc_i(imm_or_label(args[2]), r(args[1]), 0b100, r(args[0]), 0b0010011)
        elif op == "slli":
            w = enc_i(int(args[2], 0), r(args[1]), 0b001, r(args[0]), 0b0010011)
        elif op == "srli":
            w = enc_i(int(args[2], 0), r(args[1]), 0b101, r(args[0]), 0b0010011)
        elif op == "add":
            w = enc_r(0, r(args[2]), r(args[1]), 0b000, r(args[0]), 0b0110011)
        elif op == "and":
            w = enc_r(0, r(args[2]), r(args[1]), 0b111, r(args[0]), 0b0110011)
        elif op == "sll":
            w = enc_r(0, r(args[2]), r(args[1]), 0b001, r(args[0]), 0b0110011)
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
        # CSR ops (Zicsr), used by the uart2_irq test: csr number as an
        # immediate (mtvec=0x305, mie=0x304, mstatus=0x300, mcause=0x342).
        # enc_i asserts imm<=2047 so pack the csr number into bits 31:20 by hand.
        elif op in ("csrw", "csrs", "csrc"):                 # csrw csr, rs
            f3 = {"csrw": 0b001, "csrs": 0b010, "csrc": 0b011}[op]
            w = ((int(args[0], 0) & 0xFFF) << 20) | (r(args[1]) << 15) | \
                (f3 << 12) | (0 << 7) | 0b1110011
        elif op == "csrr":                                   # csrr rd, csr
            w = ((int(args[1], 0) & 0xFFF) << 20) | (0 << 15) | \
                (0b010 << 12) | (r(args[0]) << 7) | 0b1110011
        elif op == "mret":
            w = 0x30200073
        else:
            raise ValueError(f"unknown opcode: {line}")
        words.append(w)
        pc += 4
    return words


# Self-checks against known-good encodings
assert enc_j(0x2000, 0) == 0x0000206F, "assembler self-check failed (jal)"
assert enc_i(0, 0, 0, 0, 0b0010011) == 0x00000013, "assembler self-check failed (nop)"
# xori x1,x1,0xF0 = imm 0x0F0 rs1=1 f3=100 rd=1 op 0010011 -> 0x0F00C093
assert enc_i(0xF0, 1, 0b100, 1, 0b0010011) == 0x0F00C093, "assembler self-check (xori)"


# ---------------------------------------------------------------------------
# The demo program
# ---------------------------------------------------------------------------
# Register allocation:
#   s0  UART base          s6  RGB colour mask (bit0=B,1=G,2=R)
#   s1  GPIO base          s7  heartbeat digit
#   s2  PWM base           s8  main-loop counter
#   s3  LED pattern value  s9  255 (PWM max_counter)
#   s4  RGB brightness     s10 pattern mode 0..3
#   s5  brightness dir     s11 speed (delay iterations)
#   a2  RGB mode: 0 = auto-cycle, 1 = forced by command

def demo_program(speeds):
    """speeds = dict fast/med/slow -> (imm, shift): delay = imm << shift."""
    banner = "IBEX-SOC UP "

    def li_speed(which):
        imm, sh = speeds[which]
        out = [f"addi s11, zero, {imm}"]
        if sh:
            out.append(f"slli s11, s11, {sh}")
        return out

    prog = [
        "_start:",
        "lui  s0, 0x40000",        # UART base  0x4000_0000
        "lui  s1, 0x40000",
        "addi s1, s1, 0x100",      # GPIO base  0x4000_0100
        "lui  s2, 0x40000",
        "addi s2, s2, 0x600",      # PWM base   0x4000_0600
        "addi s3, zero, 0x10",     # LED pattern value
        "addi s4, zero, 0",        # RGB brightness
        "addi s5, zero, 2",        # brightness direction (+2 / -2)
        "addi s6, zero, 4",        # colour mask: start red (bit2)
        "addi s7, zero, 48",       # heartbeat digit '0'
        "addi s8, zero, 0",        # main-loop counter
        "addi s9, zero, 255",      # PWM max_counter constant
        "addi s10, zero, 0",       # pattern mode 0 (walking)
        "addi a2, zero, 0",        # RGB auto-cycle
    ] + li_speed("med") + [
        "jal  ra, print_banner",

        "main_loop:",
        # ---- UART RX: drain FIFO, dispatch commands ----
        "echo:",
        "lw   t0, 8(s0)",          # status: bit0 = rx_empty
        "andi t1, t0, 1",
        "bne  t1, zero, echo_done",
        "lw   t2, 0(s0)",          # received byte

        # pattern commands '1'..'4' (0x31..0x34)
        "addi t3, zero, 0x31",
        "bne  t2, t3, c_not1",
        "addi s10, zero, 0",
        "addi s3, zero, 0x10",
        "jal  zero, cmd_ack",
        "c_not1:",
        "addi t3, zero, 0x32",
        "bne  t2, t3, c_not2",
        "addi s10, zero, 1",
        "addi s3, zero, 0xF0",
        "jal  zero, cmd_ack",
        "c_not2:",
        "addi t3, zero, 0x33",
        "bne  t2, t3, c_not3",
        "addi s10, zero, 2",
        "addi s3, zero, 0xA0",
        "jal  zero, cmd_ack",
        "c_not3:",
        "addi t3, zero, 0x34",
        "bne  t2, t3, c_not4",
        "addi s10, zero, 3",
        "addi s3, zero, 0x00",
        "jal  zero, cmd_ack",
        "c_not4:",

        # speed commands 'f'(0x66) 'm'(0x6D) 's'(0x73)
        "addi t3, zero, 0x66",
        "bne  t2, t3, c_notf",
    ] + [f"    {ins}" for ins in li_speed("fast")] + [
        "jal  zero, cmd_ack",
        "c_notf:",
        "addi t3, zero, 0x6D",
        "bne  t2, t3, c_notm",
    ] + [f"    {ins}" for ins in li_speed("med")] + [
        "jal  zero, cmd_ack",
        "c_notm:",
        "addi t3, zero, 0x73",
        "bne  t2, t3, c_nots",
    ] + [f"    {ins}" for ins in li_speed("slow")] + [
        "jal  zero, cmd_ack",
        "c_nots:",

        # RGB commands 'r'(0x72) 'g'(0x67) 'b'(0x62) 'w'(0x77) 'a'(0x61)
        "addi t3, zero, 0x72",
        "bne  t2, t3, c_notr",
        "addi a2, zero, 1",
        "addi s6, zero, 4",
        "jal  zero, cmd_ack",
        "c_notr:",
        "addi t3, zero, 0x67",
        "bne  t2, t3, c_notg",
        "addi a2, zero, 1",
        "addi s6, zero, 2",
        "jal  zero, cmd_ack",
        "c_notg:",
        "addi t3, zero, 0x62",
        "bne  t2, t3, c_notb",
        "addi a2, zero, 1",
        "addi s6, zero, 1",
        "jal  zero, cmd_ack",
        "c_notb:",
        "addi t3, zero, 0x77",
        "bne  t2, t3, c_notw",
        "addi a2, zero, 1",
        "addi s6, zero, 7",
        "jal  zero, cmd_ack",
        "c_notw:",
        "addi t3, zero, 0x61",
        "bne  t2, t3, cmd_ack",    # unknown bytes fall through to plain echo
        "addi a2, zero, 0",        # 'a' -> auto colour cycling

        "cmd_ack:",
        "sw   t2, 4(s0)",          # echo the byte back (= command ack)
        "jal  zero, echo",
        "echo_done:",

        # ---- every 8th loop: LED pattern step / switch display ----
        "andi t0, s8, 7",
        "bne  t0, zero, skip_led",
        "lw   t1, 8(s1)",          # debounced {SW[7:4], BTN[3:0]}
        "andi t2, t1, 15",
        "beq  t2, zero, led_step",
        "andi t3, t1, 0xF0",       # button held -> LEDs mirror switches
        "sw   t3, 0(s1)",
        "jal  zero, skip_led",

        "led_step:",
        "addi t0, zero, 0",
        "beq  s10, t0, led_walk",
        "addi t0, zero, 3",
        "beq  s10, t0, led_count",
        "xori s3, s3, 0xF0",       # modes 1 & 2: flip (F0<->00 / A0<->50)
        "jal  zero, led_write",
        "led_walk:",
        "slli s3, s3, 1",
        "andi s3, s3, 0xF0",
        "bne  s3, zero, led_write",
        "addi s3, zero, 0x10",
        "jal  zero, led_write",
        "led_count:",
        "addi s3, s3, 0x10",
        "andi s3, s3, 0xF0",
        "led_write:",
        "sw   s3, 0(s1)",
        "skip_led:",

        # ---- every 256th loop: heartbeat banner ----
        "andi t0, s8, 255",
        "bne  t0, zero, skip_banner",
        "jal  ra, print_banner",
        "skip_banner:",

        # ---- RGB PWM: 12 channels, colour selected by mask s6 ----
        "addi t0, zero, 0",        # pwm index
        "addi t5, zero, 3",
        "pwm_loop:",
        "remu t4, t0, t5",         # channel = index % 3
        "addi t3, zero, 1",
        "sll  t3, t3, t4",         # 1 << channel
        "and  t3, t3, s6",         # active in current colour mask?
        "slli t1, t0, 3",
        "add  t1, t1, s2",
        "sw   s9, 4(t1)",          # max_counter = 255
        "beq  t3, zero, pwm_off",
        "sw   s4, 0(t1)",          # active -> brightness
        "jal  zero, pwm_next",
        "pwm_off:",
        "sw   zero, 0(t1)",
        "pwm_next:",
        "addi t0, t0, 1",
        "addi t6, zero, 12",
        "blt  t0, t6, pwm_loop",

        # ---- breathing ramp ----
        "add  s4, s4, s5",
        "addi t0, zero, 250",
        "blt  s4, t0, chk_low",
        "addi s5, zero, -2",       # top: dim
        "chk_low:",
        "blt  zero, s4, ramp_done",
        "addi s5, zero, 2",        # bottom: brighten
        "addi s4, zero, 0",
        "bne  a2, zero, ramp_done",  # forced colour: no auto-advance
        "srli s6, s6, 1",          # auto: red -> green -> blue -> red
        "bne  s6, zero, ramp_done",
        "addi s6, zero, 4",
        "ramp_done:",

        # ---- speed-controlled delay ----
        "add  t0, s11, zero",
        "delay:",
        "addi t0, t0, -1",
        "bne  t0, zero, delay",

        "addi s8, s8, 1",
        "jal  zero, main_loop",

        # ---- subroutine: banner + digit + CRLF ----
        "print_banner:",
    ]
    for ch in banner:
        prog += [f"addi t0, zero, {ord(ch)}", "sw   t0, 4(s0)"]
    prog += [
        "sw   s7, 4(s0)",
        "addi s7, s7, 1",
        "addi t0, zero, 58",
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
                    help="short delays for xsim simulation")
    args = ap.parse_args()

    if args.sim:
        # tiny delays so xsim reaches everything in a few ms of sim time
        speeds = {"fast": (2, 0), "med": (8, 0), "slow": (32, 0)}
        out = "sram_init_sim.vmem"
    else:
        # Hardware @20 MHz, LED step every 8 loops, ~10 cycles per delay iter:
        #   fast ~50 ms/step, med ~150 ms/step, slow ~400 ms/step
        speeds = {"fast": (781, 4), "med": (1172, 5), "slow": (781, 7)}
        out = "sram_init.vmem"

    words = assemble(demo_program(speeds), base_addr=0x80)

    sram_words = 2048                       # 8 KiB (ASIC spec)
    image = [0] * sram_words
    entry_word = 0x80 // 4                  # program entry at SRAM + 0x80
    assert len(words) < sram_words - entry_word, "program too large for SRAM"
    for i, w in enumerate(words):
        image[entry_word + i] = w

    import os
    out_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), out)
    with open(out_path, "w") as f:
        for w in image:
            f.write(f"{w:08X}\n")

    print(f"assembled {len(words)} instructions "
          f"({len(words)*4} bytes) -> {out_path}")
    print("speeds (delay iterations):",
          {k: v[0] << v[1] for k, v in speeds.items()})


if __name__ == "__main__":
    main()
