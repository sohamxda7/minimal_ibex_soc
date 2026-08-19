# FreeRTOS Port — ASIC-Representative Firmware

**Why FreeRTOS (and why this is settled):** the ASIC spec
([ASIC_SPEC.md](ASIC_SPEC.md)) caps on-chip SRAM at 8 KiB and names FreeRTOS
as the XIP payload. Project doctrine (2026-08-10): the ASIC is the product
and the FPGA is only its validation vehicle - so the RTOS of record is the
one that runs on the silicon. That is FreeRTOS. FreeRTOS is a scheduler
plus queues/semaphores — no device-tree, no driver model — and runs in ~3–4 KiB
of RAM. (A Zephyr port existed for the pre-spec 128 KiB dev configuration;
removed with the 8 KiB constraint - retrievable from git history. Zephyr's
future, if any, is a v2-chip item: [ASIC_SPEC.md sec. 10](ASIC_SPEC.md).)

**Kernel:** FreeRTOS-Kernel **V11.3.0** (MIT, latest upstream release,
synced 2026-08-18), vendored subset at `vendor/freertos_kernel/` (core +
`include/` + `portable/GCC/RISC-V` + `heap_4.c`; see `VENDORED.txt`).
Official RISC-V port, unmodified.

### Where the code lives (common questions, answered once)

- **Is the OS inside `main.c`?** No. `sw/freertos/main.c` is only the
  *application* (tasks, console, banner, the interrupt dispatch hook).
  The FreeRTOS kernel itself — scheduler, queues, context switch — is the
  vendored source at `vendor/freertos_kernel/` and gets compiled and
  linked together with main.c by `build.bat`/`build.sh` (see the exact
  file list in either script). There is no binary blob: the OS is built
  from source in this repo on every firmware build.
- **Is the firmware hardcoded in the repo?** The *sources* are the truth
  and the normal flow **builds them**: Flash to Board compiles the
  firmware first, and if no compiler is installed it *offers the
  automatic toolchain install* right there. `sw/freertos/prebuilt/` holds
  ONE known-good binary used **only when you explicitly choose it** at
  that prompt — a convenience for toolchain-less lab PCs, never the
  default (policy set 2026-08-18; the fallback is no longer silent).
- **Does FreeRTOS run in SRAM?** Mostly no. All *code* (kernel + app)
  and constants execute **in place from QSPI flash** (XIP window
  `0x2000_0000`). The 8 KiB SRAM holds only the *mutable state*:
  `.data`/`.bss` (kernel bookkeeping, ~1 KiB) and the 4 KiB heap where
  task stacks and TCBs live. See section 1's memory diagram.

### Staying current (kernel + vendored RTL)

Pinned upstream versions and how to check them, verified 2026-08-18:

| Component | Where | Pinned at | Upstream then |
|---|---|---|---|
| FreeRTOS-Kernel | `vendor/freertos_kernel` (`VENDORED.txt`) | **V11.3.0** | V11.3.0 — **current** |
| lowRISC Ibex core | `vendor/lowrisc_ibex` (`.lock.hjson`) | `594ea976` (2025-04-03) | 154 commits ahead |
| lowRISC primitives | `vendor/lowrisc_ip` (`.lock.hjson`) | `d268f271` | moves with OpenTitan |
| PULP debug module | `vendor/pulp_riscv_dbg` (`.lock.hjson`) | `138d74bc` | stable |

**Policy — software vs silicon:** the *kernel* is software: sync it to
the latest release whenever convenient (procedure in `VENDORED.txt`:
copy the same file set, rebuild all variants, re-run tb_freertos + the
regression). The *RTL* is silicon: it stays **pinned on purpose** — the
FPGA must validate the exact netlist that tapes out, so an Ibex upstream
sync is a deliberate, lead-approved event (procedure + standing patches:
[BRINGUP_HISTORY.md section 3](BRINGUP_HISTORY.md)), not routine
freshening. The Ibex delta is tracked in
[STATUS_BRIEF.md](STATUS_BRIEF.md) as a decision for the lead.

**Toolchain:** any bare-metal RISC-V GCC. The build scripts auto-detect the
install (bin prefixes tried in order: `riscv32-unknown-elf-`,
`riscv64-zephyr-elf-`, `riscv64-unknown-elf-`, `riscv-none-elf-`) and pick
the right `-march` spelling per compiler. Supported installs, easiest first:

