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

Command sequence in `docs/FPGA_BRINGUP.md`. Sim time 7 ms, all checks pass:

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

## 4. UART command interface (added later the same day — see docs/UART_CONTROL.md)

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

## 5. Not covered (future work)

- SPI-flash XIP execute-in-place (controller in fabric, no board pins wired;
  needs `STARTUPE2` for the flash clock + un-commenting QSPI pins in the XDC)
- I2C master on real pins (no pins assigned yet)
- JTAG debug via OpenOCD (dm_top synthesises with the BSCANE2 tap; not exercised)
- Running compiled C software (needs a riscv32 GCC toolchain; flow documented
  in FPGA_BRINGUP.md "Swapping in real C software")

## Verdict

**PASS — the SoC hardware platform is functional on the Arty A7-100T.**
UART both directions, GPIO in/out, PWM/RGB, CPU, buses and both memories
verified in simulation and on the board.
