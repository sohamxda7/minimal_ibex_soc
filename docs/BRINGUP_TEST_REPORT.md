# Ibex SoC Bring-up — Test Report

| | |
|---|---|
| **Date** | 2026-08-07 |
| **Board** | Digilent Arty A7-100T (XC7A100T-CSG324-1) |
| **Bitstream** | `build/fpga/top_artya7.bit` (3.6 MB), branch `fix/fpga-bringup` |
| **Tools** | Vivado / xsim v2026.1 (64-bit), Windows 11 Pro, Python 3.13 |
| **System clock** | 20 MHz (PLL: 100 MHz × 12 / 60) |
| **UART** | 115200 8N1 over the board's USB (COM4 on the test PC) |
| **Program** | `sw/asm-demo/sram_init.vmem` — 99 RV32IM instructions, entry 0x0010_2080 |

## 1. Build results

| Check | Result |
|---|---|
| Synthesis + place + route (`build_fpga.tcl`) | ✅ PASS — `BUILD OK` |
| Timing | ✅ "All user specified timing constraints are met" |
| Utilisation | 6148 LUTs (9.7 % of XC7A100T), 2.5 BRAM tiles |
| Boot ROM image read at synth | ✅ `rtl/system/boot.mem` "read successfully" |
| **SRAM program image read at synth** | ✅ `sw/asm-demo/sram_init.vmem` "read successfully" — the key fix; `SRAMInitFile` log-verified bound at every hierarchy level |

## 2. Full-SoC simulation (xsim), sped-up program image

Command sequence in `docs/BRINGUP_HISTORY.md` (sec. 4). Sim time 7 ms, all checks pass:

```
PASS: UART TX produced 32 bytes            (IBEX-SOC UP banner x2 + echo)
PASS: UART RX echo ('K' came back)
PASS: LEDs changed 4 times                 (walking pattern)
PASS: LEDs mirror switches while button held (gp_o=01010000, SW=0101)
RGB0 red duty samples every 100 us:
  0, 16, 38, 58, 68, 100, 120, 140, 164, ... 918 / 2000
  -> monotonic ramp = smooth breathing, NO glitching
```

The former "RGB glitch" cannot occur any more: it required (a) the CPU
executing empty SRAM — impossible now that the program is in the bitstream —
and (b) the 0.5 ms software timer tick, corrected to 0.1 s.

## 3. On-board results (Arty A7-100T)

| Test | Method | Result |
|---|---|---|
| Programming over USB-JTAG | `program_fpga.bat` | ✅ "BOARD PROGRAMMED" |
| CPU boots and runs | UART capture on COM4 | ✅ received `IBEX-SOC UP 0`, `IBEX-SOC UP 1` (heartbeat ~2 s) |
| UART FPGA→PC framing/baud | same capture, clean ASCII at 115200 | ✅ PASS |
| UART PC→FPGA echo | scripted: sent `A`, read back | ✅ got `A` (followed by next banner bytes) |
| Green LED walking pattern | visual | ✅ observed |
| RGB breathing red→green→blue, smooth | visual | ✅ observed — glitch gone |
| Button → LEDs mirror switches | visual | ✅ observed |

Raw UART capture from the verification script:

```
IBEX-SOC UP 0
IBEX-SOC UP 1
echo test: sent A, got b'AIBEX-SO'
```

## 4. UART command interface (added later the same day — see docs/BRINGUP_HISTORY.md sec. 5)

Simulation: **9/9 checks PASS** (pattern switch visible on gp_o, forced-blue
with red channel measured silent, acks, button override).

Hardware (scripted via `util/uart_command_test.py` on COM4):

```
IBEX-SOC UP 0
IBEX-SOC UP 1
PASS: '3' (pattern 3 (alternating)) acked=yes
PASS: 'b' (RGB force blue) acked=yes
PASS: 'f' (speed fast) acked=yes
PASS: '2' (pattern 2 (nibble flip)) acked=yes
PASS: 'r' (RGB force red) acked=yes
PASS: 'a' (RGB auto-cycle) acked=yes
PASS: 'm' (speed medium) acked=yes
PASS: 'K' (plain echo of non-command byte) acked=yes
overall: ALL PASS
```

### Manual verification by the user (PuTTY session, COM4 @ 115200)

All commands exercised by hand; user confirmed patterns, speeds and RGB
colours changed on the board as commanded ("nice all worked"):

