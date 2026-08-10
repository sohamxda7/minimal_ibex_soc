# Final Test — External Device ("Toy") Interfacing

*Agreed with the DV lead: the SoC's final acceptance test is driving real
external devices. Tier 1: ST7735 LCD over SPI. Tier 2: BME280 sensor +
SSD1306 OLED over I2C from FreeRTOS tasks. Method: simulation-first — behavioural
device models verify every byte in xsim before hardware is touched.*

## Tier 1 — ST7735 LCD (SPI)

### Interface contract (verified in RTL + upstream demo)

- SPI host @ `0x4000_0500`: TX byte at +0 (FIFO, 127 deep), STATUS at +4
  (bit0 = FIFO full, bit1 = FIFO empty). Mode 0, **MSB first**, SCK = 5 MHz.
  Note: FIFO-empty ≠ shifter idle — allow ~32 clocks drain before changing DC.
- LCD control pins = `GPIO_OUT[3:0]` (= `DISP_CTRL[3:0]`):
  bit0 = **CS**, bit1 = **RST**, bit2 = **DC** (0 cmd / 1 data), bit3 = **BL**.
- This SPI host updates MOSI on the rising SCK edge → receiver setup margin
  is a half period (fine at 5 MHz; also the source of a testbench sampling
  race — see Findings).

### Simulation (2026-08-08) — PASS 5/5

Program: `sw/asm-demo/lcd_spi_test.py` (hand-assembled, 107 instr; `--sim`
variant has short delays, hardware variant has the datasheet 120 ms waits).
Testbench: `dv/xsim/tb_lcd.sv` — behavioural ST7735 model on the SoC's
actual pins, decoding and checking the full 26-byte sequence:

```
HW reset pulse -> SWRESET -> SLPOUT -> COLMOD(05=RGB565) -> DISPON
-> CASET(0..4) -> RASET(0..4) -> RAMWR + 5 red pixels (F8 00 x5)
PASS: full init + pixel sequence matches, incl. cmd/data DC phases
PASS: 'LCD OK' printed over UART; backlight left on
=== RESULTS: 5 PASS, 0 FAIL ===
```

**Finding (caught by sim, would have cost a bench day):** sampling MOSI on
the same rising edge the host updates it races in simulation — every byte
arrived left-shifted by one. Fixed in the model by sampling a
propagation-delayed copy (what a real panel's setup time does). Real
hardware is unaffected; lesson recorded for future SPI testbenches.

### Hardware wiring (when the module arrives)

Module (red ST7735 board, pre-soldered) → Arty **ChipKit analog header**:

| LCD pin | Signal | FPGA pin | Board header label |
|---|---|---|---|
| VCC | 3.3 V | — | 3V3 (power header) |
| GND | GND | — | GND (power header) |
| CS | DISP_CTRL[0] | B7 | A6 |
| RESET | DISP_CTRL[1] | B6 | A7 |
| A0 / DC | DISP_CTRL[2] | E6 | A8 |
| SDA / MOSI | SPI_TX | E5 | A9 |
| SCK | SPI_SCK | A4 | A10 |
| LED / BL | DISP_CTRL[3] | A3 | A11 |

(Header labels per the upstream ibex-demo-system Arty hookup — verify
against the board silkscreen before powering.)

Hardware test: build with `-tclargs sw/asm-demo/lcd_spi_test.vmem` (or run
the upstream C demo once a RISC-V GCC is available) → red pixels appear in
the 5×5 window top-left. Capture SPI with the logic analyzer for the report.

## Tier 2 — I2C devices from FreeRTOS (BME280 + SSD1306)

### Pin-out (done)

`I2C_SCL` / `I2C_SDA` routed to **Pmod JA pins 1 (G13) / 2 (B11)** as an
open-drain bus (OpenCores pad-enable is active low), internal pull-ups in
the XDC plus the sensor modules' onboard pull-ups.

Hardware wiring when the parts arrive (both devices share the bus):

| Module pin | Connect to |
|---|---|
| VCC / VDD | Pmod JA pin 6 (3.3 V) via breadboard rail |
| GND | Pmod JA pin 5 (GND) via breadboard rail |
| SCL / SCK | Pmod JA pin 1 |
| SDA | Pmod JA pin 2 |

### Simulation (2026-08-08) — PASS

Program `sw/asm-demo/i2c_test.py` drives the OpenCores master
(PRER=39 -> 100 kHz @ 20 MHz) through a full register read of the team's
`i2c_slave_bfm` (EEPROM-style slave, addr 0x50, mem[i]=i): START, addr+W,
pointer 0x42, repeated START, addr+R, read+NACK, STOP -> byte 0x42
verified by the CPU, "I2C OK" on the UART (`dv/xsim/tb_i2c.sv`).
The same driver sequence reads the BME280 chip-ID (reg 0xD0 -> 0x60) on
real hardware.

**Finding — genuine bug found and fixed in the team's `i2c_slave_bfm`:**
the ST_READ path released SDA on a rising SCL edge after the last data
bit, making SDA rise while SCL was high — a phantom STOP condition that
also corrupted the final bit as sampled by the master. This is the same
bug class the BFM's own ST_ACK_ADDR comments describe having fixed
before; the read path had been missed. Fixed by releasing on the
following falling edge (and removing an equally unsafe pre-drive on the
multi-byte ACK path). The integration sim caught what unit testing had
not.

### Remaining for Tier 2

~~Zephyr devicetree nodes~~ Superseded by the FreeRTOS pivot
([ASIC_SPEC.md](ASIC_SPEC.md) / [FREERTOS_PORT.md](FREERTOS_PORT.md)):
C drivers now exist in `sw/freertos/drivers/` (i2c.c helper over the
OpenCores core, bme280.c forced-mode with 32-bit compensation, ssd1306.c
zero-framebuffer text, st7735.c for Tier 1) plus a `toy` demo task
(`build.bat toy`) that shows a BME280 reading on UART + OLED every 2 s.
All compile-clean; hardware run pending parts delivery.

## Purchases (verified listings, ~₹4,550)

ST7735 1.8" SPI (pre-soldered) · BME280 I2C 3.3 V (genuine) · SSD1306 OLED
I2C 4-pin · 80× M-F jumpers · 840-pt breadboard kit · 24 MHz/8ch logic
analyzer (Saleae-compatible) · Mextech DT830 PRO multimeter (True RMS,
continuity beeper) · 60 W soldering kit (10 header joints needed
on BME280 + OLED). Links in the procurement email / chat log.
