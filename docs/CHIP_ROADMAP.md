# Chip Roadmap — "Everything on our own silicon" as a plan, not a tapeout

The team's goal is maximum capability on our own chips. That is a **roadmap**:
every silicon company ships it across generations, with companion chips for
the pieces nobody puts on-die at this tier. Reference point: Apple does not
put WiFi on the A-series — iPhones carry Broadcom radio silicon next to it.

## v1 — NOW (frozen, validated, this repository)

GF180MCU / Caravel, ~44 kGE + 8 KiB DFFRAM, 20 MHz, FreeRTOS over XIP.
With the v1.1 additions (UART2, SPI RX, GPIO 16/16 —
[PRODUCTION_PERIPHERALS.md](PRODUCTION_PERIPHERALS.md)) and external parts,
v1 silicon delivers: sensors, display, real-time control, **internet via
ESP32**, **camera snapshots**, **audio in/out**, and the cloud-AI voice loop.

**Freeze discipline:** nothing else enters v1. Feature creep before tapeout
freeze is how first chips die. Everything below is v2+ material.

## v2 — the multimedia MCU (next shuttle, ~6–12 months after v1 returns)

| Upgrade | Enables | Feasibility |
|---|---|---|
| **OpenRAM 6T SRAM, 32–64 KB** | Zephyr (its RAM floor), bigger apps, audio DSP | OpenRAM has GF180 support; denser than DFFRAM; needs macro validation |
| **HyperRAM/PSRAM parallel controller** (~4 kGE, ~12 pins) | Megabytes at ~100 MB/s — camera comfort, buffering without the SPI bottleneck | Digital-only controller; proven on open shuttles |
| **I2S in/out** (~3 kGE) | Proper digital audio (mics, DACs) replacing ADC/PWM paths | Straightforward RTL |
| **Camera parallel port + line FIFO** | Faster capture than the AL422 crutch | Pin-budget driven; may need a non-Caravel pad ring |
| Ibex ICache enable (~+5 kGE + RAM macros) | XIP speed ~10× | Config flag + area |
| 40–50 MHz target | 2–2.5× compute | Prior art on GF180 supports it |

v2 planning starts by measuring v1 silicon: real XIP timings, real power,
real IO behavior — that data sets v2's frequency and memory targets.

## Never on-die at this tier (and that's industry-normal)

| Item | Why not | The production answer |
|---|---|---|
| **WiFi radio** | RF analog design; the open GF180 PDK has no radio IP; a radio team is years of work (Espressif's whole company = they did this once, well) | ESP32-class companion — same as v1 |
| **AI inference** | NPU + DRAM bandwidth + modern node = $$$M | Cloud (v1 already does this) or a Pi-class companion when latency demands it |

## Life after tapeout: the carrier board

When the ~300 QFN-64 packages return from Efabless, the chip needs a home: a
**carrier PCB** — schematic + layout, the same discipline as IC physical
design at centimeter scale. It carries: the chip, QSPI flash (code), PSRAM,
ESP32, mic/amp/speaker, camera connector, I2C sensors, power + decoupling,
reset, and a USB-UART bridge for the console. The Arty A7 is the rehearsal
for this board — every interface we validate there becomes a copper trace
here, which is why the FPGA pin map mirrors the chip pin plan
(37/38 pads, PRODUCTION_PERIPHERALS.md §1).

Deliverable when v1 ships: `hw/carrier-board/` KiCad project. Owner: TBD
(PD team's board-design bench is the natural fit).

## Decision log

- 2026-08-10: doctrine set (ASIC is the product; FPGA validates only).
- 2026-08-10: external-first v1.1 architecture chosen over on-die expansion —
  judged against the Caravel area/pin budget in [ASIC_SPEC.md](ASIC_SPEC.md);
  camera/Zephyr/radio explicitly deferred (v2 / never-on-die respectively).
