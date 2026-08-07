# Arty A7-100T IO Test Report

| | |
|---|---|
| **Board** | Digilent Arty A7-100T (XC7A100T-CSG324-1) |
| **Board serial no.** | *(sticker on the back)* |
| **Tester** | Soham Sen |
| **Date** | 2026-08-07 |
| **PC / OS** | Windows 11 Pro |
| **Vivado version** | v2026.1 (64-bit) |
| **COM port used** | COM4 |
| **Design version** | 7c9fd38 (tests 1–5) / 72ba1f6 (Pmod touch test) |

## Build results

| Check | Result |
|---|---|
| `build.bat` completed with `BUILD OK` | ✅ **PASS** (bitstream 3.6 MB, built 2026-08-07) |
| Timing met ("All user specified timing constraints are met") | ✅ **PASS** (99 LUTs / 138 FFs = 0.16% of device) |
| `program.bat` completed with `BOARD PROGRAMMED!` | ✅ **PASS** (2026-08-07 via USB-JTAG) |

## Test results

### 1. Green LEDs
| Item | Result |
|---|---|
| LD4 lights in chase | ✅ **PASS** |
| LD5 lights in chase | ✅ **PASS** |
| LD6 lights in chase | ✅ **PASS** |
| LD7 lights in chase | ✅ **PASS** |

### 2. Slide switches
| Item | Result |
|---|---|
| SW0 → LD4 only | ✅ **PASS** |
| SW1 → LD5 only | ✅ **PASS** |
| SW2 → LD6 only | ✅ **PASS** |
| SW3 → LD7 only | ✅ **PASS** |
| All up → all lit; all down → chase resumes | ✅ **PASS** |

### 3. Buttons + RGB LEDs (held ~4 s each; red→green→blue→white observed)
| Item | R | G | B | White | Off on release |
|---|---|---|---|---|---|
| BTN0 / LD0 | ✅ | ✅ | ✅ | ✅ | ✅ |
| BTN1 / LD1 | ✅ | ✅ | ✅ | ✅ | ✅ |
| BTN2 / LD2 | ✅ | ✅ | ✅ | ✅ | ✅ |
| BTN3 / LD3 | ✅ | ✅ | ✅ | ✅ | ✅ |

### 4. UART FPGA → PC (status messages @115200)
| Item | Result |
|---|---|
| Line printed on every switch/button change | ✅ **PASS** |
| Digits match physical positions | ✅ **PASS** — captured log shows each of the 4 SW bits and 4 BTN bits toggling individually (0001, 0010, 0100, 1000) |

Sample lines captured from the terminal (full sweep of all switches and buttons):
```
SW=0001 BTN=0000
SW=0010 BTN=0000
SW=0100 BTN=0000
SW=1000 BTN=0000
SW=0000 BTN=0001
SW=0000 BTN=0010
SW=0000 BTN=0100
SW=0000 BTN=1000
SW=0000 BTN=0000
```

### 5. UART PC → FPGA (echo)
| Item | Result |
|---|---|
| Typed characters echoed back | ✅ **PASS** (automated test) |
| Automated echo test | ✅ **PASS** — 8/8 bytes (0x55, 0x7A, 0x35, 0x00, 0xFF, 0x41, 0x0D, 0xA5), ~16 ms round-trip |

```
echo: 8/8 bytes correct, round-trip ~16.2 ms   (COM4 @ 115200, 2026-08-07)
```

### 6. Pmod connectors
Method used: ☐ A (multimeter/scope) ☑ **B (touch test, no instruments)** —
see TEST_PROCEDURE.md §Test 6 Method B. Design version 72ba1f6.

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

### 7. PROG button (informational)
| Item | Result |
|---|---|
| PROG reloads factory demo | ☐ pass ☐ fail ☐ not tested |

## Verdict

☐ **ALL BASIC IO PASS** ☐ Failures (list below)
*(pending: Pmod touch test grid above)*

| Failed item | Observation | Suspected cause |
|---|---|---|
| | | |

## Attachments
- ☐ `timing_summary.rpt`
- ☐ `utilization.rpt`
- ☐ photos of board during tests (optional)