```
IBEX-SOC UP 0
IBEX-SOC UP 1
1IBEX-SOC UP 2
23IBEX-SOC UP 3
IBEX-SOC UP 4
4IBEX-SOC UP 5
1IBEX-SOC UP 6
2IBEX-SOC UP 7
IBEX-SOC UP 8
34IBEX-SOC UP 9
IBEX-SOC UP 0
fIBEX-SOC UP 1
IBEX-SOC UP 2
mIBEX-SOC UP 3
srgIBEX-SOC UP 4
bwaIBEX-SOC UP 5
IBEX-SOC UP 6
```

Reading this log: the stray characters (`1`, `23`, `f`, `srg`, `bwa`, …)
are the **command acknowledgements** — each typed key is echoed by the FPGA
and lands wherever the cursor happens to be, interleaved with the
asynchronous `IBEX-SOC UP <n>` heartbeat. This interleaving is normal and
expected; it is not corruption.

## 5. Simulation round 2 (2026-08-10) — ASIC-spec configuration

All reruns on the **8 KiB SRAM** configuration mandated by the tapeout spec
([ASIC_SPEC.md](ASIC_SPEC.md)); logs in `build/*.log`.

| Test | Bench | Result |
|---|---|---|
| SoC demo (UART cmds, patterns, GPIO) | tb_soc | **9/9 PASS** |
| ST7735 LCD byte-exact init+draw | tb_lcd | **5/5 PASS** |
| I2C master <-> slave BFM register read | tb_i2c | **PASS** |
| **XIP: CPU executes from SPI flash** | tb_xip (new) | **PASS** (after 3 controller fixes) |
| **FreeRTOS boots + schedules over XIP** | tb_freertos (new) | **PASS** (banner @~6 ms sim, 2 tick reports; one benign xsim `Multiple conditions true` unique-case warning during the tick trap, pre-existing RTL) |
| Bitstream (8 KiB + QSPI/STARTUPE2 wiring) | build_fpga.tcl | **BUILD OK, all timing constraints met** |

**PWM-decision verification (2026-08-10, build/pwm_check.log):** after the
team confirmed the PWM block stays in BOTH FPGA and ASIC, a confirming run
was executed: tb_soc **9/9 PASS** (including the two PWM checks - blue
channel active / red channel silent after the `b` command) and a fresh
bitstream **BUILD OK with all timing constraints met**. No RTL change was
involved; the block was already in the netlist.

The XIP run first executed against the team's untested `spi_flash_xip.sv`
and failed exactly as code analysis predicted (byte-swapped instruction
fetch, phantom re-read, write hang) — three real bugs fixed pre-silicon.
Details: commit `fix(rtl): XIP controller byte order + phantom re-read`.

## 6. Simulation round 3 (2026-08-10) — v1.1 production peripherals

Full end-to-end regression (`run_regression.bat`, log `build/regression.log`)
on the v1.1 configuration (UART2 + SPI-RX + GPIO 16/16 + external-first
peripherals, docs/PRODUCTION_PERIPHERALS.md). Scoreboard:

