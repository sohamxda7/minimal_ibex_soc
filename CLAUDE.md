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

0. **THE ASIC IS THE PRODUCT — the FPGA is never a demo platform.**
   (Soham, 2026-08-10: "we are not doing demo in FPGA, this is for real
   deal.") The Arty exists ONLY to validate the exact silicon
   configuration before tapeout. Consequences, applied to every proposal:
   - No FPGA-only features. If it cannot run on the fabricated chip
     (8 KiB SRAM, 38 Caravel pins, 20 MHz, no BRAM/DDR3), it is out of
     scope until the team formally re-scopes the chip itself.
   - Zephyr / dev-RAM / DDR3-MIG / camera / audio-streaming class ideas
     all fail that test on this tapeout - do not build them; surface a
     chip-v2 requirements note instead.
   - FreeRTOS stays: it is the RTOS that runs on the silicon (XIP +
     8 KiB), which is why the spec names it.
   - Any capability request gets evaluated as "does this fit the chip's
     area/pin/RAM budget?" FIRST (docs/ASIC_SPEC.md), and chip changes
     (e.g. a second UART for an ESP32 companion) go to the team for
     sign-off before RTL.
1. **Simulation before hardware, always.** Nothing gets flashed that didn't
   pass an xsim testbench first. This has worked every single time.
1b. **Model the datasheet part, NEVER the RTL — and treat every testbench
   workaround as a suspected RTL bug** (Soham, 2026-08-18, after the SPI
   mode-0 incident). The rule exists because we violated it and it nearly
   reached silicon: on 2026-08-08 the tb_lcd model saw bytes arrive
   left-shifted when sampled the way a real ST7735 samples; instead of
   asking "why does datasheet-correct sampling fail?", the model was given
   a delayed-sampling workaround (even documented in a comment) and the
   suite went green. The RTL bug underneath (TX launched on the sampling
   edge - upstream lowRISC code from 2022, not ours, but OUR job to catch)
   then cost a hardware bench day and would have shipped a dead SPI port
   in silicon. Standing procedure: any time a model, testbench, or
   driver needs an accommodation to make the DUT pass, STOP - research the
   interface contract (datasheet/spec) first, decide which side is wrong,
   and fix or escalate the RTL; never encode the quirk into the test.
   Verify consequences before acting - a passing suite built on a wrong
   reference is worse than a failing one.
2. **Ask before**: pushing to team/upstream repos, force-pushes, deleting
   anything not ours, buying/downloading large things, and any scope change.
   Proceed freely on: local edits, sim runs, local commits, docs.
3. **Document everything, as you go**: every decision with reasoning goes in
   `docs/` (the topic doc; history in BRINGUP_HISTORY.md); every test
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
   bug with reasoning, fix, and document the review (see
   docs/BRINGUP_HISTORY.md section 5 as the pattern).
9. **Documentation layout (re-cut 2026-08-12 per Soham)**: the ROOT
   README.md IS the fork guide (start-here, legends, fixes, constraints,
   debugging pointers) - teams read it first. The original lowRISC README
   lives ONLY at docs/UPSTREAM_README.md (verbatim). All other docs stay
   under docs/. scripts/ holds only the KEEPER PowerShell tooling
   (find_tools/find_vivado, run_regression, run_bitstream, compile_sims,
   run_freertos_sim); one-off debug runners were deleted 2026-08-12 -
   recover from git history, do not re-accumulate them.
   **Docs consolidated 2026-08-17 per Soham ("too much docs")**: docs/ is
   now 9 files - ASIC_SPEC (incl. roadmap sec. 10), FREERTOS_PORT,
   PRODUCTION_PERIPHERALS (incl. toy wiring sec. 8), HW_VALIDATION_PLAN,
   BRINGUP_TEST_REPORT, BRINGUP_HISTORY (merged BRINGUP_OVERVIEW +
   FPGA_BRINGUP + UART_CONTROL), WALKTHROUGH, STATUS_BRIEF,
   UPSTREAM_README. Do NOT create new doc files; extend these.
   **ONE-SCRIPT rule (Soham, 2026-08-18)**: the repo root has exactly ONE
   user script - `ibex_soc.bat` (opens the GUI). All flow logic lives in
   `scripts/flows.ps1` (setup/xpr/build/program/firmware/flashfw/
   flashonly/regression); each GUI button opens a console running one
   flow. Do NOT re-add per-flow .bat entry points. Internal plumbing
   that stays: sw/freertos/build.bat (firmware compiler, called by
   flows + regression), scripts/find_tools.cmd (its locator), the
   *.tcl implementation scripts, and the keeper scripts/*.ps1. The
   README stays SHORT - a front page, not a manual (detail lives in
   docs/); keep it that way.

## 3. Key technical facts (verified)

- **Memory map**: Boot ROM 4 KiB @ `0x0010_0000` (NOP sled + `jal` to
  `0x0010_2080`); SRAM **8 KiB** @ `0x0010_2000..0x0010_3FFF` (ASIC-spec
  size since 2026-08-10; range decode, NOT mask — base isn't size-aligned;
  base 0x0010_2000 TEAM-CONFIRMED 2026-08-10 — the spec sheet's printed
  0x0010_1000 is stale, docs/ASIC_SPEC.md section 3); **XIP flash
  window @ `0x2000_0000`** (read-only, cmd 0x03 single-bit SPI; firmware
  sits at flash offset 0x40_0000 behind the bitstream = CPU address
  `0x2040_0000`); UART `0x4000_0000` (RX +0 / TX +4 / STATUS +8: bit0
  rx_empty, bit1 tx_full); GPIO `0x4000_0100` (OUT +0: gp_o[7:4]=LEDs,
  [3:0]=DISP_CTRL; IN-dbnc +8 = {SW,BTN}); Timer `0x4000_0200` (CLINT-style
  mtime +0/+4, mtimecmp +8/+12); I2C `0x4000_0400` (OpenCores, Pmod
  JA1/JA2); SPI host `0x4000_0500`; PWM `0x4000_0600` (in BOTH FPGA and
  ASIC — team-confirmed 2026-08-10; the guide had merely omitted an
  upstream-inherited block); debug window `0x1A11_0000`.
- **Boot contract (since 2026-08-19, lead-directed)**: the boot ROM
  (`rtl/system/boot.mem`) jumps **DIRECTLY to `0x2040_0000`** (lui+jalr
  at reset PC `0x0010_0080`) — it never reads SRAM, because silicon SRAM
  powers up random. The legacy SRAM+0x80 entry (`0x0010_2080`) is
  re-written by startup.S each boot for debug flows; the linker keeps
  SRAM+0x00..0x8F reserved for it. DV-only: the 8 asm-demo benches boot
  via `dv/xsim/boot_sram_dv.mem` (old jal) to keep SRAM-resident test
  programs; tb_xip boots the REAL ROM with uninitialised (X) SRAM, and
  tb_freertos with deterministic random garbage
  (`dv/xsim/sram_powerup_random.vmem` — X-init passes but sprays benign
  X-payload asserts; random garbage models silicon power-up cleanly).
  Changing the boot path again = re-regress those two + a board boot.
- **QSPI flash pins**: CS=L13, DQ0(MOSI)=K17, DQ1(MISO)=K18; **SCK has no
  package pin** — it's the CCLK config pin, driven via STARTUPE2.USRCCLKO
  (top_artya7.sv). XipClkDiv param: FPGA top uses 1 (10 MHz; flash rated
  50 MHz), ASIC-spec default 4. Flow `flashonly` (program_flash.tcl) =
  bitstream+firmware MCS into flash. **QSPI-boot bitstream config lives
  in data/pins_artya7.xdc** (CFGBVS VCCO, CONFIG_VOLTAGE 3.3,
  BITSTREAM.CONFIG.SPI_BUSWIDTH 4 + CONFIGRATE 33 + SPI_FALL_EDGE YES):
  without SPI_BUSWIDTH=4 the SPIx4 write_cfgmem REJECTS the bitstream
  (gotcha 23; the config-time x4 read is independent of our x1 user XIP).
  Bitstreams built before 2026-08-18 must be rebuilt before flashing.
- **Ibex is vectored-only** (mtvec[1:0]=01 hardwired, 256-byte aligned):
  RTOS trap entry needs a 32-entry vector table (sw/freertos/startup.S);
  entry 7 = machine timer, base+0 = exceptions/ecall.
- **SPI/display pins already routed** in `data/pins_artya7.xdc`: SPI_TX=E5,
  SPI_SCK=A4, DISP_CTRL[3:0]=B7/B6/E6/A3 (ChipKit AD header pins) — used by
  the upstream ST7735 LCD demo (`sw/c/demo/lcd_st7735`).
- **Toolchain locations on this PC**: Vivado `C:\AMD\2026.1\Vivado\bin`
  (xvlog/xelab/xsim there too); **RISC-V GCC = the Zephyr SDK's
  `C:\FPGA\zephyr-sdk\gnu\riscv64-zephyr-elf\bin`** (the SDK stays as a
  plain bare-metal compiler even though the Zephyr port is gone);
  CMake `C:\Program Files\CMake\bin`; gh CLI
  `C:\Program Files\GitHub CLI\gh.exe`. My shells inherit a stale
  PATH — use full paths or prepend per-call.
- **RISC-V GCC is prefix- and host-agnostic (2026-08-18)**: the team
  standard is the **lowRISC toolchain**
  (lowrisc-toolchain-rv32imcb-20220524-1, prefix `riscv32-unknown-elf-`,
  GCC 10.2) whose tar.xz is **Linux-only** - on Windows it lives inside
  WSL and is stored as `RISCV_GCC_HOME=wsl:<linux path>`; build.bat then
  compiles via `wsl --cd sw\freertos -e bash ./build.sh` (build.sh = the
  POSIX twin; keep both compile lines in sync; `.gitattributes` forces LF
  on *.sh). Native toolchains (Zephyr SDK etc.) still work - prefixes
  tried in order: riscv32-unknown-elf-, riscv64-zephyr-elf-,
  riscv64-unknown-elf-, riscv-none-elf- (`RISCV_PREFIX` in .toolpaths).
  **-march is probed**: old GCC (lowRISC 10.2) rejects `rv32imc_zicsr`
  -> scripts fall back to plain `rv32imc` (correct there: pre-2.36
  binutils still includes CSR ops). Verified: build.bat and build.sh
  produce byte-identical .bin with the same toolchain (== the committed
  prebuilt, so no prebuilt refresh was needed).
- **CRITICAL Windows gotcha**: xvlog/xelab/xsim HANG (100% CPU, zero
  output, forever) when launched with piped stdio from the agent's
  Bash/PowerShell tools. Always launch via detached
  `Start-Process powershell -File scripts\<runner>.ps1` writing an ASCII
  log, then watch the log (`scripts/compile_sims.ps1` etc. are the
  pattern). Related: `Out-File` defaults to UTF-16 — always
  `-Encoding ascii` or grep-based watchers see NUL soup.
- **Build/run commands**: README quick start; FreeRTOS in
  docs/FREERTOS_PORT.md; sim flow in docs/BRINGUP_HISTORY.md section 4;
  gotchas in docs/WALKTHROUGH.md section 8.
- **Interrupts implemented**: timer on irq_timer_i (mcause 7); UART1 RX
  fast[0] (mcause 16, not unmasked by firmware); **UART2 RX fast[1]
  (mcause 17, level = RX-FIFO-not-empty)** - unmasked by esp_at_init(),
  ISR must drain the FIFO or the trap refires. Proven by tb_uart2_irq.
- **Tool location is centralized**: every script resolves Vivado/GCC via
  `scripts/flows.ps1`, `scripts/find_tools.cmd` (batch) or
  `scripts/find_vivado.ps1` (PowerShell, no prompt - safe for detached
  runs). Search order: `.toolpaths` (per-PC saved answers, gitignored:
  VIVADO_BAT / RISCV_GCC_HOME possibly `wsl:<path>` / RISCV_PREFIX) ->
  env vars -> PATH -> common roots (\Xilinx, \AMD, \AMDDesignTools,
  zephyr-sdk*, lowrisc-toolchain*) on EXISTING drives only -> WSL (GCC
  only) -> interactive ask-and-save. PS 5.1 trap (gotcha 21): NEVER
  `Get-ChildItem -Directory` on a guessed drive letter - on a machine
  without that drive it is a parameter-binding error that -ErrorAction
  cannot suppress; enumerate `Get-PSDrive -PSProvider FileSystem` first.
  NEVER hard-code an install path in a script again; extend the locators.
- **THE user entry point**: `ibex_soc.bat` -> gui/ibex_control_panel.ps1
  (WinForms, Windows-only per team direction; no Linux user utilities).
  Every button opens a console running `scripts\flows.ps1 <flow>`:
  - `setup` - environment doctor; locates AND saves tool paths
    (.toolpaths); run first on any new PC
  - `deps [force]` - GUI "Install Missing Tools" (beginner path, Soham
    2026-08-18): auto-installs Python via winget and the **xPack
    riscv-none-elf-gcc** (native Windows zip from the official
    xpack-dev-tools GitHub releases, version PINNED in flows.ps1 -
    currently 15.2.0-1, ~470 MB download -> C:\FPGA\, no WSL/admin),
    saves .toolpaths; Vivado is manual-only (30+ GB, AMD account) so it
    just prints guidance. `force` reinstalls GCC even if one is found.
    The GUI also shows a green "New PC? 1-2-3" hint line.
  - `xpr` - generate the Vivado GUI project (gen_project.tcl,
    build/vivado_project/*.xpr) for browsing (team request)
  - `build` / `program` - bitstream (build_fpga.tcl) / JTAG load
    (program_fpga.tcl, volatile dev-only, CLI-ONLY since 2026-08-18 -
    the GUI button was removed on Soham's direction)
  - `firmware [sim]` - compile FreeRTOS (sw/freertos/build.bat). ONE
    hardware image since 2026-08-18: TOY_DEMO (LCD/sensor task) is in
    every hw build ("toy" arg = harmless alias); only `sim` differs
  - `flashfw` - THE flow: firmware -> XIP bitstream -> QSPI
    flash, persistent. **BUILD-FIRST (Soham, 2026-08-18): no GCC ->
    interactive choice [Enter]=auto-install toolchain / [p]=committed
    prebuilt / [n]=abort; build failure with a toolchain present is a
    HARD STOP, never a silent prebuilt fallback.** Refresh the prebuilt
    whenever sw/freertos/** changes
  - `flashonly [bin]` - reflash only (program_flash.tcl)
  - `regression` - full suite (run_regression.ps1): images + FreeRTOS
    build + compile + 10 sims + bitstream + scoreboard, exit 0 = green
  flows.ps1 streams tool output via Write-Host (NOT the pipeline - the
  callers consume the numeric return; piping to Out-Null would eat the
  console output, this bit once). Keep this inventory + the WALKTHROUGH
  section-7 table current when touching flows.

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
**Zephyr selected** (decision memo + plan docs since deleted in the
v1.1 cleanup - git history keeps them; FreeRTOS was the contingency). Phase A: SRAM
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
copy, never the raw wire on the same edge. Docs: PRODUCTION_PERIPHERALS.md
section 8 (incl. hardware wiring table: LCD -> ChipKit A6..A11 + 3V3/GND).

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

**2026-08-10 (later) — v1.1 production peripherals, external-first**:
Team direction: WiFi/camera/mic/speaker/internet, production, all through
EXTERNAL memory/parts, everything sim-proven and tapeout-compatible.
Silicon additions (all small, doctrine-checked): UART2 @0x4000_0700
(ESP32 companion = the whole internet story), SPI-host RX register
(SPI+0x8: {seq,byte}) - the host could only transmit before, GPIO widened
8/8 -> 16/16 (gp_o[12:8]=CS+camera ctrl, gp_i[15:8]=camera byte bus,
read via the RAW +4 register, NOT the debounced +8). Pin plan 37/38
Caravel pads. External: APS6404 8MB PSRAM (bulk store: frames/clips/
buffers - the desk-vs-warehouse rule; NOT cpu/stack memory), OV7670-FIFO
camera (snapshots only), MCP3202+MAX9814 mic, PAM8302+PWM-ch3 speaker.
Four behavioral models (periph_models.sv) + 4 tbs + 4 asm programs;
FreeRTOS drivers: spi_bus (bus mutex + atomic GPIO RMW), psram, esp_at,
audio, camera. GUI control panel (WinForms) at control_panel.bat.
Debug lessons -> gotchas 19a/19b: xsim drops edge events through
bit-select port connections (use intermediate wires), and UART models
must tolerate the reset-glitch 0xFF frame. Superseded RTOS docs
(RTOS_RESEARCH, ZEPHYR_DECISION) deleted - git history keeps them;
conclusion lives in ASIC_SPEC.md section 10. New docs (later consolidated):
PRODUCTION_PERIPHERALS.md (architecture/pins/BOM/ceilings), roadmap
(v1/v2/never-on-die + carrier board, now ASIC_SPEC.md section 10).

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

**2026-08-17/18 — lead directive executed: UART2 IRQ + toolchain-less flashing
+ docs cut**: Ravi (lead) confirmed the architecture (UART1 = console,
UART2 = ESP32) and directed: UART2 RX onto an unused Ibex fast IRQ (it was
polling-only despite the 128-byte FIFO), a high-priority RX task + unsolicited
ESP-AT event parser, regression covering simultaneous UART1+UART2 / FIFO
burst-overflow / IRQ / events / recovery, then a reviewable PR into the ARF
repo and on-board AT/join/HTTP validation. Executed: (1) RTL - uart2_irq_o
out of wrapper_top -> irq_fast_i[1] (mcause 17, vector 17); ~zero gates (the
uart module already generated the IRQ). (2) DV - tb_uart2_irq + bare-metal
proof program with a real 32-entry vector table (assemble.py grew
csrw/csrs/csrc/csrr/mret): IRQ delivery with zero polling, 160-byte burst
into the masked FIFO keeps EXACTLY 128 (32 dropped, count-verified),
'+IPD' line intact after overflow, console echoes mid-burst. PASS, 2.6 ms
sim. New gotcha 20: early `return` inside a timed loop in a tb task
FATAL_ERRORs the xsim kernel - exit via loop condition. (3) FW - esp_at.c
dual-mode: polled until esp_at_init(), then ISR->256-B ring->'esp-rx' task
(configMAX_PRIORITIES-1) with line classifier; esp_at_cmd() sleeps on task
notification; events (WIFI */+IPD/ready/busy/+CWJAP:/SEND FAIL) reach
esp_at_on_event() even mid-command; main.c dispatches mcause 17 ->
esp_at_isr(). Builds clean (data+bss 1048 B). (4) Teammate ARF-BBSR-84's
"unable to dump" (FREERTOS.docx logs) root-caused: programming SUCCEEDED
(DONE HIGH); flash_freertos died at build - no RISC-V GCC on that PC ->
prebuilt-firmware fallback committed (sw/freertos/prebuilt/, auto-fallback
in flash_freertos.bat, setup_check message). (5) Docs 13 -> 9 (rule 9).
Remaining from Ravi's list: the PR into the ARF repo (needs Soham - direct
push is branch-protected) and the on-board Phase-3 validation (parts).

