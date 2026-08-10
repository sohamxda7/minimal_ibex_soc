# RTOS Selection & Porting Plan

> **SUPERSEDED (2026-08-10).** Written against the 128 KiB-SRAM development
> build. The ASIC spec ([ASIC_SPEC.md](ASIC_SPEC.md)) later fixed SRAM at
> 8 KiB + SPI-flash XIP, which flips the conclusion to **FreeRTOS** (the
> RTOS the tapeout guide itself targets). Kept for the research record; the
> live document is [FREERTOS_PORT.md](FREERTOS_PORT.md).


*2026-08-07. Requirement from the DV lead: choose a widely supported, popular
RTOS and port it, such that the full capability of the Arty A7-100T platform
(CPU, memory, IO, all interfaces) can be exploited.*

## 1. What "full capability of the board" means in hardware terms

| Resource | Size / kind | Used by the SoC today? |
|---|---|---|
| FPGA fabric (XC7A100T) | 63 400 LUTs | 9.7 % — plenty of room for more blocks |
| On-chip block RAM | 135 tiles ≈ **600 KB** | 2.5 tiles (12 KB memories) |
| **DDR3 SDRAM** (on-board chip) | **256 MB** | ❌ not connected (needs a MIG memory controller) |
| **Ethernet PHY** (10/100) | RJ-45 + PHY on board | ❌ not connected (needs a MAC block) |
| QSPI flash | 16 MB | ❌ stub only (XIP controller present, pins not wired) |
| USB-UART | 115200 console | ✅ |
| GPIO/LEDs/switches/PWM/I2C/SPI | — | ✅ |

Conclusion: "use everything" is a **roadmap**, not a single port — DDR3 and
Ethernet require RTL additions regardless of RTOS. The RTOS choice determines
whether the software side is ready to absorb those additions when they land.

## 2. Candidates considered

| | FreeRTOS | **Zephyr** | Eclipse ThreadX | RT-Thread | NuttX |
|---|---|---|---|---|---|
| Governance / licence | AWS-stewarded, MIT | **Linux Foundation, Apache-2.0** | Eclipse, MIT | RT-Thread org, Apache-2.0 | Apache Foundation |
| Popularity | #1 deployed embedded kernel | **#1 growth, huge vendor backing** | moderate | large (esp. Asia) | moderate |
| Kernel footprint | ~10 KB | ~30–50 KB min useful | ~10 KB | ~30 KB | ~100 KB+ |
| RV32IMC / M-mode, no MMU | ✅ official port | ✅ first-class arch | ✅ | ✅ | ✅ |
| Driver model & devicetree | ❌ (BYO drivers) | ✅ **structured driver API + DTS** | partial | partial | ✅ |
| Networking stack | add-on (FreeRTOS+TCP) | ✅ **built-in (net, TCP/IP, PPP...)** | add-on (NetX) | ✅ | ✅ |
| Filesystems (flash) | add-on | ✅ built-in (littlefs, FAT) | add-on (FileX) | ✅ | ✅ |
| Shell / logging / sensors subsystems | ❌ | ✅ built-in | ❌ | partial | partial |
| Precedent on small RISC-V soft-cores | Mi-V, NEORV32 | **LiteX/VexRiscv in-tree, NEORV32 port** | few | some | some |
| Port effort to *this* SoC | days | **~2–3 weeks to console+drivers** | days–weeks | weeks | weeks+ |

## 3. Decision: **Zephyr RTOS**

Driven directly by the lead's requirement. Rationale:

1. **Only Zephyr's ecosystem matches the board's ceiling.** DDR3 → large
   heaps/buffers; Ethernet → a maintained TCP/IP stack; QSPI → flash API +
   littlefs; many peripherals → a real driver model with devicetree. With
   FreeRTOS each of those is a bolt-on we'd integrate and maintain ourselves.
2. **Widely supported and popular** — Linux Foundation project, the
   fastest-growing RTOS, backed by Intel/Nordic/NXP/ST/Google et al. Skills
   and drivers transfer in from a large community.
3. **Proven on FPGA soft RISC-V** — LiteX/VexRiscv boards are supported
   in-tree; NEORV32 (a core very like Ibex) has a documented community port.
   We are not the first to walk this path.
4. **Our hardware is compatible** (see §4) — notably the timer is already the
   CLINT-style `mtime/mtimecmp` layout Zephyr's RISC-V machine-timer driver
   expects.
5. **The devicetree culture matches the team** — the SoC is described once in
   a `.dts` that mirrors `wb_interconnect.sv`, which doubles as living
   documentation of the memory map.

*FreeRTOS remains the documented contingency*: if schedule pressure demands a
running kernel in days rather than weeks, its port is nearly configuration-
only on this hardware (CLINT-compatible timer, official RV32IMC port), at the
cost of re-doing the ecosystem work later. ThreadX/RT-Thread/NuttX offer no
advantage over these two for this platform.

