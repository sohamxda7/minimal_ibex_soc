# ASIC Tapeout Specification — Digest

**Source:** team specification bundle `opentitan_minimal_guide` (HTML, 14 chapters:
index, quick start, environment, streams 1–9, appendices A–C). This document
digests the parts that constrain work in this repository. When in doubt, the
original guide wins — ask the team for the latest copy.

**What the guide is:** a complete RTL-to-silicon plan for taping out this SoC on
**GF180MCU (180 nm)** through the **Efabless Caravel shuttle** using the
open-source flow (`sv2v → Yosys → OpenROAD`). Everything we do on the Arty A7 is
**Stream 5: FPGA Validation** of that plan — the rehearsal before committing to
silicon (an ASIC respin costs $50K+; an FPGA reflash takes seconds).

---

## 1. Chip-level parameters (the spec we must track)

| Parameter | Value | Rationale |
|---|---|---|
| CPU | Ibex RV32IMC | Silicon-proven (Azadi, OpenMPW-1) |
| Platform | ibex-demo-system fork (this repo) | Minimal Ibex SoC, Arty A7 target |
| Bus | Wishbone (via OBI bridge) | Caravel-native |
| **SRAM** | **8 KB** (DFFRAM macro + SRAM controller) | Area budget — see §2 |
| Boot ROM | 4 KB, synthesized | Initial boot code |
| External memory | SPI flash, XIP, up to 16 MB | Larger programs (**FreeRTOS**) |
| Peripherals | UART, JTAG, 8-bit GPIO, RV Timer, I2C, SPI Host | Sensor/peripheral I/O |
| Interrupts | Flat — 7 sources direct to Ibex fast IRQs (no PLIC) | PLIC ≈ 5 kGE, unnecessary |
| Target frequency | **20 MHz** (ASIC) | Prior art on open EDA: 12–25 MHz |
| Gate count | ~44 kGE excl. SRAM | Fits Caravel user area |
| PDK | GF180MCU (`gf180mcuD`), cells `gf180mcu_fd_sc_mcu7t5v0` | Best memory/cell support |
| Security | **None** — educational design | Open JTAG, no PMP; see §8 |

### Ibex core configuration (Stream 1)

```
PMPEnable=0, MHPMCounterNum=0, RV32E=0, RV32M=RV32MSingleCycle, RV32B=None,
WritebackStage=0 (2-stage pipeline), ICache=0, BranchPrediction=0,
DbgTriggerEn=0, SecureIbex=0, DmHaltAddr=DmExceptionAddr=0x00100000
```

≈25 kGE. **ICache is disabled** — this makes XIP fetch speed a real concern (§4).

## 2. Why SRAM is capped at 8 KB (the area budget)

DFFRAM builds SRAM out of standard-cell flip-flops (no true 6T bitcells in this
flow), so it is area-hungry. The Caravel user area is **~10.27 mm² (2920 × 3520 µm)**:

| SRAM size | Est. area (GF180MCU) | Fits Caravel? |
|---|---|---|
| 4 KB | ~0.9 mm² | Yes |
| **8 KB** | **~1.8 mm²** | **Yes (chosen)** |
| 16 KB | ~3.5 mm² | Yes |
| 32 KB | ~7.0 mm² | Tight |
| 64 KB | ~14.0 mm² | **No** — exceeds user area before any logic |

Planned floorplan: DFFRAM ~1.8 mm² + logic (~44 kGE) ~4.0 mm² + power/routing
~1.5 mm² + IO ~0.5 mm² ≈ **7.8 mm² (~76% utilization, ~29% margin)**.

> **Consequence for this repo:** the FPGA build's SRAM default is 8 KiB so the
> validated configuration matches silicon. Programs larger than 8 KiB run from
> SPI flash via XIP.

## 3. Memory map (Stream 1)

