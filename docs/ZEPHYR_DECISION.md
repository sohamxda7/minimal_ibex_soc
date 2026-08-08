# RTOS Selection for the ARF Ibex SoC — Decision Memo

| | |
|---|---|
| **Date** | 2026-08-08 |
| **Author** | Soham Sen |
| **Requirement** | Select a widely supported, popular RTOS and port it to the ARF Ibex SoC (Arty A7-100T platform), such that the full capability of the board — CPU, memory, and every IO interface — can be exploited over time |
| **Decision** | **Zephyr RTOS** (Linux Foundation, Apache-2.0) |
| **Status** | Port implemented; **boots and runs in full-SoC RTL simulation** (evidence in §6); hardware run is a one-command step pending board availability |

---

## 1. Evaluation criteria

Derived from the stated requirement and the platform's characteristics:

1. **CPU fit** — RV32IMC, machine mode only, no MMU, no FPU, 20 MHz;
   interrupts are the RISC-V machine timer plus Ibex fast-IRQ lines (no PLIC).
2. **Memory fit** — 128 KiB on-chip SRAM today; 256 MB DDR3 and 16 MB QSPI
   flash reachable later via RTL additions.
3. **Ceiling** — must be able to absorb the board's *full* capability:
   Ethernet (TCP/IP), flash storage (filesystem), many custom peripherals
   (UART/GPIO/PWM/I2C/SPI), a debug/console shell.
4. **Popularity and support** — active upstream, broad vendor backing,
   hireable skills, long-term viability.
5. **Port effort and precedent** — demonstrated ports to comparable
   FPGA soft RISC-V cores.
6. **Licensing** — permissive, ASIC-product compatible.

## 2. Candidates evaluated

### Zephyr (selected)
- First-class 32-bit RISC-V architecture support (machine mode, no-MMU is
  its native operating point). Devicetree-driven hardware description with
  a structured driver API for every peripheral class we have.
- **Batteries included**: native TCP/IP stack, littlefs/FAT filesystems,
  shell, logging, settings, DFU — each maps 1:1 to a planned capability of
  this board (Ethernet, QSPI flash, console).
- Fastest-growing RTOS ecosystem; Linux Foundation governance; backed by
  Intel, Nordic, NXP, ST, Google, et al. Apache-2.0.
- Proven on FPGA soft cores: LiteX/VexRiscv boards supported in-tree;
  NEORV32 community port documented.
- Cost: largest minimum footprint of the shortlist (~30–50 KB useful
  configs — fits our 128 KiB with headroom) and the most porting work
  (board + SoC definitions, DTS, per-peripheral drivers).

### FreeRTOS (runner-up, documented contingency)
- #1 deployed embedded kernel; MIT; official RV32IMC machine-mode port.
  Our timer block is exactly the CLINT-style `mtime/mtimecmp` pair its port
  expects — the kernel port is near configuration-only on this hardware.
- However it is a *kernel*, not a platform: no driver model, no devicetree,
  and networking/filesystem/shell are separately-integrated add-ons
  (FreeRTOS+TCP, third-party FS). Reaching the board's full capability
  would mean assembling and maintaining that ecosystem ourselves — the
  integration burden moves onto the team, permanently.
- Retained as the documented fallback: if schedule ever demands a running
  kernel in days, this path exists (see docs/RTOS_RESEARCH.md §5).

### Eclipse ThreadX
- Technically excellent microkernel (~10 KB), MIT via Eclipse Foundation,
  RISC-V ports exist. But the ecosystem pieces (NetX, FileX, GUIX) are
  separate products with a far smaller community post-Azure, and FPGA soft
  core precedent is thin. No advantage over FreeRTOS at the small end or
  Zephyr at the platform end.

### RT-Thread
- Popular (particularly in Asia), good RISC-V support, reasonable
  middleware. Smaller English-language community and weaker soft-core
  precedent; devicetree support immature compared to Zephyr.

### NuttX
- POSIX compliance is attractive, but the largest footprint of the
  shortlist, a heavier port, and its strengths (POSIX process model)
  are not requirements here.

### Explicitly out of scope: Linux
- Ibex has no MMU; the SoC does not use the board's DDR3 today. Linux is
  not achievable on this CPU regardless of effort — an RTOS is the correct
  product class for this platform.

## 3. Why Zephyr won — the technical core

The requirement is **ceiling, not floor**. Every candidate can blink our
LEDs; only one candidate's *upstream, maintained, single-source* ecosystem
already contains the software for everything this board can become:

| Board capability (roadmap) | Zephyr answer (in-tree) | FreeRTOS answer |
|---|---|---|
| Ethernet PHY on board | native net stack (TCP/UDP/DHCP/DNS...) + `ethernet` driver class | integrate FreeRTOS+TCP ourselves |
| 16 MB QSPI flash | `flash` API + littlefs + settings/DFU | integrate third-party FS ourselves |
| Many custom peripherals | devicetree + per-class driver APIs (serial/gpio/pwm/i2c/spi) | hand-rolled drivers, no framework |
| Debug/console | shell subsystem over any UART | build one |
| Team scaling | `west` workspaces, Kconfig, per-board isolation | ad-hoc project structure |

Two hardware facts made the choice low-risk for *this* SoC specifically:

1. **Timer compatibility** — our timer at `0x4000_0200` implements the
   CLINT-style 64-bit `mtime`/`mtimecmp` register pair; Zephyr's RISC-V
   machine-timer driver binds to it directly from the devicetree. The
   hardest part of many ports simply does not exist here.
2. **Boot contract preserved** — our boot ROM jumps to `0x0010_2080`; the
   port's devicetree declares SRAM from exactly that address, so the Zephyr
   image links at the jump target. **Zero RTL or boot-ROM changes were
   required to boot an RTOS.**

## 4. What was implemented

Out-of-tree Zephyr module in `zephyr-port/` (buildable against upstream
Zephyr with `-DZEPHYR_EXTRA_MODULES=...`, no Zephyr-tree modifications):

- Board `ibex_arty` + SoC `ibex_soc` definitions (rv32imc, M-mode, 20 MHz)
- Devicetree mirroring `wb_interconnect.sv` (doubles as memory-map
  documentation)
- Devicetree binding + polling serial driver for the custom UART
  (console-ready; interrupt-driven mode is a later increment)
- `sw/tools/bin2vmem.py`: converts any ELF/binary into the SoC's
  `SRAMInitFile` format (self-tested)
- `dv/xsim/tb_zephyr.sv`: full-SoC RTL testbench that boots the real boot
  ROM + Zephyr image and decodes the UART
- `build_fpga_zephyr.bat`: one-command bitstream with Zephyr in SRAM

Prerequisite completed first: SRAM grown 8 → 128 KiB (BRAM-backed, 24 % of
the FPGA's tiles; xsim regression 9/9 PASS; timing met).

## 5. Port effort actually observed

The 2–3 week estimate for "console + drivers" stands, but the first
milestone came in far under it: from empty toolchain to **Zephyr booting in
RTL simulation took one working session**, with only two corrections to the
hand-written port (devicetree ISA binding format; MMIO accessor style in
the UART driver). Zephyr's `lowrisc,ibex` CPU binding exists upstream —
the ecosystem had already anticipated this core.

## 6. Results / evidence

`samples/hello_world`, Zephyr v4.4.0-dev, SDK 1.0.1 (riscv64-zephyr-elf):

- Image: **11.7 KiB text**, entry `0x00102080` (exact boot-ROM target),
  fits the 128 KiB SRAM ~10×.
- Full-SoC xsim run (real boot ROM, real UART RTL, 20 MHz clock):

```
*** Booting Zephyr OS build v4.4.0-10814-gdb85c02404ca ***
Hello World! ibex_arty/ibex_soc
PASS: Zephyr booted and printed Hello World (94 UART bytes, 5000 us sim time)
```

Boot-to-banner in ~5 ms of chip time. Hardware bring-up is
`build_fpga_zephyr.bat` → `program_fpga.bat` when the board is on the bench.

## 7. Next steps (from docs/RTOS_RESEARCH.md §5)

- **Phase C** — GPIO/PWM/I2C/SPI Zephyr drivers + shell (RGB LEDs driven
  from Zephyr threads; shell over UART)
- **Phase D** — QSPI pins + flash driver + littlefs
- **Phase E** — DDR3 (MIG) and Ethernet MAC RTL + net stack: ping and a TCP
  echo server on the board's RJ-45 — the "full capability" end state

## 8. References

- Working plan & compatibility map: [RTOS_RESEARCH.md](RTOS_RESEARCH.md)
- Port sources & build guide: [`zephyr-port/`](../zephyr-port/README.md)
- Zephyr on LiteX/VexRiscv: https://numato.com/kb/running-zephyr-rtos-on-mimas-a7-using-litex-and-risc-v/
- Zephyr on NEORV32: https://ejaaskel.dev/running-zephyr-rtos-on-neorv32-soft-processor/
- FreeRTOS RISC-V kernel port: https://github.com/FreeRTOS/FreeRTOS-Kernel
