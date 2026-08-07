# Arty A7-100T IO Test Report

| | |
|---|---|
| **Board** | Digilent Arty A7-100T (XC7A100T-CSG324-1) |
| **Board serial no.** | *(sticker on the back)* |
| **Tester** | |
| **Date** | |
| **PC / OS** | |
| **Vivado version** | |
| **COM port used** | |
| **Design version** | *(git commit hash — run `git log -1 --format=%h`)* |

## Build results

| Check | Result |
|---|---|
| `build.bat` completed with `BUILD OK` | ☐ pass ☐ fail |
| Timing met (`build\timing_summary.rpt`: "All user specified timing constraints are met") | ☐ pass ☐ fail |
| `program.bat` completed with `BOARD PROGRAMMED!` | ☐ pass ☐ fail |

## Test results

### 1. Green LEDs
| Item | Result |
|---|---|
| LD4 lights in chase | ☐ pass ☐ fail |
| LD5 lights in chase | ☐ pass ☐ fail |
| LD6 lights in chase | ☐ pass ☐ fail |
| LD7 lights in chase | ☐ pass ☐ fail |

### 2. Slide switches
| Item | Result |
|---|---|
| SW0 → LD4 only | ☐ pass ☐ fail |
| SW1 → LD5 only | ☐ pass ☐ fail |
| SW2 → LD6 only | ☐ pass ☐ fail |
| SW3 → LD7 only | ☐ pass ☐ fail |
| All up → all lit; all down → chase resumes | ☐ pass ☐ fail |

### 3. Buttons + RGB LEDs (hold ~4 s each; expect red→green→blue→white)
| Item | R | G | B | White | Off on release |
|---|---|---|---|---|---|
| BTN0 / LD0 | ☐ | ☐ | ☐ | ☐ | ☐ |
| BTN1 / LD1 | ☐ | ☐ | ☐ | ☐ | ☐ |
| BTN2 / LD2 | ☐ | ☐ | ☐ | ☐ | ☐ |
| BTN3 / LD3 | ☐ | ☐ | ☐ | ☐ | ☐ |

### 4. UART FPGA → PC (status messages @115200)
| Item | Result |
|---|---|
| Line printed on every switch/button change | ☐ pass ☐ fail |
| Digits match physical positions | ☐ pass ☐ fail |

Sample lines captured from the terminal:
```
(paste 2-3 lines like "SW=0100 BTN=0000" here)
```

### 5. UART PC → FPGA (echo)
| Item | Result |
|---|---|
| Typed characters echoed back | ☐ pass ☐ fail |
| `tools\uart_selftest.py` summary (if used) | ☐ pass ☐ fail |

```
(paste the self-test output here if used)
```

### 6. Pmod connectors
Method used: ☐ A (multimeter/scope) ☐ B (touch test, no instruments)

**Method A** (skip if B used):
| Check | JA | JB | JC | JD |
|---|---|---|---|---|
| Pin 1 slow toggle (~0.37 Hz, 0↔3.3 V) | ☐ | ☐ | ☐ | ☐ |
| Pin 6 supply (measured V) | ___ V | ___ V | ___ V | ___ V |
| Pins 2–4 behave per table | ☐ | ☐ | ☐ | ☐ |
| Pins 7–10 behave per table | ☐ | ☐ | ☐ | ☐ |

**Method B** — tick each pin whose UART digit dropped to 0 (and the
connector LED lit) when touched to GND:
| Physical pin | JA | JB | JC | JD |
|---|---|---|---|---|
| 1 | ☐ | ☐ | ☐ | ☐ |
| 2 | ☐ | ☐ | ☐ | ☐ |
| 3 | ☐ | ☐ | ☐ | ☐ |
| 4 | ☐ | ☐ | ☐ | ☐ |
| 7 | ☐ | ☐ | ☐ | ☐ |
| 8 | ☐ | ☐ | ☐ | ☐ |
| 9 | ☐ | ☐ | ☐ | ☐ |
| 10 | ☐ | ☐ | ☐ | ☐ |

Sample `JA=… JB=… JC=… JD=…` lines captured from the terminal:
```
(paste 2-3 lines here)
```

Oscilloscope/LA measured frequencies (optional):
```
(pin : measured Hz, e.g. JA1: 0.37 Hz)
```

### 7. PROG button (informational)
| Item | Result |
|---|---|
| PROG reloads factory demo | ☐ pass ☐ fail ☐ not tested |

## Verdict

☐ **ALL BASIC IO PASS** ☐ Failures (list below)

| Failed item | Observation | Suspected cause |
|---|---|---|
| | | |

## Attachments
- ☐ `timing_summary.rpt`
- ☐ `utilization.rpt`
- ☐ photos of board during tests (optional)
