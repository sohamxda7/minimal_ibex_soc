# UART Command Interface — LED Patterns & RGB Control

*Added 2026-08-07 on branch `fix/fpga-bringup`, from a draft `main.c` supplied
by the DV team lead. This documents the command set, the code review of the
draft (5 bugs), every decision, and the verification evidence.*

## Command reference (serial console, 115200 8N1, single characters)

| Key | Action |
|---|---|
| `1` | Green-LED pattern 1 — **walking single bit** (LD4→LD5→LD6→LD7) |
| `2` | Pattern 2 — **nibble flip** (all 4 LEDs on ↔ off) |
| `3` | Pattern 3 — **alternating pairs** (LD4/LD6 ↔ LD5/LD7) |
| `4` | Pattern 4 — **binary count** on the 4 LEDs |
| `f` / `m` / `s` | Pattern speed: **fast** ~50 ms, **medium** ~150 ms (default), **slow** ~400 ms per step |
| `r` / `g` / `b` / `w` | Force the RGB LEDs to red / green / blue / white (breathing continues) |
| `a` | RGB back to **automatic** colour cycling red→green→blue (default) |
| anything else | echoed back |

Every recognised command is **echoed back as its acknowledgement** (the C
version additionally prints a text confirmation like `-> Speed: FAST`).
Holding any board button still makes the LEDs mirror the switches, and the
`IBEX-SOC UP <n>` heartbeat continues every few seconds.

## Two implementations, one behaviour

| | File | Runs where | Why it exists |
|---|---|---|---|
| **Assembly demo** | `sw/asm-demo/assemble.py` (program + assembler in one) | **On the board today** — baked into the bitstream by `build_fpga.bat` | No RISC-V GCC toolchain exists on the lab PCs; the Python assembler needs nothing but Python |
| **C reference** | `sw/c/demo/hello_world/main.c` | When a `riscv32-unknown-elf-gcc` toolchain is available (see FPGA_BRINGUP.md for the swap-in procedure) | The maintainable long-term version, fixed and extended from the DV lead's draft |

Both implement the same command set. The assembly version acks by echoing the
command character; the C version also prints descriptive text.

## Code review of the DV lead's draft (what was fixed and why)

1. **Fatal: `timer_enable(g_speed_delay)` inside the `while(1)` loop.**
   `timer_enable()` (see `sw/c/common/timer.c`) zeroes `time_elapsed` and
   re-arms `mtimecmp = mtime + delay` on every call. Called every loop pass,
   the compare value runs away ahead of `mtime` and the timer interrupt
   (almost) never fires → `get_elapsed_time()` stays 0 → **no pattern would
   ever advance**. Fix: arm once at startup; the ISR sets a
   `g_speed_changed` flag and the main loop re-arms only then (keeps the ISR
   short and the elapsed-counter reset deliberate).
2. **Speed table inverted and ~500× too fast.** Draft: FAST=50000,
   MEDIUM=15000, SLOW=30000 cycles — so "FAST" was the *slowest* of the
   three, and at 20 MHz all of them mean 0.75–2.5 ms per step: patterns blur
   into a shimmer and the per-tick status line (~30 chars ≈ 2.6 ms at
   115200) floods the UART TX FIFO. Fix: FAST/MED/SLOW = 1 M / 3 M / 8 M
   cycles = 50/150/400 ms.
3. **Startup `g_speed_delay = 100`** (5 µs tick — the comment even said
   "change before FPGA implementation"). Dangerous default; now defaults to
   MEDIUM.
4. **Patterns wrote the wrong nibble.** `gp_o[3:0]` are the DISP_CTRL/LCD
   lines on Arty — only `gp_o[7:4]` drive LEDs. Draft patterns 2 (0x0F) and
   4 (`led_pattern++`) mostly toggled invisible pins. All patterns now
   operate on the LED nibble (flip = `^0xF0`, count = `+0x10`).
5. **RGB control was missing** although "control the RGB via UART" was the
   goal. Added `r/g/b/w/a`: a forced colour holds while the brightness
   breathing continues; `a` resumes cycling. (Auto-advance of the colour is
   suppressed while forced — otherwise the cycle would fight the override.)
6. Minor: `puthex(115200)` printed `1C200` labelled "Baudrate" (now a text
   literal); status line rate-limited to every 16th tick; `wfi` sleep
   restored in the idle loop.

## Design decisions

- **Commands handled in the UART RX interrupt (C) / RX-drain loop (asm)** —
  identical observable behaviour; the asm demo polls because it has no
  interrupt plumbing, and its main loop spins fast enough (<20 ms) that
  commands feel instant either way.
- **Forced-colour keeps breathing** rather than pinning full brightness:
  proves PWM keeps being updated live while forced, and avoids a blinding
  constant LED.
- **Echo-as-ack for every byte** keeps the interface scriptable (a test can
  assert on the echo) without parsing text banners.
- **Speed change = timer re-arm** resets the tick counter; the C code
  resynchronises `last_elapsed_time` to avoid a phantom extra step.

## Verification

**Simulation** (`dv/xsim/tb_soc.sv`, sped-up image `sram_init_sim.vmem`):

```
=== RESULTS: 9 PASS, 0 FAIL ===
  UART TX banner present            default walking pattern runs
  '3' command acked (echoed)        pattern 3 active (LEDs alternate A/5)
  'b' command acked (echoed)        blue PWM active after 'b'
  red PWM silent after 'b'          non-command byte 'K' echoed
  LEDs mirror switches while button held
```

**On board**: see the "UART command interface" section appended to
[BRINGUP_TEST_REPORT.md](BRINGUP_TEST_REPORT.md) after the hardware run.
