# Board Bring-up — The Whole Journey and Every Decision

*ARF Design, 2026-08-07. From "brand-new board, nothing installed" to
"custom RISC-V SoC verified on hardware" in one day, on one Windows laptop.*

This is the narrative + decision log. The technical deep-dive lives in
[FPGA_BRINGUP.md](FPGA_BRINGUP.md), the recorded results in
[BRINGUP_TEST_REPORT.md](BRINGUP_TEST_REPORT.md).

---

## Phase 0 — Toolchain from zero

The test PC started with no FPGA tooling at all. Installed: **Vivado ML
Standard 2026.1** (free edition, Artix-7 device support only, cable drivers
enabled) to the default `C:\AMD\2026.1` location.

**Decisions**
- *Keep FPGA work off OneDrive and out of paths with spaces* — Vivado
  breaks on `C:\Users\Soham Sen\…` and OneDrive fights build churn. All
  work lives under `C:\FPGA\`.
- *Vivado Standard, Artix-7 only* — free, sufficient for XC7A100T, saves
  ~50 GB of disk.

## Phase 1 — Board IO qualification (`C:\FPGA\arty-io-test`, separate repo)

Before trusting a complex SoC on the board, every IO was qualified with a
purpose-built bare-metal FPGA design (no CPU): LED chase, switch mirror,
button-driven RGB colour cycling, UART status messages + echo, Pmod square
waves. All tests **passed** — full report in that repo
(`docs/TEST_REPORT_2026-08-07_soham.md`).

**Findings & decisions that carried over**
- Board enumerates as two FTDI channels: JTAG + `USB Serial Port (COMx)` —
  COM number is per-PC, 115200 8N1 works cleanly.
- Board's LEDs/switches/buttons/RGB electrically verified — so any later
  SoC misbehaviour is *logic*, not damaged hardware. This was decisive when
  debugging the "RGB glitch": the LEDs were provably fine.
- A "simulation looks frozen / hardware looks fast" time-scale confusion
  misled the team once; both repos now ship testbenches with sped-up time
  bases and explicit documentation of the illusion.
- Pmod pins verified via a no-instruments "touch test" mode (pins as
  pulled-up inputs, grounded pin reported over UART) — invented because no
  multimeter was available.

## Phase 2 — The Ibex SoC ("it's glitching")

The DV team had forked the lowRISC Ibex Demo System, rebuilt its bus into a
custom OBI→Wishbone fabric, and reported: hard to build, needs cloning and
tweaks, works in simulation, **RGB LEDs glitch on the board**.

### Investigation results (all four confirmed by code + simulation)

1. **No program in the bitstream** — the root cause of "glitching".
   `SRAMInitFile` existed but was connected to nothing; the program only
   ever reached SRAM through a Verilator-simulation back-door. On hardware
   the CPU jumped into empty SRAM and crash-looped. A teammate's hardcoded
   `C:/Users/Raji/...` path found in the RTL was a manual workaround fossil
   — proof the team had hit this without identifying it.
2. **Software timer 500× too fast** — `timer_enable(10000)` = 0.5 ms tick
   made the RGB ramp strobe at kHz rates: the *visible* glitch.
3. **UART clock parameter never plumbed** — `uart u_uart` took defaults;
   console output was garbled at the wrong effective baud.
4. **PLL made 50 MHz for a 20 MHz design** — every parameter in the SoC
   assumes 20 MHz.

### Decisions (with reasoning)

| Decision | Reasoning |
|---|---|
| Work from branch `cursor/setup-dev-environment-93f3`, fixes on new branch `fix/fpga-bringup` | Team said latest work is there; a separate branch keeps fixes reviewable as a PR |
| **System clock = 20 MHz; fix the PLL, not the parameters** | Team decision (ASIC target frequency). PLL divide 24 → 60 |
| **Bake the program into the bitstream** (`SRAMInitFile` → BRAM init) | Simplest correct boot story: no loader, no toolchain, no JTAG needed to get a live board; synthesis log proves inclusion |
| **Hand-assembled demo program via a ~200-line Python assembler** | No RISC-V GCC exists on the lab PC and none can be assumed for teammates; Python is always there. Assembler self-checks against the known-good `jal` word in `boot.mem` |
| **Plain-Vivado batch build instead of FuseSoC** | FuseSoC needs a Python venv + lowRISC forks + generated "abstract prims" — the main reason the team found building "hard". One `filelist.f` + one Tcl works everywhere Vivado does |
| **One shared filelist for xsim and synthesis** | Whatever simulates is exactly what ships — removes a whole class of sim/hw drift |
| **xsim, not Verilator, for Windows simulation** | Verilator flow needs Linux-ish tooling; xsim ships with Vivado. Cost: two DPI-export guards had to be corrected (`ifndef SYNTHESIS` → `ifdef VERILATOR`) — which also keeps the upstream Verilator flow intact |
| **Verify in simulation before touching the board** | The full-SoC testbench reproduced clean UART/GPIO/PWM behaviour first; hardware then worked on the first programming attempt |
| **Tie off XIP/I2C at the top level for now** | No board pins are assigned (QSPI needs STARTUPE2 handling); wiring them untested would add risk without adding verified function. Documented as future work |
| Touch vendored files only when unavoidable | Two one-line-ish edits (PLL divide, DPI guard), both loudly commented — easy to upstream or re-vendor |

### Outcome

Simulation: all checks PASS. Hardware: programmed on first attempt —
`IBEX-SOC UP` heartbeat on UART, echo working, LEDs walking, switches
mirrored on button hold, RGB breathing smoothly. Evidence in
[BRINGUP_TEST_REPORT.md](BRINGUP_TEST_REPORT.md).

## Phase 3 — ASIC spec alignment (2026-08-10)

The team's tapeout guide (digested into [ASIC_SPEC.md](ASIC_SPEC.md))
revealed the endgame: GF180MCU silicon via the Caravel shuttle, with SRAM
hard-capped at 8 KiB by the area budget.

### Decisions (with reasoning)

- **SRAM back to 8 KiB** — chip-size constraint is physics, not preference:
  64 KiB of DFFRAM alone (~14 mm²) exceeds the whole 10.27 mm² user area.
  The FPGA now validates the exact silicon configuration.
- **XIP from the onboard QSPI flash for anything bigger** — controller
  existed but was untested; proven in sim (tb_xip), which exposed and fixed
  3 real bugs (byte order, phantom re-read, write hang) before they could
  reach silicon.
- **Zephyr → FreeRTOS** — 8 KiB is below Zephyr's RAM floor; the spec names
  FreeRTOS explicitly. Port done, boots in full-SoC sim over XIP
  ([FREERTOS_PORT.md](FREERTOS_PORT.md)); Zephyr work preserved in git
  history + superseded decision docs.
- **Flagged, not changed**: SRAM base (ours 0x0010_2000 vs spec
  0x0010_1000) and the PWM block (absent from the spec) await team calls.

## Repository landscape after bring-up

| Location | Contents |
|---|---|
| `C:\FPGA\arty-io-test` (git) | Board IO qualification: bare-metal test design, one-click build/program, test procedure + filled report, xsim testbench, UART self-test tooling |
| `C:\FPGA\minimal-ibex-soc` (git, this repo) | The SoC. Branch `fix/fpga-bringup`: all fixes + Windows build/sim flow + these docs |

## Handy references

- Memory map: Boot ROM `0x0010_0000` (4 KiB) → jumps to SRAM `0x0010_2080`;
  SRAM `0x0010_2000` (8 KiB, to 0x0010_3FFF - shrunk from the 128 KiB dev size per docs/ASIC_SPEC.md); UART `0x4000_0000`; GPIO `0x4000_0100`;
  Timer `0x4000_0200`; I2C `0x4000_0400`; SPI host `0x4000_0500`;
  PWM `0x4000_0600` (PWM *i*: `+8i` pulse width, `+8i+4` max count;
  index%3 → 0=blue, 1=green, 2=red per `pins_artya7.xdc`).
- Serial: 115200 8N1, find the COM number in Device Manager (per-PC!).
- Programming is volatile: power-cycle returns the board to its flash
  content; re-run `program_fpga.bat`.
