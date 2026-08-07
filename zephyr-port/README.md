# Zephyr port for the ARF Ibex SoC (`ibex_arty` board)

Out-of-tree Zephyr module: board + SoC definition + drivers for this repo's
SoC. **Status: BUILDS AND BOOTS (simulation).** 2026-08-08, Zephyr v4.4.0-dev:
`hello_world` compiles and links at the boot-ROM entry (0x00102080, 11.7 KB)
and boots in the full-SoC xsim testbench (`dv/xsim/tb_zephyr.sv`):

```
*** Booting Zephyr OS build v4.4.0-10814-gdb85c02404ca ***
Hello World! ibex_arty/ibex_soc
```

Hardware run pending board availability: `build_fpga_zephyr.bat` →
`program_fpga.bat`.

Selection rationale, compatibility map and the phased plan:
[../docs/RTOS_RESEARCH.md](../docs/RTOS_RESEARCH.md).

## Prerequisites (once per PC)

CMake + Ninja (`winget`), `pip install west`, then:

```
west init C:\FPGA\zephyrproject
cd C:\FPGA\zephyrproject
west update
west packages pip --install
west sdk install -t riscv64-zephyr-elf
```

## Build (from `C:\FPGA\zephyrproject`)

```
west build -p -b ibex_arty zephyr/samples/hello_world -- ^
  -DZEPHYR_EXTRA_MODULES=C:/FPGA/minimal-ibex-soc/zephyr-port
```

## Turn the ELF into an SRAM image and run it

```
riscv64-zephyr-elf-objcopy -O binary build/zephyr/zephyr.elf zephyr.bin
python C:/FPGA/minimal-ibex-soc/sw/tools/bin2vmem.py zephyr.bin ^
  C:/FPGA/minimal-ibex-soc/sw/asm-demo/sram_init_zephyr.vmem --offset 0x80
```

- **Simulate first** (no board needed): point the testbench's `SRAMInitFile`
  at `sram_init_zephyr.vmem` (edit `dv/xsim/tb_soc.sv` dut parameter, or make
  a copy of the tb) and run the xsim flow — the UART decoder in the tb will
  print Zephyr's boot banner.
- **On hardware**: pass the vmem via `-generic SRAMInitFile=...` in
  `build_fpga.tcl`, rebuild, `program_fpga.bat`.

## Memory/boot contract

Boot ROM jumps to **0x0010_2080**; the devicetree therefore declares SRAM at
`0x00102080` (size `0x1FF80`), so Zephyr links exactly at the jump target —
no RTL or boot-ROM change needed. `bin2vmem.py --offset 0x80` places the
binary to match.

## Layout

```
zephyr/module.yml            west module manifest (board/soc/dts roots)
boards/arf/ibex_arty/        board definition + devicetree + defconfig
soc/arf/ibex_soc/            SoC Kconfig (rv32imc, machine timer)
dts/bindings/serial/         binding for the custom UART
drivers/serial/uart_arf.c    polling console driver (RX+0 TX+4 STATUS+8)
```
