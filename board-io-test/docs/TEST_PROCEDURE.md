# Arty A7-100T IO Test — Physical Test Procedure

**Purpose:** verify every basic IO of the Arty A7-100T board using the
`arty_io_test` design. Anyone can run this without knowing the design's
internals. Total time: ~15 minutes.

**You need:**
- Arty A7-100T + micro-USB data cable
- Windows PC with Vivado installed (see main README, Step 1)
- A serial terminal (PuTTY) — settings: **115200 baud, 8N1**
- For the Pmod test: a multimeter, or an LED + ~330 Ω resistor + 2 jumper wires

---

## 0. Setup

1. Plug the board in via micro-USB. Confirm a red power LED lights.
2. Find the COM port: **Device Manager → Ports (COM & LPT) → "USB Serial Port
   (COMx)"**. Write the number in the report; it differs per PC.
3. Build and program: double-click `build.bat` (wait for `BUILD OK`), then
   `program.bat` (wait for `BOARD PROGRAMMED!`).
4. Open PuTTY: Connection type *Serial*, Serial line *COMx*, Speed *115200*,
   then *Open*. Keep it open for the whole procedure.

> The design is loaded into volatile FPGA memory: power-cycling the board
> reverts it to the factory demo. Re-run `program.bat` if that happens.

---

## Test 1 — Green LEDs (LD4, LD5, LD6, LD7)

**Precondition:** all 4 slide switches DOWN, no buttons pressed.

| Step | Expected | Record |
|---|---|---|
| Just watch the 4 green LEDs for ~2 s | A single lit LED "chases": LD4 → LD5 → LD6 → LD7 → LD4…, moving ~6 steps/second | Each of the 4 LEDs lights at its turn: pass/fail per LED |

**Fail hints:** one LED never lights → that LED (or its pin) is faulty.

## Test 2 — Slide switches (SW0–SW3)

| Step | Expected | Record |
|---|---|---|
| Flip **only SW0** up | Chase stops; **only LD4** is lit solid | pass/fail |
| SW0 down, **only SW1** up | only LD5 lit | pass/fail |
| Only SW2 up | only LD6 lit | pass/fail |
| Only SW3 up | only LD7 lit | pass/fail |
| All four up | all four LEDs lit | pass/fail |
| All down again | chase pattern resumes | pass/fail |

Each flip also prints a line in PuTTY (e.g. `SW=0001 BTN=0000`) — that's
Test 4 working; note it but don't record it yet.

## Test 3 — Push buttons (BTN0–BTN3) and RGB LEDs (LD0–LD3)

BTN0 is next to LD0, BTN1 next to LD1, etc.

| Step | Expected | Record |
|---|---|---|
| Press **and hold** BTN0 for ~4 s | LD0 (RGB) cycles: **red → green → blue → white**, ~0.7 s per colour, dim | all 4 colours seen: pass/fail |
| Release BTN0 | LD0 goes dark | pass/fail |
| Repeat for BTN1/LD1, BTN2/LD2, BTN3/LD3 | same behaviour | pass/fail each |

**Why it matters:** each RGB package contains 3 separate LEDs (R, G, B).
Seeing red, green, blue AND white (all three at once) proves all 3 channels.

**Fail hints:** a colour missing on one LED only → that channel is faulty.
Missing on all 4 → unlikely hardware; re-program and retest.

## Test 4 — UART, FPGA → PC direction

| Step | Expected | Record |
|---|---|---|
| Flip any switch while watching PuTTY | A new line appears instantly, e.g. `SW=0100 BTN=0000`. The 4 digits after `SW=` are SW3,SW2,SW1,SW0; after `BTN=` are BTN3..BTN0 | pass/fail |
| Hold a button | New line with the matching BTN bit = 1 | pass/fail |
| Check the digits actually match the physical switch/button positions | exact match | pass/fail |

## Test 5 — UART, PC → FPGA direction (echo)

| Step | Expected | Record |
|---|---|---|
| Click into the PuTTY window and type `hello123` | Every character appears as you type it | pass/fail |

PuTTY does **not** locally display what you type (local echo is off by
default) — if you see the characters, they made the round trip
PC → FPGA → PC. Alternative/automated version: run
`python tools\uart_selftest.py` and follow its prompts; it prints a PASS/FAIL
summary you can paste into the report.

## Test 6 — Pmod connectors (JA, JB, JC, JD)

Every Pmod pin outputs a square wave. Pin numbering on each 12-pin socket:

```
        upper row:  1   2   3   4   5(GND)  6(+3.3V)
        lower row:  7   8   9  10  11(GND) 12(+3.3V)
```

Nominal frequencies (same on all four connectors):

| Pin | Freq | What a multimeter (DC V) shows |
|---|---|---|
| 1 | ~0.37 Hz | flips 0 V ↔ 3.3 V every ~1.3 s (visible!) |
| 2 | ~0.75 Hz | flips every ~0.7 s |
| 3 | ~1.5 Hz | fast flipping |
| 4 | ~3 Hz | jittery ~1.6 V |
| 7–10 | 6 → 48 Hz | steady ~1.6 V (meter averages) |
| 5, 11 | — | 0 V (ground) |
| 6, 12 | — | 3.3 V (supply) |

Two methods — use whichever your equipment allows. **Method B needs no
instruments at all.**

### Method A — multimeter / oscilloscope

**Procedure per connector (JA, JB, JC, JD):**

1. ⚠️ Nothing must be plugged into the Pmods (all pins are driven).
2. Multimeter on DC volts. Black probe → pin 5 (GND).
3. Red probe on pin 1 → slow 0/3.3 V flipping. Record ✓.
4. Red probe on pin 6 → steady 3.3 V. Record the exact reading (should be
   3.2–3.4 V).
5. Red probe briefly on pins 2, 3, 4, 7, 8, 9, 10 → each behaves per the
   table above. Record ✓ per pin.
6. If you have an oscilloscope or logic analyzer instead: probe pins 1–4 and
   7–10, confirm clean 0–3.3 V square waves at the listed frequencies (each
   pin is 2× the previous). Record measured frequencies.

Variant: LED (long leg = +) + 330 Ω resistor in series between pin 1 and
pin 5 blinks ~every 1.3 s.

### Method B — touch test (no instruments; a paperclip or any wire)

1. Flip **ALL four slide switches UP**. The design enters *Pmod test mode*:
   every Pmod pin becomes an **input with an internal pull-up**, and the four
   green LEDs go dark — they now mean "a grounded pin on JA/JB/JC/JD".
2. Keep PuTTY open. On entering the mode it prints the full pin map:
   `JA=11111111 JB=11111111 JC=11111111 JD=11111111`
   (all 1 = all pins pulled high; the 8 digits are pins **1,2,3,4,7,8,9,10**
   left to right).
3. Straighten a paperclip (or use a jumper wire / metal tweezers). Touch one
   end to a **GND pin (5 or 11)** and the other end to one **signal pin**
   (1, 2, 3, 4, 7, 8, 9 or 10) of the same connector.
   ⚠️ **Never touch pin 6 or 12 (+3.3 V) to anything.**
4. While touching, two things happen:
   - the connector's LED lights: **JA→LD4, JB→LD5, JC→LD6, JD→LD7**;
   - PuTTY prints the map again with that pin's digit = 0. Example, touching
     JA pin 3: `JA=11011111 JB=11111111 JC=11111111 JD=11111111`.
5. Repeat for all 8 signal pins of each of the 4 connectors (32 touches),
   ticking each off in the report as its digit drops to 0.
   A pin that never reads 0 when touched — or reads 0 untouched — fails.
6. Finish: flip the switches back down; pins return to square-wave outputs.

Method B proves each pin's full electrical path (FPGA bond wire → PCB trace →
connector). Only the output drive voltage is left unmeasured; that is
additionally covered by pin 6 (fixed 3.3 V rail) in Method A if a multimeter
is ever available.

## Test 7 — Board-level buttons (informational)

| Step | Expected |
|---|---|
| Press **PROG** (red) | FPGA reloads from flash → factory demo returns (our design is gone). This is correct behaviour! Re-run `program.bat` to continue. |

---

## Recording results

Fill in `docs/TEST_REPORT_TEMPLATE.md` (copy it, e.g.
`TEST_REPORT_2026-08-07_yourname.md`). Attach:
- the PASS/FAIL table,
- your PuTTY observations (copy a few `SW=… BTN=…` lines),
- `build\timing_summary.rpt` (timing must show "All user specified timing
  constraints are met") and `build\utilization.rpt` from your build.

## Not covered (needs separate designs)

Ethernet PHY, DDR3 RAM, QSPI flash contents, XADC analog inputs, ChipKit
headers. These are advanced tests; the basic-IO health of the board is fully
covered by Tests 1–6.