| Start | Size | Block | Notes |
|---|---|---|---|
| `0x0010_0000` | 4 KB | Boot ROM | Reset vector; synthesized |
| `0x0010_2000` | 8 KB | SRAM | *(team-confirmed base, 2026-08-10; the guide's printed `0x0010_1000` is superseded)* |
| `0x2000_0000` | 256 MB window | SPI Flash XIP | External, read-only, memory-mapped |
| `0x4000_0000` | 256 B | UART | |
| `0x4000_0100` | 256 B | GPIO | 8-bit |
| `0x4000_0200` | 256 B | RV Timer | mtime/mtimecmp (CLINT-style) |
| `0x4000_0300` | 256 B | SPI Control | Flash config registers *(not yet in RTL)* |
| `0x4000_0400` | 256 B | I2C | OpenCores master |
| `0x4000_0500` | 256 B | SPI Host | General-purpose master |

### Known deviations in this repo (flagged to team, pending decision)

| Item | Spec | This repo | Status |
|---|---|---|---|
| SRAM base | ~~`0x0010_1000`~~ | `0x0010_2000` | **RESOLVED 2026-08-10: team confirmed `0x0010_2000` is correct** (the guide's printed value is stale). Boot ROM jump contract (entry = SRAM+0x80 = `0x0010_2080`) stands. |
| PWM block | absent | `0x4000_0600` (12 ch, RGB demo) | Not in the ASIC gate budget. Team must decide: keep (adds gates) or FPGA-only. |
| SPI control regs | `0x4000_0300` | absent (XIP has no CSRs) | Fine for now — XIP controller is fixed-function. |

### Interrupt plan (spec)

Flat wiring to Ibex fast IRQs: UART RX=fast[0], UART TX=fast[1], Timer=fast[2],
GPIO=fast[3], I2C done=fast[4], I2C arb-lost=fast[5], SPI host done=fast[6].
8 of 15 fast inputs remain free.

## 4. SPI Flash XIP (Streams 1 & 3) — the key enabler

With 8 KB SRAM, execute-in-place from external SPI NOR flash is **essential**:

- Memory-mapped at `0x2000_0000`, 24-bit flash address (16 MB reach)
- SPI Mode 0, **single-bit** SPI (not quad — fewer pins, simpler), read command `0x03`
- One 32-bit read = 8 (cmd) + 24 (addr) + 32 (data) = **64 SPI clocks**
- At 20 MHz system clock, `CLK_DIV=4` → 2.5 MHz SPI → **~26 µs per word**

**Performance reality:** with ICache disabled, straight-line XIP code executes
~500× slower than SRAM code. The guide's intended pattern: boot ROM (or startup
code) copies hot code to SRAM; cold paths and big constants XIP from flash.
FreeRTOS kernel hot paths in SRAM, application code XIP.

**Boot flow (spec):** reset vector `0x0010_0000` (boot ROM) → set SP → clear
BSS → jump to main in SRAM *or* directly into the XIP window.

This repo already implements the controller (`rtl/system/spi_flash_xip.sv`,
decoded at `0x2000_0000` in `wb_interconnect.sv`); simulation proof and board
wiring are tracked in [FPGA_BRINGUP.md](FPGA_BRINGUP.md).

## 5. FPGA validation (Stream 5) — our stream

The guide targets Arty A7-35T; we validate on **A7-100T** (same family, more
resources — utilization numbers only get more comfortable). Expected usage:
~8–10K LUTs, 4–8 BRAMs, well under 30% of even the -35T.

Validation checklist from the spec (✓ = already demonstrated in this repo):

- ✓ UART hello/banner output
- ✓ GPIO LEDs test pattern
- ✓ Timer interrupt at correct interval (UART-command demo speed control)
- ✓ I2C register read/write to attached peripheral (sim: team BFM; hw: pending parts)
- ✓ SPI host transfer (sim: ST7735 model; hw: pending parts)
- ☐ JTAG halt/resume/single-step via OpenOCD
- ☐ SPI flash XIP read on hardware
- ☐ Software interrupt delivery
- ☐ SPI host loopback (MOSI→MISO jumper)

Note: the guide's XDC maps external SPI flash to Pmod JA — **we instead use the
Arty's onboard 16 MB QSPI flash** (CS=L13, DQ0=K17, DQ1=K18; SCK via `STARTUPE2`
because the flash clock is the FPGA's dedicated configuration pin). Same
controller, no extra hardware needed.

## 6. ASIC flow summary (Streams 2, 6–9) — the team's work downstream of us

1. **sv2v** converts all SystemVerilog to Verilog-2005 (Yosys can't parse SV).
   Proven on Ibex (Azadi). Assertions are stripped — expected and safe.
2. **Yosys** synthesis via OpenLane 2: `SYNTH_STRATEGY "AREA 2"`, 50 ns clock,
   die area 3100×3100 µm, DFFRAM instantiated as a hard macro (GDS/LEF/LIB),
   placed lower-left; target density 45%.
3. **OpenROAD** P&R → GDSII; signoff = Magic DRC + Netgen LVS + OpenSTA.
4. **Gate-level sim** (Icarus + SDF), post-synth and post-route, run inside the
   Caravel wrapper.
5. **Tapeout:** Efabless chipIgnite/OpenMPW GF180MCU shuttle; ~300 packaged
   QFN-64 chips returned; automated precheck before submission.

### Caravel integration facts that affect firmware

In Caravel, our SoC **does not boot autonomously**. The management SoC (a
VexRiscv) boots first and must: configure the IO mux to route our UART/JTAG/
GPIO/I2C/SPI pins to pads, enable the user-area clock, then release our reset.
The management firmware (`caravel_mgmt_firmware.c`) is part of the tapeout
deliverables. Our design also exposes a Wishbone *slave* port to the management
SoC (it can write memory before releasing reset).

## 7. Alternatives considered (Appendix B — abridged)

- **Cores:** Ibex chosen over PicoRV32 (~5 kGE but no debug module), VexRiscv
  (Scala toolchain), NEORV32 (no ASIC track record), SERV (tiny but bit-serial).
  Reasons: silicon-proven, sv2v-clean, built-in RISC-V debug, lowRISC ecosystem.
- **PDK:** GF180MCU over sky130 (better cell library maturity, DFFRAM variant,
  active shuttle) — sky130 viable fallback.
- **Memory:** DFFRAM over OpenRAM (simpler integration, better tested on
  gf180mcuD; OpenRAM denser but needs SRAM-specific process rules).

## 8. Security posture (Appendix C — read before anyone ships this)

**Zero security hardening, permanently.** Open unauthenticated JTAG (full CPU
halt/memory/CSR access), no PMP (any code reaches everything), no secure boot,
no flash encryption (firmware readable off the SPI bus), no glitch detectors.
On FPGA this is normal development practice; **on the ASIC it is baked into
silicon forever**. The guide is explicit: educational/prototyping only, never
production. All OpenTitan security IP (AES, HMAC, KMAC, OTBN, keymgr, OTP,
lifecycle, alert handler, entropy) was deliberately removed — ~271 kGE saved.

## 9. What this spec means for work in this repo

1. **SRAM = 8 KiB default** in RTL parameters; the 128 KiB configuration is
   history (it validated the fabric but is not silicon-representative).
2. **Firmware model = XIP**: code in SPI flash at `0x2000_0000`, data/stack in
   8 KiB SRAM. On the Arty we use the onboard QSPI flash behind the bitstream.
3. **RTOS = FreeRTOS** — named by the spec itself, and the only mainstream RTOS
   comfortable in 8 KiB RAM. (The earlier Zephyr port was built against the
   128 KiB dev configuration and was removed when the 8 KiB constraint landed —
   decision trail in [ZEPHYR_DECISION.md](ZEPHYR_DECISION.md).)
4. **20 MHz stays the system clock** — same number the ASIC targets.
5. Everything we validate on the FPGA must be in the **same configuration the
   chip will have** (8 KiB SRAM, XIP boot, flat IRQs), or it isn't validation.
