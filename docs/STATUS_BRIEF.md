# Status Brief — Lead Review (updated 2026-08-18)

One-page state of the Ibex SoC programme: what is done, what was chosen and
why, what needs your sign-off today, and what happens next.
Deep detail lives in [ASIC_SPEC.md](ASIC_SPEC.md),
[PRODUCTION_PERIPHERALS.md](PRODUCTION_PERIPHERALS.md),
[HW_VALIDATION_PLAN.md](HW_VALIDATION_PLAN.md).

---

## 1. Where we are

The SoC is **feature-complete for v1 and fully proven in simulation**. Every
subsystem — the original SoC plus WiFi, camera, mic, speaker and external
memory — passes full-SoC RTL simulation, and the FPGA bitstream builds with
all timing constraints met.

| Area | State |
|---|---|
| Full regression (10 simulations + bitstream) | **14/14 PASS**, timing met |
| Firmware | **One** FreeRTOS image: console + LED/RGB/switch control + all drivers |
| **UART2 RX interrupt** (Ravi's items 3+4, 2026-08-17) | **Done & sim-proven**: fast IRQ 1 wired; IRQ-driven ESP-AT client with high-priority RX task + unsolicited-event parser; polled mode kept for bring-up |
| Lead's regression ask (item 5, sim part) | **Done**: `tb_uart2_irq` covers simultaneous UART1+UART2 traffic, 128-byte FIFO burst/overflow (exactly 128 kept of 160), IRQ vectoring, unsolicited events, post-overflow recovery |
| Toolchain-less lab PCs | **Unblocked**: `flash_freertos.bat` falls back to a committed prebuilt firmware — fixes ARF-BBSR-84's "unable to dump" (programming had succeeded; the firmware build was failing for lack of RISC-V GCC) |
| Bugs found & fixed pre-silicon | 7 (incl. 3 in the untested XIP controller, 1 in the team I2C BFM) |
| Hardware validation | **Owed** — last board test was the old config; plan ready, waiting on board + parts |
| Docs | Consolidated 13 → 9 files; root README is the front door |
| Open decisions | **2** (below) |

**Guiding rule adopted:** the ASIC is the product; the FPGA is only its
pre-silicon validation vehicle. Nothing is built that cannot run on the
fabricated chip.

## 2. What was selected in each phase, and why

| Phase | Decision | Why |
|---|---|---|
| Memory | **8 KiB SRAM** kept as spec'd; bulk data moves to **external 8 MB SPI PSRAM** | 8 KiB is a die-area law (64 KiB DFFRAM ≈ 14 mm² > the 10.27 mm² user area). PSRAM is a driver-accessed *store*, not CPU/stack memory — so the area budget is untouched |
| Code storage | **XIP from 16 MB QSPI flash** | Programs larger than 8 KiB execute in place; validated end-to-end in simulation |
| RTOS | **FreeRTOS** | Runs in ~4 KiB RAM, named by the tapeout spec, boots and schedules over XIP. Zephyr's RAM floor does not fit v1 — deferred to chip v2 |
| Peripherals | **External-first**: ESP32 (WiFi), OV7670-FIFO (camera), MCP3202+MAX9814 (mic), PAM8302 (speaker), APS6404 (PSRAM) | Keeps silicon small and low-risk; all the heavy lifting sits on the carrier board, exactly like production embedded systems |
| Silicon additions for v1.1 | **UART2**, **SPI-host RX register**, **GPIO 8→16** | ≈ +2 kGE total (~76% → ~78% utilization). Everything else reuses buses the chip already had |

## 3. Why UART2 is needed (decision #1)

**UART2 is the chip's entire internet path — nothing else uses it.**
The ESP32 module owns the radio and the TCP/IP stack; our chip sends it
text (AT) commands over UART2 and receives replies. Camera, mic, speaker and
PSRAM do **not** touch UART2.

- **Cost:** ~1.5 kGE ≈ 0.14 mm² (against ~2.4 mm² of margin) and 2 pins.
- **Why not share UART1:** UART1 is the debug console. Sharing means every
  log line is fed to the modem as garbage, AT replies interleave with console
  output, and we lose all visibility exactly when networking breaks — i.e.
  debugging first silicon blind. Time-sharing or an external mux both work
  but remove concurrency and add cost. Every commercial MCU (including the
  ESP32 itself) ships multiple UARTs for this reason.
- **Status:** implemented and simulation-proven (`tb_wifi`: AT → OK round
  trip; `tb_uart2_irq`: interrupt delivery, FIFO burst/overflow, recovery,
  console alive throughout). Per Ravi's direction (2026-08-17) UART2 RX now
  rides Ibex **fast IRQ 1** with a high-priority receive task and an
  unsolicited ESP-AT event parser — the chip never misses a `WIFI
  DISCONNECT` or `+IPD` even mid-command. **Still not in the PD synthesis
  netlist** — see §6.

**If the answer is "no internet in v1":** drop UART2 cleanly; camera, mic,
speaker and PSRAM all still work, and internet becomes a chip-v2 item.

## 4. How everything else is interfaced (no new silicon)

| Function | Interface used | Silicon impact |
|---|---|---|
| **External memory** (8 MB PSRAM) | Existing SPI host + one chip-select on GPIO | RX register only |
| **Camera** (OV7670 + AL422 FIFO) | Module's own 384 KB FIFO → 8-bit read over GPIO → PSRAM; config over existing I2C | GPIO width only |
| **Mic** | MCP3202 ADC on the same SPI host + one chip-select | none |
| **Speaker** | Existing PWM channel → external amplifier | none |
| **Sensors / display** (BME280, SSD1306, ST7735) | Existing I2C and SPI host | none |

Honest ceilings, stated up front: camera = **snapshots, not video**;
speaker = tones and 8-bit clips, not hi-fi; mic = detection and clip capture.
The voice-AI use case works as record → PSRAM → ESP32 → cloud AI → play.

## 5. Next plan

| Phase | Trigger | Content |
|---|---|---|
| **Phase 1** | Board back on desk | Re-validate all base IO on the current build: LEDs, RGB, patterns, speed, switches, buttons, UART both ways, Pmods, plus FreeRTOS boot from flash and power-cycle persistence. One flow: `flash_freertos.bat` → PuTTY. ~1 session |
| **Phase 2** | Batch-1 parts (in transit) | LCD, BME280, OLED bring-up with logic-analyzer captures |
| **Phase 3** | Batch-2 parts (~₹1,800, awaiting approval) | PSRAM, ESP32/WiFi, mic, speaker, camera, then the full voice-AI loop |
| **Tapeout** | After decisions below | Reconcile RTL ↔ PD netlist, re-run regression on the frozen config, hand over to synthesis |

## 6. Decisions needed from you today

1. **UART2 in the tapeout netlist — yes or no?** (§3). PD's current synthesis
   netlist does **not** include the v1.1 additions, while the FPGA validates
   RTL that does. Either answer is workable; the mismatch is not — whatever
   is decided, the FPGA must re-validate exactly the netlist being taped out.
   Files affected if included: `spi_top.sv`, `wb_interconnect.sv`,
   `wrapper_top.sv`, `ibex_demo_system.sv` (UART2 reuses the existing UART
   module — no new blocks; GPIO change is parameter-only; the 2026-08-17
   RX-interrupt wiring lives in the same two system files and adds ~zero
   gates — the UART already generated the IRQ signal).
2. **Pin plan sign-off:** 37 of Caravel's 38 user pads used, 1 spare.
3. **Batch-2 parts approval** (~₹1,800) so Phase 3 is not blocked on shipping.

