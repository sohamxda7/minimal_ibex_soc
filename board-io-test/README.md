# Arty A7-100T — Complete IO Test (Beginner Guide)

> **Context:** this repo is Phase 1 of the ARF Design board bring-up — it
> qualified every IO of the Arty A7-100T *before* the custom Ibex RISC-V SoC
> was debugged and brought up on the same board (Phase 2, see the
> `minimal-ibex-soc` repo, `docs/BRINGUP_OVERVIEW.md`). Because these tests
> passed, later SoC misbehaviour could be attributed to logic with
> confidence, not to board damage.

This folder contains everything to test **every basic IO** on your Arty A7-100T:
the 4 green LEDs, 4 RGB LEDs, 4 switches, 4 buttons, the USB serial port (UART),
and all 4 Pmod connectors.

**The big picture** (how FPGA work always flows):

1. You write a hardware description (already done — the `.v` files in `src\`).
2. A tool called **Vivado** compiles it into a **bitstream** (`.bit` file).
3. You load the bitstream onto the board over USB.
4. The FPGA now *is* that circuit, until power-off.

**For testers & report writers:** [docs/TEST_PROCEDURE.md](docs/TEST_PROCEDURE.md)
is the step-by-step physical test anyone can run;
[docs/TEST_REPORT_TEMPLATE.md](docs/TEST_REPORT_TEMPLATE.md) is the form to fill
in and submit; [docs/DESIGN_OVERVIEW.md](docs/DESIGN_OVERVIEW.md) explains how
the design works internally.

```
arty-io-test\
├── README.md          <- you are here
├── docs\              <- test procedure, report template, design overview
├── build.bat          <- double-click to compile   (step 3)
├── program.bat        <- double-click to load onto board  (step 4)
├── src\               <- the Verilog design (the "circuit description")
├── constraints\       <- which FPGA pin connects to which LED/button/etc.
├── scripts\           <- automation scripts used by the .bat files
├── sim\               <- simulation testbench (see "Simulating" below)
├── tools\             <- Python serial monitor + automated UART self-test
└── build\             <- compiled output ends up here (not in git)
```

---

## Step 1 — Install Vivado (one time, ~1–2 hours mostly waiting)

Vivado is AMD's (formerly Xilinx's) FPGA tool. The **Standard edition is free**
and fully supports your board.

1. Go to <https://www.xilinx.com/support/download.html>
2. Download the **latest "Vivado ML Edition" Windows Self-Extracting Web Installer**
   (a small ~200 MB `.exe`).
3. You'll need a **free AMD account** — create one and note the email/password;
   the installer asks for the same login.
4. Run the installer. When it asks what to install, choose:
   - Product: **Vivado**
   - Edition: **Vivado ML Standard** (the free one — *not* Enterprise)
5. On the device/options selection screen, **save disk space**:
   - Under Devices, keep only **"Artix-7"** (that's your chip) — you can untick
     the other 7-series, UltraScale, SoC families, etc.
   - **IMPORTANT: keep "Install Cable Drivers" ticked** — without it Windows
     can't talk to the board.
6. Install to the default `C:\Xilinx` (or `C:\AMD`) location. The `.bat` files
   in this folder look there automatically.
7. Expect a 10–25 GB download and 30–60+ min install. Go have chai.

> **Why not install to OneDrive/Desktop?** Vivado breaks on paths with spaces
> (like `Soham Sen`) and OneDrive chokes syncing its thousands of temp files.
> That's why this project lives at `C:\FPGA\arty-io-test`.

## Step 2 — Plug in the board

1. Connect the Arty to your PC with a **micro-USB data cable** (the one that
   came with it). This single cable does power + programming + serial.
2. The red **LD13 "DONE/POWER"** area LED lights up. The board may already blink
   LEDs — that's Digilent's factory demo stored in flash. Ignore it.
3. Windows should install FTDI USB drivers automatically. To check: open
   **Device Manager → Ports (COM & LPT)** — you should see
   **"USB Serial Port (COMx)"**. Note that COM number, you'll need it in Step 5.

## Step 3 — Build the bitstream

Double-click **`build.bat`**. A console window opens and churns for ~3–6
minutes. Success looks like:

```
BUILD OK  ->  build/arty_io_test.bit
```

(First troubleshooting stop if it fails: `build\build.log`.)

## Step 4 — Program the board

With the board plugged in, double-click **`program.bat`**. After ~15 seconds you
should see `BOARD PROGRAMMED!` — and the 4 green LEDs on the board start a
chase pattern. **Congratulations, your design is running on real hardware.**

> Programming this way is temporary: unplug the board and it reverts to the
> factory demo. That's normal and ideal while learning — just re-run
> `program.bat`. (Making it permanent = "flash programming", a later topic.)

---

## Step 5 — Test every IO ✅

### 5a. Green LEDs (LD4–LD7)
Right after programming, all 4 green LEDs run a **chase pattern**
(one lit LED marching along). If all 4 positions light up → **LEDs pass**.

### 5b. Slide switches (SW0–SW3)
Flip any switch **up**: the chase stops and the LEDs now **mirror the
switches** — SW0 up lights LD4, SW1 lights LD5, etc. Try each switch alone.
All four control their LED → **switches pass**. (All switches down → chase
resumes.)

### 5c. Buttons + RGB LEDs (BTN0–BTN3, LD0–LD3)
**Hold** a button: the RGB LED next to it slowly cycles
**red → green → blue → white**. Hold through a full cycle (~3 s) to see all
three colors — that proves all 3 channels of that RGB LED work. Repeat for all
4 buttons → **buttons + RGB LEDs pass**.

### 5d. UART (serial over USB) — both directions
1. Open **PuTTY** (already installed on your PC).
2. Set: Connection type **Serial**, Serial line **COMx** (from Step 2),
   Speed **115200**. Click **Open**.
3. Now flip a switch or press a button — the terminal prints e.g.
   `SW=0100 BTN=0000` on every change → **FPGA→PC direction passes**.
4. Type any characters into the PuTTY window — each one comes back on screen
   (the FPGA echoes it) → **PC→FPGA direction passes**.

   *(To verify echo is real: PuTTY doesn't display typed characters by itself —
   if you see what you type, it made a round trip through the FPGA.)*

Alternative to PuTTY: `pip install pyserial` then run
`python tools\uart_monitor.py`.

### 5e. Pmod connectors (JA, JB, JC, JD)
Every Pmod pin outputs a square wave. **Pin 1 toggles at ~0.4 Hz** (slow
blink), each next pin twice as fast.

Pmod pinout (each 12-pin header, looking at the socket):
```
 top row:    1  2  3  4  GND(5)  3V3(6)
 bottom row: 7  8  9 10  GND(11) 3V3(12)
```

Easiest check — **multimeter** (DC volts): black probe on pin 5 (GND), red
probe on pin 1. The reading flips between ~0 V and ~3.3 V about every 1.4 s.
Faster pins (e.g. pin 4) read a steady ~1.6 V (the meter averages the fast
square wave). Repeat on JA, JB, JC, JD → **Pmods pass**.

**No multimeter?** Use the built-in **touch test**: flip all four switches
up and every Pmod pin becomes an input with a pull-up — touching a signal pin
to a GND pin with a paperclip lights the connector's LED and prints the exact
pin over UART. Full instructions: `docs\TEST_PROCEDURE.md`, Test 6, Method B.

> ⚠️ Unplug any Pmod modules before running this test — all 32 pins are driven
> as outputs here.

### Not covered by this test (fine for later)
- **Ethernet port** — needs a much bigger design (MAC + PHY control).
- **ChipKit/Arduino headers** — same idea as Pmods; ask me to add them.
- **QSPI flash / DDR3 RAM** — internal, needs dedicated test designs.
- **Red RESET & PROG buttons** — board-level functions, not normal IO. PROG
  makes the FPGA reload from flash (you'll see the factory demo return — that
  actually proves PROG works! Re-run `program.bat` afterwards).

---

## Simulating (and why waveforms look "wrong")

If someone views this design in a simulator's **waveform viewer**, it will
*seem* broken — the green LEDs appear frozen while the RGB signals toggle
insanely fast. **Nothing is wrong.** It's a timescale mismatch:

| Signal | Real speed | In a waveform view |
|---|---|---|
| LED chase step | every 0.17 **s** | looks frozen (sims cover µs, not seconds) |
| RGB colour change | every 0.67 **s** | looks frozen |
| RGB PWM | 390 **kHz** | looks like crazy-fast toggling |
| UART bit | 8.7 **µs** | visible frames |

On the board your **eye** does the opposite: it sees the slow patterns and
blurs the 390 kHz PWM into steady dim light. Both views are correct — the
LEDs are not supposed to "follow" the RGB PWM; they run on time bases about
100,000x apart.

To make simulation useful, use **`sim\tb_top.v`**: it instantiates the design
with a sped-up time base (`SPEEDUP=12`), so in ~8 ms of simulated time you see
the chase move, colours cycle, status messages and UART echo — with pass/fail
messages printed to the console. In the Vivado GUI: add `sim\tb_top.v` as a
**simulation-only** source, set `tb_top` as simulation top, then
*Run Simulation → run all*.

**Also remember:** the RGB LEDs only light **while a button is held** — that's
by design, they're bright.

## About COM port numbers

Windows assigns a different COM number on every PC (COM3 on one laptop, COM5
on another). Whatever number *your* Device Manager shows under
**Ports (COM & LPT) → "USB Serial Port"** with the board plugged in is the
one to use in PuTTY. There is no "correct" number — COM5 on a teammate's
laptop means nothing for yours.

---

## Troubleshooting

| Problem | Fix |
|---|---|
| `build.bat` says Vivado not found | Install Vivado (Step 1), or edit the `VIVADO=` line in the `.bat` files to point at your `vivado.bat` |
| `program.bat` fails / no target found | Board unplugged, bad USB cable (some are charge-only — try another), or cable drivers missing: reinstall them from `C:\Xilinx\Vivado\<ver>\data\xicom\cable_drivers\nt64\digilent\install_digilent.exe` |
| No COM port in Device Manager | Different USB cable/port; let Windows Update fetch FTDI drivers |
| PuTTY shows garbage | Wrong speed — must be 115200 |
| PuTTY "Access Denied" on COM port | Something else has the port open (e.g. the Python monitor) — close it |
| Build fails with timing/pin errors | Send me `build\build.log` and I'll fix it |

## What's next on your FPGA journey?

1. **Open the code**: `src\top.v` is heavily commented — read it top to bottom
   and match each block to the behavior you just saw.
2. **Change something small**: make the chase faster (use `tick[23:22]` instead
   of `tick[25:24]`), rebuild, reprogram. This edit→build→test loop is 90% of
   FPGA development.
3. **Learn the Vivado GUI**: batch scripts hide it, but the GUI's simulator and
   schematic viewer are great for learning.
4. Good resources: Digilent's Arty A7 reference manual, [HDLBits](https://hdlbits.01xz.net)
   (interactive Verilog exercises), and [Nandland](https://nandland.com) (beginner FPGA tutorials).
