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
supported delivery is the non-volatile QSPI flow - `ibex_soc.bat` →
**Flash to Board (QSPI)** -
and the unified FreeRTOS firmware now carries the full former asm-demo
command console (1-4 patterns, f/m/s speed, r/g/b/w/a RGB, echo,
switch-mirror-while-button-held) plus banner/tick/blinky. All Phase-1
tests below run on that ONE image; JTAG programming is a dev-only tool.

---

## Phase 1 — base IO re-validation (needs: the board only)

**Phase 1 vehicle** — `ibex_soc.bat` → **Flash to Board** (bitstream +
firmware into QSPI, survives power-cycle; no toolchain needed - prebuilt
fallback) → press PROG → PuTTY 115200:

| # | Test | Pass criterion | 2026-08-07 (old cfg) | v1.1 result |
|---|---|---|---|---|
| 1 | UART TX | `FreeRTOS on Ibex` banner + `tick=` heartbeat | PASS (old cfg) | **PASS 2026-08-18** (ARF-BBSR-84 board) |
| 2 | UART RX + echo | typed keys echoed | PASS | **PASS 2026-08-18** |
| 3 | Green LEDs, patterns 1–4 | `1` `2` `3` `4` switch patterns | PASS | **PASS 2026-08-18** |
| 4 | Speed control | `f` `m` `s` visibly change step rate | PASS | **PASS 2026-08-18** |
| 5 | **RGB LEDs via PuTTY** | `r` `g` `b` `w` force colour; `a` auto-cycle; breathing continues, **all 4 LEDs** | PASS | PARTIAL 2026-08-18: control worked but only LED0 lit (fw bug, fixed) → **re-check after next flash** ☐ |
| 6 | Switches | SW mirrored to LEDs while BTN held | PASS | **PASS 2026-08-18** |
| 7 | Buttons | BTN state readable (same test) | PASS | **PASS 2026-08-18** |
| 8 | Scripted sweep | `python util/uart_command_test.py` → 8/8 | 8/8 | ☐ |
| 9 | Pmod continuity | touch-test on JA free pins (board-io-test procedure) | PASS | ☐ |

**Same image, RTOS-level checks:**

| # | Test | Pass criterion | v1.1 result |
|---|---|---|---|
| 10 | XIP boot from QSPI flash | `FreeRTOS on Ibex (XIP, 8KiB SRAM)` banner | **PASS 2026-08-18** |
| 11 | Scheduler + timer IRQ | heartbeat lines advancing | **PASS 2026-08-18** |
| 12 | LED task | gp_o[7:4] rotating pattern | **PASS 2026-08-18** |
| 13 | Power-cycle persistence | unplug/replug → boots again from flash | **PASS 2026-08-18** (PROG re-config from flash) |

Evidence + the two flow bugs found during the 2026-08-18 run:
[BRINGUP_TEST_REPORT.md section 8](BRINGUP_TEST_REPORT.md). Note the
console behaviour changed after that run (system-info banner; heartbeat
quiet 30 s then every 10 s as `tick=N up=Ss`; `t` toggles): criteria 1/11
read "heartbeat" accordingly.

## Phase 2 — batch-1 purchased hardware (needs: Phase 1 green + parcels)

Wire per [PRODUCTION_PERIPHERALS.md sec. 8](PRODUCTION_PERIPHERALS.md) tables
(LCD → ChipKit A6–A11; BME280 + SSD1306 → Pmod JA1/JA2 + power).
Firmware: `ibex_soc.bat` → variant *toy* → **Flash to Board**.

**Phase 2a first — LCD only, no soldering** (the ST7735 comes pre-soldered;
jumper wires only, PRODUCTION_PERIPHERALS §8 "Phase 2a"): run test 14 with
nothing else wired. Tests 15-17 wait for the ~10 OLED/BME280 header joints.

| # | Test | Pass criterion | Result |
|---|---|---|---|
| 14 | ST7735 LCD | system-status screen: ARF logo + banner render, uptime/tick advance and the alive-spinner rotates every second, PuTTY keys (`1-4`, `r/g/b/w/a`, `t`) change the pat/rgb/key fields within 1 s | ☐ |
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
| 20 | ESP32 link (polled) | tb_wifi | `esp_at_ping()` → OK at 115200 | ☐ |
| 20b | ESP32 link (IRQ mode) | tb_uart2_irq | `esp_at_init()` → re-ping OK; a forced `WIFI DISCONNECT` reaches the `esp_at_on_event` callback; console stays clean throughout | ☐ |
| 21 | WiFi join + internet | — | `AT+CWJAP` join; HTTP GET via AT; UART1 console usable simultaneously | ☐ |
| 22 | Mic | tb_audio | level meter reacts to sound; clip → PSRAM | ☐ |
| 23 | Speaker | tb_audio | `audio_beep()` audible; clip playback | ☐ |
| 24 | Camera | tb_cam | SCCB PID=0x76; frame → PSRAM; upload via ESP32 | ☐ |
| 25 | Voice-AI loop demo | all | record → cloud → reply audio plays | ☐ |

---

**Bookkeeping rule:** as each phase completes, copy its table with results +
date into BRINGUP_TEST_REPORT.md and tick here. No phase is "done" until the
report shows it.
