# Walkthrough — Clean PC to Working Board, Step by Step

*Follow this top to bottom and you will reproduce exactly what we have:
the Ibex SoC running on an Arty A7 with UART-interactive LED/RGB control.
Time: ~1–2 h if Vivado needs installing, ~20 min if it's already there.*

Every utility script is documented in §7, every known gotcha in §8.

---

## 1. Prerequisites

| Need | Notes |
|---|---|
| Windows PC, ~40 GB free disk | Windows-first tooling; Linux users drive the same Tcl scripts by hand |
| **Vivado ML Standard** (free) | Installer: https://www.xilinx.com/support/download.html — needs a free AMD account. Select product **Vivado**, edition **Standard**, devices: **Artix-7 only** (saves ~50 GB), and **keep "Install Cable Drivers" ticked** (without it the board is invisible). Default install path (`C:\Xilinx` or `C:\AMD`) — the tooling auto-detects both, including the new `C:\AMD\<version>\Vivado` layout |
| Python 3.x | Any recent version; stock library only. Optional `pip install pyserial` for the scripted serial tools |
| Arty A7 board + **micro-USB data cable** | Some charging cables have no data lines — if no COM port appears, try another cable first |
| Git | To clone the repo |

> **Gotcha #0:** clone to a path **without spaces** and **outside OneDrive**
> (e.g. `C:\FPGA\minimal-ibex-soc`). Vivado misbehaves with spaces in paths,
> and OneDrive sync fights the thousands of build files.

## 2. Get the code

```
git clone https://github.com/ArfDesign-DB/minimal-ibex-soc.git C:\FPGA\minimal-ibex-soc
cd C:\FPGA\minimal-ibex-soc
git checkout fix/fpga-bringup
```

The branch matters: it contains the fixes that make the FPGA flow work at
all (see [BRINGUP_HISTORY.md](BRINGUP_HISTORY.md) for what was broken).

## 3. Put FreeRTOS on the board — the ONE flow (~20 min)

Double-click **`ibex_soc.bat`** (the single entry point — a GUI with one
button per flow) and click **Flash to Board (QSPI)**. It runs three steps in
a console window:

1. builds the FreeRTOS firmware (**build-first**: no toolchain? it offers
   the automatic GCC install right there; the committed prebuilt is
   flashed only if you explicitly pick it),
2. builds the XIP-boot bitstream (~15 min),
3. programs bitstream + firmware into the QSPI flash — survives power-cycle.

Then **press PROG** on the board (or power-cycle). CLI equivalent:
`powershell -File scripts\flows.ps1 flashfw`.

Verifying the bitstream step — `build\fpga\build.log` must contain BOTH
`$readmem` "read successfully" lines (boot.mem + the SRAM image), and
`build\fpga\timing_summary.rpt` must say
*"All user specified timing constraints are met."*

> Board variant: the flow targets the **Arty A7-100T** (`xc7a100tcsg324-1`).
> For an A7-35T change one line in `build_fpga.tcl`:
> `set part xc7a35ticsg324-1L`.

## 4. Dev-only: JTAG programming (~30 s)

`ibex_soc.bat` → **Program Board (JTAG)** loads the bitstream over USB
without touching the flash — quick during development but **volatile**
(power-cycle restores the flash content), and the default bitstream boots
FreeRTOS *from flash*, so the flash must have been programmed once by the
Flash to Board flow or PuTTY stays silent.

## 5. Talk to it over UART

1. Find the COM port: Device Manager → *Ports (COM & LPT)* →
   "USB Serial Port (COMx)". **The number is per-PC** — ours was COM4,
   yours may differ.
2. PuTTY: Connection type *Serial*, Serial line *COMx*, Speed **115200**,
   Open.
3. You should see the `FreeRTOS on Ibex (XIP, 8KiB SRAM)` banner followed
   by a full system-info block (core, kernel version, memory map,
   peripherals, key help). The board is quiet for the next 30 s (time to
   actually read it), then a liveness heartbeat `tick=N up=Ss` reports
   every 10 s — it is diagnostics only, not required for anything; the
   `t` key switches it off/on. All four RGB LEDs breathe together. Now
   type single characters (no Enter):

   `1`-`4` LED pattern · `f/m/s` speed · `r/g/b/w` force RGB colour ·
   `a` RGB auto · `t` heartbeat on/off · anything else echoes.

