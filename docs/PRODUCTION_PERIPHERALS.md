# Peripherals — All External Hardware: Wiring, Drivers, Evidence

*One doc for every external device: the v1.1 production set (WiFi, camera,
mic, speaker, PSRAM) in §1-§7, and the already-purchased batch-1 "toy"
set (LCD, BME280, OLED) in §8 (absorbed from the former TOY_INTERFACING.md).*

**Doctrine check (Rule 0):** every feature on this page runs on the fabricated
chip. The architecture is *external-first*: the silicon gained only three
small additions (UART2, an SPI RX register, wider GPIO); everything heavy —
radio, TCP/IP, frame storage, clip storage — lives in external parts on the
carrier board, exactly like production embedded systems are built.

```
                          ┌──────────────────────────── carrier board ───┐
   ┌──── our chip ─────┐  │                                              │
   │ FreeRTOS, 8 KiB   │  │  ESP32  ── WiFi + TCP/IP (AT firmware)       │
   │ SRAM, XIP flash   │──┼─ UART2                                       │
   │                   │  │  APS6404 ── 8 MB PSRAM   (bulk data)         │
   │ SPI host ─────────┼──┼─ shared SPI bus + MCP3202 ── mic ADC         │
   │ I2C ──────────────┼──┼─ BME280 · SSD1306 · OV7670 SCCB              │
   │ GPIO[15:8] in ────┼──┼─ OV7670-FIFO camera data bus                 │
   │ GPIO[12:8] out ───┼──┼─ CS lines + camera FIFO control              │
   │ PWM ch3 ──────────┼──┼─ PAM8302 amp ── speaker                      │
   └───────────────────┘  └──────────────────────────────────────────────┘
```

## 1. What the silicon gained (v1.1 spec additions)

| Addition | Cost | Why |
|---|---|---|
| **UART2** @ `0x4000_0700` | ~1.5 kGE, +2 pins | The ESP32 companion link = the chip's entire WiFi/internet story |
| **SPI RX register** @ SPI+0x8 | ~30 flops, 0 pins | The SPI host could transmit only; PSRAM/ADC reads need receive |
| **GPIO 16/16** (was 8/8) | ~trivial gates | gp_o[12:8] = CS + camera control, gp_i[15:8] = camera data bus |

Total ≈ +2 kGE on the ~44 kGE budget; utilization ~76% → ~78%. Registers:
UART2 mirrors UART1 (RX +0, TX +4, STATUS +8). SPI RX returns
`{seq[15:8], byte[7:0]}` — byte is the receive shift register (stable once
the bus idles), seq counts byte boundaries.

### Pin budget (Caravel: 38 user pads)

UART1 2 · UART2 2 · JTAG 4 (TRST tied high) · XIP-SPI 4 · SPI host 3 +
CS×2 in gp_o · I2C 2 · PWM 2 (status RGB + SPKR) · gp_o 12 (4 display ctrl,
2 status LED, 2 CS, 3 camera ctrl, 1 spare) · gp_i 8 (camera bus) =
**37 of 38**. One pad spare — flagged for team review at pin-plan freeze.
(On the Arty, the same signals map to Pmods JB/JC, with the shared SPI
MISO return on Pmod JA3 — see `pins_artya7.xdc`.)

## 2. External memory: the PSRAM (the enabler for everything below)

**8 MB SPI PSRAM (APS6404-class, ~₹200)** on the shared SPI host bus,
CS = gp_o[8]. Desk-vs-warehouse rule: the 8 KiB SRAM is the CPU's desk
(stacks, RTOS state); the PSRAM is a warehouse reached by bus commands
(0x02 write / 0x03 read, 24-bit address, auto-increment) — bulk storage,
**never** CPU-executable/stack memory, which is also why Zephyr remains
impossible on v1 and lives in [ASIC_SPEC.md sec. 10](ASIC_SPEC.md) under v2.

Suggested layout (`drivers/psram.h`): camera frames @0x100000, audio clips
@0x200000, network buffers @0x300000. Effective driver throughput at the
5 MHz SPI host: ~250–500 KB/s — a QVGA frame moves in well under a second.

## 3. Capability contract (honest ceilings, per ASIC_SPEC §9)