| Item | Result |
|---|---|
| Program images (7 generators incl. periph_tests.py) | **PASS** |
| FreeRTOS firmware build (all variants incl. new drivers) | **PASS** |
| Full RTL + tb compile | **PASS** (0 errors) |
| tb_soc — UART cmds, LED patterns, **RGB/PWM**, switches/buttons | **9/9 PASS** |
| tb_lcd — ST7735 byte-exact init+draw (purchased hw #1) | **5/5 PASS** |
| tb_i2c — register read via team BFM (purchased hw #2/#3 path) | **PASS** |
| tb_xip — CPU executing from SPI flash | **PASS** |
| tb_freertos — RTOS boot + scheduling over XIP | **PASS** |
| tb_psram — external-memory write/readback via SPI RX reg (NEW) | **PASS** |
| tb_wifi — AT→OK round trip over UART2 / ESP32 model (NEW) | **PASS** |
| tb_audio — mic ADC ramp + speaker PWM active (NEW) | **PASS** |
| tb_cam — camera FIFO frame readout + checksum (NEW) | **PASS** |
| Bitstream (v1.1 pins incl. camera bus, UART2, SPI_RX) | **BUILD OK, all timing met** |

First bitstream attempt failed on an unconstrained `SPI_RX` port (the
shared MISO return only became a real pad once the RX register used it) —
fixed by pinning it to Pmod JA3; rebuild green.

Debug findings of the round (now WALKTHROUGH gotchas 19a/19b): xsim does
not propagate edge events through bit-select port connections (camera
testbench), and UART lines emit a glitch 0xFF frame at reset (ESP32 model
now noise-tolerant like real AT firmware).

## 7. Simulation round 4 (2026-08-17/18) — UART2 interrupt path (lead-requested)

Ravi's pre-freeze regression request: simultaneous UART1 console + UART2
traffic, RX FIFO burst/overflow, interrupt handling, unsolicited ESP-AT
events, error/recovery. All covered by the new `tb_uart2_irq` (program:
`sw/asm-demo/uart2_irq_test.py`, a bare-metal image with a real 32-entry
vector table at mtvec):

| Check | Evidence | Result |
|---|---|---|
| IRQ vectoring: UART2 RX → fast IRQ 1 → vector 17 → ISR | 17-byte unsolicited line (`WIFI DISCONNECT`) counted by the ISR with **zero polling** in the main flow → `EVT OK` | **PASS** |
| FIFO burst/overflow | 160-byte burst into the **masked** 128-deep FIFO; on unmask the ISR drains **exactly 128** (32 dropped, exact-count check) → `OVF OK` | **PASS** |
| Simultaneous UART1 + UART2 traffic | console char `X` sent MID-burst and echoed; `G` handshake echoed | **PASS** |
| Error/recovery | fresh `+IPD,4:ping` line arrives intact after the overflow → `RCV OK` | **PASS** |
| Full-regression rerun on the wired-IRQ RTL | 10 sims + FreeRTOS build + compile + bitstream | **14/14 PASS, timing met** |

Sim cost: 2.6 ms simulated / ~1 min wall — cheap enough to stay in every
regression run. FreeRTOS-level counterpart (esp_at_init IRQ mode +
event callback) is compile-proven and lands on hardware as Phase-3 check
20b (HW_VALIDATION_PLAN.md) — the RTL contract it relies on is what this
round proves.

Debug finding of the round (WALKTHROUGH gotcha 20): an early `return`
inside a timed loop in a testbench task kills the xsim kernel with
FATAL_ERROR; exit via the loop condition instead.

## 8. Hardware round 2 (2026-08-18) — FIRST v1.1 BOARD RUN: XIP + FreeRTOS

Run by ARF-BBSR-84 on their Arty A7-100T + PC (Vivado 2025.2, no RISC-V
toolchain — the **prebuilt-firmware fallback carried the whole flow**).

| Check | Result |
|---|---|
| `git pull` → Flash to Board (QSPI), 3 steps | PASS (after two same-day fixes below) |
| FPGA configures **from flash** after PROG/power-cycle | PASS |
| FreeRTOS boots via XIP, banner on PuTTY 115200 | PASS |
| Preemptive scheduling alive (tick heartbeat) | PASS |
| Console commands: patterns 1-4, f/m/s, r/g/b/w/a, echo-ack | PASS |
| Switch-mirror while a button is held | PASS |
| RGB LEDs | **BUG: only LED0 lit** — prvRgbTask drove PWM ch0-2 only; fixed same day to all 12 channels (all four LEDs), sim-verified + prebuilt refreshed |

Two latent flow bugs surfaced and were fixed during this run (details:
CLAUDE.md findings 2026-08-18, WALKTHROUGH gotchas 21/23):

1. `write_cfgmem` rejected the bitstream (`SPI_BUSWIDTH=1` vs SPIx4 MCS)
   — QSPI-boot config block added to `data/pins_artya7.xdc`.
2. Environment-check red error spew on PCs with fewer drives (PS 5.1
   `-Directory` dynamic-parameter binding) — locators now enumerate only
   existing drives.

Console UX reworked on lead feedback the same day: comprehensive
system-info boot banner, heartbeat quiet for 30 s then every 10 s
(`tick=N up=Ss`), `t` toggles it.

This closes the core of **Phase 1** (HW_VALIDATION_PLAN.md): base IO +
RTOS checks on the ONE FreeRTOS image. Remaining Phase-1 oddments (RGB
re-check with the fixed firmware, scripted `uart_command_test.py` run)
ride along with the next flash.

## 9. Hardware round 3 (2026-08-18, Soham's bench) — Phase 2a first LCD contact

ST7735 wired per the sec.-8 tables (jumpers only, no soldering), Soham's
board on the dev PC. Two failures, both root-caused and fixed same day:

| Check | Result |
|---|---|
| Phase-1 console re-check on this board (patterns, RGB, speed, echo, mirror) | PASS |
| LCD attempt 1 | **DARK** — GUI variant dropdown had flashed the LCD-less "standard" image. Structural fix: ONE hardware image (LCD task always included), dropdown + JTAG button removed from the GUI (gotcha 25) |
| LCD attempt 2 (correct image) | **Backlight white, nothing drawn** — backlight proved firmware + GPIO path good; panel never initialised. **Root cause: real RTL bug in `spi_host.sv`** (below) |

**The SPI mode-0 hold-time bug** (question credit: ARF DV teammate —
"verify spi_host/spi_top mode of operation"): with CPOL=0/CPHA=0 the RTL
launched each TX bit on the **rising** SCK edge — the very edge a mode-0
slave samples — giving the panel zero hold time; every byte arrived
garbled and the controller never left reset-default (white). Simulation
never saw it because the SPI models sampled a **delayed copy** of MOSI,
matching the RTL's race instead of the physical part (workaround was
commented in tb_lcd.sv). Fix: TX now launches on the **falling** edge —
half an SCK period of setup and hold, textbook mode 0. RX sampling
(rising edge) unchanged, so the PSRAM/ADC read path is unaffected.
**ASIC-relevant: `spi_top` ships in the tapeout netlist — this fix must be
in whatever netlist PD synthesises** (STATUS_BRIEF decision list).
Gotcha 26 records the modelling lesson: models must mimic the datasheet
part, never the RTL's quirks.

Evidence: full regression re-run after the fix — **14/14 ALL GREEN**
(images, FreeRTOS build, compile, all 10 sims incl. tb_lcd 5/5 and
tb_psram on the fixed edge, bitstream with timing met). The fixed
bitstream + one-image firmware were then flash-programmed to the bench
board from the dev PC (`Erase/Program/Verify successful`,
build/fpga/program_flash.log).

### 9b. Autonomous live testing (same bench, same day) — and bug #9

With the board on the dev PC, testing ran fully scripted: JTAG
`boot_hw_device` (identical effect to pressing PROG) + pyserial on COM4.

**First finding: a "hang" that wasn't.** The board booted perfectly
(banner, `toy: lcd up`, heartbeat at up=30 s) but appeared dead to every
*subsequent* serial session. A bracketing run (poke `K` every 5 s from
boot) showed 130 s of flawless echoes + heartbeats — the board only
"died" after a serial session **closed**. A control experiment proved
causality: alive with echoes at t=43 s → port closed at 45 s → reopened
5 s later → silence. A JTAG *touch* did not revive it; only
reconfiguration did.

**Root cause — bug #9 (warm-reset boot, ASIC-relevant):** closing the
serial port deasserts DTR, which the Arty couples to `ck_rst` =
`IO_RST_N`, and `rst_sys_n = locked_pll & IO_RST_N` — so the SoC is held
in reset until the port reopens. That warm reset then **crash-looped**:
the boot ROM jumps to SRAM+0x80 on EVERY reset, but the firmware's
`.bss` covered 0x102080 — the XIP trampoline was clobbered the moment
FreeRTOS started (the old linker script even documented the clobber as
harmless: "it has served its purpose by then" — true only when every
reset is a reconfiguration). Fix: linker reserves SRAM+0x00..0x8F and
`startup.S` re-writes the trampoline at every boot (self-healing).
tb_freertos PASS, reflashed, and the control experiment re-run:
**port close → reopen now yields an instant fresh banner + working
console** — the board self-recovers.

**Phase-1 completions from the autonomous run:**

| # | Test | Result |
|---|---|---|
| 1/2/10/11 | banner, echo, XIP boot, heartbeat | **PASS** (serial captures, three boots) |
| 5 | RGB all-4 re-check | **PASS** (Soham, PuTTY, same day) |
| 8 | `uart_command_test.py` scripted sweep | **PASS 8/8** |
| 13 | boot-from-flash persistence | **PASS** (5 JTAG-triggered reconfig cycles) |
| 14 | LCD firmware path (`toy: lcd up` = full SPI init + draw completed) | **PASS** — panel visually confirmed by Soham (ARF logo + live status render); **Phase 2a COMPLETE** |

**ASIC flag from bug #9:** on silicon, SRAM powers up random and there is
no bitstream initialisation — the boot ROM as-is (jump to SRAM+0x80)
cannot complete a *first* boot. The ROM must either write the trampoline
itself or jump directly to the XIP window. Raised as a lead decision in
STATUS_BRIEF. **RESOLVED 2026-08-19: lead chose direct XIP; implemented
and regressed — see §11.**

## 10. Team-repo commit audit (2026-08-18, requested by Soham)

Three commits on `ArfDesign-DB/minimal-ibex-soc` reviewed for adoption:

| Commit | Content | Verdict for our tree |
|---|---|---|
| `740d59c9` (Ravalika) | 50→20 MHz defaults, hardcoded `C:/Users/Raji` path removed, Verilator sim ctrl, `sram_model`→`dffram` swap | **Not adopted** — the MHz/path fixes landed here first (2026-08-07); Verilator/hello_world are outside our xsim flow. **Two review flags sent back**: (a) the DFFRAM instantiation sits under `` `ifdef verilator `` with an empty `else` — as committed, *synthesis gets no SRAM instance at all*; (b) confirm the DFFRAM macro's `WE` is per-byte — Ibex issues `sb`/`sh` to SRAM, a single-bit WE breaks byte stores |
| `498798b` (Ravalika) | `boot.mem` copyto in the FuseSoC `.core` | **Not adopted** — we run the no-FuseSoC flow; correct fix for their build |
| `8ed494d` (Khalid) | comments out the dead SPI_CTRL stub (0x4000_0300) | **Adopted, as full removal** — decode/ports/stub logic deleted from `wb_interconnect.sv` + `wrapper_top.sv` (ours also left `spictrl_rvalid` undriven, a latent X-source). Shrinks the RTL↔PD-netlist delta. **Verified: full regression 14/14 ALL GREEN, reflashed, on-board boot + scripted sweep 8/8 PASS on the stub-free build** |

## 11. Simulation round 5 (2026-08-19) — direct XIP boot + Phase 2b prep

Lead-directed (Ravi, 2026-08-19): direct XIP boot chosen as the ASIC
first-boot solution, "regress it thoroughly". Implemented and regressed
the same day:

**Boot ROM (`rtl/system/boot.mem`)**: the single `jal → SRAM+0x80` was
replaced by `lui t0,0x20400; jalr x0,0(t0)` at reset PC `0x0010_0080` —
the ROM never touches SRAM. Testbench topology change:

| Bench | Boot ROM | SRAM at t=0 | Why |
|---|---|---|---|
| tb_xip | **real** `boot.mem` (direct XIP) | **uninitialised (X)** | Strictest boot-path check: any read of SRAM before it is written X-poisons the sim. Ran completely clean — zero X asserts |
| tb_freertos | **real** `boot.mem` (direct XIP) | **deterministic random garbage** (`dv/xsim/sram_powerup_random.vmem`, fixed xorshift seed) | The silicon power-up condition for the full product. X-init was tried first and *passed*, but flooded the log with 571 benign `IbexDataRPayloadX` asserts (byte-built buffers/padded structs word-read later — silicon returns random bytes there, xsim returns X); defined random garbage models the part, keeps the log clean, and still kills any boot that depends on SRAM contents |
| 8 asm-demo benches | `dv/xsim/boot_sram_dv.mem` (DV-only, old jal) | backdoor-loaded program | Peripheral DV keeps its fast SRAM-resident programs; clearly labelled non-product boot path |

The FPGA bitstream no longer bakes any SRAM image (`build_fpga.tcl`,
`gen_project.tcl`, `flashfw` flow) — every board boot now exercises the
silicon boot path. Legacy SRAM+0x80 entry stays alive via startup.S for
debug flows; all old/new bitstream×firmware pairings remain bootable
(WALKTHROUGH gotcha 29).

**SPI model strictness (Rule 1b follow-through):** the delayed-MOSI
sampling workaround was removed from `tb_lcd`'s ST7735 model and
`periph_models.sv`'s PSRAM model. All SPI models now sample the raw wire
on the rising edge like the datasheet parts — a reintroduced hold-time
bug now fails tb_lcd/tb_psram instead of a physical panel.

**Phase 2b firmware hardening (`main.c` toy task):** signed temperature
formatting (`-12.07C`, was a 4-billion print below 0 °C), humidity on the
LCD live block, pressure + uptime on the OLED, UART T/P/H report every
10 s gated with the `t` toggle (was: every second, unconditionally),
absent parts re-probed every 5 s (hot-attach), 3 consecutive I2C failures
demote a part back to absent (`toy: bme lost`).

**Result: full regression 14/14 ALL GREEN** — all 10 sims (incl. both
uninitialised-SRAM XIP boots and the strict SPI models), images, firmware,
compile, bitstream with timing met and **no SRAM init image**.

## 12. Verilator cross-check + Linux flow (2026-08-19, later)

`./ibex_soc.sh` (new, the Linux twin of `ibex_soc.bat`) runs the **same
10 full-SoC testbenches unmodified under Verilator 5** (`--timing`) —
providing the tooling for the independent Verilator regression Ravi asked
for before RTL sign-off, and a second engine cross-checking every xsim
result.

**Result (Verilator 5.050): 12/12 ALL GREEN** — images + FreeRTOS sim
firmware (built by `build.sh`) + all 10 testbenches with identical PASS
criteria to the xsim suite, including tb_xip/tb_freertos on the direct-XIP
boot ROM and tb_uart2_irq's full FIFO-overflow/recovery matrix. Two
simulators, two vendors, zero disagreements.

Host quirks found while proving it (encoded in the script + WALKTHROUGH
gotcha 30): Verilator resolves dead-generate module refs (needs
`prim_cipher_pkg` fed explicitly); MinGW GCC 16.2 `-Os` link bug → `-O2`
on MSYS hosts; msys vs ucrt python path handling.

**FuseSoC wrapper** (`minimal_ibex_soc.core`, `arf:ibex:minimal_ibex_soc`,
mirrors filelist.f, no dependency on the vendored core tree; `$readmemh`
images via `copyto` — the approach from team commit `498798b`, adopted):

| Target | Tool | Verified |
|---|---|---|
| `lint` | Verilator `--lint-only` | **run green** (exit 0) |
| `sim` (tb_soc) | Verilator `--main --timing` | **builds + binary passes 9/9** (edalize's run stage calls `./Vtb_soc` which misses the `.exe` on native Windows — Linux unaffected) |
| `synth` (top_artya7) | Vivado | **full build green**: synthesis → place → route → 3.8 MB bitstream, "all user specified timing constraints are met" (run under MSYS2 make + Windows Vivado 2026.1; caught + fixed a file-type bug first — the SV-content `.v` i2c files must be `systemVerilogSource`) |

The `deps` flow installs the complete environment (apt/dnf/pacman +
xPack RISC-V GCC fallback); `build`/`flashfw` drive the Windows-proven
`.tcl` scripts through a Linux Vivado — pending first exercise on a real
Linux Vivado install.

**DFFRAM configuration (same day, evening — teammate proposal, upgraded).**
A teammate proposed an `` `ifdef verilator `` split (dffram under
Verilator, sram_model under Vivado). Adopted as a **`UseDffram`
parameter** instead — Ravi's direction was that synthesis must not depend
on a simulator define, and a parameter lets *every* engine elaborate
either SRAM: `wrapper_top.sv` generate-selects `sram_model` (default,
FPGA BRAM) or `dffram` (GF180 DFFRAM behavioral model, **per-byte
WE[3:0]** — our copy already satisfied review flag b). `dffram.sv`'s DPI
exports were re-guarded from `` `ifndef SYNTHESIS `` to
`` `ifdef VERILATOR `` (the same guard bug that once broke xsim in
sram_model). New regression row **tb_soc-dffram**: the full 9-check
console test (sb/sh-heavy — a byte-store torture test by nature) on the
DFFRAM model, in **both** xsim (`xelab -generic_top UseDffram=1`) and
Verilator (`-GUseDffram=1`) — no extra compile, same PASS bar.

## 13. Not covered (future work)

- **Phase 2b on hardware** — parts + soldering kit in hand; needs the
  board on the bench (guide: PRODUCTION_PERIPHERALS §8). Test rows
  15-17b in HW_VALIDATION_PLAN.
- Direct-XIP boot on hardware — sim-proven; first `flashfw` with the new
  bitstream verifies it on the board (any boot = the silicon path now)
- `ibex_soc.sh build`/`flashfw` on a real Linux Vivado install
- Pmod touch-test (no-instruments continuity check — needs hands)
- JTAG debug via OpenOCD (dm_top synthesises with the BSCANE2 tap; not exercised)

## Verdict

**PASS — the SoC hardware platform is functional on the Arty A7-100T,
and the ASIC-representative v1.1 configuration (8 KiB SRAM, XIP boot
from QSPI flash, FreeRTOS) now runs on the physical board.** UART both
directions, GPIO in/out, PWM/RGB, CPU, buses, both memories, flash
config and XIP execution verified in simulation and on the board.
