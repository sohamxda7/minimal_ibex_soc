# Design Overview — how `arty_io_test` works

For reviewers and anyone modifying the design. Beginner-friendly.

## Block diagram

```
                 +--------------------------------------------------+
 100 MHz clk --->|  32-bit free-running counter "tick"              |
                 |  (t = tick << SPEEDUP; SPEEDUP=0 on hardware)    |
                 +---+----------+-----------+----------+------------+
                     |          |           |          |
                     v          v           v          v
               [LED chase] [RGB PWM +  [Pmod square [~24 Hz sample
                t[25:24]    colour      waves        strobe
                     |      phase       t[27:20]]    t[21:0]==0]
   sw[3:0] --+-------+      t[27:26]]      |             |
             |       |          |          v             v
             |       v          |      ja,jb,jc,jd   [change detect]
             |  led[3:0] =      |                        |
             |  sw (if any up)  |                        v
             |  else chase      |                 [message engine]
             |                  |                 "SW=xxxx BTN=xxxx\r\n"
  btn[3:0] --+------------------+                        |
             |                                           v
             |                                   [uart_tx]--> uart_rxd_out
             |                                       ^
             +--> (per-button RGB enable)            |
                                             [echo: 1-byte queue]
  uart_txd_in -->[uart_rx]---------------------------+
```

## Files

| File | Role |
|---|---|
| `src/top.v` | everything above except the two UART shifters |
| `src/uart_tx.v` | serialises one byte: start bit, 8 data bits (LSB first), stop bit |
| `src/uart_rx.v` | reverse: detects start bit, samples each bit at its centre |
| `constraints/arty_a7.xdc` | maps port names to physical package pins, 3.3 V IO |
| `sim/tb_top.v` | simulation testbench (sped-up timebase, prints UART traffic) |
| `scripts/build.tcl` | batch flow: synth → place → route → reports → bitstream |
| `scripts/program.tcl` | loads the bitstream over USB-JTAG |

## Key design decisions

- **One counter drives everything.** Human-visible time scales are made by
  picking high bits of a 100 MHz counter: bit *n* toggles at
  100 MHz / 2^(n+1). E.g. bit 27 → 0.37 Hz.
- **`SPEEDUP` parameter** (0 on hardware): the testbench sets 12, which
  left-shifts the counter so slow effects run 4096× faster. This exists
  because simulators cover microseconds while the design's behaviour lives in
  seconds — without it, waveforms look "frozen" and confuse people.
- **RGB PWM at ~390 kHz, ~6 % duty** (`BRIGHT = 16/256`): the RGB LEDs are
  uncomfortably bright at full drive. In a waveform viewer this PWM looks like
  rapid toggling — that is correct, the eye averages it to dim light.
- **UART = 115200 8N1**, `CLKS_PER_BIT = 100 MHz / 115200 = 868`.
- **Status messages** are sent from a small FSM reading a character ROM
  (`case` on `msg_idx`); the switch/button state is latched at message start
  so a mid-message flip can't corrupt the text.
- **Echo has a 1-byte queue** and yields to an in-progress status message;
  at human typing rates nothing is lost.
- **Pmod pins are bidirectional**: square-wave outputs normally; when all
  four switches are up ("touch-test mode") they release to inputs with
  internal pull-ups (`PULLUP true` in the XDC), so grounding a pin with a
  paperclip is detectable — each connector's LED shows "some pin grounded"
  and the UART prints the full 32-pin map. Unplug Pmod modules during normal
  mode (outputs are driven).

## Resource cost (approx.)

A few hundred LUTs/FFs — under 1 % of the XC7A100T. See
`build/utilization.rpt` after a build.

## Extending

- ChipKit header test: add ports + XDC lines (Digilent master XDC has the
  pins), drive like the Pmods.
- Pmod loopback: jumper JA↔JB, make JB inputs, compare and report over UART.
- Ethernet/DDR3/XADC: separate, larger designs (MIG, MAC IP, XADC wizard).