- **One click (recommended): `ibex_soc.bat` → Install Missing Tools.**
  Downloads the official **xPack riscv-none-elf-gcc** (native Windows,
  ~470 MB, no WSL, no admin rights) to `C:\FPGA\`, verifies it, and saves
  it to `.toolpaths`. Terminal equivalent:
  `powershell -File scripts\flows.ps1 deps` (add `force` to reinstall).
  Version pinned in flows.ps1 (currently 15.2.0-1).
- **lowRISC toolchain** (the Ibex-upstream reference; advanced) — download
  [`lowrisc-toolchain-rv32imcb-20220524-1.tar.xz`](https://github.com/lowRISC/lowrisc-toolchains/releases/download/20220524-1/lowrisc-toolchain-rv32imcb-20220524-1.tar.xz)
  (Clang 13 + GCC 10.2, prefix `riscv32-unknown-elf-`). The tarball contains
  **Linux binaries only**, so on Windows it needs **WSL** (skip this if you
  don't know WSL — use the one-click install above instead):
  `sudo mkdir -p /opt && xzcat lowrisc-toolchain-*.tar.xz | sudo tar -x -C /opt -f -`
  The locators find it automatically in WSL (`/opt/lowrisc-toolchain*`,
  `/tools/riscv`, `~/lowrisc-toolchain*`) and `build.bat` then compiles
  through `wsl` via `sw/freertos/build.sh`. Its GCC 10.2 rejects the modern
  `rv32imc_zicsr` march spelling — the scripts probe and fall back to plain
  `rv32imc` (equivalent there: old binutils still includes the CSR ops).
- **Zephyr SDK** (native Windows, e.g. `C:\FPGA\zephyr-sdk`) — its
  `riscv64-zephyr-elf-gcc` is a normal multilib bare-metal compiler.
  (`build.bat` and `build.sh` are verified byte-identical given the same
  toolchain; different GCC versions naturally differ in codegen.)
- **Linux: `./ibex_soc.sh deps`** installs the same xPack toolchain to
  `~/ibex-tools` on every distro. Do NOT use Ubuntu's
  `gcc-riscv64-unknown-elf` apt package — it ships **without a C
  library** (no `stdlib.h`) and cannot build the firmware;
  `build.sh --check-toolchain` compile-probes for exactly this.

Flags: `-march=rv32imc_zicsr` (or probed fallback) `-mabi=ilp32
-mcmodel=medany -Os`, no libc startup (`-nostartfiles`). Native Linux users
run `sw/freertos/build.sh` directly.

---

## 1. Execution model: XIP + 8 KiB SRAM

```
FLASH (XIP window)                        SRAM (8 KiB @ 0x0010_2000)
0x2040_0000  _start, vectors, .text       0x0010_2000  .data (copied at boot)
             .rodata                                   .bss  (zeroed at boot)
             .data load image                          .noinit: 4 KiB heap (heap_4)
                                                       512 B ISR stack (in .bss)
                                                       startup/main stack (top, dies
                                                       after the scheduler starts)
