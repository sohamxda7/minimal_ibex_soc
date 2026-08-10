# ARF Design Fork Guide — minimal-ibex-soc

This is the front door for everything ARF added on top of lowRISC's Ibex Demo
System (the original README is preserved unmodified at the repository root
below the fork banner, and verbatim at
[UPSTREAM_README.md](UPSTREAM_README.md)).

A minimal RISC-V SoC around the [lowRISC Ibex](https://github.com/lowRISC/ibex)
RV32IMC core, on a custom **OBI → Wishbone fabric**, validated on the
**Digilent Arty A7-100T** and headed for **GF180MCU silicon** via the
Efabless Caravel shuttle:

```
Ibex (RV32IMC) ──┬─ instr OBI ─┐
                 └─ data  OBI ─┤ 2:1 arbiter ─→ obi2wb ─→ wb_interconnect
                                                              │
   Boot ROM 4 KiB · SRAM 8 KiB · UART · GPIO · Timer · PWM ──┘
   I2C master · SPI host · SPI-flash XIP · RISC-V debug module
```

System clock **20 MHz** (the ASIC target; the FPGA PLL divides the board's
100 MHz down to match). RTOS: **FreeRTOS**, executing in place from the
onboard 16 MB QSPI flash.

---

## 1. Where to start

| You want to... | Read |
|---|---|
| Go from clean PC to working board, with every pitfall | **[WALKTHROUGH.md](WALKTHROUGH.md)** |
| Understand the binding chip constraints (why 8 KiB, why XIP) | [ASIC_SPEC.md](ASIC_SPEC.md) |
| Build/run/flash FreeRTOS firmware | [FREERTOS_PORT.md](FREERTOS_PORT.md) |
| See every recorded test result | [BRINGUP_TEST_REPORT.md](BRINGUP_TEST_REPORT.md) |
| Follow the whole story + decision log | [BRINGUP_OVERVIEW.md](BRINGUP_OVERVIEW.md) |

## 2. How to start (quick start)

Requirements: Windows or Linux PC with **Vivado** (free ML Standard,
Artix-7 support + cable drivers) and Python 3. No FuseSoC needed; the demo
program needs no RISC-V toolchain (Python mini-assembler); FreeRTOS builds
with the RISC-V GCC from a Zephyr SDK install (see FREERTOS_PORT.md).

```
git clone git@github.com:sohamxda7/minimal_ibex_soc.git
cd minimal_ibex_soc
build_fpga.bat          # synthesise -> build/fpga/top_artya7.bit  (~15 min)
program_fpga.bat        # load onto the board over USB-JTAG (volatile)
```

Open a serial terminal (115200 8N1; COM port from Device Manager). The board
prints an `IBEX-SOC UP <n>` heartbeat and accepts single-key commands:

| Keys | Function |
|---|---|
| `1` `2` `3` `4` | Green-LED pattern: walking / nibble flip / alternating / binary count |
| `f` `m` `s` | Pattern speed: 50 / 150 / 400 ms per step |
| `r` `g` `b` `w` | Force RGB LED colour (brightness breathing continues) |
| `a` | RGB automatic colour cycling (default) |

Scripted equivalent: `python util/uart_command_test.py`. Full-SoC simulation
without hardware: [WALKTHROUGH.md](WALKTHROUGH.md) §6.

FreeRTOS from flash (XIP): `build_fpga.tcl -tclargs sw/asm-demo/xip_stub.vmem`,
then `sw\freertos\build.bat`, then `program_flash.bat` — details in
[FREERTOS_PORT.md](FREERTOS_PORT.md).

## 3. Fixes we made (all confirmed by simulation, then hardware where possible)

| # | Issue | Impact | Fix |
|---|---|---|---|
| 1 | `SRAMInitFile` parameter wired to nothing (program reached SRAM only through a Verilator-only DPI back-door) | FPGA bitstream contained **no program**; CPU crash-looped in empty SRAM — the reported "glitch" | Parameter plumbed `top_artya7 → ibex_demo_system → wrapper_top → sram_model`; program baked into BRAM at synthesis |
| 2 | Software timer tick 10 000 cycles (0.5 ms) | RGB ramp/colour cycle ~500× fast — LEDs strobed at kHz | 0.1 s tick (2 000 000 cycles @ 20 MHz) |
| 3 | `uart` instantiated parameterless (internal default used); PLL generated 50 MHz for a 20 MHz design | Wrong baud — garbled serial console | `ClockFrequency`/`BaudRate` passed down every level; PLL `CLKOUT0_DIVIDE` 24 → 60 |
| 4 | Verilator-only DPI exports guarded `ifndef SYNTHESIS` | Vivado xsim failed compiling generated C | Guards changed to `ifdef VERILATOR` (`sram_model.sv`, vendored `ibex_if_stage.sv`) |
| 5 | DV lead's UART-command draft: `timer_enable()` re-armed in the main loop; speed table inverted and ~500× fast; patterns wrote the display nibble | Tick never fired; UART flooded; patterns invisible | Timer armed once, re-armed on speed change only; corrected table; LED nibble only — review in [UART_CONTROL.md](UART_CONTROL.md) |
| 6 | `spi_flash_xip.sv` (untested): first flash byte into `rdata[31:24]` not `[7:0]`; FSM re-triggered during the ack cycle (stale-data phantom read); writes hung the bus | CPU executed byte-reversed garbage from flash — XIP unusable; latent data corruption | All three fixed; proven by the `tb_xip` execute-from-flash sim |
| 7 | Team's `i2c_slave_bfm.sv`: read path released SDA on the SCL sampling edge | Phantom STOP + corrupted final bit on I2C reads | Release moved to the following SCL-low phase; unsafe pre-drive removed |

## 4. What we added

- **Windows-native, no-FuseSoC build**: one compile list (`dv/xsim/filelist.f`)
  shared by simulation and synthesis; plain Vivado `.tcl/.bat` flows;
  hand-written primitive shims.
- **A dependency-free Python RV32IM assembler** (`sw/asm-demo/assemble.py`) —
  demo firmware with zero toolchain install.
- **Full-SoC xsim testbenches**: `tb_soc` (9 self-checks), `tb_lcd`
  (behavioral ST7735), `tb_i2c` (team slave BFM as sensor), `tb_xip`
  (CPU executing from a behavioral SPI NOR flash), `tb_freertos`
  (RTOS boot over XIP).
- **SPI-flash XIP path, wired and proven**: controller fixed (row 6 above),
  QSPI pins connected (flash SCK via `STARTUPE2` — it has no package pin),
  `program_flash.bat` burns bitstream + firmware in one MCS.
- **FreeRTOS V11.2.0 port** for the 8 KiB + XIP configuration
  ([FREERTOS_PORT.md](FREERTOS_PORT.md)) with peripheral drivers
  (I2C, ST7735, BME280, SSD1306) sized for 8 KiB RAM.
- **I2C pinned out** to Pmod JA1/JA2 as a proper open-drain bus.
- **Scripted hardware tests** (`util/uart_command_test.py`) and detached
  regression runners (`scripts/*.ps1`).
- **Phase-1 board IO qualification project** (`board-io-test/`) with its own
  test report — the board itself is known-good.

## 5. Patches to vendored code (re-apply if `vendor/` is ever re-imported)

| File | Patch | Why |
|---|---|---|
| `vendor/lowrisc_ibex/shared/rtl/fpga/xilinx/clkgen_xil7series.sv` | `CLKOUT0_DIVIDE` 24 → 60 | 20 MHz system clock (ASIC target) |
| `vendor/lowrisc_ibex/rtl/ibex_if_stage.sv` | DPI guard `ifndef SYNTHESIS` → `ifdef VERILATOR` | xsim cannot compile Verilator-only DPI |

Upstream-sync policy: fetch the `lowrisc` remote, merge taking OURS for
fork-owned files, re-apply the two patches above if `vendor/` changed, run
the full regression before pushing. FreeRTOS kernel is vendored unmodified
(`vendor/freertos_kernel/VENDORED.txt`).

## 6. Constraints (binding — from the tapeout spec)

Digest with full reasoning: **[ASIC_SPEC.md](ASIC_SPEC.md)**.

- **SRAM = 8 KiB** (`0x0010_2000..0x0010_3FFF`). The Caravel user area is
  10.27 mm²; 64 KiB of DFFRAM alone is ~14 mm². Not negotiable by software.
- **Code > 8 KiB executes in place** from SPI flash at `0x2000_0000`
  (firmware at flash offset 0x40_0000 → CPU address `0x2040_0000`).
- **20 MHz system clock** — the ASIC target; do not "fix" it upward.
- **Boot contract**: entry = SRAM+0x80 = `0x0010_2080`; XIP firmware boots
  via a 2-instruction trampoline there.
- **RTOS = FreeRTOS** (fits the RAM budget; named by the spec).
- No PLIC — interrupts go flat into Ibex's fast IRQ inputs; Ibex is
  vectored-only (`mtvec[1:0]` hardwired), so trap code needs a vector table.

### ⚠ Open questions for the team (unresolved deviations)

1. **SRAM base address**: spec sheet says `0x0010_1000`; this repo uses
   `0x0010_2000` (preserves the boot-ROM jump contract and every existing
   image). One of the two must change before tapeout RTL freeze.
2. **PWM block at `0x4000_0600`**: used by the RGB demo, but absent from the
   ASIC spec and its gate budget. Keep (costs gates) or make it FPGA-only?

## 7. Repository layout

| Path | Contents |
|---|---|
| `rtl/system/` | SoC fabric: `wrapper_top`, `obi2wb`, `wb_interconnect`, peripherals (UART, GPIO, timer, PWM, I2C, SPI, XIP), memories |
| `rtl/fpga/` | Board top levels (`top_artya7.sv`, incl. STARTUPE2 flash-clock access) |
| `vendor/` | Vendored: Ibex core, lowRISC primitives, PULP debug module, FreeRTOS kernel |
| `sw/asm-demo/` | Python mini-assembler + demo programs → `.vmem` images (incl. XIP trampoline) |
| `sw/freertos/` | FreeRTOS firmware: port glue, linker, drivers, demo app, `build.bat` |
| `sw/c/` | C software (CMake, RISC-V GCC); `demo/hello_world/main.c` mirrors the asm demo |
| `sw/rust/` | Embedded Rust HAL and demos (owned by the Rust team) |
| `dv/xsim/` | Windows-friendly full-SoC simulation: file list, 5 testbenches, shims, device models |
| `dv/verilator/` | Upstream Verilator simulation flow |
| `data/` | Pin constraints (`pins_artya7.xdc`) |
| `build_fpga.*` / `program_fpga.*` / `program_flash.*` | Build · JTAG program · flash bitstream+firmware |
| `scripts/` | Detached-launch compile/sim/bitstream regression runners |
| `util/` | Scripted hardware test, OpenOCD configs |
| `board-io-test/` | Phase-1 board IO qualification (pre-SoC) |
| `DFFRAM/`, `gds.tar.gz` | ASIC-side artifacts — unused by FPGA/sim/software flows |

## 8. Full documentation index

**Live documents**

| Document | Read it for |
|---|---|
| [WALKTHROUGH.md](WALKTHROUGH.md) | Clean PC → working board; every script; all 19 gotchas |
| [ASIC_SPEC.md](ASIC_SPEC.md) | The tapeout spec digest — area budget, memory map, XIP contract, Caravel flow, security |
| [FREERTOS_PORT.md](FREERTOS_PORT.md) | FreeRTOS on 8 KiB + XIP: memory model, vectored interrupts, build/flash/run |
| [FPGA_BRINGUP.md](FPGA_BRINGUP.md) | Bring-up bugs deep-dive + the no-FuseSoC build/sim flow |
| [UART_CONTROL.md](UART_CONTROL.md) | UART command interface: design + review of the original draft |
| [TOY_INTERFACING.md](TOY_INTERFACING.md) | Final acceptance test: LCD + I2C sensors, wiring tables, sim evidence |
| [BRINGUP_TEST_REPORT.md](BRINGUP_TEST_REPORT.md) | All recorded results: builds, simulations, hardware tests |
| [BRINGUP_OVERVIEW.md](BRINGUP_OVERVIEW.md) | Project narrative + decision log with reasoning |
| [../board-io-test/README.md](../board-io-test/README.md) | Phase-1 board IO qualification project |

**History / archive** (kept for the record; superseded by the ASIC pivot)

| Document | What it was |
|---|---|
| [RTOS_RESEARCH.md](RTOS_RESEARCH.md) | RTOS evaluation for the 128 KiB dev configuration |
| [ZEPHYR_DECISION.md](ZEPHYR_DECISION.md) | The Zephyr selection memo (superseded → FreeRTOS) |
| [UPSTREAM_README.md](UPSTREAM_README.md) | The original lowRISC README, verbatim (also restored at the repo root) |

## 9. Continuous integration

- **CMake** — cross-compiles `sw/c` with the lowRISC RISC-V GCC on every
  push (green).
- **Rust** — builds the embedded HAL; runs only on `sw/rust/**` changes.
  Pre-existing nightly failure; the Rust owner should re-pin
  `rust-toolchain.toml`.

## License

Apache-2.0, following upstream lowRISC (see `LICENSE`).
