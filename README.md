# ARF Design Fork Guide — minimal-ibex-soc

The front door: where to start, what was fixed and added, the binding chip
constraints, and where to look when debugging. The original lowRISC README
is preserved verbatim at [docs/UPSTREAM_README.md](docs/UPSTREAM_README.md).

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

> **Project doctrine — the ASIC is the product.** The FPGA board is strictly
> the pre-silicon validation vehicle, never a demo or dev platform. Nothing
> gets built here unless it runs (or is destined to run) on the fabricated
> chip: 8 KiB SRAM, 38 Caravel pins, 20 MHz, no BRAM, no DDR3. Features that
> cannot fit that budget (Zephyr, cameras, audio streaming, big-RAM network
> stacks) are out of scope unless the team re-scopes the silicon itself —
> see [ASIC_SPEC.md](docs/ASIC_SPEC.md) section 9.

---

## 1. Where to start

| You want to... | Read |
|---|---|
| **Brief the lead / get the current status in 5 min** | **[docs/STATUS_BRIEF.md](docs/STATUS_BRIEF.md)** |
| Go from clean PC to working board, with every pitfall | **[WALKTHROUGH.md](docs/WALKTHROUGH.md)** |
| Understand the binding chip constraints (why 8 KiB, why XIP) | [ASIC_SPEC.md](docs/ASIC_SPEC.md) |
| Build/run/flash FreeRTOS firmware | [FREERTOS_PORT.md](docs/FREERTOS_PORT.md) |
| See every recorded test result | [BRINGUP_TEST_REPORT.md](docs/BRINGUP_TEST_REPORT.md) |
| Run the hardware re-validation when board/parts arrive | **[HW_VALIDATION_PLAN.md](docs/HW_VALIDATION_PLAN.md)** |
| Follow the whole story + decision log | [BRINGUP_HISTORY.md](docs/BRINGUP_HISTORY.md) |

## 2. How to start (quick start)

Requirements: Windows or Linux PC with **Vivado** (free ML Standard,
Artix-7 support + cable drivers) and Python 3. No FuseSoC needed; the demo
program needs no RISC-V toolchain (Python mini-assembler); FreeRTOS builds
with the RISC-V GCC from a Zephyr SDK install (see FREERTOS_PORT.md).

**One-click scripts** (double-click from the repo root). Every script finds
its tools dynamically through a shared locator (`scripts/find_tools.cmd`):
saved answers (`.toolpaths`) → environment variables → the PATH → common
install roots on **every drive** → and if all that fails it **asks you for
the install directory once and remembers it** (per-PC `.toolpaths` file,
gitignored). Nothing is hard-coded; no drive letter is assumed:

| Script | One click does | Needs board? |
|---|---|---|
| `setup_check.bat` | **Run this first.** Environment doctor: verifies Vivado, Python, RISC-V GCC, git, repo location; changes nothing; prints fixes | no |
| `build_fpga.bat` | Synthesise the bitstream with the demo program baked in (~15 min) | no |
| `program_fpga.bat` | Load the bitstream over USB-JTAG (volatile — lost at power-cycle) | yes |
| `run_regression.bat` | The **entire test suite**: regenerate images, build FreeRTOS, compile, all 10 simulations, bitstream + timing, PASS/FAIL scoreboard (~45–60 min, `build\regression.log`) | no |
| `flash_freertos.bat` | **FreeRTOS to the board, end to end**: firmware → XIP-boot bitstream → QSPI flash (survives power-cycle). `toy` argument adds the LCD/sensor task. **No RISC-V toolchain? It falls back to the committed prebuilt firmware automatically** | yes |
| `program_flash.bat` | Just the flash-programming step (any firmware .bin) | yes |
| `sw\freertos\build.bat` | Just the firmware (`sim`/`toy` variants); honours `RISCV_GCC_HOME` | no |
| `control_panel.bat` | **The Windows GUI**: buttons for everything above + firmware variants + docs + live log viewer | no |

```
git clone git@github.com:sohamxda7/minimal_ibex_soc.git
cd minimal_ibex_soc
setup_check.bat         # environment doctor - fix anything it flags
flash_freertos.bat      # firmware + bitstream -> QSPI flash (the ONE flow)
```

Press PROG (or power-cycle) and open a serial terminal (115200 8N1; COM port
from Device Manager). The board prints `FreeRTOS on Ibex (XIP, 8KiB SRAM)`,
a `tick=N` heartbeat, and accepts single-key commands:

