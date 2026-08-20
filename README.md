# minimal-ibex-soc — ARF Design

A minimal RISC-V SoC around the [lowRISC Ibex](https://github.com/lowRISC/ibex)
RV32IMC core on a custom **OBI → Wishbone fabric**, validated on the
**Digilent Arty A7-100T** and headed for **GF180MCU silicon** via the
Efabless Caravel shuttle. The original lowRISC README is preserved at
[docs/UPSTREAM_README.md](docs/UPSTREAM_README.md).

```
Ibex (RV32IMC) ──┬─ instr OBI ─┐
                 └─ data  OBI ─┤ 2:1 arbiter ─→ obi2wb ─→ wb_interconnect
                                                              │
   Boot ROM 4 KiB · SRAM 8 KiB · UART ×2 · GPIO 16/16 ────────┤
   Timer · PWM · I2C · SPI host · SPI-flash XIP · debug module┘
```

20 MHz system clock (the ASIC target). RTOS: **FreeRTOS**, executing in
place (XIP) from the onboard 16 MB QSPI flash.

> **Doctrine — the ASIC is the product.** The FPGA board is strictly the
> pre-silicon validation vehicle. Nothing is built here unless it runs on
> the fabricated chip: 8 KiB SRAM, 38 Caravel pads, 20 MHz, no BRAM/DDR3.
> Details: [docs/ASIC_SPEC.md](docs/ASIC_SPEC.md).

## Quick start — one script

Everything runs from **`ibex_soc.bat`** (double-click): a Windows GUI with
one button per flow — environment check + tool setup, bitstream build,
Vivado `.xpr` generation, firmware build, board flashing, the full
regression, docs and live logs.

```
git clone git@github.com:sohamxda7/minimal_ibex_soc.git C:\FPGA\minimal_ibex_soc
cd C:\FPGA\minimal_ibex_soc
ibex_soc.bat
```

1. **Environment Check** — verifies Vivado/Python/GCC/git, asks for and
   remembers missing tool paths (`.toolpaths`, per-PC).
2. **Install Missing Tools** — auto-installs whatever the check flagged:
   Python (winget) and a native Windows RISC-V GCC (official xPack build,
   downloaded to `C:\FPGA\`, no WSL, no admin). Only Vivado stays a manual
   install. (Flash to Board is build-first: it offers this same install
   if GCC is missing; the committed prebuilt flashes only on request.)
3. **Flash to Board (QSPI)** — firmware → XIP bitstream → QSPI flash.
   Press PROG on the board; survives power-cycle.
4. Open PuTTY at **115200 8N1** (COM port from Device Manager).

Every button is also a command: `powershell -File scripts\flows.ps1 <flow>`
with `setup | deps | xpr | build | program | firmware [sim] |
flashfw | flashonly [bin] | regression`. (Requires Windows; clone
outside OneDrive, path without spaces — Vivado breaks on both.)

### Linux / open-source flow

**`./ibex_soc.sh`** is the Linux twin — run with no arguments for a menu,
or name a flow: `setup | deps | images | firmware [sim] | lint |
sim <tb> | regression | build | flashfw | flashonly [bin]`.

- **`deps` installs everything**, and never dead-ends: apt (Ubuntu/Debian),
  dnf (RHEL/Fedora) or pacman (MSYS2) for make/g++/python3; the **xPack
  RISC-V GCC on every Linux distro** (the apt `gcc-riscv64-unknown-elf`
  ships without a libc and cannot build the firmware — the toolchain check
  is a real compile probe for this); and where the packaged **Verilator is
  older than 5** (Ubuntu 22.04 ships 4.210 and no apt package fixes it) it
  **builds Verilator from source** into `~/ibex-tools/verilator`, ~5-10 min.
  A toolchain already sitting in `~/ibex-tools` is picked up automatically
  even by a brand-new clone that has no `.toolpaths.sh` yet, so nothing is
  re-downloaded. Anything it cannot resolve it *asks* for and remembers in `.toolpaths.sh`,
  exactly like the Windows GUI. Tools are found by **version across every
  PATH entry**, so a stale 4.x first on PATH cannot mask a good build.
  Proven end-to-end on a fresh Ubuntu 24.04, and again **from a pristine
  clone of the pushed branch** with no saved tool paths — and with the
  scripts' executable bits deliberately stripped, since a tree can arrive
  by zip or by copy: regression 13/13 either way. Missing program images
  are built or reported by name, never left to fail as a fetch loop.
- **`setup` checks the checkout before the tools** (both OSes): one
  `git ls-files --deleted` line, because a half-copied or partly-deleted
  tree otherwise surfaces much later as a wall of twelve `No such file or
  directory` errors from gcc that look like a toolchain fault. The
  firmware build repeats that check before calling the compiler, and runs
  from any working directory.
- **Simulation is fully open-source**: all 11 simulations (10 testbenches
  + the DFFRAM/ASIC-SRAM config) run unmodified under **Verilator 5**
  (`--timing`), same PASS criteria as the xsim suite.
- **`build` / `flashfw`** drive the same Vivado `.tcl` scripts through a
  Linux Vivado install (found via `$VIVADO`, PATH, or `/opt|/tools/Xilinx`).
- **`lint`** covers the SoC *and* each simulation model as its own top
  under `-Wall`: Verilator lints only what `--top-module` reaches, so the
  models — which hang off testbenches, not off the SoC — would otherwise
  never be checked. A width mismatch this repo's `-Wno-fatal` flows
  tolerate is a build stopper under the upstream FuseSoC sim target,
  which runs `-Wall` fatal.
- A FuseSoC wrapper (`minimal_ibex_soc.core`, targets `lint | sim | synth`)
  exists for FuseSoC-based team flows — the native scripts remain the
  supported path.

**Verilator on a Windows PC** (no WSL needed): install
[MSYS2](https://www.msys2.org/), open the **MSYS2 UCRT64** shell (not
cmd/PowerShell — Verilator needs make/g++), then:

```
cd /c/<path-to-repo>
./ibex_soc.sh deps          # pacman installs verilator/gcc/make/python
./ibex_soc.sh regression    # all 11 sims, same PASS criteria as xsim
```

The script reads the RISC-V GCC from the Windows GUI's `.toolpaths`
automatically. Verified: Verilator 5.050 under MSYS2, 13/13 green.

> **On an old checkout?** If your tree has `setup_check.bat`,
> `build_fpga.bat` or `flash_freertos.bat`, it predates 2026-08-18 —
> those entry points are retired and `ibex_soc.sh`/Verilator support
> does not exist there. `git pull` first; the only entry points are
> `ibex_soc.bat` (Windows GUI) and `ibex_soc.sh` (Linux/MSYS2).

### Vivado-only or Verilator-only? Pick a profile

Nobody has to install both. Each entry script carries a **tool profile**,
so the half you do not use is reported `[SKIP]` — never `[FAIL]` — and is
never prompted for:

| Profile | Means | Needs |
|---|---|---|
| `sim` | simulation + lint only | Verilator (no Vivado) |
| `fpga` | bitstream + flash only | Vivado (no Verilator) |
| `full` | both | both |
| `auto` | inferred from what is installed — the default | — |

```
./ibex_soc.sh profile sim                      # Linux / MSYS2
powershell -File scripts\flows.ps1 profile fpga  # Windows (GUI: Tool Profile)
```

The choice is remembered per-PC (`.toolpaths.sh` / `.toolpaths`). `auto`
already does the right thing on a one-tool machine, so a Verilator-only
box is all-green without Vivado and vice versa; pin a profile when you
want the answer fixed regardless of what else gets installed later.

**Verilator on Windows without Vivado:** the GUI's **Verilator
Regression** button (or `flows.ps1 simregression`) runs all 11 sims
through MSYS2's Verilator — the same `ibex_soc.sh` Linux uses, one PASS
table on either OS. If MSYS2 is absent it tells you how to install it.

### The serial console

Boot prints a full system-info banner (core, kernel, memory map,
peripherals, key help). After 30 quiet seconds a liveness heartbeat
(`tick=N up=Ss`) reports every 10 s — purely diagnostic, toggle it with
`t`. All four RGB LEDs breathe/cycle in unison. Single-key commands (each
echoed back as its ack):

| Keys | Function |
|---|---|
| `1` `2` `3` `4` | Green-LED pattern: walking / nibble flip / alternating / binary count |
| `f` `m` `s` | Pattern speed: 50 / 150 / 400 ms per step |
| `r` `g` `b` `w` / `a` | Force RGB colour (all 4 LEDs) / automatic colour cycling |
| `t` | Heartbeat report on/off |
| `i` | Re-scan the I2C bus — prints every address that ACKs, no reboot |

Holding any board button makes the LEDs mirror the switches. Scripted
check: `python util/uart_command_test.py`.

The flashed image always includes the LCD status screen: wire the batch-1
ST7735 (pre-soldered — jumper wires only, no soldering, see
[PRODUCTION_PERIPHERALS.md §8](docs/PRODUCTION_PERIPHERALS.md)) and the
ARF logo + the same system info render on it, updating live as you type.
The same image also drives the batch-1 I2C parts: wire the SSD1306 OLED
and/or BME280 sensor (Pmod JA, §8 wiring) and they are auto-detected —
temperature + humidity join the LCD, the OLED runs its own status screen
(double-height ARF logo, uptime, pattern/speed/key, rgb/heartbeat, sensor
row and a sweeping activity bar) with or without a sensor fitted, and a
`T=... P=... H=...` line joins the console every 10 s (off with `t`).
Parts are re-probed every 5 s, so late wiring or a re-seated jumper
self-heals. Nothing wired? Every task idles harmlessly.

## Binding constraints (from the tapeout spec)

- **SRAM = 8 KiB** at `0x0010_2000` — the Caravel area budget; not
  negotiable by software. Bigger code executes in place from SPI flash at
  `0x2000_0000` (firmware at flash offset 0x40_0000).
- **Boot contract (since 2026-08-19)**: the boot ROM jumps **directly into
  the XIP window** (`0x2040_0000`) — it never reads SRAM, because silicon
  SRAM powers up with random contents. The legacy SRAM+0x80 entry is
  re-written by the firmware each boot for debug flows.
- **20 MHz clock** — do not "fix" it upward.
- Interrupts are flat into Ibex fast IRQs (no PLIC); Ibex is vectored-only.
  Implemented: timer (mcause 7), UART1 RX fast[0], UART2 RX fast[1].
- Full spec digest, memory map, pin budget, roadmap:
  [docs/ASIC_SPEC.md](docs/ASIC_SPEC.md).

## Status

**15/15 regression green in xsim** (11 full-SoC simulations — including
`tb_soc-dffram`, the GF180 DFFRAM/ASIC-SRAM configuration — + images +
firmware + compile + bitstream with timing met), **cross-checked ALL
GREEN under Verilator 5** (`./ibex_soc.sh regression`), and **Phase 1 +
Phase 2a passed on the physical board (2026-08-18)** — FreeRTOS (V11.3.0)
booting from QSPI flash, scripted console sweep 8/8, all four RGB LEDs,
and the ST7735 rendering the live ARF status screen. First hardware
contact found and fixed two silicon-relevant RTL/firmware bugs (SPI
mode-0 hold time; warm-reset trampoline clobber). **2026-08-19:
direct-XIP boot landed** (lead-directed — the ROM never reads SRAM;
tb_xip/tb_freertos regress the exact silicon power-up condition) and
**2026-08-20: Phase 2b half done** — the SSD1306 OLED passed on the bench
with its own live status screen, while the BME280 module proved **dead**
(a boot-time I2C bus scan, new, reports the OLED and nothing else on a bus
the OLED itself proves healthy) and waits on a replacement. Plan in
[docs/HW_VALIDATION_PLAN.md](docs/HW_VALIDATION_PLAN.md), current state
in [docs/STATUS_BRIEF.md](docs/STATUS_BRIEF.md).

## Documentation (all of it)

| Document | Read it for |
|---|---|
| [STATUS_BRIEF.md](docs/STATUS_BRIEF.md) | Current status + decisions needed — the 5-minute lead brief |
| [ASIC_SPEC.md](docs/ASIC_SPEC.md) | The tapeout contract: area budget, memory map, interrupts, XIP, Caravel flow, roadmap |
| [FREERTOS_PORT.md](docs/FREERTOS_PORT.md) | FreeRTOS on 8 KiB + XIP: memory model, interrupts, build/flash/run |
| [PRODUCTION_PERIPHERALS.md](docs/PRODUCTION_PERIPHERALS.md) | Every external device: WiFi/camera/mic/speaker/PSRAM + LCD/sensor wiring, pin budget, BOM |
| [HW_VALIDATION_PLAN.md](docs/HW_VALIDATION_PLAN.md) | The 3-phase hardware re-validation checklist |
| [BRINGUP_TEST_REPORT.md](docs/BRINGUP_TEST_REPORT.md) | Every recorded result: builds, simulations, hardware |
| [WALKTHROUGH.md](docs/WALKTHROUGH.md) | Clean PC → working board, every script, all the gotchas |
| [BRINGUP_HISTORY.md](docs/BRINGUP_HISTORY.md) | History: the bugs, the decisions, the reviews |
| [UPSTREAM_README.md](docs/UPSTREAM_README.md) | The original lowRISC README, verbatim |

## Repository layout

| Path | Contents |
|---|---|
| `ibex_soc.bat` / `ibex_soc.sh` | **The one entry point per OS** (Windows GUI / Linux CLI+menu) |
| `minimal_ibex_soc.core` | FuseSoC wrapper (`lint` / `sim` / `synth` targets) |
| `scripts/` | `flows.ps1` (all flows) + regression/compile runners + tool locators |
| `rtl/system/`, `rtl/fpga/` | SoC fabric + peripherals; board top levels |
| `vendor/` | Vendored Ibex, lowRISC primitives, debug module, FreeRTOS kernel |
| `sw/freertos/` | The firmware: port glue, drivers, `main.c`, prebuilt fallback |
| `sw/asm-demo/` | Python mini-assembler + DV proof-program generators |
| `dv/xsim/` | 10 full-SoC testbenches, device models, the shared file list |
| `data/`, `*.tcl` | Pin constraints; Vivado build/program/project scripts |
| `docs/` | The 9 documents above |

Debugging? Start with the [WALKTHROUGH gotcha list](docs/WALKTHROUGH.md) —
every trap we ever hit is numbered there.

## License

Apache-2.0, following upstream lowRISC (see `LICENSE`).
