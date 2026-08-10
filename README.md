# minimal-ibex-soc

A minimal RISC-V SoC built around the [lowRISC Ibex](https://github.com/lowRISC/ibex)
core, targeting the Digilent Arty A7 FPGA board (and, separately, an ASIC
implementation). Forked from the lowRISC Ibex Demo System; the original memory
bus has been replaced with a custom **OBI → Wishbone fabric**:

```
Ibex (RV32IMC) ──┬─ instr OBI ─┐
                 └─ data  OBI ─┤ 2:1 arbiter ─→ obi2wb ─→ wb_interconnect
                                                              │
   Boot ROM 4 KiB · SRAM 8 KiB · UART · GPIO · Timer · PWM ──┘
   I2C master · SPI host · SPI-flash XIP · RISC-V debug module
```

System clock: **20 MHz** (ASIC target frequency; the FPGA PLL divides the
board's 100 MHz down to match). Verified working on an Arty A7-100T:
simulation and on-board tests all pass (2026-08-07).

**This SoC is headed for silicon**: the team's tapeout plan targets GF180MCU
(180 nm) via the Efabless Caravel shuttle — digest in
[docs/ASIC_SPEC.md](docs/ASIC_SPEC.md). That spec fixes SRAM at **8 KiB**
(Caravel area budget), so larger firmware executes in place (XIP) from the
Arty's onboard 16 MB QSPI flash at `0x2000_0000`, and the RTOS is
**FreeRTOS** ([docs/FREERTOS_PORT.md](docs/FREERTOS_PORT.md)) — proven
booting and scheduling in full-SoC RTL simulation (2026-08-10).

## Getting started

Requirements: Windows or Linux PC with **Vivado** (free ML Standard edition,
Artix-7 device support + cable drivers) and Python 3. No FuseSoC, no RISC-V
toolchain, no other dependencies.

```
git clone git@github.com:sohamxda7/minimal_ibex_soc.git
cd minimal_ibex_soc
build_fpga.bat          # synthesise -> build/fpga/top_artya7.bit  (~15 min)
program_fpga.bat        # load onto the board over USB
```

Open a serial terminal (115200 8N1, COM port from Device Manager). The board
prints an `IBEX-SOC UP <n>` heartbeat and accepts single-key commands:

| Keys | Function |
|---|---|
| `1` `2` `3` `4` | Green-LED pattern: walking / nibble flip / alternating / binary count |
| `f` `m` `s` | Pattern speed: 50 / 150 / 400 ms per step |
| `r` `g` `b` `w` | Force RGB LED colour (brightness breathing continues) |
| `a` | RGB automatic colour cycling (default) |
| other | Echoed back |

Scripted equivalent: `python util/uart_command_test.py`.
Full-SoC simulation (Vivado xsim, no hardware needed): see
[docs/WALKTHROUGH.md](docs/WALKTHROUGH.md) §6.

For the complete step-by-step guide including every known pitfall, read
**[docs/WALKTHROUGH.md](docs/WALKTHROUGH.md)** first.

## Issues found and fixed (FPGA bring-up, 2026-08-07)

The design worked in Verilator simulation but failed on hardware
("glitching" RGB LEDs, garbled serial output). Root causes, all fixed on
this branch:

| # | Issue | Impact | Fix |
|---|---|---|---|
| 1 | `SRAMInitFile` parameter was wired to nothing; the program only reached SRAM through a Verilator-only DPI back-door | FPGA bitstream contained **no program**; the CPU jumped into empty SRAM and crash-looped — the primary "glitch" | Parameter plumbed `top_artya7 → ibex_demo_system → wrapper_top → sram_model`; the program image is now baked into the SRAM block RAM at synthesis (verified in the synth log) |
| 2 | Software timer tick set to 10 000 cycles (0.5 ms) | RGB brightness ramp and colour cycle ran ~500× fast — LEDs strobed at kHz rates (the *visible* glitch) | 0.1 s tick (2 000 000 cycles @ 20 MHz) |
| 3 | `uart` instantiated without parameters, so its internal 20 MHz default was used regardless of the top-level setting; PLL additionally generated 50 MHz for a 20 MHz design | Wrong effective baud rate — garbled serial console | `ClockFrequency`/`BaudRate` passed down every level; PLL divider corrected (`CLKOUT0_DIVIDE` 24 → 60 = 20 MHz) |
| 4 | Verilator-only DPI exports guarded `ifndef SYNTHESIS` | Vivado xsim failed to compile the design (broken generated C) | Guards corrected to `ifdef VERILATOR` (`sram_model.sv`, vendored `ibex_if_stage.sv`) |
| 5 | UART command draft (`main.c`): `timer_enable()` called every main-loop pass; speed table inverted and ~500× too fast; patterns wrote the LCD-control nibble instead of the LEDs | Timer interrupt never fired (no pattern would advance); UART flooded; patterns invisible | Timer armed once and re-armed only on speed change; corrected speed table; patterns confined to the LED nibble; RGB commands added — see [docs/UART_CONTROL.md](docs/UART_CONTROL.md) |
| 6 | `spi_flash_xip.sv` (untested): first flash byte landed in `rdata[31:24]` instead of `[7:0]`; FSM re-triggered during the ack cycle (phantom read able to complete a later request with stale data); writes to the window hung the bus | CPU executed byte-reversed garbage when fetching from flash — XIP unusable | All three fixed and proven by the new `tb_xip` execute-from-flash simulation (2026-08-10) |

Supporting infrastructure added: a plain-Vivado batch build (no FuseSoC), a
single compile list shared by simulation and synthesis, hand-written
replacements for the FuseSoC-generated primitives, a dependency-free Python
RV32IM assembler that produces the demo program (no GCC required), a
full-SoC xsim testbench, and a scripted hardware test.

## Repository layout

| Path | Contents |
|---|---|
| `rtl/system/` | SoC fabric: `wrapper_top`, `obi2wb`, `wb_interconnect`, peripherals (UART, GPIO, timer, PWM, I2C, SPI, XIP stub), memories |
| `rtl/fpga/` | Board top levels (`top_artya7.sv`) |
| `vendor/` | Vendored dependencies: Ibex core, lowRISC primitives, PULP debug module |
| `sw/asm-demo/` | Python mini-assembler + demo programs → `.vmem` images (incl. the XIP boot trampoline) |
| `sw/freertos/` | FreeRTOS firmware: port glue, linker, drivers (I2C/ST7735/BME280/SSD1306), demo app, `build.bat` |
| `vendor/freertos_kernel/` | FreeRTOS-Kernel V11.2.0 subset (MIT), unmodified |
| `sw/c/` | C software (CMake, RISC-V GCC); `demo/hello_world/main.c` mirrors the asm demo |
| `sw/rust/` | Embedded Rust HAL and demos (owned by the Rust team) |
| `dv/xsim/` | Windows-friendly full-SoC simulation: file list, testbench, primitive shims |
| `dv/verilator/` | Upstream Verilator simulation flow |
| `data/` | Pin constraints per board (`pins_artya7.xdc`) |
| `build_fpga.*`, `program_fpga.*` | One-click build and program scripts |
| `program_flash.*` | Program bitstream **+ XIP firmware** into the onboard QSPI flash |
| `scripts/` | Detached-launch compile/sim/bitstream runners used for regressions |
| `util/` | `uart_command_test.py` (scripted hardware test), OpenOCD configs |
| `board-io-test/` | Phase 1: standalone board IO qualification project (pre-SoC), with its own guide and test report |
| `docs/` | All documentation (see below) |
| `DFFRAM/`, `gds.tar.gz` | **ASIC-only artifacts** — not used by any FPGA/simulation/software flow; candidates for Git LFS |

## Documentation index

| Document | Read it for |
|---|---|
| [docs/WALKTHROUGH.md](docs/WALKTHROUGH.md) | **Start here.** Clean PC → working board, every script, all 15 known gotchas |
| [docs/FPGA_BRINGUP.md](docs/FPGA_BRINGUP.md) | Technical deep-dive on the bring-up bugs and the no-FuseSoC build/sim flow |
| [docs/UART_CONTROL.md](docs/UART_CONTROL.md) | UART command interface: design, review of the original draft, evidence |
| [docs/BRINGUP_TEST_REPORT.md](docs/BRINGUP_TEST_REPORT.md) | All recorded results: build, simulation, scripted and manual hardware tests |
| [docs/BRINGUP_OVERVIEW.md](docs/BRINGUP_OVERVIEW.md) | Project narrative and the decision log with reasoning |
| [docs/ASIC_SPEC.md](docs/ASIC_SPEC.md) | **The tapeout spec digest**: area budget, memory map, XIP contract, Caravel flow, security posture |
| [docs/FREERTOS_PORT.md](docs/FREERTOS_PORT.md) | FreeRTOS on 8 KiB + XIP: memory model, vectored interrupts, build/flash/run |
| [docs/TOY_INTERFACING.md](docs/TOY_INTERFACING.md) | Final acceptance test: LCD + I2C sensors, wiring tables, sim evidence |
| [docs/RTOS_RESEARCH.md](docs/RTOS_RESEARCH.md) / [docs/ZEPHYR_DECISION.md](docs/ZEPHYR_DECISION.md) | RTOS evaluation record (superseded by the 8 KiB constraint → FreeRTOS) |
| [docs/UPSTREAM_README.md](docs/UPSTREAM_README.md) | Original lowRISC documentation (Linux/FuseSoC/Verilator/GCC flows, other boards, JTAG debug) |
| [board-io-test/README.md](board-io-test/README.md) | The Phase-1 board IO qualification project |

## Continuous integration

- **CMake** — cross-compiles `sw/c` with the lowRISC RISC-V GCC on every
  push (green; independently proves the C demo builds).
- **Rust** — builds the embedded HAL; runs only when `sw/rust/**` changes.
  Currently failing against recent nightlies (pre-existing; the Rust owner
  should re-pin `rust-toolchain.toml`).

## License

Apache-2.0, following upstream lowRISC (see `LICENSE`).
