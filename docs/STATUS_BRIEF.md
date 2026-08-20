# Status Brief — Lead Review (updated 2026-08-19)

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
| Full regression (11 simulations + bitstream) | **15/15 PASS** in xsim, timing met; **cross-checked ALL GREEN under Verilator 5** — incl. `tb_soc-dffram`, the ASIC-SRAM (DFFRAM) configuration — on **two hosts**: MSYS2/Windows (Verilator 5.050) and a fresh Ubuntu 24.04 (5.020, full `deps`→`regression` 13/13) |
| Firmware | **One** FreeRTOS image: console + LED/RGB/switch control + all drivers |
| **UART2 RX interrupt** (Ravi's items 3+4, 2026-08-17) | **Done & sim-proven**: fast IRQ 1 wired; IRQ-driven ESP-AT client with high-priority RX task + unsolicited-event parser; polled mode kept for bring-up |
| Lead's regression ask (item 5, sim part) | **Done**: `tb_uart2_irq` covers simultaneous UART1+UART2 traffic, 128-byte FIFO burst/overflow (exactly 128 kept of 160), IRQ vectoring, unsolicited events, post-overflow recovery |
| Toolchain-less lab PCs | **Unblocked twice over**: the GUI now auto-installs a native Windows RISC-V GCC (Install Missing Tools / offered inside Flash to Board - build-first policy), and a committed prebuilt remains as an explicit-choice fallback — fixes ARF-BBSR-84's "unable to dump" (programming had succeeded; the firmware build was failing for lack of RISC-V GCC) |
| Bugs found & fixed pre-silicon | **9** — the two newest both came from first physical contact (2026-08-18): a real **SPI mode-0 hold-time bug** in `spi_host.sv` (TX launched on the sampling edge; first physical ST7735 stayed white; sim had masked it because the models matched the RTL's race — fixed, full regression green, **fix must reach the PD netlist**, §6), and a **warm-reset boot crash** (firmware `.bss` clobbered the SRAM+0x80 XIP trampoline the boot ROM jumps to on every reset — fixed: linker reserves the region, startup re-writes it; exposes an ASIC first-boot question, §6) |
| Hardware validation | **Phase 1 COMPLETE and Phase 2a (LCD) PASSED 2026-08-18** (BRINGUP_TEST_REPORT secs. 8-9): FreeRTOS from QSPI flash, console sweep 8/8 scripted, all-4 RGB, and the ST7735 renders the live ARF status screen — after physical contact exposed and we fixed the SPI mode-0 and warm-reset-trampoline bugs. **Phase 2b (OLED + BME280) 2026-08-20 — OLED PASSED, sensor WIP**: first attempt read `oled=2 bme=2` (I2C bus held low; photo-diagnosed as junctions bunched in the breadboard's edge-rail columns), and after rewiring into proper field rows the SSD1306 runs its own live status screen (ARF logo, uptime/pattern/rgb, activity bar), **visually confirmed on the bench**. The BME280 answers at **no** address (boot bus scan prints `3C` only, re-confirmed after a re-solder) with power, CSB, SDO and continuity all verified at its pins → dead module, **replacement on order**; firmware path unchanged and sim-proven. Wiring diagram, decode table and multimeter procedure: PRODUCTION_PERIPHERALS §8. Same session root-caused a console cosmetic bug (patterns 1-3 shared state; keys looked dead after pattern 3 — fixed + regression-locked in tb_freertos) and Vivado's 2-thread Windows default (all .tcl now use 8). Then: Pmod touch-test (hands), batch-2 parts (Phase 3) |
| Docs | Consolidated 13 → 9 files; root README is the front door |
| Open decisions | **2** (below) + one watch-item: vendored Ibex is pinned at `594ea976` (2025-04) and upstream has moved 154 commits — we deliberately do NOT sync RTL pre-tapeout (the FPGA must validate the exact tapeout netlist); the 154 commits were AUDITED 2026-08-18: ~60% DV/formal/CI/docs, ~30% features we do not enable (Zcb/Zcmp, CHERIoT, SecureIbex/PMP/ICache hardening, U-mode counters), and no functional fix in the logic we tape out (closest: a minstret counter fix - unused by our firmware). Recommendation: stay pinned through tapeout; evaluate Zcmp (code density) for chip v2. FreeRTOS kernel synced to latest V11.3.0 (software, sim-verified) |

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
| **Phase 1** | Board back on desk | Re-validate all base IO on the current build: LEDs, RGB, patterns, speed, switches, buttons, UART both ways, Pmods, plus FreeRTOS boot from flash and power-cycle persistence. One flow: `ibex_soc.bat` → Flash to Board → PuTTY. ~1 session |
| **Phase 2a** | Now (no soldering) | ST7735 LCD only, jumper wires: live system-status screen (ARF logo) mirrors the PuTTY console — `ibex_soc.bat` → Flash to Board, nothing to select |
| **Phase 2b** | Now (parts in hand; ~10 header joints) | BME280, OLED join the same image, auto-detected + self-healing; logic-analyzer captures. Guide: PRODUCTION_PERIPHERALS §8 |
| **Phase 3** | Batch-2 parts (~₹1,800, awaiting approval) | PSRAM, ESP32/WiFi, mic, speaker, camera, then the full voice-AI loop |
| **Tapeout** | After decisions below | Reconcile RTL ↔ PD netlist, re-run regression on the frozen config, hand over to synthesis |

## 6. Lead decisions received 2026-08-19 — status of each

Ravi's reply resolved most of the open items. Where each stands on our side:

1. **UART2 in the tapeout netlist — YES** (decided). UART1 = host/debug,
   UART2 = dedicated ESP32 link, as shipped in v1.1.
   *Our follow-up:* "revalidate the exact RTL/netlist configuration going
   to PD on the FPGA" — the board already runs and passes on the full v1.1
   RTL (this repo's main). The final revalidation pass runs **when PD's
   merged.v / frozen file list exists**, so we bit-build exactly that
   configuration; blocked on receiving it, not on us.
2. **ASIC first boot — direct XIP chosen, and now IMPLEMENTED (2026-08-19)**:
   `rtl/system/boot.mem` jumps straight to `0x2040_0000`; no SRAM read at
   boot. Regressed as asked: `tb_xip` boots the real ROM with
   **uninitialised (X) SRAM** and `tb_freertos` with **deterministic
   random-garbage SRAM** — the exact silicon power-up condition — and
   the FPGA bitstream no longer bakes any SRAM image, so
   every board boot exercises the silicon path too. Legacy SRAM+0x80 entry
   kept alive by startup.S for debug flows.
3. **SPI mode-0 hold-time fix must reach PD — confirmed by lead.** The fix
   is in `spi_host.sv` on main and in PR #17. Sim models were additionally
   tightened (2026-08-19) to strict datasheet mode-0 slaves so any
   regression of this bug fails in simulation, not on a panel.
4. **DFFRAM (`740d59c9`) issues — RESOLVED in our tree (2026-08-19 evening,
   on a teammate's ifdef proposal, upgraded per Ravi's "no simulator
   ifdef" direction):** the SRAM storage array is now selected by a
   **`UseDffram` parameter** (default 0 = `sram_model`; 1 = `dffram`, the
   GF180 DFFRAM behavioral model with **per-byte WE**), so xsim, Verilator
   and Vivado all elaborate either SRAM deterministically — synthesis can
   never silently lose the SRAM. Regressed: `tb_soc-dffram` runs the full
   sb/sh-heavy console on the DFFRAM model in **both** simulators — that
   empirically proves byte/half-word writes (flag b). The team repo can
   lift `dffram.sv` + the wrapper_top select as-is.
5. **Verilator regression** — Shivanee's sign-off, and the infrastructure
   for it now exists (2026-08-19): `./ibex_soc.sh regression` runs **all
   10 full-SoC testbenches unmodified under Verilator 5** (`--timing`),
   same PASS criteria as the xsim suite, plus a FuseSoC wrapper
   (`minimal_ibex_soc.core`) with all three targets verified: `lint`
   green, `sim` 9/9, `synth` = full routed bitstream with timing met.
   All 11 sims (incl. `tb_soc-dffram`) verified green under Verilator
   5.050 on 2026-08-19 as a cross-check, and the same day the whole flow
   was re-proven end-to-end on a **fresh Ubuntu 24.04** (`deps` →
   regression **13/13** → lint → FuseSoC lint + sim, Verilator 5.020) —
   the independent sign-off *run* remains hers.

**Still needed from the lead:**

- **Pin plan sign-off:** 37 of Caravel's 38 user pads used, 1 spare.
- **Batch-2 parts approval** (~₹1,800) — unblocks Phase 3 (ESP32/WiFi
  on-board validation, Ravi's own checklist item 5).

