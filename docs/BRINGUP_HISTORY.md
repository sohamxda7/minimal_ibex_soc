# Bring-up History — Board Zero → Working SoC → ASIC Alignment

*Historical record (2026-08-07 … 2026-08-10), merged from the former
BRINGUP_OVERVIEW / FPGA_BRINGUP / UART_CONTROL docs (verbatim originals in
git history). Some statements describe that moment in time — e.g. "XIP
untested" (it is now regression-proven) and the asm demo as the user vehicle
(retired 2026-08-10; the unified FreeRTOS image is the only supported flow).
Current state: root [README.md](../README.md) + [STATUS_BRIEF.md](STATUS_BRIEF.md).*

---

## 1. Toolchain from zero

The test PC started with no FPGA tooling. Installed **Vivado ML Standard**
(free, Artix-7 only, cable drivers on). Two standing decisions:

- **FPGA work lives under `C:\FPGA\`** — Vivado breaks on spaces
  (`C:\Users\Soham Sen\…`) and OneDrive fights build churn.
- Vivado Standard is sufficient for the XC7A100T and saves ~50 GB.

## 2. Board IO qualification (`C:\FPGA\arty-io-test`, separate repo)

Every IO was qualified with a purpose-built bare-metal design (no CPU):
LED chase, switch mirror, button RGB cycling, UART echo, Pmod square waves —
all PASS. Two findings that carried over:

- The board is electrically fine, so later SoC misbehaviour is *logic* —
  decisive when debugging the "RGB glitch".
- **The time-scale illusion**: human-speed effects look frozen in a
  microsecond waveform; both repos ship sped-up sim images because of it.
- Pmod pins verified via a no-instruments "touch test" (pulled-up inputs,
  grounded pin reported over UART) — invented for a bench with no multimeter.

## 3. The "RGB glitch" — four root causes

The DV team's fork "worked in simulation, glitched on the board". All four
causes confirmed by code + simulation, then fixed:

1. **No program in the bitstream** (the actual "glitch"). `SRAMInitFile`
   was wired to nothing; only a Verilator DPI back-door ever loaded the
   program, so on hardware the CPU crash-looped in empty SRAM. A hardcoded
   `C:/Users/Raji/...` path in the RTL was the fossil of a manual workaround.
2. **Software timer 500× too fast** — `timer_enable(10000)` = 0.5 ms tick
   made the RGB ramp strobe at kHz: the visible "flicker".
3. **UART clock parameter never plumbed** — `uart u_uart` took defaults;
   garbled console at the wrong effective baud.
4. **PLL made 50 MHz for a 20 MHz design** — fixed the PLL
   (`CLKOUT0_DIVIDE 24 → 60`), not the parameters: 20 MHz is the ASIC target.

Also fixed en route: Verilator-only DPI exports guarded `ifndef SYNTHESIS`
broke xsim → real purpose is `ifdef VERILATOR`.

| File | Change |
|---|---|
| `rtl/system/wrapper_top.sv` | `ClockFrequency`/`BaudRate`/`SRAMInitFile` params, passed to uart + sram_model |
| `rtl/system/ibex_demo_system.sv` | passes params down; hardcoded personal path removed |
| `rtl/fpga/top_artya7.sv` | 20 MHz + SRAMInitFile plumbed |
| `vendor/.../clkgen_xil7series.sv` | PLL 50 → 20 MHz |
| `rtl/system/sram_model.sv`, `vendor/.../ibex_if_stage.sv` | DPI guard → `ifdef VERILATOR` |
| `sw/c/demo/hello_world/main.c` | timer tick 10000 → 2000000 (0.1 s @ 20 MHz) |

**Standing patches to vendored code — re-apply if `vendor/` is ever
re-imported** (upstream-sync policy: fetch `lowrisc`, merge taking OURS for
fork-owned files, re-apply these, run the full regression before pushing):

| File | Patch | Why |
|---|---|---|
| `vendor/lowrisc_ibex/shared/rtl/fpga/xilinx/clkgen_xil7series.sv` | `CLKOUT0_DIVIDE` 24 → 60 | 20 MHz system clock (ASIC target) |
| `vendor/lowrisc_ibex/rtl/ibex_if_stage.sv` | DPI guard `ifndef SYNTHESIS` → `ifdef VERILATOR` | xsim cannot compile Verilator-only DPI |

**Vendored pins** (checked 2026-08-18; RTL stays pinned on purpose — the
FPGA must validate the exact netlist that tapes out, so an RTL sync is a
deliberate lead-approved event, never routine freshening; the kernel is
software and tracks upstream releases):

| Component | Pin | Delta vs upstream (2026-08-18) |
|---|---|---|
| `vendor/lowrisc_ibex` | `594ea976` (2025-04-03) | 154 commits behind master — flagged in STATUS_BRIEF for the lead |
| `vendor/lowrisc_ip` (OpenTitan prims) | `d268f271` | pinned with Ibex |
| `vendor/pulp_riscv_dbg` | `138d74bc` | stable upstream |
| `vendor/freertos_kernel` | **V11.3.0** | current (synced from V11.2.0 on 2026-08-18; kernel unmodified — `VENDORED.txt` has the sync procedure) |

## 4. The no-FuseSoC, no-toolchain build path

Why the team found building "hard": FuseSoC needs a venv + lowRISC forks +
generated "abstract prims". Replaced with:

- **`dv/xsim/filelist.f`** — one hand-maintained compile order used by BOTH
  xsim and synthesis: what simulates is exactly what ships.
- **`dv/xsim/prim_shims.sv`** — hand-written replacements for the primgen
  primitives (real `BUFGCE` under `FPGA_XILINX`, latch model in sim).
- **`sw/asm-demo/assemble.py`** — dependency-free ~200-line Python RV32IM
  assembler; the demo program gets baked into the bitstream, so a working
  board needs no RISC-V GCC. Self-checks against the known-good `jal` in
  `boot.mem`.
- **xsim, not Verilator, on Windows** — ships with Vivado; Verilator flow
  preserved behind its guards.
- **Verify in simulation before touching the board** — hardware then worked
  on the first programming attempt.

## 5. UART command interface (now tasks inside the FreeRTOS image)

Console 115200 8N1, single characters — the command set lives on unchanged
in `sw/freertos/main.c` (see the root README for the user-facing table):
`1-4` patterns · `f/m/s` speed · `r/g/b/w` force RGB / `a` auto · echo-as-ack
· switches mirrored while a button is held.

The DV lead's draft `main.c` was reviewed; 6 findings, all fixed:

1. **Fatal:** `timer_enable()` re-armed inside the main loop — mtimecmp ran
   away, the tick (almost) never fired, patterns never advanced. Arm once;
   re-arm only on speed change.
2. Speed table inverted AND ~500× too fast (FAST was slowest; all values
   sub-3 ms). Now 50/150/400 ms.
3. Startup tick 5 µs ("change before FPGA implementation") → default MEDIUM.
4. Patterns wrote `gp_o[3:0]` (display-control pins) instead of the LED
   nibble `gp_o[7:4]` — half the patterns were invisible.
5. RGB control was missing entirely (the stated goal); added `r/g/b/w/a`
   with breathing kept alive under a forced colour.
6. Minor: hex-printed baud "115200" label, status-line flooding, `wfi` idle.

Design decisions kept: echo-as-ack (scriptable — `util/uart_command_test.py`
asserts on it), forced colour keeps breathing (proves PWM stays live).

Verification then: tb_soc 9/9 PASS + on-board run (BRINGUP_TEST_REPORT §2-4).

## 6. ASIC spec alignment (2026-08-10)

The tapeout guide (digested in [ASIC_SPEC.md](ASIC_SPEC.md)) fixed the
endgame — GF180MCU via Caravel, SRAM hard-capped at 8 KiB by die area:

- **SRAM back to 8 KiB** — 64 KiB DFFRAM (~14 mm²) exceeds the whole
  10.27 mm² user area. The FPGA validates the exact silicon configuration.
- **XIP from QSPI flash** for anything bigger — proving it in sim (tb_xip)
  exposed and fixed 3 real controller bugs before silicon.
- **Zephyr → FreeRTOS** — 8 KiB is below Zephyr's floor; the spec names
  FreeRTOS ([FREERTOS_PORT.md](FREERTOS_PORT.md)).
- **Doctrine (Rule 0)**: the ASIC is the product; the FPGA is strictly the
  pre-silicon validation vehicle.
- Both open spec questions later **resolved**: SRAM base 0x0010_2000
  confirmed; PWM stays in both FPGA and ASIC.

## 7. Handy references

- Memory map: BootROM `0x0010_0000` (4 KiB) → jumps to SRAM `0x0010_2080`;
  SRAM `0x0010_2000` (8 KiB); XIP window `0x2000_0000`; UART `0x4000_0000`;
  GPIO `0x4000_0100`; Timer `0x4000_0200`; I2C `0x4000_0400`; SPI host
  `0x4000_0500`; PWM `0x4000_0600`; UART2 `0x4000_0700`.
- Serial: 115200 8N1; COM number is per-PC (Device Manager).
- JTAG programming is volatile + dev-only; the supported flow is
  `ibex_soc.bat` → Flash to Board (survives power-cycle).
