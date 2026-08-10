# CLAUDE.md — Project Memory & Working Rules

*Reference for Claude (and any AI agent or new human) working in this repo.
Maintained continuously: **update the Findings Log and Status sections as
part of every push.***

---

## 1. What this project is

Fork of the lowRISC Ibex Demo System, heavily modified by ARF Design:
custom **OBI → Wishbone fabric** (2:1 arbiter → `obi2wb` → `wb_interconnect`)
around an **Ibex RV32IMC** core. Target platforms: **Digilent Arty A7-100T**
FPGA (bring-up/prototyping — this repo's main concern) and a real **ASIC
tapeout on GF180MCU (180 nm) via the Efabless Caravel shuttle** — the team's
spec bundle (`opentitan_minimal_guide` HTML, from Soham's Downloads) is
digested into **docs/ASIC_SPEC.md**, the binding constraints document:
**SRAM = 8 KiB** (Caravel area budget), code >8 KiB executes via **SPI-flash
XIP at 0x2000_0000**, RTOS = **FreeRTOS**, 20 MHz, no PLIC (flat fast IRQs).
FPGA validation must run the silicon configuration or it isn't validation.
(`DFFRAM/`, `gds.tar.gz` are ASIC-side artifacts, unused by FPGA flows.)

- **System clock: 20 MHz** (team/ASIC decision — never "fix" it to 50 MHz;
  the PLL was corrected TO 20 MHz on purpose).
- Owner of this fork: **Soham Sen** (`sensoham135@gmail.com`, GitHub
  `sohamxda7`). Background: physical design / SKILL & Tcl automation lead —
  strong engineer, **new to RTL/DV/embedded**; explain in plain language,
  no unexplained jargon, use analogies (he knows Android ROMs/kernels well).
- Remotes: `origin` = github.com/sohamxda7/minimal_ibex_soc (personal, main
  branch, push freely). `upstream` = github.com/ArfDesign-DB/minimal-ibex-soc
  (team repo; branches are push-protected — contribute via PR; PR #16 is
  the bring-up PR into `cursor/setup-dev-environment-93f3`).

## 2. Rules of engagement (learned & agreed with Soham)

1. **Simulation before hardware, always.** Nothing gets flashed that didn't
   pass an xsim testbench first. This has worked every single time.
2. **Ask before**: pushing to team/upstream repos, force-pushes, deleting
   anything not ours, buying/downloading large things, and any scope change.
   Proceed freely on: local edits, sim runs, local commits, docs.
3. **Document everything, as you go**: every decision with reasoning goes in
   `docs/` (BRINGUP_OVERVIEW decision log, or the topic doc); every test
   result with evidence goes in `docs/BRINGUP_TEST_REPORT.md`; every new
   script gets a WALKTHROUGH.md entry; **and update this file's Findings
   Log + Status on every push**.
4. **Commit style**: short subject (conventional prefix: fix/feat/docs/ci/
   test), blank line, detailed body. Author `Soham Sen <sensoham135@gmail.com>`.
5. **Repo hygiene**: no build junk (gitignore covers xsim/Vivado outputs);
   FPGA work lives under `C:\FPGA\` (never OneDrive / paths with spaces).
6. **Keep the two demo implementations in sync**: `sw/c/demo/hello_world/main.c`
   (C reference) and `sw/asm-demo/assemble.py` (what actually runs — no
   RISC-V GCC on lab PCs; the Python assembler is the no-toolchain path).
7. **Touch vendored files only when unavoidable**, with loud comments.
8. When the user pastes team code to review: review honestly, list every
   bug with reasoning, fix, and document the review (see docs/UART_CONTROL.md
   as the pattern).
9. **Documentation layout (2026-08-10 reorganization)**: the ROOT README.md
   is the ORIGINAL lowRISC README restored, with only a short fork banner on
   top pointing to **docs/README.md** — that file is the fork's front door
   (where/how to start, fixes table minus Zephyr, additions, vendored
   patches, ASIC constraints, open questions, full doc index). The verbatim
   upstream copy also stays at docs/UPSTREAM_README.md. Keep it this way:
   new fork content goes in docs/, never into the root README beyond the
   banner. Zephyr-era docs live under the index's History/archive section.

## 3. Key technical facts (verified)

- **Memory map**: Boot ROM 4 KiB @ `0x0010_0000` (NOP sled + `jal` to
  `0x0010_2080`); SRAM **8 KiB** @ `0x0010_2000..0x0010_3FFF` (ASIC-spec
  size since 2026-08-10; range decode, NOT mask — base isn't size-aligned;
  spec sheet says base 0x0010_1000, we keep 0x0010_2000 for the boot
  contract — flagged deviation, docs/ASIC_SPEC.md section 3); **XIP flash
  window @ `0x2000_0000`** (read-only, cmd 0x03 single-bit SPI; firmware
  sits at flash offset 0x40_0000 behind the bitstream = CPU address
  `0x2040_0000`); UART `0x4000_0000` (RX +0 / TX +4 / STATUS +8: bit0
  rx_empty, bit1 tx_full); GPIO `0x4000_0100` (OUT +0: gp_o[7:4]=LEDs,
  [3:0]=DISP_CTRL; IN-dbnc +8 = {SW,BTN}); Timer `0x4000_0200` (CLINT-style
  mtime +0/+4, mtimecmp +8/+12); I2C `0x4000_0400` (OpenCores, Pmod
  JA1/JA2); SPI host `0x4000_0500`; PWM `0x4000_0600` (FPGA-only — NOT in
  the ASIC spec, pending team decision); debug window `0x1A11_0000`.
- **Boot contract**: everything enters at SRAM+0x80 = `0x0010_2080`.
  For XIP firmware the SRAM image is a 2-instruction trampoline
  (`sw/asm-demo/xip_test.py` -> xip_stub.vmem) jumping to `0x2040_0000`.
  Changing this contract breaks boot.mem — don't.
- **QSPI flash pins**: CS=L13, DQ0(MOSI)=K17, DQ1(MISO)=K18; **SCK has no
  package pin** — it's the CCLK config pin, driven via STARTUPE2.USRCCLKO
  (top_artya7.sv). XipClkDiv param: FPGA top uses 1 (10 MHz; flash rated
  50 MHz), ASIC-spec default 4. `program_flash.bat` = bitstream+firmware
  MCS into flash.
- **Ibex is vectored-only** (mtvec[1:0]=01 hardwired, 256-byte aligned):
  RTOS trap entry needs a 32-entry vector table (sw/freertos/startup.S);
  entry 7 = machine timer, base+0 = exceptions/ecall.
- **SPI/display pins already routed** in `data/pins_artya7.xdc`: SPI_TX=E5,
  SPI_SCK=A4, DISP_CTRL[3:0]=B7/B6/E6/A3 (ChipKit AD header pins) — used by
  the upstream ST7735 LCD demo (`sw/c/demo/lcd_st7735`).
- **Toolchain locations on this PC**: Vivado `C:\AMD\2026.1\Vivado\bin`
  (xvlog/xelab/xsim there too); **RISC-V GCC = the Zephyr SDK's
  `C:\FPGA\zephyr-sdk\gnu\riscv64-zephyr-elf\bin`** (the SDK stays as a
  plain bare-metal compiler even though the Zephyr port is gone — it is
  what `sw/freertos/build.bat` uses); CMake `C:\Program Files\CMake\bin`;
  gh CLI `C:\Program Files\GitHub CLI\gh.exe`. My shells inherit a stale
  PATH — use full paths or prepend per-call.
- **CRITICAL Windows gotcha**: xvlog/xelab/xsim HANG (100% CPU, zero
  output, forever) when launched with piped stdio from the agent's
  Bash/PowerShell tools. Always launch via detached
  `Start-Process powershell -File scripts\<runner>.ps1` writing an ASCII
  log, then watch the log (`scripts/compile_sims.ps1` etc. are the
  pattern). Related: `Out-File` defaults to UTF-16 — always
  `-Encoding ascii` or grep-based watchers see NUL soup.
- **Build/run commands**: README quick start; FreeRTOS in
  docs/FREERTOS_PORT.md; sim flow in docs/FPGA_BRINGUP.md; gotchas in
  docs/WALKTHROUGH.md section 8.

## 4. Findings Log (chronological, condensed)

**2026-08-07 — Phase 1, board IO qualification** (separate project, imported
as `board-io-test/`): all Arty A7-100T IO electrically verified (LEDs, RGB,
switches, buttons, UART both ways, Pmods via no-instrument "touch test").
Board hardware is known-good — later SoC issues are logic, not silicon.
Vivado 2026.1 installed at `C:\AMD\2026.1` (new layout). Board = COM4 on
this PC (per-PC number). Lesson: sim-vs-hardware time-scale illusion
confuses waveform readers; testbenches ship sped-up program images.

**2026-08-07 — SoC bring-up, root causes of "RGB glitch"**:
(1) `SRAMInitFile` unwired → FPGA bitstream had NO program → CPU crash-loop
in empty SRAM (Verilator DPI back-door had hidden this; hardcoded
`C:/Users/Raji/...` path was a manual-workaround fossil).
(2) `timer_enable(10000)` = 0.5 ms tick → RGB ramp strobed at kHz = the
visible glitch. (3) `uart u_uart` instantiated parameterless → wrong baud.
(4) PLL made 50 MHz for the 20 MHz design → divider 24→60.
Also: DPI exports guarded `ifndef SYNTHESIS` break xsim C codegen → use
`ifdef VERILATOR` (hit twice: sram_model.sv, vendored ibex_if_stage.sv).
Infra born here: filelist.f shared by sim+synth, prim_shims.sv (primgen
replacement), Python RV32IM assembler, plain-Vivado .tcl/.bat flow.
Hardware verified same day: heartbeat/echo/LEDs/RGB all good.

**2026-08-07 — UART command interface** (from DV lead's draft): draft had
fatal `timer_enable()` re-arm-in-loop (tick never fires), inverted+500x-fast
speed table, patterns writing DISP_CTRL nibble instead of LEDs, no RGB
control. Rebuilt in C + asm: patterns 1-4, speed f/m/s, RGB r/g/b/w/a.
9/9 sim checks; 8/8 scripted hardware commands; user-verified in PuTTY.

**2026-08-07 — repo publication**: personal repo `sohamxda7/minimal_ibex_soc`
(main); authors rewritten to sensoham135@gmail.com (avatar fix); Rust CI
scoped to `sw/rust/**` (pre-existing nightly failure, needs toolchain
re-pin by sw/rust owner); ASIC artifacts documented as FPGA-irrelevant;
README rewritten as technical front page (upstream README preserved at
docs/UPSTREAM_README.md).

**2026-08-08 — RTOS**: evaluated Zephyr/FreeRTOS/ThreadX/RT-Thread/NuttX
against "use full board capability" (DDR3, Ethernet, QSPI roadmap).
**Zephyr selected** (decision memo: docs/ZEPHYR_DECISION.md; plan:
docs/RTOS_RESEARCH.md; FreeRTOS = documented contingency). Phase A: SRAM
8→128 KiB (range decode; 32.5/135 BRAM; regression 9/9). Phase B: out-of-tree
port `zephyr-port/` — **hello_world BOOTS in xsim** (banner + print, 5 ms sim
time, entry exactly at boot-ROM target via DTS trick; zero RTL changes).
Port fixes needed: `riscv,isa-base`/`riscv,isa-extensions` DTS format;
RISC-V arch lacks sys_read32/sys_write32 → volatile accessors in drivers.
Zephyr tooling on this PC: west 1.5.0 (venv!), SDK 1.0.1. Windows traps:
Store-Python Scripts dir not on PATH; `west packages pip` demands venv;
SDK setup needs 7-Zip; PowerShell mangles `-DFOO=C:/...` args (quote them)
and multiline gh args (use --body-file). Team repo access granted; bring-up
delivered as upstream PR #16 (direct push blocked by branch protection).

**2026-08-08 — Final test ("toy interfacing") agreed with DV lead**:
Tier 1 = ST7735 1.8" SPI LCD (pins already routed, upstream demo exists,
zero RTL change). Tier 2 = I2C BME280 sensor + SSD1306 OLED via Zephyr
in-tree drivers (needs I2C SCL/SDA pinned to a Pmod as open-drain — small
RTL change). Purchases verified on Amazon.in (~₹3,300 incl. 24 MHz logic
analyzer + soldering kit; LCD ships pre-soldered, OLED/BME280 need 10
header joints). Sim-first plan: behavioral ST7735 SPI model + I2C models
in xsim before hardware arrives.

**2026-08-08 — Tier-1 LCD sim PASS (5/5)**: hand-assembled ST7735 driver
(sw/asm-demo/lcd_spi_test.py) + behavioural LCD model (dv/xsim/tb_lcd.sv)
verify the full 26-byte init+pixel sequence on the SoC's real SPI pins.
SPI facts confirmed: TX +0 / STATUS +4 (bit0 full, bit1 empty), mode 0,
MSB first, 5 MHz; FIFO-empty is not shifter-idle (drain ~32 clks before DC
changes); LCD pins = GPIO_OUT[3:0] = CS/RST/DC/BL. Sim caught a real
testbench race: this host updates MOSI on rising SCK — sample a delayed
copy, never the raw wire on the same edge. Docs: docs/TOY_INTERFACING.md
(incl. hardware wiring table: LCD -> ChipKit A6..A11 + 3V3/GND).

**2026-08-08 — Tier-2 I2C sim PASS + team BFM bug fixed**: I2C pinned out
to Pmod JA1/JA2 (open-drain, XDC pull-ups; OpenCores pad-enable is ACTIVE
LOW). OpenCores reg map via wrapper: PRERlo +0x00, PRERhi +0x04, CTR +0x08,
TXR/RXR +0x0C, CR/SR +0x10; PRER=39 -> 100 kHz @ 20 MHz; CR bits STA=80
STO=40 RD=20 WR=10 NACK=08; SR TIP=bit1. Full register read verified against
the team's i2c_slave_bfm (addr 0x50, mem[i]=i). Found+fixed a real bug in
that BFM: ST_READ released SDA on scl_rise after the last bit (phantom STOP
+ corrupted final bit — same class its ST_ACK_ADDR comments already warn
about); release moved to the following scl_fall, unsafe multi-byte pre-drive
removed. I2C-side lesson mirrors the SPI one: never change bus lines on the
sampling edge.

**2026-08-08 — lowRISC upstream sync**: added remote `lowrisc`
(github.com/lowRISC/ibex-demo-system). Fork base 0a8ce38 (2025-11-25);
only ONE upstream commit existed (d37beb7, container/Dockerfile fix) —
merged cleanly, zero overlap with fork files, branding/RTL/docs intact.
Full post-merge regression: SoC demo 9/9, Zephyr boot, LCD 5/5, I2C, and
bitstream (timing met) — ALL PASS. Safety branch backup-pre-upstream-sync
kept locally. Policy for future syncs: fetch lowrisc, merge, take OURS for
fork-owned files, re-apply the two vendored patches (clkgen 20 MHz divide,
ibex_if_stage VERILATOR guard) if vendor/ is updated, then run the full
regression (build/regression.log via scratchpad run_all_tests.ps1 pattern)
before pushing. Note: Out-File default UTF-16 encoding corrupts grep-based
log watchers — strip NULs or use ASCII encoding in log scripts.

**2026-08-10 — ASIC spec lands; SRAM 8 KiB; XIP proven; Zephyr -> FreeRTOS**:
Team decision: SRAM cannot grow (chip area), use the 16 MB QSPI flash via
XIP instead. Their spec bundle (opentitan_minimal_guide) digested into
docs/ASIC_SPEC.md — this SoC is going to GF180MCU silicon via Caravel;
8 KiB DFFRAM is an area-budget fact (64 KiB ~ 14 mm2 > the 10.27 mm2 user
area). Executed: (1) SRAM 15->11 addr bits + all image tooling; regression
green on the small SRAM (SoC 9/9, LCD 5/5, I2C). (2) New tb_xip +
behavioral SPI NOR model: CPU boots from a 2-instruction SRAM trampoline
and runs entirely from flash — **found 3 real bugs in the team's untested
spi_flash_xip.sv** (byte order reversed [31:24] vs [7:0]; phantom re-read
during the ack cycle that can serve stale data to a later request; writes
hang the bus) — all fixed, tb_xip PASS. (3) QSPI wired on the board top:
CS=L13/DQ0=K17/DQ1=K18 + STARTUPE2 for CCLK; program_flash.tcl builds a
bitstream+firmware MCS. (4) Zephyr port REMOVED (8 KiB is below Zephyr's
RAM floor; supersession notices keep the decision trail; SDK kept as our
GCC). (5) **FreeRTOS V11.2.0 ported** (vendored subset, zero kernel
mods): vector table for Ibex's vectored-only mtvec, CLINT timer at
0x4000_0200 matches the official port out of the box, heap in .noinit,
~770 B data+bss + 4 KiB heap inside 8 KiB. **Boots + schedules in
full-SoC sim over XIP** (banner ~6 ms sim, tick reports; tb_freertos).
(6) Drivers for the purchased toys (sw/freertos/drivers/): i2c helper,
ST7735 (no framebuffer), BME280 (32-bit-only compensation), SSD1306
(font-from-flash); `build.bat toy` adds the demo task. All 3 firmware
variants compile clean. Lesson reinforced: sim-first caught
silicon-killing bugs again, before tapeout instead of after.

## 5. Open questions for the team (track until answered)

1. **SRAM base address**: ASIC spec sheet says `0x0010_1000`; the repo uses
   `0x0010_2000` (keeps the boot-ROM jump contract SRAM+0x80=0x0010_2080 and
   every existing image). One of the two must change before tapeout RTL
   freeze. Decision owner: DV lead / tapeout stream.
2. **PWM block at `0x4000_0600`**: the RGB demo uses it, but it is absent
   from the ASIC spec and its ~44 kGE budget. Keep in silicon (costs gates)
   or make it FPGA-only? Decision owner: DV lead.

Both are documented for the team in docs/README.md section 6 and
docs/ASIC_SPEC.md section 3.

## 6. Current status / next steps

- **Configuration is now ASIC-representative**: 8 KiB SRAM, XIP wired to
  the onboard QSPI flash, FreeRTOS as the RTOS. Full sim regression green
  2026-08-10 (SoC 9/9, LCD 5/5, I2C, XIP, FreeRTOS boot; bitstream BUILD OK with
  all timing constraints met).
- Board returns -> (a) `program_fpga.bat` for the asm-demo sanity check;
  (b) FreeRTOS-from-flash run: `vivado -mode batch -source build_fpga.tcl
  -tclargs sw/asm-demo/xip_stub.vmem`, then `sw\freertos\build.bat`, then
  `program_flash.bat` (PuTTY 115200: banner + tick lines + walking LEDs).
  Record results in BRINGUP_TEST_REPORT section 5.
- Parts arrive -> wire per docs/TOY_INTERFACING.md tables, flash the
  `build.bat toy` firmware; solder guidance promised for BME280/OLED
  headers ("ping me before you start").
- Open team decisions: SRAM base 0x0010_2000 vs spec 0x0010_1000; PWM
  keep/drop for the ASIC; PR #16 review.
