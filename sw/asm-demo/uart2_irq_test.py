#!/usr/bin/env python3
"""UART2 RX interrupt proof program (lead-requested regression, 2026-08-17).

Proves, at RTL level, the exact contract the FreeRTOS driver relies on:

  1. UART2 RX-not-empty is a LEVEL interrupt on Ibex fast IRQ 1
     (mcause 17, vector entry 17) - bytes arrive with NO polling.
  2. The 128-byte RX FIFO absorbs a burst while the IRQ is masked;
     bytes beyond 128 are dropped (overflow is bounded, not corrupting).
  3. After overflow the link keeps working (error/recovery).
  4. UART1 console RX+TX stays fully usable while UART2 traffic flows.

Protocol with dv/xsim/tb_uart2_irq.sv (console UART1 at 2 Mbaud):

  program: "IRQ2"            ready, IRQ enabled
  tb:      17 bytes on UART2 ("WIFI DISCONNECT\\r\\n" - unsolicited event)
  program: "EVT OK"          ISR counted 17 bytes (no polling anywhere)
  program: "MASK"            UART2 IRQ now masked (mie.fast1 cleared)
  tb:      160-byte burst on UART2; 'X' on UART1 MID-burst; 'G' after
  program: echoes 'X','G'    UART1 alive during UART2 burst
  program: unmask -> pending level IRQ fires -> ISR drains the FIFO
  program: "OVF OK"          count == 17+128 exactly (32 of 160 dropped)
  tb:      "+IPD,4:ping\\r\\n" on UART2 (13 bytes)
  program: "RCV OK"          count == 158: link recovered after overflow

Register discipline: the ISR may fire anywhere in the main flow, so it
touches ONLY s5-s9 (s5 UART2 base, s6 count, s7 checksum, s8/s9 scratch);
the main flow never uses those five.

Image layout: words 0..31 are the 32-entry vector table (mtvec = SRAM base
0x0010_2000, 256-byte aligned); entry 17 -> isr, all others -> bad (prints
"TRP"). Code starts at +0x80 where the boot ROM jumps.

Run:  python sw/asm-demo/uart2_irq_test.py   -> uart2_irq_test.vmem
"""

import os
from assemble import assemble, enc_j

SRAM_BASE = 0x0010_2000   # mtvec target; team-confirmed base (CLAUDE.md)

PUTC = [
    "putc:",                      # char in a1, clobbers t1 (never s5-s9)
    "  lw t1, 8(s0)",
    "  andi t1, t1, 2",
    "  bne t1, zero, putc",
    "  sw a1, 4(s0)",
    "  jalr zero, ra, 0",
]


def puts(text):
    out = []
    for ch in text:
        out += [f"  addi a1, zero, {ord(ch)}", "  jal ra, putc"]
    return out


def program():
    p = [
        "start:",
        "  lui s0, 0x40000",          # UART1 (console)
        "  lui s5, 0x40000",
        "  addi s5, s5, 0x700",       # UART2 (ESP32 side)
        "  add s6, zero, zero",       # ISR byte count
        "  add s7, zero, zero",       # ISR checksum (not checked yet)
        # vectored trap base = SRAM base (vector table = image words 0..31)
        "  lui t0, 0x102",
        "  csrw 0x305, t0",           # mtvec
        "  lui t0, 0x20",             # 1<<17 = fast IRQ 1 (UART2 RX)
        "  csrs 0x304, t0",           # mie
        "  addi t0, zero, 8",
        "  csrs 0x300, t0",           # mstatus.MIE
    ]
    p += puts("IRQ2\r\n")

    # phase 1: unsolicited event line lands via ISR only (17 bytes)
    p += [
        "w_evt:",
        "  addi t0, zero, 17",
        "  bne s6, t0, w_evt",
    ]
    p += puts("EVT OK\r\n")

    # mask the UART2 IRQ so the burst must ride on the hardware FIFO
    p += [
        "  lui t0, 0x20",
        "  csrc 0x304, t0",
    ]
    p += puts("MASK\r\n")

    # phase 2: console stays alive during the burst - echo until 'G'
    p += [
        "w_go:",
        "  lw t0, 8(s0)",
        "  andi t1, t0, 1",
        "  bne t1, zero, w_go",
        "  lw t2, 0(s0)",
        "  andi t2, t2, 0xFF",
        "  add a1, t2, zero",
        "  jal ra, putc",             # echo
        "  addi t3, zero, 0x47",      # 'G'
        "  bne t2, t3, w_go",
        # unmask: the pending LEVEL irq fires at once, ISR drains the FIFO
        "  lui t0, 0x20",
        "  csrs 0x304, t0",
        "  addi t0, zero, 2000",      # ~settle: drain is ~2k cycles
        "d1:",
        "  addi t0, t0, -1",
        "  bne t0, zero, d1",
        "  addi t0, zero, 145",       # 17 + 128 (FIFO depth; 32 dropped)
        "  bne s6, t0, er_ovf",
    ]
    p += puts("OVF OK\r\n")

    # phase 3: recovery - a fresh line must arrive intact after overflow
    p += [
        "w_rcv:",
        "  addi t0, zero, 158",       # 145 + 13 ("+IPD,4:ping\r\n")
        "  bne s6, t0, w_rcv",
    ]
    p += puts("RCV OK\r\n")
    p += ["hang:", "  jal zero, hang"]

    p += ["er_ovf:"] + puts("OVF ER\r\n") + ["  jal zero, hang"]
    p += ["bad:"] + puts("TRP\r\n") + ["  jal zero, hang"]

    # the ISR: drain the whole FIFO (level IRQ - must leave it empty)
    p += [
        "isr:",
        "isr_loop:",
        "  lw s8, 8(s5)",
        "  andi s8, s8, 1",           # rx_empty
        "  bne s8, zero, isr_done",
        "  lw s9, 0(s5)",
        "  andi s9, s9, 0xFF",
        "  addi s6, s6, 1",
        "  add s7, s7, s9",
        "  jal zero, isr_loop",
        "isr_done:",
        "  mret",
    ]
    p += PUTC
    return p


def get_labels(prog, base):
    """Replicates assemble()'s pass 1 - label -> byte offset from SRAM base."""
    labels, pc = {}, base
    for line in prog:
        line = line.split("#")[0].strip()
        if not line:
            continue
        if line.endswith(":"):
            labels[line[:-1]] = pc
        else:
            pc += 4
    return labels


def main():
    prog = program()
    words = assemble(prog, base_addr=0x80)
    labels = get_labels(prog, 0x80)

    image = [0] * 2048
    # 32-entry vector table at the image base (= mtvec): entry i is a
    # 'jal x0' at byte 4*i; entry 17 = UART2 fast IRQ, the rest trap to bad.
    for i in range(32):
        target = labels["isr"] if i == 17 else labels["bad"]
        image[i] = enc_j(target - 4 * i, 0)
    for i, w in enumerate(words):
        image[0x80 // 4 + i] = w

    here = os.path.dirname(os.path.abspath(__file__))
    with open(os.path.join(here, "uart2_irq_test.vmem"), "w") as f:
        for w in image:
            f.write(f"{w:08X}\n")
    print(f"assembled {len(words)} instructions -> uart2_irq_test.vmem "
          f"(isr @ +0x{labels['isr']:X})")


if __name__ == "__main__":
    main()
