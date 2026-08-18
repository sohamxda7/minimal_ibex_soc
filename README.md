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
   install. (Skippable: flashing falls back to the committed prebuilt
   firmware even with no GCC at all.)
3. **Flash to Board (QSPI)** — firmware → XIP bitstream → QSPI flash.
   Press PROG on the board; survives power-cycle.
4. Open PuTTY at **115200 8N1** (COM port from Device Manager).

Every button is also a command: `powershell -File scripts\flows.ps1 <flow>`
with `setup | deps | xpr | build | program | firmware [sim|toy] |
flashfw [toy] | flashonly [bin] | regression`. (Requires Windows; clone
outside OneDrive, path without spaces — Vivado breaks on both.)

### The serial console

Boot banner `FreeRTOS on Ibex (XIP, 8KiB SRAM)` + `tick=N` heartbeat, then
single-key commands (each echoed back as its ack):

| Keys | Function |
|---|---|
| `1` `2` `3` `4` | Green-LED pattern: walking / nibble flip / alternating / binary count |
| `f` `m` `s` | Pattern speed: 50 / 150 / 400 ms per step |
| `r` `g` `b` `w` / `a` | Force RGB colour / automatic colour cycling |

Holding any board button makes the LEDs mirror the switches. Scripted
check: `python util/uart_command_test.py`.

## Binding constraints (from the tapeout spec)

- **SRAM = 8 KiB** at `0x0010_2000` — the Caravel area budget; not
  negotiable by software. Bigger code executes in place from SPI flash at
  `0x2000_0000` (firmware at flash offset 0x40_0000).
- **Boot contract**: entry = SRAM+0x80 = `0x0010_2080` (XIP boots via a
  2-instruction trampoline there).
- **20 MHz clock** — do not "fix" it upward.
- Interrupts are flat into Ibex fast IRQs (no PLIC); Ibex is vectored-only.
  Implemented: timer (mcause 7), UART1 RX fast[0], UART2 RX fast[1].
- Full spec digest, memory map, pin budget, roadmap:
  [docs/ASIC_SPEC.md](docs/ASIC_SPEC.md).

## Status

**14/14 regression green** (10 full-SoC simulations + images + firmware +
compile + bitstream with timing met). Seven real bugs found and fixed
pre-silicon. Hardware re-validation of the current config is owed — plan in
[docs/HW_VALIDATION_PLAN.md](docs/HW_VALIDATION_PLAN.md), current state in
[docs/STATUS_BRIEF.md](docs/STATUS_BRIEF.md).

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
| `ibex_soc.bat` | **The one entry point** (GUI) |
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