| Keys | Function |
|---|---|
| `1` `2` `3` `4` | Green-LED pattern: walking / nibble flip / alternating / binary count |
| `f` `m` `s` | Pattern speed: 50 / 150 / 400 ms per step |
| `r` `g` `b` `w` | Force RGB LED colour (brightness breathing continues) |
| `a` | RGB automatic colour cycling (default) |

Anything else typed is echoed back; holding any board button makes the LEDs
mirror the switches. Scripted equivalent: `python util/uart_command_test.py`.
Full-SoC simulation without hardware: [WALKTHROUGH.md](docs/WALKTHROUGH.md) §6.
(`build_fpga.bat` + `program_fpga.bat` remain as dev-only steps — volatile,
and the flash must already hold firmware for the board to boot anything.)

## 3. Fixes we made (all confirmed by simulation, then hardware where possible)

| # | Issue | Impact | Fix |
|---|---|---|---|
| 1 | `SRAMInitFile` parameter wired to nothing (program reached SRAM only through a Verilator-only DPI back-door) | FPGA bitstream contained **no program**; CPU crash-looped in empty SRAM — the reported "glitch" | Parameter plumbed `top_artya7 → ibex_demo_system → wrapper_top → sram_model`; program baked into BRAM at synthesis |
| 2 | Software timer tick 10 000 cycles (0.5 ms) | RGB ramp/colour cycle ~500× fast — LEDs strobed at kHz | 0.1 s tick (2 000 000 cycles @ 20 MHz) |
| 3 | `uart` instantiated parameterless (internal default used); PLL generated 50 MHz for a 20 MHz design | Wrong baud — garbled serial console | `ClockFrequency`/`BaudRate` passed down every level; PLL `CLKOUT0_DIVIDE` 24 → 60 |
| 4 | Verilator-only DPI exports guarded `ifndef SYNTHESIS` | Vivado xsim failed compiling generated C | Guards changed to `ifdef VERILATOR` (`sram_model.sv`, vendored `ibex_if_stage.sv`) |
| 5 | DV lead's UART-command draft: `timer_enable()` re-armed in the main loop; speed table inverted and ~500× fast; patterns wrote the display nibble | Tick never fired; UART flooded; patterns invisible | Timer armed once, re-armed on speed change only; corrected table; LED nibble only — review in [BRINGUP_HISTORY.md](docs/BRINGUP_HISTORY.md) §5 |
| 6 | `spi_flash_xip.sv` (untested): first flash byte into `rdata[31:24]` not `[7:0]`; FSM re-triggered during the ack cycle (stale-data phantom read); writes hung the bus | CPU executed byte-reversed garbage from flash — XIP unusable; latent data corruption | All three fixed; proven by the `tb_xip` execute-from-flash sim |
| 7 | Team's `i2c_slave_bfm.sv`: read path released SDA on the SCL sampling edge | Phantom STOP + corrupted final bit on I2C reads | Release moved to the following SCL-low phase; unsafe pre-drive removed |

## 4. What we added

- **Windows-native, no-FuseSoC build**: one compile list (`dv/xsim/filelist.f`)
  shared by simulation and synthesis; plain Vivado `.tcl/.bat` flows;
  hand-written primitive shims.
- **A dependency-free Python RV32IM assembler** (`sw/asm-demo/assemble.py`) —
  demo firmware with zero toolchain install.
- **Full-SoC xsim testbenches** (10): `tb_soc` (9 self-checks), `tb_lcd`
  (behavioral ST7735), `tb_i2c` (team slave BFM as sensor), `tb_xip`
  (CPU executing from a behavioral SPI NOR flash), `tb_freertos`
  (RTOS boot over XIP), `tb_psram`/`tb_wifi`/`tb_audio`/`tb_cam`
  (v1.1 peripherals), `tb_uart2_irq` (interrupt/overflow/recovery).
- **SPI-flash XIP path, wired and proven**: controller fixed (row 6 above),
  QSPI pins connected (flash SCK via `STARTUPE2` — it has no package pin),
  `program_flash.bat` burns bitstream + firmware in one MCS.
- **FreeRTOS V11.2.0 port** for the 8 KiB + XIP configuration
  ([FREERTOS_PORT.md](docs/FREERTOS_PORT.md)) with peripheral drivers
  (I2C, ST7735, BME280, SSD1306) sized for 8 KiB RAM.
- **I2C pinned out** to Pmod JA1/JA2 as a proper open-drain bus.
- **Scripted hardware tests** (`util/uart_command_test.py`) and detached
  regression runners (`scripts/*.ps1`).