> **Reading the terminal:** your typed keys are echoed back by the FPGA as
> the acknowledgement, so they appear interleaved with any heartbeat line
> (`srgtick=642 up=32s` = you pressed s, r, g just before a report).
> That interleaving is expected, not corruption.

4. Optional scripted check (close PuTTY first — **only one program can own
   a COM port**):

```
python util\uart_command_test.py
```

Expected: 8× PASS, `overall: ALL PASS`.

## 6. Optional: run the full-SoC simulation

From the repo root (paths are relative to it):

```
python sw\asm-demo\assemble.py --sim
xvlog -sv -f dv/xsim/filelist.f dv/xsim/tb_soc.sv dv/xsim/sim_stubs.sv -i vendor/lowrisc_ip/ip/prim/rtl -i rtl/system -i vendor/lowrisc_ibex/vendor/lowrisc_ip/dv/sv/dv_utils
xelab tb_soc -s soc_sim -timescale 1ns/1ps
xsim soc_sim -R
```

(`xvlog`/`xelab`/`xsim` live in `C:\AMD\<ver>\Vivado\bin` — use a "Vivado
Tcl shell" or add that dir to PATH.) Expected: `9 PASS, 0 FAIL` in a few
minutes of wall clock (~6 ms of simulated time).

## 7. Script & file reference

| Script | What it does | How to run | Notes / gotchas |
|---|---|---|---|
| **`ibex_soc.bat`** | THE entry point: opens the GUI (every flow is a button + live log pane) | double-click | The only .bat in the repo root by design |
| **`scripts/flows.ps1`** | All flows in one dispatcher: `setup` `deps [force]` `xpr` `build` `program` `firmware [sim]` `flashfw` `flashonly [bin]` `regression` | `powershell -File scripts\flows.ps1 <flow>` (each GUI button opens exactly this in a console) | Locates tools itself (same `.toolpaths` order as find_tools.cmd) |
| flow `deps` | GUI **Install Missing Tools**: auto-installs Python (winget) + the xPack riscv-none-elf GCC (native Windows, pinned version, ~470 MB from the official xPack GitHub releases into `C:\FPGA\`) and saves `.toolpaths`; prints manual guidance for Vivado | GUI **Install Missing Tools**, or `flows.ps1 deps` (`force` = reinstall GCC) | Needs internet + ~3 GB free on C:. No WSL, no admin. The beginner path: Environment Check -> Install Missing Tools -> Flash to Board |
| `build_fpga.tcl` (flow `build`) | Full synth→place→route→bitstream, SRAM image baked in (default: the XIP trampoline) | GUI **Build Bitstream** | Must run from the repo root (the Tcl `cd`s there itself). Change `set part` for other boards |
| `program_fpga.tcl` (flow `program`) | Loads `build/fpga/top_artya7.bit` over USB-JTAG | GUI **Program Board (JTAG)** | Dev-only, volatile; board must be plugged in |
| `gen_project.tcl` (flow `xpr`) | Generates a Vivado GUI project (`build/vivado_project/*.xpr`) for browsing | GUI **Generate .xpr** | Browsing only — the official build stays the batch flow |
| `sw/asm-demo/assemble.py` | RV32IM mini-assembler **and** the demo program in one file; regenerates `sram_init.vmem` | `python assemble.py` (hardware) / `--sim` (simulation image) | Rebuild the bitstream after regenerating. The two `.vmem` files are committed so this step is only needed when *changing* the program. Program entry must stay at SRAM+0x80 (the boot ROM jumps there) |
| `util/uart_command_test.py` | Scripted hardware test of every UART command with PASS/FAIL output | `python util\uart_command_test.py [COMx]` | Needs `pip install pyserial`; auto-detects the FTDI port; **close PuTTY first** or you get "Access is denied" |
| `dv/xsim/filelist.f` | The single compile-order list used by BOTH xsim and synthesis | consumed by the commands in §6 and by `build_fpga.tcl` | Add new RTL files here (packages before users). Keeping one list is what guarantees sim==hardware |
| `dv/xsim/tb_soc.sv` | Full-SoC testbench: boots the real ROM+SRAM images, drives UART/buttons, self-checks | §6 | Uses a 2 Mbaud sim UART and the `--sim` program image so everything happens in ms, not minutes |
| `dv/xsim/prim_shims.sv` | Hand-written stand-ins for the FuseSoC-generated "abstract primitives" | always in the filelist | With `FPGA_XILINX` defined (synthesis) the clock gate becomes a real BUFGCE |
| `dv/xsim/sim_stubs.sv` | Behavioural stub for the Xilinx `BSCANE2` JTAG macro | **simulation only** | Never add to a synthesis file list — Vivado supplies the real primitive |
| `program_fpga`/`build_fpga` logs | `build\fpga\build.log`, `program.log`, timing + utilisation reports | — | First place to look when something fails |
| `util/load_demo_system.sh`, `util/*openocd*` | Upstream lowRISC helpers (Linux, OpenOCD/JTAG debug) | see upstream README below the divider | Untested in this Windows flow |
| `program_flash.tcl` (flow `flashonly`) | Combines bitstream + **XIP firmware** into one MCS and programs the onboard QSPI flash | `flows.ps1 flashonly [firmware.bin]` | Needed whenever XIP firmware changes; JTAG programming is faster for bitstream-only. Press PROG after |
| `sw/freertos/build.bat` | Internal firmware compiler (ONE hardware image incl. the LCD/sensor task; `sim` variant for testbenches; `toy` = accepted alias of the default), called by the `firmware`/`flashfw` flows and the regression | `flows.ps1 firmware [sim]` | Outputs `.bin` (for flash) + `_flash.vmem` (for sim). RAM budget printed at the end - keep data+bss+heap inside 8 KiB. Prefix-agnostic; probes the right `-march` spelling; a WSL-hosted toolchain (`RISCV_GCC_HOME=wsl:...`) compiles through `build.sh` |
| `sw/freertos/build.sh` | The POSIX twin of build.bat: same compile line for Linux/WSL (how the Linux-only lowRISC toolchain builds on Windows) | `./build.sh [hw\|sim] [toolchain-root]` from `sw/freertos` (build.bat calls it via `wsl` automatically); `--check-toolchain` = probe-only | Keep its compile line in sync with build.bat. LF-only (`.gitattributes` enforces) |
| `ibex_soc.sh` | **The Linux one-entry point** (interactive menu with no args) — the 10 testbenches under Verilator 5 `--timing`, dependency installer, firmware, and Vivado bitstream/flash via a Linux Vivado | `./ibex_soc.sh setup \| deps \| images \| firmware [sim] \| lint \| sim <tb> \| regression \| build \| flashfw \| flashonly [bin]` | `deps` = apt/dnf/pacman + xPack RISC-V GCC fallback; paths persist in `.toolpaths.sh` (gitignored). PASS-string table mirrors run_regression.ps1 — keep in sync. Vivado found via `$VIVADO`/PATH/`/opt\|/tools/Xilinx`. Verilator flows proven green (host quirks = gotcha 30); `build`/`flashfw` reuse the Windows-proven .tcl, first exercise on a Linux Vivado still pending |
| `minimal_ibex_soc.core` | FuseSoC (CAPI2) wrapper: targets `lint` (Verilator), `sim` (tb_soc, Verilator), `synth` (Vivado, top_artya7 — all three verified: lint green, sim 9/9, synth = routed bitstream w/ timing met) | `fusesoc --cores-root=. run --target=<t> arf:ibex:minimal_ibex_soc` | Mirrors `dv/xsim/filelist.f` — keep in sync. Self-contained (no `depend:` on vendored cores). `$readmemh` images land via `copyto` (the 498798b idea). Run `./ibex_soc.sh images` before `sim` |
| `sw/asm-demo/xip_test.py` | Generates the XIP proof program (+ `xip_stub.vmem`, the legacy SRAM trampoline) | `python xip_test.py` | Since 2026-08-19 the boot ROM jumps directly to XIP — the stub is no longer baked into any bitstream or testbench; the generator stays for the flash proof program |
| `scripts/*.ps1` | Detached-launch compile/sim/bitstream runners (write ASCII logs under `build/`) | `Start-Process powershell -File scripts\compile_sims.ps1` | See gotcha 16 - EDA tools hang if launched with piped stdio |
| `scripts/find_tools.cmd` / `scripts/find_vivado.ps1` | Tool locators for the remaining cmd/detached-PS callers: `.toolpaths` -> env -> PATH -> existing-drive scan -> WSL (GCC only) | called by sw/freertos/build.bat and the runner scripts | flows.ps1 carries the same search order - keep all three in sync. `.toolpaths` (per-PC, gitignored) stores `VIVADO_BAT`, `RISCV_GCC_HOME` (may be `wsl:<path>`), `RISCV_PREFIX` |
| flow `setup` | Environment doctor: Vivado/Python/GCC/git/repo-path/board checks; asks + saves missing tool paths | GUI **Environment Check**, first thing on a new PC | The [WARN] on RISC-V GCC is fine - flashing falls back to the prebuilt firmware |
| `scripts/run_regression.ps1` (flow `regression`) | The whole test suite in one click: images, FreeRTOS build, compile, 11 sims (10 TBs + the DFFRAM config of tb_soc), bitstream, timing, scoreboard | GUI **Full Regression** (~45-60 min) | Sequential on purpose - concurrent xelab+vivado has killed 16 GB machines. Log: `build\regression.log`, exit code 0 = all green |
| flow `flashfw` | Firmware BUILD (offers GCC install if missing; prebuilt only on explicit choice) -> XIP-boot bitstream -> QSPI flash, end to end; the image always includes the LCD/sensor task | GUI **Flash to Board (QSPI)** with board attached | Persists across power-cycles (unlike JTAG). Press PROG after; expect the FreeRTOS banner at 115200 |

## 8. Gotchas — the complete list

1. **Path with spaces / OneDrive** → Vivado fails in odd ways. Use `C:\FPGA\...`.
2. **Wrong branch** → `develop` doesn't build for FPGA. Use `fix/fpga-bringup`.
3. **"Vivado not found" / "RISC-V GCC not found"** from a flow → the locators (`scripts/flows.ps1`, `scripts/find_tools.cmd`) search saved `.toolpaths` → env vars (`XILINX_VIVADO`, `RISCV_GCC_HOME`) → PATH → `\Xilinx`/`\AMD`/`\AMDDesignTools` and `zephyr-sdk*`/`lowrisc-toolchain*` roots on every existing drive → (GCC only) inside WSL, then **ask you for the install dir and save the answer** to `.toolpaths` (per-PC, gitignored). GCC is prefix-agnostic: `riscv32-unknown-elf-` (lowRISC), `riscv64-zephyr-elf-` (Zephyr SDK) and friends all work. If a tool moves, delete `.toolpaths` or re-run **Environment Check**. Never edit paths inside scripts.
4. **No COM port in Device Manager** → charge-only USB cable (try another), or cable drivers weren't installed with Vivado (rerun `install_digilent.exe` from `Vivado\<ver>\data\xicom\cable_drivers\...`).
5. **COM number differs per PC** → always check Device Manager; never hard-code a teammate's port number.
6. **"Access is denied" opening the COM port** → PuTTY (or another monitor) still has it open. One owner at a time.
7. **Board reverts to other content after power-cycle** → expected with JTAG programming (volatile); the Flash to Board flow persists.
8. **Terminal shows commands mixed into heartbeat lines** → that's the echo-ack interleaving; normal (see §5).
9. **Changed `assemble.py` but board behaves the same** → you must re-run `python assemble.py` *and* rebuild the bitstream; the `.vmem` is read at synthesis time.
10. **Waveforms look "frozen" / PWM looks "too fast" in a simulator** → time-scale illusion; human-visible effects live in ms–s while sims show µs. Use the `--sim` image (short delays) as the testbench does.
11. **xsim fails compiling generated C with DPI errors** → some `ifndef SYNTHESIS` DPI export snuck back in; guard Verilator-only DPI with `ifdef VERILATOR` (this bit us twice — see BRINGUP_HISTORY.md).
12. **`timer_enable()` in a loop freezes ticks** (C software) → it re-arms mtimecmp and zeroes the elapsed counter; arm once, re-arm only on speed change (see BRINGUP_HISTORY.md sec. 5).
13. **Editing LED patterns in C**: only `gp_o[7:4]` are LEDs on Arty; `gp_o[3:0]` go to the DISP/LCD lines.
14. **Simulating after `git clean` / fresh clone** → recompile everything with the full `xvlog -f` command first; `xelab` alone can't find modules if `xsim.dir` was deleted.
15. **A7-35T vs A7-100T** → one-line part change in `build_fpga.tcl` (see §3).
16. **xvlog/xelab/xsim hang forever (100% CPU, empty log)** when launched with piped/captured stdio from automation (agent shells, some CI wrappers) → launch DETACHED: `Start-Process powershell -File scripts\<runner>.ps1`, write progress to an ASCII log, watch the log. The `scripts/` runners are the pattern.
17. **`Out-File` writes UTF-16 by default** → grep/`Select-String` watchers see NUL-riddled text and never match; always pass `-Encoding ascii` in log-writing scripts.
18. **Programs bigger than 8 KiB don't fit SRAM anymore** (ASIC spec) → that's what XIP is for: link against `sw/freertos/link_xip.ld`, put the firmware at flash offset 0x40_0000 (flow `flashonly`), boot via the trampoline image.
19a. **xsim does not reliably propagate edge events through BIT-SELECT port
    connections** (`.rclk(gp_o[12])`): the value changes but `@(posedge ...)`
    inside the model never fires. Route through an explicit intermediate wire
    (`wire cam_rclk = gp_o[12];`) - cost us the camera testbench.
19b. **UART lines glitch during reset** (one spurious low pulse -> a garbage
    0xFF frame). Any UART-listening model/tool must tolerate line noise -
    the ESP32 model filters non-printable bytes exactly like real AT firmware.
19. **XIP code runs ~500x slower than SRAM code** (no ICache, 128 sysclks per fetch at XipClkDiv=1) → keep tick rates coarse (20 Hz), avoid busy-wait loops in flash-resident code, and don't "fix" the slowness by raising the SPI clock past the flash's 50 MHz cmd-0x03 rating.
20. **xsim kernel FATAL_ERROR ("exceptional condition") inside a testbench task** → an early `return` from inside a timed `for` loop (a loop containing `#delay`) kills the simulator kernel outright. Exit loops via the loop condition (`&& !done` flag) instead of `return`. Cost us the first tb_uart2_irq run.
21. **Red `Get-ChildItem : A parameter cannot be found that matches parameter name 'Directory'` spew** (Windows PowerShell 5.1) → `-Directory`/`-File` are *dynamic* parameters of the FileSystem provider; against a drive that doesn't exist the provider can't bind them, and that is a parameter-BINDING error `-ErrorAction SilentlyContinue` cannot suppress. Enumerate real drives (`Get-PSDrive -PSProvider FileSystem`) instead of guessing `C..G:`. Hit on every teammate PC with fewer drives than the dev box.
22. **The lowRISC toolchain "doesn't run" on Windows** → its tar.xz contains Linux ELF binaries; extracted natively on Windows they simply cannot execute. Easiest fix: don't use it — click **Install Missing Tools** in the GUI, which installs a native Windows GCC (xPack) automatically. If you specifically want the lowRISC one, install it inside WSL (FREERTOS_PORT.md, Toolchain) — the locators find it there and build.bat compiles through `wsl` automatically.
23. **`write_cfgmem` fails with `SPI_BUSWIDTH property is set to "1"`** (Flash to Board step 3) → the bitstream was built before `data/pins_artya7.xdc` gained the QSPI-boot config block (`BITSTREAM.CONFIG.SPI_BUSWIDTH 4` etc. — the MCS is SPIx4). `git pull` and rebuild the bitstream; the Flash to Board flow rebuilds it automatically. Found by the first real on-board run of the flash flow (2026-08-18).
24. **Raw read-modify-write on GPIO_OUT races the other tasks** → GPIO_OUT is one shared register (LED nibble, display control lines, CS lines, camera strobes). A task doing `read → modify → write` can be preempted between the read and the write, and then writes back a stale copy of every other bit — LEDs freeze or a chip-select glitches, rarely and unreproducibly. Every GPIO OUT change must go through `gpio_out_update()` (critical-section RMW in `drivers/spi_bus.c`). Found by review in st7735.c when the LCD went from write-once to once-a-second status updates (2026-08-18).
25. **Wired LCD stays completely dark, console fine** → nine times out of ten the flashed firmware simply has no LCD code. Exactly this cost a bench session on 2026-08-18: wiring was verified pin-by-pin against the XDC and 3.3 V was present, but the GUI's variant dropdown had defaulted to "standard demo", whose image never touches the display. Fix was structural: ONE hardware image now (LCD task always in, missing parts tolerated) and the dropdown is gone — so on current firmware this symptom means: (a) firmware older than 2026-08-18 (`git pull`, reflash), (b) BL/backlight wire not on A11, (c) the module's silkscreen pin order differs from the doc table, or (d) CS/DC swapped.
26. **LCD backlight lits white but nothing ever draws** → the backlight proves firmware + GPIO wiring (BL is just gp_o[3]); a white-only panel means the ST7735 controller never received a valid init — look at the SPI signalling. Real case (2026-08-18, same bench day): `spi_host.sv` launched the TX bit on the **rising** SCK edge in CPHA=0 mode — the exact edge a mode-0 slave samples — so the panel got zero hold time and garbage bytes. Never caught in simulation because the SPI models sampled a **delayed copy** of MOSI, i.e. the models were written to match the RTL's race instead of the physical part (the workaround was even commented in tb_lcd.sv). Fixed by launching TX on the falling edge (half a period of setup AND hold). **Lesson for every future model: make the model behave like the datasheet part, not like the RTL — a model that tolerates an RTL quirk is hiding a silicon bug.** Found by the ARF DV teammate's question ("verify spi_host/spi_top mode of operation").
27. **Board goes silent after a serial script/terminal disconnects** → closing the COM port deasserts DTR, which the Arty couples to `ck_rst` = our `IO_RST_N` — the SoC is held in **reset** until the port reopens. That is by design (shield auto-reset); the bug was that the warm reset then crash-looped: the boot ROM jumps to SRAM+0x80 on every reset, and the firmware's `.bss` used to clobber the XIP trampoline there (the old linker comment even called the clobber harmless — true only when every reset was a reconfiguration). Since 2026-08-18 the linker reserves SRAM+0x00..0x8F and startup.S re-writes the trampoline each boot, so a disconnect is just a clean reboot: expect a fresh banner when you reconnect (PuTTY close/reopen = board reboot — normal). Also the reason `uart_command_test.py` reboots the board when it exits.
28. **Flash programming fails once with `cannot set write enable bit or block(s) protected`** (erase OK, program fails) → transient; seen once in ~6 programming cycles on 2026-08-18, immediately after a session where the running design's XIP controller was mid-transaction when the flash-programmer bitstream took over. Just re-run Flash to Board / `flashonly` — the retry succeeded verbatim. If it persists across a power-cycle, then suspect the flash-part selection.

29. **Boot-ROM change 2026-08-19 (direct XIP) and mixed old/new versions** → the ROM now jumps straight to `0x2040_0000` and never reads SRAM; bitstreams no longer bake an SRAM image. Every combination stays bootable: *new bitstream + any firmware* boots direct; *old (pre-08-19) bitstream + any post-08-18 firmware* still boots via the SRAM trampoline, which the bitstream init provides and every firmware startup re-writes. The one dead combination was already dead: old bitstream + pre-08-18 firmware after a DV program clobbered SRAM (bug #9). If a freshly pulled repo "won't boot", check you re-built the **bitstream**, not just firmware — the ROM lives in the FPGA logic.

30. **Verilator flow quirks (2026-08-19, all encoded in `ibex_soc.sh`)** → (a) Verilator resolves module refs even inside dead generate blocks: the disabled dummy-instr block references `prim_lfsr`, which Verilator finds via the incdirs and which then needs `prim_cipher_pkg` — fed explicitly (`VLT_EXTRA`), NOT added to filelist.f (xsim/Vivado never need it). (b) On MSYS2/Windows hosts, GCC 16.2 at `-Os` (Verilator's default OPT) drops std::string's move-ctor instantiation → undefined reference at link; the script forces `-O2` there (Linux keeps defaults). (c) MSYS2's *msys*-flavored python mangles `C:/` paths in Verilator's `verilator_includer` step — install the *ucrt64* python (`mingw-w64-ucrt-x86_64-python`) so the native one wins on PATH. (d) A comment line must never START with the word "verilator" — Verilator parses it as a metacomment and errors out (`BADVLTPRAGMA`). (e) `--quiet-stats` only exists in Verilator ≥ 5.022 — Ubuntu 24.04 ships 5.020, so the flow doesn't use it (verilate output is log-redirected anyway). (f) **Ubuntu's `gcc-riscv64-unknown-elf` apt package ships without any C library** (`stdlib.h: No such file or directory`) — it can't build the firmware even though the compiler is on PATH; `build.sh --check-toolchain` is a real compile probe for exactly this, and `deps` installs the xPack `riscv-none-elf` GCC instead (same toolchain as the Windows GUI). (g) Under MSYS2, `ibex_soc.sh` reads the RISC-V GCC from the Windows GUI's `.toolpaths` (cygpath-translated) when `.toolpaths.sh` doesn't provide one — one saved config serves both entry scripts.

31. **`oled=2 bme=2` (I2C TIMEOUT) on the bench = the bus is physically held low**, not an address problem. The OpenCores master waits for SCL to actually rise (clock-stretch detection); if SCL or SDA is clamped, TIP never clears and every access returns timeout (code 2). A NACK (code 1) means the bus is *healthy* and the device just didn't answer. Both modules failing with the same code = shared-bus fault: the classic causes are an **unpowered module clamping the lines through its ESD diodes** (breadboard power rail not actually connected), a wire in the wrong Pmod hole (JA pin 5 is GND), or a solder bridge. Full decode table: PRODUCTION_PERIPHERALS §8. Firmware cannot unstick a held bus — it's a wiring fix.

32. **Vivado uses only 2 threads on Windows by default** (`general.maxThreads`; Linux defaults to 8). Every repo `.tcl` entry point now does `set_param general.maxThreads 8` (Vivado's cap) — if synthesis looks single-threaded in a new script, that param is missing.

33. **A testbench reset must make a real FALLING edge** — initialising `rst_n = 1'b0` at time zero means `always_ff @(posedge clk or negedge rst_ni)` blocks behind a **gated clock** (Ibex's core clock gate) never execute their reset branch in event-driven simulation: no negedge event, no clock during reset. Result here: `priv_lvl_q` kept the simulator's init value (U-mode) and the first `csrw mtvec` trapped as an illegal instruction — recovered only by the accident that the reset mtvec re-enters the boot path. Real async-reset cells are level-sensitive, so this NEVER affects silicon/FPGA — it's a sim-only trap that hides real information (any reset-value ≠ init-value flop behind a gated clock is wrong until first use). All 10 testbenches drive `1 → 0 → 1` since 2026-08-20.

34a. **"Can't run Verilator" on a teammate PC — two causes seen (2026-08-20, ARF-BBSR-84 transcript):** (a) an **old checkout**: trees with `setup_check.bat` / `build_fpga.bat` / `flash_freertos.bat` predate 2026-08-18 — those entry points are retired and the Verilator flow (2026-08-19) does not exist there; `git pull`. (b) **wrong shell on Windows**: `ibex_soc.sh` needs a POSIX shell with make/g++ — install MSYS2, open the **UCRT64** shell, `./ibex_soc.sh deps` then `regression` (README "Verilator on a Windows PC"). Related: `program_flash` erroring `firmware not found` means the firmware was never built — the GUI's **Flash to Board** is build-first and offers the GCC auto-install; the standalone tcl does not.

34. **In a sim profile, check the CPU budget before trusting task behavior**: at XIP speed (~6.4 µs/fetch) a 5 ms tick = ~1k instructions — tick ISR + two every-tick tasks exceed that, and lower-priority tasks silently never run (tb_freertos's LED checks caught it). Sim tick is 100 Hz for this reason; if a sim-build task "does nothing", audit the per-tick instruction budget first.

- [BRINGUP_TEST_REPORT.md](BRINGUP_TEST_REPORT.md) — all recorded evidence
- [BRINGUP_HISTORY.md](BRINGUP_HISTORY.md) — bring-up history: bugs, decisions, UART command design
