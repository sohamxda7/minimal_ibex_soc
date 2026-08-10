# FreeRTOS Port — ASIC-Representative Firmware

**Why FreeRTOS (and why this is settled):** the ASIC spec
([ASIC_SPEC.md](ASIC_SPEC.md)) caps on-chip SRAM at 8 KiB and names FreeRTOS
as the XIP payload. Project doctrine (2026-08-10): the ASIC is the product
and the FPGA is only its validation vehicle - so the RTOS of record is the
one that runs on the silicon. That is FreeRTOS. FreeRTOS is a scheduler
plus queues/semaphores — no device-tree, no driver model — and runs in ~3–4 KiB
of RAM. (A Zephyr port existed for the pre-spec 128 KiB dev configuration;
removed with the 8 KiB constraint - retrievable from git history. Zephyr's
future, if any, is a v2-chip item: [CHIP_ROADMAP.md](CHIP_ROADMAP.md).)

**Kernel:** FreeRTOS-Kernel **V11.2.0** (MIT), vendored subset at
`vendor/freertos_kernel/` (core + `include/` + `portable/GCC/RISC-V` +
`heap_4.c`; see `VENDORED.txt`). Official RISC-V port, unmodified.

**Toolchain:** `riscv64-zephyr-elf-gcc` from the Zephyr SDK install at
`C:\FPGA\zephyr-sdk` (the SDK stayed after the Zephyr port was removed — its
GCC is a normal bare-metal RISC-V compiler). Flags: `-march=rv32imc_zicsr
-mabi=ilp32 -mcmodel=medany -Os`, no libc startup (`-nostartfiles`).

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
- Boot: the SRAM boot image is just a 2-instruction trampoline
  (`sw/asm-demo/xip_test.py` → `xip_stub.vmem`) at the boot-ROM jump target
  SRAM+0x80 that jumps to `0x2040_0000`. `_start` (in flash) then sets SP,
  installs `mtvec`, copies `.data` to SRAM, zeroes `.bss`, calls `main`.
  The trampoline gets overwritten by `.data` afterwards — by design.
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

**Tick rate:** 20 Hz on hardware. With ICache disabled (ASIC spec) every trap
instruction is an XIP fetch; at `XipClkDiv=1` the tick path costs ~1 ms, so
20 Hz keeps overhead ~2%. The sim build (`-DSIM_BUILD`) uses 200 Hz and
1-tick delays to bound simulation time.

## 3. Building and running

```
sw\freertos\build.bat         # hardware image -> build\freertos_demo_flash.vmem
sw\freertos\build.bat sim     # simulation image (fast tick, for tb_freertos)
sw\freertos\build.bat toy     # hardware image incl. the toy-interfacing task
```

Simulation (after `python sw/asm-demo/xip_test.py` and the usual compile):

```
xelab tb_freertos -s freertos_sim -timescale 1ns/1ps && xsim freertos_sim -R
```

PASS = `FreeRTOS on Ibex` banner + two `tick=` lines over the simulated UART
(scheduler, vectored trap entry, context switch, vTaskDelay all exercised).

Hardware flow (board): build the FPGA image with the trampoline baked in,
then program firmware into flash at 0x40_0000 —

```
vivado -mode batch -source build_fpga.tcl -tclargs sw/asm-demo/xip_stub.vmem
```

(Flash programming script for the firmware partition: pending first board
session — will use `write_cfgmem` to append the firmware to the bitstream MCS.)

## 4. Demo application (`sw/freertos/main.c`)

- `blink` task (prio 1): rotates a pattern on LEDs `gp_o[7:4]`.
- `report` task (prio 2): prints `tick=N` over UART.
- `toy` task (TOY_DEMO builds, prio 1): the toy-interfacing final test —
  ST7735 LCD banner over SPI, then a BME280 reading every 2 s to UART and the
  SSD1306 OLED. Needs hardware wired per
  [TOY_INTERFACING.md](TOY_INTERFACING.md).

## 5. Peripheral drivers (`sw/freertos/drivers/`)

| Driver | Bus | RAM cost | Notes |
|---|---|---|---|
| `i2c.c` | — | 0 | OpenCores master @0x4000_0400, 100 kHz, bounded waits, probe/reg/burst ops |
| `st7735.c` | SPI host | 0 | No framebuffer (40 KB doesn't exist here); streams pixels to RAMWR. Control lines on GPIO[3:0] per TOY_INTERFACING wiring |
| `bme280.c` | I2C 0x76 | 33 B calib | Forced-mode one-shot; 32-bit-only Bosch compensation (no 64-bit math on RV32IMC) |
| `ssd1306.c` | I2C 0x3C | 0 | Zero-framebuffer text rendering from flash-resident 5×7 font; ~21×8 chars |
| `spi_bus.c` | — | ~80 B mutex | v1.1: shared-bus arbitration + atomic GPIO RMW + RX-paced byte primitives |
| `psram.c` | SPI CS=gp_o[8] | 0 | v1.1: 8 MB external memory - write/read/selftest (docs/PRODUCTION_PERIPHERALS.md) |
| `esp_at.c` | UART2 | 0 | v1.1: WiFi/internet via ESP32 AT commands; bulk upload streams from PSRAM |
| `audio.c` | SPI + PWM ch3 | 0 | v1.1: mic sample/record + speaker play/beep, clips in PSRAM |
| `camera.c` | GPIO + I2C | 32 B bounce | v1.1: OV7670-FIFO snapshot capture into PSRAM |

Status: compile-clean in all three build variants; ST7735 protocol previously
validated against the behavioral LCD model (tb_lcd) at the assembly level;
BME280/SSD1306 await hardware (parts on order, see procurement mail).

## 6. Validation status

| Check | Status |
|---|---|
| Kernel + port + drivers build (3 variants) | ✅ done |
| XIP controller proven in sim (tb_xip) | see [BRINGUP_TEST_REPORT.md](BRINGUP_TEST_REPORT.md) |
| FreeRTOS boots in full-SoC sim (tb_freertos) | see [BRINGUP_TEST_REPORT.md](BRINGUP_TEST_REPORT.md) |
| Hardware boot from QSPI flash | pending board |
| Toy demo on hardware | pending parts |