```

- Code and constants stay in the 16 MB onboard QSPI flash, memory-mapped
  read-only at `0x2000_0000` by `rtl/system/spi_flash_xip.sv`. Firmware sits
  at **flash offset 0x40_0000** (behind the ~3.7 MB A7-100T bitstream), so the
  entry point is **0x2040_0000**.
- Boot (since 2026-08-19): the boot ROM jumps **directly** to `0x2040_0000`
  — it never reads SRAM (silicon SRAM powers up random). `_start` (in
  flash) then sets SP, installs `mtvec`, re-writes the legacy SRAM+0x80
  trampoline (kept for debug flows; the linker reserves SRAM+0x00..0x8F
  for it), copies `.data` to SRAM, zeroes `.bss`, calls `main`.
- The 4 KiB FreeRTOS heap lives in `.noinit` (not zeroed at boot): heap_4
  builds its own free list, and zeroing 4 KiB over XIP wastes ~20 ms.

### RAM budget (measured, `sw/freertos/build/*.map`)

| Item | Bytes |
|---|---|
| `.data` + `.bss` (kernel state, ISR stack 512 B, app) | ~770 |
| heap (`.noinit`, holds TCBs + task stacks) | 4096 |
| startup/main stack (top of SRAM, reusable after scheduler start) | ~3300 free |
| **Total SRAM** | **8192** |

## 2. Interrupts: Ibex is vectored-only

Ibex hard-wires `mtvec[1:0]=01` (vectored, 256-byte aligned) — you cannot
point `mtvec` at `freertos_risc_v_trap_handler` like on direct-mode cores.
`sw/freertos/startup.S` provides a 32-entry vector table routing:

| Vector | Target (provided by the V11 port's portASM.S) |
|---|---|
| base+0 (exceptions, incl. `ecall` = task yield) | `freertos_risc_v_exception_handler` |
| base+4·7 (machine timer) | `freertos_risc_v_mtimer_interrupt_handler` (tick) |
| everything else (ext/fast IRQs) | `freertos_risc_v_interrupt_handler` |

The tick comes from the SoC's CLINT-style timer: `configMTIME_BASE_ADDRESS
0x4000_0200`, `configMTIMECMP_BASE_ADDRESS 0x4000_0208` — exactly the layout
the official port expects, zero port-layer changes needed.

### UART2 RX interrupt (fast IRQ 1 — lead-directed, 2026-08-17)

UART2 (the ESP32 link) raises Ibex **fast IRQ 1** (mcause 17, vector entry
17) whenever its 128-byte RX FIFO is non-empty (level). The application
interrupt handler in `main.c` reads `mcause` and dispatches cause 17 to
`esp_at_isr()`, which drains the hardware FIFO into a 256-byte software
ring and wakes the driver's RX task (`portYIELD_FROM_ISR` — legal here
because the port saves full context before calling the handler).

The IRQ is masked until **`esp_at_init()`** is called (sets `mie.17`,
spawns the `esp-rx` task at `configMAX_PRIORITIES-1` and the command
mutex — ~650 B of heap). Until then `esp_at_cmd()` works in the original
polled mode, so the default Phase-1 image spends nothing. After init:

- `esp_at_cmd()` sleeps on a task notification instead of polling; OK /
  ERROR / SEND OK / FAIL terminate it.
- **Unsolicited ESP-AT events** (`WIFI DISCONNECT`, `+IPD...`, `ready`,
  `busy`, `+CWJAP:`, `SEND FAIL`) are recognised even mid-command and
  delivered to the `esp_at_on_event()` callback from the RX task.
- `esp_at_rx_dropped()` counts software-ring overflows (diagnostic).

RTL contract proven by `dv/xsim/tb_uart2_irq.sv`: vectoring, ISR-only
delivery, 128-byte FIFO burst/overflow (exactly 128 kept of a 160-byte
burst), recovery after overflow, UART1 console alive throughout.

**Tick rate:** 20 Hz on hardware. With ICache disabled (ASIC spec) every trap
instruction is an XIP fetch; at `XipClkDiv=1` the tick path costs ~1 ms, so
20 Hz keeps overhead ~2%. The sim build (`-DSIM_BUILD`) uses 200 Hz and
1-tick delays to bound simulation time.

## 3. Building and running

```
sw\freertos\build.bat         # THE hardware image (incl. LCD/sensor task)
sw\freertos\build.bat sim     # simulation image (fast tick, for tb_freertos)
```

Simulation (after `python sw/asm-demo/xip_test.py` and the usual compile):

```
xelab tb_freertos -s freertos_sim -timescale 1ns/1ps && xsim freertos_sim -R
```

(Linux / open-source: `./ibex_soc.sh sim tb_freertos` — same testbench
under Verilator 5, minutes of wall time instead of ~10.)

PASS = `FreeRTOS on Ibex` banner + two `tick=` lines over the simulated UART
(scheduler, vectored trap entry, context switch, vTaskDelay all exercised).

Hardware flow (board): build the FPGA image (the direct-XIP boot ROM is in
the RTL; no SRAM image is baked since 2026-08-19), then program firmware
into flash at 0x40_0000 —

```
vivado -mode batch -source build_fpga.tcl
```

(or just `ibex_soc.bat` → **Flash to Board**, which does both.)

## 4. Demo application (`sw/freertos/main.c`) — THE one firmware

Unified 2026-08-10: the asm-demo command interface moved in here; the only
supported delivery is the **Flash to Board** flow in `ibex_soc.bat`
(non-volatile QSPI). Tasks:

- `blink` (prio 1): LED patterns 1-4 on `gp_o[7:4]`; while any button is
  held, mirrors the switches.
- `rgb` (prio 1): all four RGB LEDs via PWM ch0-11 - brightness breathing,
  colour auto-cycle or forced.
- `console` (prio 2): PuTTY commands, same as the old asm demo -
  `1`-`4` pattern, `f/m/s` speed (50/150/400 ms), `r/g/b/w` force colour,
  `a` auto-cycle, `t` heartbeat toggle, all other keys echoed.
- `report` (prio 2): heartbeat `tick=N up=Ss` (quiet 30 s, then every 10 s).
- `toy` task (prio 1, **in every hardware image** since 2026-08-18): the
  ST7735 live system-status screen (deep-blue ARF logo, banner, per-second
  status with change-only redraws). With a BME280 wired: signed `T`/`H` on
  the LCD live block + a `T/P/H` console line every 10 s (gated with the
  `t` heartbeat toggle). With an SSD1306 wired: title + T/H + pressure +
  uptime. Missing-part tolerant (bounded I2C waits), **self-healing**:
  absent parts re-probed every 5 s (hot-attach), parts failing 3 cycles in
  a row demoted back to absent. Wiring per
  [PRODUCTION_PERIPHERALS.md sec. 8](PRODUCTION_PERIPHERALS.md).
  Excluded from `sim` builds to keep tb_freertos fast.

## 5. Peripheral drivers (`sw/freertos/drivers/`)

| Driver | Bus | RAM cost | Notes |
|---|---|---|---|
| `i2c.c` | — | 0 | OpenCores master @0x4000_0400, 100 kHz, bounded waits, probe/reg/burst ops |
| `st7735.c` | SPI host | 0 | No framebuffer (40 KB doesn't exist here); streams pixels to RAMWR. Control lines on GPIO[3:0] per PRODUCTION_PERIPHERALS.md sec. 8 wiring |
| `bme280.c` | I2C 0x76 | 33 B calib | Forced-mode one-shot; 32-bit-only Bosch compensation (no 64-bit math on RV32IMC) |
| `ssd1306.c` | I2C 0x3C | 0 | Zero-framebuffer text rendering from flash-resident 5×7 font; ~21×8 chars |
| `spi_bus.c` | — | ~80 B mutex | v1.1: shared-bus arbitration + atomic GPIO RMW + RX-paced byte primitives |
| `psram.c` | SPI CS=gp_o[8] | 0 | v1.1: 8 MB external memory - write/read/selftest (docs/PRODUCTION_PERIPHERALS.md) |
| `esp_at.c` | UART2 | ~450 B static + ~650 B heap after `esp_at_init()` | v1.1: WiFi/internet via ESP32 AT commands; polled until `esp_at_init()`, then IRQ-driven with RX task + unsolicited-event parser (§2); bulk upload streams from PSRAM |
| `audio.c` | SPI + PWM ch3 | 0 | v1.1: mic sample/record + speaker play/beep, clips in PSRAM |
| `camera.c` | GPIO + I2C | 32 B bounce | v1.1: OV7670-FIFO snapshot capture into PSRAM |

Status: compile-clean in all build variants; ST7735 validated on the
physical panel (Phase 2a, 2026-08-18); I2C driver sequence validated in
tb_i2c; BME280/SSD1306 hardware test = Phase 2b (parts in hand,
soldering + wiring per PRODUCTION_PERIPHERALS.md §8).

## 6. Validation status

| Check | Status |
|---|---|
| Kernel + port + drivers build (all variants) | ✅ done |
| XIP controller proven in sim (tb_xip) | ✅ — since 2026-08-19 boots the REAL direct-XIP ROM with uninitialised SRAM |
| FreeRTOS boots in full-SoC sim (tb_freertos) | ✅ — same silicon-boot conditions |
| Hardware boot from QSPI flash | ✅ Phase 1 passed 2026-08-18 (power-cycle + warm-reset safe) |
| LCD status screen on hardware | ✅ Phase 2a passed 2026-08-18 |
| OLED + BME280 on hardware | Phase 2b — parts in hand, pending wiring session |
