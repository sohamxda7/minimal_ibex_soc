#!/bin/sh
# =========================================================================
# Build FreeRTOS firmware on Linux/WSL - the POSIX twin of build.bat.
#
#   ./build.sh [hw|sim|toy] [toolchain-root]
#
# Run from sw/freertos. On Windows you never call this directly: build.bat
# invokes it as  wsl --cd sw\freertos -e bash ./build.sh <variant> <root>
# whenever the located toolchain lives inside WSL (RISCV_GCC_HOME=wsl:...),
# e.g. the lowRISC toolchain, whose tar.xz ships Linux binaries only:
#   https://github.com/lowRISC/lowrisc-toolchains/releases
# With no root argument the toolchain is taken from RISCV_GCC_HOME or PATH.
# Keep the compile line in sync with build.bat.
# =========================================================================
set -e

VARIANT="${1:-hw}"
# --check-toolchain: exit 0 iff a RISC-V GCC is discoverable, build nothing
# (used by ibex_soc.sh to decide whether firmware can be rebuilt).
CHECK_ONLY=0
[ "$VARIANT" = "--check-toolchain" ] && CHECK_ONLY=1
ROOT="${2:-${RISCV_GCC_HOME:-}}"
case "$ROOT" in wsl:*) ROOT="${ROOT#wsl:}" ;; esac

BIN=""
[ -n "$ROOT" ] && BIN="$ROOT/bin/"

# Any bare-metal RISC-V GCC works; same prefix order as find_tools.cmd
PREFIX="${RISCV_PREFIX:-}"
if [ -z "$PREFIX" ]; then
    for p in riscv32-unknown-elf- riscv64-zephyr-elf- riscv64-unknown-elf- riscv-none-elf-; do
        if [ -x "${BIN}${p}gcc" ] || [ -x "${BIN}${p}gcc.exe" ] || \
           { [ -z "$BIN" ] && command -v "${p}gcc" >/dev/null 2>&1; }; then
            PREFIX="$p"
            break
        fi
    done
fi
if [ -z "$PREFIX" ]; then
    echo "ERROR: no RISC-V gcc found (root: '${ROOT:-PATH}')." >&2
    exit 1
fi
GCC="${BIN}${PREFIX}gcc"
OBJCOPY="${BIN}${PREFIX}objcopy"
OBJDUMP="${BIN}${PREFIX}objdump"

if [ "$CHECK_ONLY" = 1 ]; then
    echo "toolchain: ${GCC}"
    exit 0
fi

KERNEL=../../vendor/freertos_kernel
PORT=$KERNEL/portable/GCC/RISC-V

# One hardware image (since 2026-08-18): the LCD/sensor task ships in every
# hw build ("toy" stays as an alias); sim excludes it to keep tb_freertos fast.
NAME=freertos_demo
DEFS=-DTOY_DEMO
case "$VARIANT" in
    sim) NAME=freertos_demo_sim; DEFS=-DSIM_BUILD ;;
esac

mkdir -p build

# Older GCC (e.g. the lowRISC toolchain's 10.2) rejects the modern _zicsr
# march spelling; there the CSR ops are still part of plain rv32imc.
MARCH=rv32imc_zicsr
echo 'int _march_probe;' > build/march_probe.c
"$GCC" -march=$MARCH -mabi=ilp32 -c build/march_probe.c \
    -o build/march_probe.o >/dev/null 2>&1 || MARCH=rv32imc

"$GCC" $DEFS \
    -march=$MARCH -mabi=ilp32 -mcmodel=medany \
    -Os -g -ffunction-sections -fdata-sections -ffreestanding \
    -I . -I "$KERNEL/include" -I "$PORT" \
    -I "$PORT/chip_specific_extensions/RV32I_CLINT_no_extensions" \
    -T link_xip.ld -nostartfiles -Wl,--gc-sections \
    -Wl,-Map="build/$NAME.map" \
    startup.S main.c uart.c \
    drivers/i2c.c drivers/st7735.c \
    drivers/spi_bus.c drivers/psram.c \
    drivers/esp_at.c drivers/audio.c drivers/camera.c \
    drivers/bme280.c drivers/ssd1306.c \
    "$KERNEL/tasks.c" "$KERNEL/list.c" "$KERNEL/queue.c" \
    "$KERNEL/portable/MemMang/heap_4.c" \
    "$PORT/port.c" "$PORT/portASM.S" \
    -o "build/$NAME.elf"

"$OBJCOPY" -O binary "build/$NAME.elf" "build/$NAME.bin"
"$OBJDUMP" -h "build/$NAME.elf" > "build/$NAME.sections.txt"

# _flash.vmem for simulation. In the WSL-from-build.bat flow this also runs
# again on the Windows side - harmless, the output is deterministic.
if command -v python3 >/dev/null 2>&1; then
    python3 ../tools/bin2flashvmem.py "build/$NAME.bin" "build/${NAME}_flash.vmem"
elif command -v python >/dev/null 2>&1; then
    python ../tools/bin2flashvmem.py "build/$NAME.bin" "build/${NAME}_flash.vmem"
else
    echo "note: no python here - build.bat generates ${NAME}_flash.vmem on the Windows side"
fi

echo
echo "RAM budget (data+bss must fit 8192 bytes together with stacks):"
grep -Ei '\.(data|bss)' "build/$NAME.sections.txt" || true
echo "BUILD OK: sw/freertos/build/$NAME.bin"
