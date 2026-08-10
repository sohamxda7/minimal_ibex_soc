# Arty A7 FPGA Bring-up — What Was Broken, What Was Fixed, How To Use It

*Branch `fix/fpga-bringup`, 2026-08-07. Board: Arty A7-100T. Vivado 2026.1 on Windows.*

This document explains why the SoC "glitched" on the board (especially the RGB
LEDs), the four root causes that were found and fixed, and the new
**no-FuseSoC, no-RISC-V-toolchain** build path that goes from a clean checkout
to a working board with two double-clicks.

---

## TL;DR — the "RGB glitch" was two separate bugs

1. **The FPGA bitstream contained no program.** The CPU boots from Boot ROM
   (`0x00100000`, NOPs + one `jal`) and jumps to SRAM (`0x00102080`) — but
   nothing ever initialised the SRAM on FPGA. In Verilator simulation the
   test harness loads the program through a DPI back-door, which is why *sim
   worked* and *hardware didn't*: on the board the CPU executed empty memory
   and crash-looped forever. (The `SRAMInitFile` parameter existed but was
   wired to nothing; one team member worked around it by hand-editing a
   Vivado project — the hardcoded `C:/Users/Raji/...` path in
   `ibex_demo_system.sv` was the fossil of that.)
2. **The software timer ran ~500x too fast.** `main.c` had
   `timer_enable(10000)` — a 0.5 ms tick. The RGB brightness ramp + colour
   cycle that should take seconds completed in ~2 ms, strobing the RGB LEDs
   at ~kHz: exactly the "flickering/glitching" reported. Fixed to
   `timer_enable(2000000)` (0.1 s at 20 MHz).

Two more latent bugs would have bitten next:

3. **UART clock parameter never reached the UART.** `wrapper_top`
   instantiated `uart u_uart` with **no parameters**, so the baud divider
   used uart.sv's local 20 MHz default regardless of the top-level
   `ClockFrequency`. Additionally the PLL actually generated **50 MHz**
   while the SoC is parameterised for **20 MHz**. Decision: the system runs
   at **20 MHz** — the PLL divider was corrected
   (`CLKOUT0_DIVIDE 24 -> 60` in `clkgen_xil7series.sv`) and
   `ClockFrequency`/`BaudRate` are now passed down every level
   (`top_artya7 -> ibex_demo_system -> wrapper_top -> uart`).
4. **DPI exports broke the xsim flow.** Verilator-only DPI exports in
   `sram_model.sv` and (vendored) `ibex_if_stage.sv` were guarded with
   `ifndef SYNTHESIS`; xsim tried to compile them and failed with a C
   codegen error. Guards changed to `ifdef VERILATOR` (their real purpose).

## Fix list (files changed)

| File | Change |
|---|---|
| `rtl/system/wrapper_top.sv` | new `ClockFrequency`/`BaudRate`/`SRAMInitFile` parameters; passed to `uart` and `sram_model` |
| `rtl/system/ibex_demo_system.sv` | passes the three parameters down; removed hardcoded personal path; default 20 MHz |
| `rtl/fpga/top_artya7.sv` | passes 20 MHz + SRAMInitFile; connects the new XIP/I2C ports (tied off — no board pins yet) |
| `vendor/lowrisc_ibex/.../clkgen_xil7series.sv` | PLL output 50 MHz → **20 MHz** (`CLKOUT0_DIVIDE 60`) |
| `rtl/system/sram_model.sv`, `vendor/lowrisc_ibex/rtl/ibex_if_stage.sv` | DPI export guard `ifndef SYNTHESIS` → `ifdef VERILATOR` |
| `sw/c/demo/hello_world/main.c` | timer tick 10000 → 2000000 cycles (0.1 s @ 20 MHz) |

## New: build & run with nothing but Vivado

Previously building required cloning dependencies, a Linux-ish FuseSoC/Python
environment, and a RISC-V GCC toolchain. Now, from a clean checkout on
Windows with only Vivado installed:

```
build_fpga.bat        <- synthesises everything -> build/fpga/top_artya7.bit
program_fpga.bat      <- loads it onto the Arty A7 over USB
```

Key enablers (all in-repo):

- **`dv/xsim/filelist.f`** — hand-maintained compile order (packages →
  prims → Ibex → debug module → system). Used by both xsim and
  `build_fpga.tcl`, so sim and synthesis can never drift apart.
- **`dv/xsim/prim_shims.sv`** — replaces the FuseSoC/primgen *generated*
  "abstract primitives" (`prim_clock_gating`, `prim_buf`, `prim_flop`, …)
  with hand-written equivalents. With `FPGA_XILINX` defined the clock gate
  becomes a real `BUFGCE`; in simulation a latch-based model.
- **`sw/asm-demo/assemble.py`** — a ~200-line, dependency-free Python
  RV32IM assembler + demo program. It generates `sram_init.vmem`, which the
  build bakes into the SRAM block RAM via the (now working) `SRAMInitFile`
  parameter. **No RISC-V toolchain needed to get a working board.**
  The assembler self-checks against the known-good `jal` word in `boot.mem`.

### What the demo program does on the board

- UART @ **115200**: prints `IBEX-SOC UP <n>` about every 2 s and **echoes
  every character you type**.
- Green LEDs LD4–LD7: walking pattern.
- **Hold any button**: LEDs show the switch positions instead.
- RGB LEDs LD0–LD3: slow breathing, cycling **red → green → blue** (~2.5 s
  per colour). *Smooth breathing here is the visual proof that the former
  "RGB glitch" is gone.*

### Swapping in real C software later

When a `riscv32-unknown-elf-gcc` toolchain is available, build
`sw/c` as before, convert the binary to a **word-per-line hex (.vmem)** image
based at SRAM+0x80, point `SRAMInitFile` in `build_fpga.tcl` at it, and
rebuild. (Reminder: SRAM is 8 KiB — `0x00102000..0x00103FFF`, ASIC spec size — with entry at
`0x00102080`; see `sw/common/link.ld`.)

## Simulation flow (xsim, Windows-friendly)

Full-SoC simulation without Verilator — boots the real boot ROM + SRAM image
and checks UART TX/RX, GPIO out/in, and PWM duty progression:

```
python sw/asm-demo/assemble.py --sim
xvlog -sv -f dv/xsim/filelist.f dv/xsim/tb_soc.sv dv/xsim/sim_stubs.sv ^
      -i vendor/lowrisc_ip/ip/prim/rtl -i rtl/system ^
      -i vendor/lowrisc_ibex/vendor/lowrisc_ip/dv/sv/dv_utils
xelab tb_soc -s soc_sim -timescale 1ns/1ps
xsim soc_sim -R
```

Result (2026-08-07, xsim 2026.1):

```
PASS: LEDs mirror switches while button held (gp_o=01010000)
PASS: UART TX produced 32 bytes
PASS: UART RX echo ('K' came back)
PASS: LEDs changed 4 times
RGB0 red duty ramps 0 -> 918/2000 monotonically  (breathing verified)
```

Note the sim image (`sram_init_sim.vmem`) uses a ~1000x shorter delay loop —
human-speed effects would look frozen in a microsecond-scale waveform
(the same time-scale illusion that confused earlier waveform debugging).

## Known limitations / next steps

- **XIP SPI flash**: the controller is wired inside the SoC but not to board
  pins (QSPI pins are commented out in `pins_artya7.xdc`; the flash clock
  needs a `STARTUPE2` macro on 7-series). Execute-in-place is untested.
- **I2C**: bus master present, no board pins assigned; inputs tied idle.
- **JTAG debug (dm_top)**: synthesises (BSCANE2 tap) but OpenOCD bring-up
  not attempted in this pass.
- The Verilator flow still works: `VERILATOR`-guarded DPI code is preserved.
