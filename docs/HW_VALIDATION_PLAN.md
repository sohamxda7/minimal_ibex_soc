# Hardware Validation Plan — v1.1 configuration

**Why this document exists:** the last physical board tests (2026-08-07)
ran on the OLD configuration (128 KiB SRAM, no XIP wiring, no v1.1
peripherals, pre-FreeRTOS). Everything since — 8 KiB SRAM, XIP, UART2,
SPI-RX, GPIO 16/16, FreeRTOS — passes **simulation only** (13/13,
[BRINGUP_TEST_REPORT.md](BRINGUP_TEST_REPORT.md) §6). Every base IO test
must therefore be **re-run on hardware** on the current build. Three phases,
strictly in order; each phase's results get a dated table in the test report.

**ONE FLOW (Soham, 2026-08-10):** the asm demo is retired as a user
vehicle (it remains DV-internal: tb_soc + the XIP trampoline). The ONLY
supported delivery is the non-volatile QSPI flow - `flash_freertos.bat` -
and the unified FreeRTOS firmware now carries the full former asm-demo
command console (1-4 patterns, f/m/s speed, r/g/b/w/a RGB, echo,
switch-mirror-while-button-held) plus banner/tick/blinky. All Phase-1
tests below run on that ONE image; `program_fpga.bat` is a dev-only tool.

---

## Phase 1 — base IO re-validation (needs: the board only)

**Phase 1 vehicle** — `flash_freertos.bat` (bitstream + firmware into QSPI,
survives power-cycle) → press PROG → PuTTY 115200:

| # | Test | Pass criterion | 2026-08-07 (old cfg) | v1.1 result |
|---|---|---|---|---|
| 1 | UART TX | `FreeRTOS on Ibex` banner + `tick=N` heartbeat | PASS (old cfg) | ☐ |
| 2 | UART RX + echo | typed keys echoed | PASS | ☐ |
| 3 | Green LEDs, patterns 1–4 | `1` `2` `3` `4` switch patterns | PASS | ☐ |
| 4 | Speed control | `f` `m` `s` visibly change step rate | PASS | ☐ |
| 5 | **RGB LEDs via PuTTY** | `r` `g` `b` `w` force colour; `a` auto-cycle; breathing continues | PASS | ☐ |
| 6 | Switches | SW mirrored to LEDs while BTN held | PASS | ☐ |
| 7 | Buttons | BTN state readable (same test) | PASS | ☐ |
| 8 | Scripted sweep | `python util/uart_command_test.py` → 8/8 | 8/8 | ☐ |
| 9 | Pmod continuity | touch-test on JA free pins (board-io-test procedure) | PASS | ☐ |

**Same image, RTOS-level checks:**

| # | Test | Pass criterion | v1.1 result |
|---|---|---|---|
| 10 | XIP boot from QSPI flash | `FreeRTOS on Ibex (XIP, 8KiB SRAM)` banner | ☐ |
| 11 | Scheduler + timer IRQ | `tick=N` lines advancing | ☐ |
| 12 | LED task | gp_o[7:4] rotating pattern | ☐ |
| 13 | Power-cycle persistence | unplug/replug → boots again from flash | ☐ |

## Phase 2 — batch-1 purchased hardware (needs: Phase 1 green + parcels)

Wire per [TOY_INTERFACING.md](TOY_INTERFACING.md) tables
(LCD → ChipKit A6–A11; BME280 + SSD1306 → Pmod JA1/JA2 + power).
Firmware: `sw\freertos\build.bat toy` → `flash_freertos.bat toy`.

| # | Test | Pass criterion | Result |
|---|---|---|---|
| 14 | ST7735 LCD | banner + orange rectangle (matches tb_lcd sequence) | ☐ |
| 15 | I2C bus scan | OLED (0x3C) and BME280 (0x76) both ACK | ☐ |
| 16 | BME280 | plausible T/P/H on UART every 2 s | ☐ |
| 17 | SSD1306 | title + live temperature line rendered | ☐ |
| 18 | Logic-analyzer capture | SPI + I2C traces archived for the report | ☐ |

(Soldering note: BME280/OLED need ~10 header joints — ping before starting,
guidance promised.)

## Phase 3 — batch-2 production peripherals (needs: Phase 2 green + order)

Parts per the procurement mail (ESP32, PSRAM, OV7670-**FIFO**, mic chain,
speaker chain). Wire per [PRODUCTION_PERIPHERALS.md](PRODUCTION_PERIPHERALS.md)
§1/§7. One device at a time, each mirroring its passing testbench:

| # | Test | Mirrors | Pass criterion | Result |
|---|---|---|---|---|
| 19 | PSRAM selftest | tb_psram | `psram_selftest()`=0 write/readback | ☐ |
| 20 | ESP32 link | tb_wifi | `esp_at_ping()` → OK at 115200 | ☐ |
| 21 | WiFi join + internet | — | `AT+CWJAP` join; HTTP GET via AT | ☐ |
| 22 | Mic | tb_audio | level meter reacts to sound; clip → PSRAM | ☐ |
| 23 | Speaker | tb_audio | `audio_beep()` audible; clip playback | ☐ |
| 24 | Camera | tb_cam | SCCB PID=0x76; frame → PSRAM; upload via ESP32 | ☐ |
| 25 | Voice-AI loop demo | all | record → cloud → reply audio plays | ☐ |

---

**Bookkeeping rule:** as each phase completes, copy its table with results +
date into BRINGUP_TEST_REPORT.md and tick here. No phase is "done" until the
report shows it.
