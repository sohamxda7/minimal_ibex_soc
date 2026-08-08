# CLAUDE.md — Project Memory & Working Rules

*Reference for Claude (and any AI agent or new human) working in this repo.
Maintained continuously: **update the Findings Log and Status sections as
part of every push.***

---

## 1. What this project is

Fork of the lowRISC Ibex Demo System, heavily modified by ARF Design:
custom **OBI → Wishbone fabric** (2:1 arbiter → `obi2wb` → `wb_interconnect`)
around an **Ibex RV32IMC** core. Target platforms: **Digilent Arty A7-100T**
FPGA (bring-up/prototyping — this repo's main concern) and an ASIC
implementation (the `DFFRAM/`, `gds.tar.gz` artifacts — not used by any
FPGA/sim/software flow here).

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

## 3. Key technical facts (verified)

- **Memory map**: Boot ROM 4 KiB @ `0x0010_0000` (NOP sled + `jal` to
  `0x0010_2080`); SRAM **128 KiB** @ `0x0010_2000..0x0012_1FFF` (range
  decode, NOT mask — base isn't size-aligned); UART `0x4000_0000`
  (RX +0 / TX +4 / STATUS +8: bit0 rx_empty, bit1 tx_full); GPIO
  `0x4000_0100` (OUT +0: gp_o[7:4]=LEDs, [3:0]=DISP_CTRL; IN-dbnc +8 =
  {SW,BTN}); Timer `0x4000_0200` (CLINT-style mtime +0/+4, mtimecmp +8/+12);
  I2C `0x4000_0400` (OpenCores, **not pinned out yet**); SPI host
  `0x4000_0500`; PWM `0x4000_0600` (pwm i: +8i pulse, +8i+4 max; i%3:
  0=Blue,1=Green,2=Red); debug module window `0x1A11_0000` (pre-WB decode).
- **Boot contract**: everything enters at SRAM+0x80 = `0x0010_2080`
  (asm demo via assembler base; Zephyr via DTS declaring SRAM at that
  address). Changing this breaks boot.mem — don't.
- **SPI/display pins already routed** in `data/pins_artya7.xdc`: SPI_TX=E5,
  SPI_SCK=A4, DISP_CTRL[3:0]=B7/B6/E6/A3 (ChipKit AD header pins) — used by
  the upstream ST7735 LCD demo (`sw/c/demo/lcd_st7735`).
- **Toolchain locations on this PC**: Vivado `C:\AMD\2026.1\Vivado\bin`
  (xvlog/xelab/xsim there too); Zephyr workspace `C:\FPGA\zephyrproject`
  (venv: `.venv\Scripts`, activate before west); Zephyr SDK
  `C:\FPGA\zephyr-sdk` (riscv64-zephyr-elf tools); CMake
  `C:\Program Files\CMake\bin`; Ninja via WinGet packages dir; gh CLI
  `C:\Program Files\GitHub CLI\gh.exe`. My shells inherit a stale PATH —
  use full paths or prepend per-call.
- **Build/run commands**: see README quick start + `zephyr-port/README.md`;
  sim flow in `docs/FPGA_BRINGUP.md`; all gotchas in `docs/WALKTHROUGH.md` §8.

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

## 5. Current status / next steps

- Bitstream with UART-command demo + 128 KiB SRAM: built, timing met —
  **board flash pending** (board away from desk; `program_fpga.bat`).
- Zephyr hardware run pending same: `build_fpga_zephyr.bat` → program.
- In progress: ST7735 behavioral sim model + SPI-path asm test; I2C pin-out
  RTL + sim; then Zephyr devicetree nodes for LCD/BME280/OLED (Phase C).
- Waiting on: parts delivery; PR #16 review by team.