| Feature | Delivered by | Ceiling |
|---|---|---|
| WiFi + internet | ESP32 over UART2 (AT commands; ESP32 owns TCP/IP) | Full internet access at UART speeds; join/HTTP/MQTT all via `esp_at_cmd()` |
| Camera | OV7670 **FIFO version** (384 KB buffer on module) → GPIO readout → PSRAM → upload via ESP32 | **Snapshots** (~1 QVGA frame / 1–2 s), never video |
| Speaker | PWM ch3 → PAM8302 amp | Tones, alerts, 8-bit clips from PSRAM — not hi-fi |
| Mic | MAX9814 preamp → MCP3202 SPI ADC | Level/event detection; clip capture to PSRAM; tick-paced rates until the mtime pacer lands (hw bring-up item) |
| Voice-AI loop | record → PSRAM → ESP32 → cloud AI → PSRAM → play | ~10 s round trip; the heavy AI stays in the cloud |

## 4. Software (FreeRTOS, `sw/freertos/drivers/`)

| Driver | Covers | Validated by |
|---|---|---|
| `spi_bus.c` | Bus mutex + atomic GPIO RMW + RX-paced byte primitives | all SPI tbs |
| `psram.c` | write/read/selftest | tb_psram |
| `esp_at.c` | AT client: `cmd/ping/join/send_raw`(from PSRAM) | tb_wifi |
| `audio.c` | mic sample/record-to-PSRAM/play-from-PSRAM/beep | tb_audio |
| `camera.c` | SCCB init (via existing I2C), capture arm, FIFO→PSRAM | tb_cam |
| `i2c.c` `st7735.c` `bme280.c` `ssd1306.c` | the toy-test parts already purchased | tb_i2c, tb_lcd |

Shared-bus rule: **every** SPI session takes `spi_bus_lock()`; **every** GPIO
OUT change goes through `gpio_out_update()` (critical-section RMW) — LEDs,
display, CS lines and camera strobes all share one register.

## 5. Simulation evidence (models in `dv/xsim/periph_models.sv`)

| Bench | Models used | Proves |
|---|---|---|
| tb_psram | spi_psram_model | write+readback through the new RX register |
| tb_wifi | esp32_at_model | UART2 both directions, AT→OK round trip |
| tb_audio | mcp3202_model | ADC sample ramp + speaker PWM activity |
| tb_cam | ov7670_fifo_model | RRST/RCLK handshake, RAW GPIO byte reads, checksum |

Results live in [BRINGUP_TEST_REPORT.md](BRINGUP_TEST_REPORT.md). The SPI
models follow the sampled-edge discipline that caught real bugs in tb_lcd and
tb_i2c (never sample and change on the same edge).

## 6. Bill of materials (documentation only — nothing ordered yet)

Already purchased (arriving via Amazon — §8 below):
ST7735 LCD, BME280, SSD1306, jumpers, breadboard, logic analyzer, soldering
kit, DT830 multimeter (~₹4,550).

To add for the production peripherals (~₹1,800):

| Part | Role | Est. |
|---|---|---|
| ESP32 DevKit (WROOM-32, AT firmware) | WiFi + TCP/IP companion | ~₹500 |
| APS6404 / ESP-PSRAM64H 8 MB SPI PSRAM (SOP-8 on breakout) | external memory | ~₹200 |
| **OV7670 with AL422 FIFO** (must be the FIFO version) | camera | ~₹500 |
| MCP3202 (DIP-8) + MAX9814 mic module | mic ADC + preamp | ~₹300 |
| PAM8302 amp + 4 Ω 3 W speaker | speaker | ~₹250 |

## 7. Hardware bring-up items (recorded now, executed when parts land)

1. PSRAM SO and ADC DOUT share the SPI_RX line — both tri-state when
   deselected; add 10 k pull-ups on both CS lines (reset-window cover).
2. Camera WEN/VSYNC framing needs the real sensor's timing (model is
   simplified by design); SCCB probe (`cam_init`, PID=0x76) is the smoke test.
3. mtime-paced audio sampling (true 8 kHz) replaces tick pacing.
4. ESP32 first contact at its 115200 default; keep `esp_at_ping()` as step 1.

## 8. Batch-1 "toy" hardware (purchased, ~₹4,550 — the Phase-2 test set)