## 4. Component compatibility map (SoC ↔ Zephyr)

| SoC component | Zephyr mechanism | Status / work needed |
|---|---|---|
| Ibex RV32IMC, M-mode only | `CONFIG_RISCV`, rv32imc ISA, no PMP use | ✅ supported arch; SoC definition to write |
| Timer @ `0x4000_0200` (mtime +0/+4, mtimecmp +8/+12) | `riscv,machine-timer` driver, base addresses from DTS | ✅ layout matches; DTS entry only |
| Ibex interrupts (mtimer + fast IRQs, no PLIC) | RISC-V direct-mode IRQs; custom `soc_interrupt` hooks for fast lines | small shim (UART fast-IRQ routing) |
| UART @ `0x4000_0000` (custom RX/TX/STATUS regs) | custom `serial` driver implementing `uart_driver_api` | ~1–2 days; console + shell backend |
| GPIO @ `0x4000_0100` | custom `gpio` driver | ~1 day |
| PWM @ `0x4000_0600` | custom `pwm` driver (12 channels) | ~1 day |
| I2C @ `0x4000_0400` (OpenCores) | Zephyr has an existing OpenCores-compatible pattern to crib | ~1–2 days |
| SPI host @ `0x4000_0500` | custom `spi` driver | ~1–2 days |
| SRAM 128 KiB | — | ✅ grown 8 → 128 KiB (Phase A, done 2026-08-07) |
| Boot ROM → SRAM entry `+0x80` | Zephyr image linked to SRAM base, entry aligned | linker script in board port |
| QSPI flash / XIP | `flash` driver + littlefs (later: XIP execution) | after pins are wired (Phase D) |
| DDR3 256 MB | MIG controller RTL + Zephyr `mem` region | Phase E (RTL project) |
| Ethernet PHY | MAC RTL (e.g. LiteEth/TEMAC) + Zephyr `ethernet` driver + net stack | Phase E (RTL project) |
| Toolchain | Zephyr SDK (bundled RISC-V GCC), `west`, CMake/Ninja | install on lab PC + CI |

## 5. Staged plan (each phase independently verifiable)

| Phase | Work | Acceptance |
|---|---|---|
| **A. Memory** | Grow SRAM 8 → 128 KiB (BRAM budget: uses ~32/135 tiles), update decode + linker + docs | xsim regression passes; current demo still runs on board |
| **B. Minimal Zephyr port** | ✅ port in `zephyr-port/` (board `ibex_arty`, SoC `ibex_soc`, DTS, UART driver). `hello_world` **boots in xsim** 2026-08-08 (banner + print, 5 ms sim time); board console run pending hardware availability | `samples/hello_world` prints — DONE in simulation |
| **C. Peripheral drivers** | GPIO, PWM, I2C, SPI drivers + shell enabled | `blinky`, `button`, shell over UART; RGB controlled from a Zephyr thread |
| **D. Storage** | Wire QSPI pins (STARTUPE2), flash driver, littlefs | mount + file read/write from shell |
| **E. Full capability** | MIG/DDR3 and Ethernet MAC RTL, net stack | 256 MB heap visible; ping + TCP echo server on the RJ-45 |
| Contingency | FreeRTOS quick port (days) if B slips against a deadline | task blink + UART print |

Phases A–C use only what is already on the SoC. D–E are joint RTL+software
projects and deliver the "full capability" goal.

## 6. Risks

- **Port complexity vs FreeRTOS**: mitigated by the staged plan and the
  documented FreeRTOS fallback.
- **Windows dev flow**: Zephyr supports Windows (`west` + SDK); CI should
  add a Linux build job for the Zephyr app to keep builds reproducible.
- **Memory ceiling before DDR3**: 128–256 KB BRAM caps net buffers until
  Phase E; sized acceptable for console/driver phases.
- **Ibex has no PLIC**: fine for UART-only interrupts; if peripheral IRQ
  count grows, add a small interrupt controller block (or adopt a CLIC) —
  flagged early to the RTL owners.

## 7. References

- Zephyr on LiteX/VexRiscv soft-core: https://numato.com/kb/running-zephyr-rtos-on-mimas-a7-using-litex-and-risc-v/
- Zephyr on NEORV32 soft-core: https://ejaaskel.dev/running-zephyr-rtos-on-neorv32-soft-processor/
- FreeRTOS RISC-V port (contingency): https://github.com/FreeRTOS/FreeRTOS-Kernel
- NEORV32 FreeRTOS port (precedent): https://github.com/stnolting/neorv32-freertos
- Mi-V RV32IMC FreeRTOS (precedent): https://github.com/RISCV-on-Microsemi-FPGA/Operating-Systems
- lowRISC ibex-demo-system (upstream): https://github.com/lowRISC/ibex-demo-system