- **Phase-1 board IO qualification project** (`board-io-test/`) with its own
  test report — the board itself is known-good.
- **v1.1 production-peripheral stack** ([PRODUCTION_PERIPHERALS.md](docs/PRODUCTION_PERIPHERALS.md)):
  UART2 + SPI-RX + GPIO-16 silicon additions; external 8 MB PSRAM, ESP32
  WiFi/internet, OV7670-FIFO camera snapshots, mic ADC + PWM speaker;
  behavioral models + 4 dedicated testbenches; FreeRTOS drivers for all of it.
- **A Windows GUI control panel** (`control_panel.bat`, WinForms, zero
  dependencies) driving setup/build/program/flash/regression with live logs.
- **UART2 RX interrupt path** (lead-directed, 2026-08-17): UART2 RX →
  Ibex fast IRQ 1, IRQ-driven ESP-AT client (high-priority RX task +
  unsolicited-event parser), proven by `tb_uart2_irq` (event / 128-byte
  FIFO burst-overflow / recovery, console alive throughout).
- **Prebuilt firmware fallback** (`sw/freertos/prebuilt/`):
  `flash_freertos.bat` works on machines with **no RISC-V toolchain**.

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

Digest with full reasoning: **[ASIC_SPEC.md](docs/ASIC_SPEC.md)**.

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

### ⚠ Open questions for the team

1. ~~SRAM base address~~ **RESOLVED (2026-08-10): the team confirmed
   `0x0010_2000` — this repo's value — is correct**; the spec sheet's
   printed `0x0010_1000` is stale. The boot contract (entry = SRAM+0x80 =
   `0x0010_2080`) stands unchanged.
2. ~~PWM block at `0x4000_0600`~~ **RESOLVED (2026-08-10): keep in BOTH
   FPGA and ASIC.** Sub-lead confirmed the spec omitted it only because it
   predates the fork - the block was already present in the original
   ibex-demo-system. No RTL change; it stays in the silicon netlist.

**No open questions remain** - the validated FPGA configuration is the
tapeout configuration.

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
| `dv/xsim/` | Windows-friendly full-SoC simulation: file list, 10 testbenches, shims, device models |
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
| [STATUS_BRIEF.md](docs/STATUS_BRIEF.md) | Current status + decisions needed — the 5-minute lead brief |
| [WALKTHROUGH.md](docs/WALKTHROUGH.md) | Clean PC → working board; every script; all the gotchas |
| [ASIC_SPEC.md](docs/ASIC_SPEC.md) | The tapeout spec digest — area budget, memory map, interrupts, XIP contract, Caravel flow, **roadmap (§10)** |
| [FREERTOS_PORT.md](docs/FREERTOS_PORT.md) | FreeRTOS on 8 KiB + XIP: memory model, vectored interrupts, build/flash/run |
| [PRODUCTION_PERIPHERALS.md](docs/PRODUCTION_PERIPHERALS.md) | **Every external device**: v1.1 WiFi/camera/mic/speaker/PSRAM + batch-1 LCD/sensor wiring (§8), pin budget, BOM, sim evidence |
| [HW_VALIDATION_PLAN.md](docs/HW_VALIDATION_PLAN.md) | The 3-phase hardware re-validation checklist |
| [BRINGUP_TEST_REPORT.md](docs/BRINGUP_TEST_REPORT.md) | All recorded results: builds, simulations, hardware tests |
| [BRINGUP_HISTORY.md](docs/BRINGUP_HISTORY.md) | History: bring-up bugs, build-flow decisions, UART-command design review, ASIC alignment |
| [board-io-test/README.md](board-io-test/README.md) | Phase-1 board IO qualification project |
| [UPSTREAM_README.md](docs/UPSTREAM_README.md) | The original lowRISC README, verbatim |

*(Docs were consolidated 2026-08-17: FPGA_BRINGUP / UART_CONTROL /
BRINGUP_OVERVIEW merged into BRINGUP_HISTORY; TOY_INTERFACING into
PRODUCTION_PERIPHERALS §8; CHIP_ROADMAP into ASIC_SPEC §10. Zephyr-era
evaluations were removed earlier — all recoverable from git history.)*

## 9. Continuous integration

- **CMake** — cross-compiles `sw/c` with the lowRISC RISC-V GCC on every
  push (green).
- **Rust** — builds the embedded HAL; runs only on `sw/rust/**` changes.
  Pre-existing nightly failure; the Rust owner should re-pin
  `rust-toolchain.toml`.

## License

Apache-2.0, following upstream lowRISC (see `LICENSE`).