**2026-08-18 — ONE-SCRIPT consolidation + lean README (Soham directive)**:
"only one AIO bat script with gui... readme simple, docs simple". Executed:
8 root .bat entry points (setup_check, build_fpga, program_fpga,
program_flash, flash_freertos, run_regression, gen_project, control_panel)
DELETED and replaced by `ibex_soc.bat` -> the WinForms GUI, whose buttons
each open a console running `scripts\flows.ps1 <flow>` (setup/xpr/build/
program/firmware/flashfw/flashonly/regression). flows.ps1 carries a full
PowerShell port of the tool locator (same .toolpaths contract) and the
prebuilt-firmware fallback. Verified: `setup` flow all-OK, `firmware` flow
BUILD OK. Bug caught: helper functions that return an exit code must
Write-Host the tool output - callers piping to Out-Null were eating the
console stream. Root README rewritten as a short front page (~120 lines:
quick start = one script, console table, constraints, status, doc index,
layout); the fixes/added/patches detail lives in docs/BRINGUP_HISTORY.md
and git history. WALKTHROUGH sections 3-5 re-cut to lead with the ONE flow
(also fixed a latent \\f/\\b control-char corruption in its script table).
All doc/tcl/script references to the deleted .bats updated.

**2026-08-18 (later) — teammate lab logs + lowRISC toolchain support**:
Three logs from ARF-BBSR-84 (Vivado 2025.2 @ C:\AMDDesignTools): bitstream
BUILD OK and .xpr PROJECT OK - both flows work on their PC; the env check
worked but spewed red `Get-ChildItem -Directory` parameter-binding errors
(gotcha 21: dynamic FileSystem param can't bind on drives D..G that don't
exist there; -ErrorAction can't suppress binding errors) - fixed by
enumerating Get-PSDrive. Team compiles with the lowRISC toolchain
(riscv32-unknown-elf-, Linux-only tar.xz -> WSL): all three locators went
multi-prefix + WSL-aware (RISCV_GCC_HOME=wsl:..., RISCV_PREFIX saved),
build.bat gained the -march probe (GCC 10.2 rejects _zicsr) and a WSL
delegation path through the new sw/freertos/build.sh (POSIX twin, LF
enforced via .gitattributes). \AMDDesignTools added to the Vivado scans.
Verified: cold+warm setup and find_tools runs, build.bat == build.sh ==
prebuilt byte-identical (b15234fc...), march-probe fallback exercised,
PSParser 0 errors. Docs: FREERTOS_PORT Toolchain section rewritten
(lowRISC install incl. WSL commands), WALKTHROUGH gotchas 21+22 +
locator/table text, this file.

**2026-08-18 (evening) — GUI dependency installer (Soham: "they don't
know what is WSL/opt... install easily in Windows, through GUI")**: new
`deps` flow + GUI button "Install Missing Tools" (row 1, step 2 of the
green New-PC hint line). Installs Python (winget) and the xPack
riscv-none-elf-gcc - chosen because it is the only major RISC-V bare-metal
GCC shipped as a NATIVE Windows zip (no WSL, no admin, official
xpack-dev-tools releases; our locators already knew the riscv-none-elf-
prefix). Version pinned (15.2.0-1, asset name verified via GitHub API);
extract to C:\FPGA\ and save .toolpaths. lowRISC/WSL remains the advanced
option in FREERTOS_PORT (reference toolchain), xPack is the recommended
beginner path. xpack-riscv-none-elf-gcc* added to the scan roots of both
GCC locators. Tested for real on this PC: forced install downloaded +
extracted + saved, then a full firmware build with the xPack GCC.
Gotchas: $home is a READ-ONLY PS automatic variable (use $gccHome);
IWR needs TLS1.2 opt-in on PS 5.1; $ProgressPreference silent makes IWR
~10x faster.

**2026-08-18 (night) — first REAL Flash-to-Board run found a latent bug**:
teammate reached step 3/3 (so the prebuilt-firmware fallback worked on
their PC) and hit `write_cfgmem ERROR SPI_BUSWIDTH property is set to
"1"` - our bitstreams never set BITSTREAM.CONFIG.SPI_BUSWIDTH, while
program_flash.tcl writes an SPIx4 MCS. Never seen locally because the
flash flow had not run end-to-end since XIP (board away; regression
builds the bitstream but no MCS). Fix in data/pins_artya7.xdc (single
source for batch build AND .xpr): CFGBVS VCCO, CONFIG_VOLTAGE 3.3,
SPI_BUSWIDTH 4, CONFIGRATE 33, SPI_FALL_EDGE YES (Digilent-recommended
for the Arty S25FL128). program_flash.tcl now catches the stale-bitstream
case with a "git pull + rebuild" hint. Verified: full bitstream rebuild
with the new XDC (timing met) + write_cfgmem now produces the MCS.
Gotcha 23. Old build/ trees must rebuild the bitstream once.

**2026-08-18 (night, later) — FIRST v1.1 HARDWARE PASS + console UX rework**:
after the SPI_BUSWIDTH fix the teammate's Flash-to-Board ran clean end to
end: FreeRTOS BOOTED FROM QSPI FLASH ON THE BOARD - banner on PuTTY, tick
heartbeat, all console keys, switch-mirror. Phase 1 core = PASSED (evidence
table: BRINGUP_TEST_REPORT section 8; plan boxes ticked in
HW_VALIDATION_PLAN). Their two findings, both fixed same day:
(1) only RGB LED0 lit - prvRgbTask drove PWM ch0-2; now drives all 12
channels = all 4 board RGB LEDs in unison (ch3 doubles as SPKR - harmless
until a speaker is wired, note in main.c). (2) tick spam - Soham/lead
want boot info readable: new hardware-only system-info banner (core,
kernel ver, memory map, peripherals, key help - NO __DATE__/__TIME__,
builds must stay byte-reproducible), heartbeat now quiet 30 s then
`tick=N up=Ss` every 10 s, new 't' key toggles it. SIM_BUILD keeps the
short banner + immediate 1-tick cadence so tb_freertos still passes
(re-ran: PASS banner=1 ticks=2). All variants rebuilt, RAM budget
unchanged (1048 B), prebuilt refreshed (7552 B). Teammate needs ONE more
Flash-to-Board click to get the 4-RGB/banner firmware.

**2026-08-18 (late night) — kernel V11.3.0 + build-first flashing +
vendored-pin audit (Soham: "prefer build the flash... ensure OS and Ibex
always updated")**: (1) FreeRTOS kernel vendored subset synced V11.2.0 ->
V11.3.0 (latest upstream; diff = FPU/VPU port support compiled out on
RV32IMC, task-startup mstatus fix, context renumbering; the
freertos_risc_v_application_interrupt_handler contract unchanged; all
variants rebuilt, RAM budget unchanged, tb_freertos PASS, prebuilt
refreshed 7576 B; procedure recorded in VENDORED.txt). (2) flashfw is now
BUILD-FIRST: extracted Install-XpackGcc into a shared function; no-GCC
case asks install/prebuilt/abort; prebuilt NEVER silent (all docs +
tooltips reworded). (3) Vendored-pin audit: Ibex 594ea976 (2025-04-03) is
154 commits behind master - DELIBERATELY not synced (FPGA must validate
the tapeout netlist; standing patches + policy in BRINGUP_HISTORY sec. 3,
pin table added there + FREERTOS_PORT "Staying current"); flagged as a
lead watch-item in STATUS_BRIEF. Answered in docs (FREERTOS_PORT "Where
the code lives"): kernel is vendor/freertos_kernel (main.c is only the
app); code XIPs from flash, SRAM holds only data/bss/heap/stacks.

**2026-08-18 (Phase 2a prep) — LCD system-status screen, no-solder wiring
(Soham: "wire only the led display... without soldering... same stuff as
putty can be shown in that")**: the ST7735 is the ONE batch-1 part that is
pre-soldered, so Phase 2a = LCD only on 8 jumper wires (ChipKit A6-A11 +
3V3/GND; tables in PRODUCTION_PERIPHERALS sec. 8 "Phase 2a"). (1) st7735.c
gained a classic 5x7 font (475 B const -> XIP flash, ZERO SRAM) +
st7735_text/_ex (6x8 cells, 21 cols x 20 rows, streams straight into RAMWR
like every primitive - same command sequence tb_lcd proved). (2) prvToyTask
is now a live status screen mirroring the PuTTY console: orange title bar,
core/kernel/memory banner, then uptime/tick/pattern/speed/last-key/RGB/
beat/OLED-BME presence (+ temperature when a BME280 joins) refreshed every
1 s; missing I2C parts show "--" (all I2C waits are bounded - nothing
hangs, so LCD-only wiring is safe). (3) REAL BUG fixed by review: st7735's
prv_gpio_set did a raw RMW on shared GPIO_OUT, racing the LED tasks'
gpio_out_update (stale-nibble writeback on preemption); harmless at
write-once frequency, real at 1 Hz updates -> now routes through
gpio_out_update. Gotcha 24: EVERY GPIO OUT change goes through
gpio_out_update(). tb_freertos re-run PASS (banner=1 ticks=2); all three
variants rebuilt; prebuilt refreshed (7584 B); RAM budget unchanged
(~1.1 KB static). Test 14 criterion updated (status screen, not the old
orange rectangle); new Phase 2a row in HW_VALIDATION_PLAN + STATUS_BRIEF.
Follow-up same day (Soham: "write ARF or something informative... if its
not too much sluggish"): st7735_text_scale (any integer scale, pixel
coords; text_ex is now the scale-1 wrapper) draws a big orange ARF logo
(3x) at the top; live "up" line gained a rotating |/-\ alive-spinner.
Sluggishness handled head-on: XIP code is ~500x slower than SRAM (gotcha
19), so a full redraw every second would crawl -> prvLcdLiveLine keeps a
126 B shadow of the live rows and rewrites ONLY changed cells (~6
cells/s, tens of ms). Also documented for beginners: the "power header"
is a socket row printed on the Arty itself (3V3/GND silkscreen), nothing
to buy - Phase 2a shopping list is the LCD + 8 F-M jumpers; recommended
session order (Phase 1 console re-check unwired -> power off -> wire ->
Phase 2a) now in PRODUCTION_PERIPHERALS sec. 8. Standard/sim binaries
byte-identical after the change (toy-only code); tb_freertos re-run PASS.

**2026-08-18 (bench debug) — dark LCD root-caused: variant dropdown ->
ONE hardware image; JTAG button removed**: Soham wired the LCD (console
fine, 3.3 V present, screen dead). Debug: XDC verified pin-by-pin against
the sec.-8 table (DISP_CTRL[0]=B7/A6, [1]=B6/A7, [2]=E6/A8, SPI_TX=E5/A9,
SPI_SCK=A4/A10, [3]=A3/A11 - wiring story is CORRECT); real cause = GUI
variant dropdown defaulted to "standard demo", which had no LCD code -> a
correctly wired display stays dark (gotcha 25, incl. the residual
checklist: old fw / BL wire / silkscreen order / CS-DC swap). Structural
fix per Soham: MERGED THE VARIANTS - build.bat/build.sh default hw image
now defines TOY_DEMO ("toy" stays a harmless alias; NAME stays
freertos_demo so flows/prebuilt paths are unchanged), the LCD/sensor task
is missing-part tolerant so it ships everywhere; FW_VARIANT is now just
hw/sim. GUI: variant dropdown DELETED, Program Board (JTAG) button
DELETED (dev-only, CLI `flows.ps1 program` remains). ARF logo recoloured
deep blue per request (ST7735_RGB(0x00,0x40,0xE0)). Heap check: 6 tasks
~3.4 KB of the 4 KiB heap - fits, sections budget unchanged. tb_freertos
PASS (sim image unaffected); prebuilt refreshed = the combined image
(~12.8 KB; XIP makes code size a non-issue). Docs swept for "variant
toy" (README, FREERTOS_PORT incl. stale task list, PRODUCTION_PERIPHERALS,
HW_VALIDATION_PLAN, WALKTHROUGH flow table, STATUS_BRIEF, prebuilt
README).

**2026-08-18 (bench, round 2) — REAL RTL BUG: SPI mode-0 hold time; first
bug found by physical hardware**: after the one-image fix the LCD backlit
WHITE but never drew (backlight = gp_o[3], so its lighting proved firmware
+ GPIO wiring good; white = ST7735 controller never initialised). Teammate
asked to verify spi_host/spi_top mode of operation - correct instinct.
Root cause in vendor-fork rtl/system/spi_host.sv gen_no_cpha (CPOL=0/
CPHA=0): the TX shift (current_byte_q <= current_byte_d) sat in the
sck_pos branch, so MOSI changed ON the rising edge - the exact edge a
mode-0 slave samples: zero hold time, every byte garbled. The block
comment even said "shifted out on the falling edge" - code contradicted
it. NEVER caught in sim because tb_lcd's model (and periph_models.sv)
sampled a #2-DELAYED MOSI copy - models written to match the RTL race
instead of the datasheet part (the workaround was explicitly commented!).
Fix: TX launch moved to sck_neg (half period setup AND hold; also loads
byte7 half a cycle before the pad clock starts via the START->SEND
commit). RX sampling (sck_pos) + state bookkeeping untouched -> PSRAM/ADC
read path unaffected; models unchanged (delayed copy now reads the same
stable bit). CPHA=1 branch left alone (unused, unverified - noted).
ASIC-CRITICAL: spi_top is in the tapeout netlist; flagged in STATUS_BRIEF
decision 1 (netlist delta grew; fix is non-optional for silicon SPI).
Gotcha 26 = the modelling lesson (model the part, not the RTL). Full
regression re-run after the fix; board flashed from this bench (board
connected to the dev PC for the first time).

**2026-08-18 (bench, round 3) — autonomous Phase-1 testing + BUG #9 (warm
reset) + mode-0 accountability**: board on the dev PC; testing fully
scripted (JTAG boot_hw_device = PROG press; pyserial COM4). (1) Soham's
mode-0 questions answered honestly: the RTL bug is upstream lowRISC 2022
code ("Basic SPI Host implementation", pre-fork), NOT introduced here -
BUT the 2026-08-08 tb_lcd session SAW the symptom (bytes left-shifted
under datasheet-correct sampling) and adapted the MODEL instead of
questioning the RTL. Owned as a process failure -> Rule 1b (model the
part, never the RTL; every test workaround = suspected RTL bug; verify
consequences before acting). (2) The "board hangs after ~1 min" red
herring: bracketing showed 130 s of flawless echoes/heartbeats - the
board only died when a serial session CLOSED. Causality experiment:
alive at t=43 s, close at 45 s, reopen at 50 s = dead; JTAG touch no
revive, reconfig revives. Mechanism: port close deasserts DTR ->
Arty couples it to ck_rst = IO_RST_N -> rst_sys_n held low (level!)
until reopen; the warm reset then CRASH-LOOPED because .bss covered
0x102080 - the boot ROM jumps to SRAM+0x80 on EVERY reset and the XIP
trampoline was clobbered at startup (old link_xip.ld comment even
documented the clobber as harmless - only true when reset==reconfig;
same lesson family as Rule 1b: written-down assumptions need re-checks).
Fix: RAM ORIGIN 0x102090 (SRAM 0x00-0x8F reserved) + startup.S rewrites
the trampoline (self-healing, covers post-DV-program resets too).
Verified end-to-end: tb_freertos PASS, reflash, close/reopen now = clean
reboot with fresh banner; uart_command_test.py 8/8 ALL PASS (Phase-1
test 8 done; 1/2/10/11/13 re-evidenced; RGB 4-LED = PASS per Soham's
PuTTY session). ASIC IMPLICATION raised as STATUS_BRIEF decision 4:
silicon SRAM powers up random + no bitstream init -> boot ROM as-is
cannot complete FIRST boot; ROM must write the trampoline or jump
straight to XIP. Serial disconnect = board reboot (gotcha 27) - normal
and now harmless.

**2026-08-18 (round 4) — Phase 2a PASSED + team-commit audit + SPICTRL
removed**: Soham confirmed the TFT renders ("tft is also coming fine") -
Phase 2a test 14 PASS, Phase 1 + 2a both closed same day. Audited three
ArfDesign-DB commits on request: 740d59c9 (their 20 MHz/path fixes = our
day-one fixes, Verilator flow = not ours; REVIEW FLAGS raised: DFFRAM
under `ifdef verilator` with empty else = synthesis gets NO SRAM as
committed, and DFFRAM WE must be per-byte for sb/sh), 498798b (FuseSoC
.core boot.mem - their flow only), 8ed494d (SPI_CTRL stub comment-out -
ADOPTED as a full delete: decode + ports + stub logic gone from
wb_interconnect/wrapper_top/map comment; ours even had spictrl_rvalid
UNDRIVEN, a latent X-source; shrinks the PD-netlist delta). Also fixed
the stale ibex_demo_system.sv map comment (0x600 is PWM, 0x700 UART2).
Full regression re-run after the RTL delete; board reflashed.

**2026-08-18 (round 5) — PR to the team repo**: pushed our main as branch
`freertos` on ArfDesign-DB/minimal-ibex-soc (their main is an ancestor -
clean diff, 345 commits) and opened PR #17
(https://github.com/ArfDesign-DB/minimal-ibex-soc/pull/17): full
technical summary - Phase 1 + 2a hardware passes, the 10 fixes
(bring-up quartet, 3 XIP bugs, I2C BFM, SPI_BUSWIDTH, mode-0, warm-reset
trampoline, SPICTRL removal), v1.1 additions, 14/14 regression,
next steps + the pre-freeze decision list incl. both DFFRAM review
flags. Merging is the team's call (branch-protected main).

**2026-08-19 — DIRECT XIP BOOT (lead-directed) + Phase 2b prep**: Ravi's
reply resolved the open decisions: UART2 IS in the tapeout netlist;
first boot = **direct XIP** ("no dependency on SRAM power-up contents,
regress thoroughly"); DFFRAM fixes assigned to the team; mode-0 fix
confirmed must reach PD; Verilator regression is Shivanee's.
Implemented same day:
- `boot.mem` word 32/33 = `lui t0,0x20400; jalr x0,0(t0)` — the ROM
  never reads SRAM. New `BootInitFile` param plumbed through
  ibex_demo_system/wrapper_top; the 8 asm-demo benches boot a DV-only
  SRAM-jump ROM (`dv/xsim/boot_sram_dv.mem`); **tb_xip boots the real
  ROM with SRAMInitFile="" = X-filled SRAM (clean — zero asserts);
  tb_freertos with deterministic random garbage** (X-init passed but
  produced 571 benign IbexDataRPayloadX asserts from word-reads of
  byte-built buffers — silicon returns random there, so
  `sram_powerup_random.vmem` models the part per Rule 1b without
  X-pessimism noise). Bitstream bakes NO SRAM
  image any more (build_fpga.tcl conditional generic, gen_project.tcl,
  flashfw). startup.S keeps writing the legacy SRAM+0x80 trampoline
  (debug flows; comment updated). Compatibility matrix = gotcha 29.
- **Rule 1b follow-through**: removed the delayed-MOSI sampling from
  tb_lcd's ST7735 model + periph_models' PSRAM model — all SPI models
  now sample the raw wire at the rising edge (datasheet behaviour); a
  hold-time regression fails in sim now, not on a panel.
- **Phase 2b firmware** (OLED + BME280 arrived): signed temperature
  print (was 4-billion below 0 degC), H on LCD, P + uptime on OLED,
  UART T/P/H every 10 s gated by 't' (was 1/s unconditional), absent
  parts re-probed every 5 s (hot-attach `toy: oled/bme attached`), 3
  consecutive I2C fails demote to absent (`toy: bme lost`). Soldering +
  wiring guide written (PRODUCTION_PERIPHERALS sec. 8 Phase 2b).
- Regression **14/14 ALL GREEN** on all of the above (incl. bitstream,
  timing met). Board was not connected this session — first `flashfw`
  + Phase 2b bench run is the next hardware step.

## 5. Open questions for the team (track until answered)

1. ~~SRAM base address~~ **RESOLVED 2026-08-10: team confirmed
   `0x0010_2000` (the repo's value) is correct**; the spec sheet's printed
   `0x0010_1000` is stale. (Boot entry moved off SRAM entirely on
   2026-08-19 — direct XIP, see section 2 "Boot contract".)
2. ~~PWM block at `0x4000_0600`~~ **RESOLVED 2026-08-10: keep in BOTH FPGA
   and ASIC** (sub-lead: spec omitted it only because it predates the fork;
   it was present in the original ibex-demo-system). No RTL change.

**All open questions resolved** — the validated FPGA configuration IS the
tapeout configuration. Resolution trail: README.md section 6 and
docs/ASIC_SPEC.md section 3.

## 6. Current status / next steps

- **Configuration is now ASIC-representative**: 8 KiB SRAM, XIP wired to
  the onboard QSPI flash, FreeRTOS as the RTOS. Full regression green
  **2026-08-19: 14/14** (images, FreeRTOS build, compile, 10 sims,
  bitstream BUILD OK with all timing met) - the first run on the
  direct-XIP boot ROM with uninitialised-SRAM XIP benches and strict
  mode-0 SPI models.
- **ONE FLOW decision (Soham, 2026-08-10)**: user-facing delivery is
  ONLY the non-volatile QSPI path (flow `flashfw`); the unified
  FreeRTOS firmware absorbed the asm-demo console (patterns/speed/RGB/
  echo/switch-mirror as tasks in main.c). The asm demo + program_fpga
  (JTAG) remain DV/dev-internal only - do not present them as user
  flows. Since 2026-08-19 bitstreams bake NO SRAM image (direct-XIP boot
  ROM; every bitstream boots FreeRTOS from flash via the silicon path).
  Rationale: FreeRTOS cannot fit in 8 KiB SRAM, so a truly volatile
  FreeRTOS load is physically impossible.
- **Hardware validation: Phase 1 core PASSED 2026-08-18** on
  ARF-BBSR-84's board - v1.1 FreeRTOS booted from QSPI flash (XIP),
  console/patterns/switch-mirror all good (BRINGUP_TEST_REPORT section
  8, HW_VALIDATION_PLAN boxes ticked). **Phase 1 COMPLETE + Phase 2a
  (LCD) PASSED 2026-08-18** (autonomous bench run: sweep 8/8, RGB 4-LED
  PASS, banner/echo/XIP/heartbeat/persistence re-evidenced; TFT visually
  confirmed by Soham; only the no-instruments Pmod touch-test remains,
  needs hands). **Phase 2b READY 2026-08-19** (parts in hand, firmware
  auto-detects + self-heals, guide in PRODUCTION_PERIPHERALS sec. 8;
  needs one board session - board was not connected on 08-19),
  Phase 3 = batch-2 parts (ESP32 incl.
  IRQ-mode check 20b / PSRAM / camera / mic / speaker). Results get
  dated tables in BRINGUP_TEST_REPORT.md; a phase is not done until the
  report shows it. Teammate PCs verified working (2026-08-18): bitstream
  build, .xpr generation, flash programming, board bring-up - all on
  Vivado 2025.2 with no local RISC-V toolchain (prebuilt fallback).
- **UART2 IRQ path is in RTL as of 2026-08-17** - the PD synthesis
  netlist mismatch (netlist predates ALL v1.1 additions) is still THE
  open decision with the lead; whatever is decided, the FPGA must
  re-validate exactly the netlist being taped out. Ravi's remaining
  asks: reviewable PR into the ARF repo (Soham must open it - branch
  protection), and on-board AT/join/HTTP validation (Phase 3, parts).
- CI: evaluated 2026-08-10 and DEFERRED by Soham ("ignore for now").
  When revisited: Tier A/A+ (firmware + images + sv2v/Yosys check) fits
  free GitHub runners; full xsim/Vivado regression needs a self-hosted
  runner (repo is PUBLIC - push-to-main-only trigger, never PRs);
  GitHub ships no EDA images (licensing). tsfpga evaluated: flow-automation
  overlap with what we built, does not solve Vivado hosting - v2-era
  tooling candidate at most.
- Procurement: batch-1 parts (~Rs 4,550) in transit; batch-2 v1.1 parts
  (~Rs 1,800: ESP32, PSRAM, OV7670-FIFO, mic chain, speaker chain) mail
  PREPARED and handed to Soham 2026-08-10 (Outlook clipboard flow);
  awaiting order confirmation. Camera MUST be the AL422B-FIFO variant.
- Parts arrive -> wire per docs/TOY_INTERFACING.md tables, flash the
  `build.bat toy` firmware; solder guidance promised for BME280/OLED
  headers ("ping me before you start").
- No open spec questions (SRAM base 0x0010_2000 and PWM-in-both confirmed
  2026-08-10). Waiting on: PR #16 review.