ST7735 1.8" SPI LCD (pre-soldered) · BME280 I2C sensor · SSD1306 OLED ·
jumpers · breadboard · 24 MHz logic analyzer · DT830 multimeter · soldering
kit (BME280 + OLED need ~10 header joints — ask for guidance before starting).

Firmware: `ibex_soc.bat` → variant *toy (LCD+sensors)* → **Flash to Board**
(adds the toy task: a live LCD system-status screen, plus a BME280 reading
on UART + OLED every cycle once those are wired).

### Phase 2a — LCD only, NO soldering needed (start here)

The ST7735 ships with its header pre-soldered, so it is the one batch-1
part testable the day it arrives. **Everything you need:** the LCD + 8
jumper wires (female end onto the LCD's pins, male end into the Arty's
sockets). Nothing else to buy — "ChipKit header" and "power header" in the
table below are just names for socket rows **already printed on the Arty
board**: the analog row is labelled A0–A11 on the silkscreen, and the power
row (a few sockets along the same edge) is labelled 3V3 / GND / 5V0 / VIN.

**Test order for the session:**

1. **Phase 1 re-check first, nothing wired** — the full PuTTY console the
   board already passed (the old asm-demo controls, which now live inside
   the FreeRTOS image): `1-4` patterns, `f/m/s` speed, `r/g/b/w/a` RGB on
   all four LEDs, `t` heartbeat, button-hold switch-mirror. This also
   closes the Phase-1 RGB re-check (only LED0 lit last time; fixed).
2. **Power off, wire the LCD** per the table below, double-checking your
   module's silkscreen (pin order varies between ST7735 boards).
3. **Phase 2a**: flash the *toy* firmware variant and watch the screen.

**What the LCD shows:** a big orange **ARF** logo, the
`minimal-ibex-soc` title bar, the core/kernel/memory banner, then a live
status block refreshed every second — uptime (with a rotating `|/-\`
"alive" spinner), tick count, LED pattern + speed, last key pressed, RGB
mode, heartbeat state, OLED/BME presence, and the temperature once a
BME280 joins. Keys typed in PuTTY update the screen within a second: that
round trip (UART RX → task state → SPI text render) is itself the test.

*Why it stays smooth:* code executes in place from flash (~500× slower
than SRAM, gotcha 19), so the firmware keeps a shadow copy of the live
block and redraws **only the characters that changed** each second — a
handful of cells, tens of milliseconds. Only the one-time boot draw takes
a moment.

The toy firmware is missing-part tolerant — every I2C wait is bounded, so
the un-wired OLED/BME280 just show as `--` on screen and
`oled=... bme=... (0=ok)` non-zero on UART; nothing hangs.

### ST7735 LCD (SPI) — wiring to the Arty ChipKit analog header

| LCD pin | Signal | FPGA pin | Header label |
|---|---|---|---|
| VCC / GND | 3.3 V / GND | — | power header 3V3 / GND |
| CS | DISP_CTRL[0] | B7 | A6 |
| RESET | DISP_CTRL[1] | B6 | A7 |
| A0 / DC | DISP_CTRL[2] | E6 | A8 |
| SDA / MOSI | SPI_TX | E5 | A9 |
| SCK | SPI_SCK | A4 | A10 |
| LED / BL | DISP_CTRL[3] | A3 | A11 |

Contract: SPI host mode 0, MSB first, 5 MHz; FIFO-empty ≠ shifter idle —
allow ~32 clocks drain before toggling DC. Verify silkscreen before power.

### BME280 + SSD1306 (I2C) — Pmod JA, shared bus

| Module pin | Connect to |
|---|---|
| VCC / GND | Pmod JA pin 6 (3.3 V) / pin 5 (GND) via breadboard rails |
| SCL | Pmod JA pin 1 (G13) |
| SDA | Pmod JA pin 2 (B11) |

Open-drain with XDC pull-ups + module pull-ups; OpenCores master at 100 kHz.

### Simulation evidence (2026-08-08, both PASS)

- **tb_lcd 5/5**: full 26-byte init + pixel sequence decoded by a
  behavioural ST7735 model (found the sample-on-driving-edge race — SPI
  models must sample a delayed copy).
- **tb_i2c**: full register read through the team's `i2c_slave_bfm` — found
  and fixed a real BFM bug (read path released SDA on rising SCL = phantom
  STOP). The same driver sequence reads the BME280 chip-ID on hardware.
