#!/usr/bin/env bash
# =============================================================================
# ibex_soc.sh - the Linux twin of ibex_soc.bat: ONE entry point, same flows.
# Run with no arguments for an interactive menu, or name a flow directly:
#
#   ./ibex_soc.sh setup            # tool doctor (verilator/python/gcc/vivado)
#   ./ibex_soc.sh deps             # INSTALL missing tools (apt/dnf/pacman + xPack GCC)
#   ./ibex_soc.sh images           # regenerate all program .vmem images
#   ./ibex_soc.sh firmware [sim]   # FreeRTOS build (default: hw image)
#   ./ibex_soc.sh lint             # verilator --lint-only of the SoC RTL
#   ./ibex_soc.sh sim <tb>         # build + run ONE testbench (e.g. tb_soc)
#   ./ibex_soc.sh regression       # images + sim firmware + all 11 sims (Verilator)
#   ./ibex_soc.sh build            # bitstream via Vivado-on-Linux (build_fpga.tcl)
#   ./ibex_soc.sh flashfw          # firmware + bitstream + program QSPI flash
#   ./ibex_soc.sh flashonly [bin]  # program existing bitstream + firmware .bin
#
# Simulation is fully open-source: Verilator 5 (--timing) runs all xsim
# testbenches unmodified (10 TBs + the DFFRAM config of tb_soc).
# Bitstream/flash flows need a Linux Vivado install
# (located via $VIVADO, PATH, or /opt|/tools/Xilinx). Supported distros for
# `deps`: Ubuntu/Debian (apt), RHEL/Fedora (dnf), MSYS2 (pacman).
# Ubuntu 22.04's verilator 4.x is too old - deps warns; 24.04+ is fine.
#
# Tool paths persist in .toolpaths.sh (gitignored), the twin of .toolpaths.
# Logs: build/verilator/<tb>/, build/fpga/.  Exit code 0 = green.
# =============================================================================
set -u
cd "$(dirname "$0")"

# Per-PC tool locations written by `deps` (RISCV_GCC_HOME, VIVADO, ...)
[ -f .toolpaths.sh ] && . ./.toolpaths.sh

# ---- the 10 testbenches and their PASS lines (same table as the Windows
#      regression, scripts/run_regression.ps1 - keep in sync) ----------------
TBS="tb_soc tb_soc_dffram tb_lcd tb_i2c tb_xip tb_freertos tb_psram tb_wifi tb_uart2_irq tb_audio tb_cam"
pass_of() {
    case "$1" in
        tb_soc)       echo "9 PASS, 0 FAIL" ;;
        tb_soc_dffram) echo "9 PASS, 0 FAIL" ;;  # tb_soc on the GF180 DFFRAM model (ASIC SRAM, per-byte WE)
        tb_lcd)       echo "5 PASS, 0 FAIL" ;;
        tb_i2c)       echo "PASS: register" ;;
        tb_xip)       echo "PASS: CPU executed" ;;
        tb_freertos)  echo "PASS: FreeRTOS" ;;
        tb_psram)     echo "PASS: PSRAM" ;;
        tb_wifi)      echo "PASS: AT" ;;
        tb_uart2_irq) echo "PASS: UART2 IRQ" ;;
        tb_audio)     echo "PASS: 4 increasing" ;;
        tb_cam)       echo "PASS: 16-byte" ;;
        *)            echo "__NO_SUCH_TB__" ;;
    esac
}

VERILATOR="${VERILATOR:-verilator}"
PYTHON="${PYTHON:-python3}"
command -v "$PYTHON" >/dev/null 2>&1 || PYTHON=python
JOBS="$(nproc 2>/dev/null || echo 4)"

INCDIRS="+incdir+vendor/lowrisc_ip/ip/prim/rtl +incdir+rtl/system \
         +incdir+vendor/lowrisc_ibex/vendor/lowrisc_ip/dv/sv/dv_utils"
DV_SRC="dv/xsim/spi_nor_flash_model.sv dv/xsim/periph_models.sv \
        dv/xsim/sim_stubs.sv rtl/system/i2c_slave_bfm.sv"
# Verilator resolves even dead-generate module refs (prim_lfsr inside the
# disabled dummy-instr block) by searching the incdirs, which pulls in a
# package xsim never needs - feed it explicitly.
VLT_EXTRA="vendor/lowrisc_ip/ip/prim/rtl/prim_cipher_pkg.sv"

# MSYS2/MinGW host quirk (GCC 16.2, 2026-08): -Os (Verilator's default OPT)
# fails to emit std::string's move ctor and the link dies on an undefined
# reference; -O2 is fine (and faster at runtime anyway). Linux keeps the
# Verilator defaults. (WALKTHROUGH gotcha 30.)
VLT_MAKEFLAGS=""
case "$(uname -o 2>/dev/null)" in
    Msys|Cygwin) VLT_MAKEFLAGS="-MAKEFLAGS OPT_FAST=-O2 -MAKEFLAGS OPT_SLOW=-O2 -MAKEFLAGS OPT_GLOBAL=-O2" ;;
esac

have() { command -v "$1" >/dev/null 2>&1; }

vlt_version_ok() {
    have "$VERILATOR" || return 1
    v=$("$VERILATOR" --version 2>/dev/null | awk '{print $2}')
    maj=${v%%.*}
    [ "${maj:-0}" -ge 5 ]
}

# Vivado (for bitstream/flash): $VIVADO > PATH > standard install roots.
find_vivado() {
    if [ -n "${VIVADO:-}" ] && [ -x "$VIVADO" ]; then echo "$VIVADO"; return 0; fi
    if have vivado; then command -v vivado; return 0; fi
    for root in /opt/Xilinx/Vivado /tools/Xilinx/Vivado; do
        # shellcheck disable=SC2012
        v=$(ls -1d "$root"/*/bin/vivado 2>/dev/null | sort -V | tail -1)
        [ -n "$v" ] && { echo "$v"; return 0; }
    done
    return 1
}

# ---- flows ------------------------------------------------------------------
do_setup() {
    echo "=== Environment check (Linux flow) ==="
    ok=0
    if vlt_version_ok; then
        echo "[ OK ] verilator: $("$VERILATOR" --version)"
    else
        echo "[FAIL] verilator >= 5 not found (need --timing/--binary). Run: $0 deps"
        ok=1
    fi
    if have "$PYTHON"; then echo "[ OK ] python: $("$PYTHON" --version 2>&1)"
    else echo "[FAIL] python3 not found. Run: $0 deps"; ok=1; fi
    if have make && have g++; then echo "[ OK ] make + g++"
    else echo "[FAIL] make/g++ missing. Run: $0 deps"; ok=1; fi
    if sw/freertos/build.sh --check-toolchain 2>/dev/null; then
        echo "[ OK ] RISC-V GCC (firmware builds enabled)"
    else
        echo "[WARN] RISC-V GCC not found - firmware cannot be rebuilt (sims can"
        echo "       reuse an existing sw/freertos/build image). Run: $0 deps"
    fi
    if v=$(find_vivado); then echo "[ OK ] vivado: $v (bitstream/flash flows enabled)"
    else echo "[INFO] Vivado not found - sim flows unaffected; build/flashfw need it"; fi
    if have fusesoc; then echo "[ OK ] fusesoc: $(fusesoc --version 2>&1)"
    else echo "[INFO] fusesoc not installed (optional): pip install fusesoc"; fi
    return $ok
}

# xPack RISC-V GCC into ~/ibex-tools - the same toolchain the Windows GUI
# auto-installs; works on any distro (RHEL has no packaged bare-metal GCC).
install_xpack_gcc() {
    dest="${IBEX_TOOLS_DIR:-$HOME/ibex-tools}"
    mkdir -p "$dest"
    echo "Fetching latest xPack riscv-none-elf-gcc release tag..."
    tag=$(curl -sL https://api.github.com/repos/xpack-dev-tools/riscv-none-elf-gcc-xpack/releases/latest \
          | grep -m1 '"tag_name"' | sed 's/.*"v\([^"]*\)".*/\1/')
    [ -n "$tag" ] || { echo "ERROR: could not query GitHub - install manually:"; \
                       echo "  https://github.com/xpack-dev-tools/riscv-none-elf-gcc-xpack/releases"; return 1; }
    url="https://github.com/xpack-dev-tools/riscv-none-elf-gcc-xpack/releases/download/v${tag}/xpack-riscv-none-elf-gcc-${tag}-linux-x64.tar.gz"
    echo "Downloading $url"
    curl -L -o "$dest/xpack-gcc.tar.gz" "$url" || return 1
    tar -xzf "$dest/xpack-gcc.tar.gz" -C "$dest" && rm "$dest/xpack-gcc.tar.gz"
    root=$(ls -1d "$dest"/xpack-riscv-none-elf-gcc-* 2>/dev/null | sort -V | tail -1)
    [ -x "$root/bin/riscv-none-elf-gcc" ] || { echo "ERROR: extract failed"; return 1; }
    { echo "export RISCV_GCC_HOME=\"$root\""
      echo "export RISCV_PREFIX=riscv-none-elf-"; } >> .toolpaths.sh
    echo "RISC-V GCC installed -> $root (recorded in .toolpaths.sh)"
}

do_deps() {
    echo "=== Installing dependencies ==="
    SUDO=""; [ "$(id -u)" != 0 ] && have sudo && SUDO=sudo
    if have apt-get; then                       # Ubuntu / Debian
        $SUDO apt-get update
        $SUDO apt-get install -y verilator make g++ python3 python3-pip curl \
            gcc-riscv64-unknown-elf || true
    elif have dnf; then                         # RHEL / Fedora / Rocky
        $SUDO dnf install -y verilator make gcc-c++ python3 python3-pip curl || true
        echo "(RHEL has no packaged bare-metal RISC-V GCC - xPack fallback below)"
    elif have pacman; then                      # MSYS2 (dev convenience)
        pacman -S --noconfirm --needed make mingw-w64-ucrt-x86_64-gcc \
            mingw-w64-ucrt-x86_64-verilator mingw-w64-ucrt-x86_64-python \
            mingw-w64-ucrt-x86_64-python-pip || true
    else
        echo "ERROR: no supported package manager (apt/dnf/pacman)."; return 1
    fi
    if ! vlt_version_ok; then
        echo "[WARN] verilator >= 5 still missing (Ubuntu 22.04 ships 4.x)."
        echo "       Use Ubuntu 24.04+, or build verilator from source:"
        echo "       https://verilator.org/guide/latest/install.html"
    fi
    if ! sw/freertos/build.sh --check-toolchain >/dev/null 2>&1; then
        case "$(uname -o 2>/dev/null)" in
            Msys|Cygwin) echo "[INFO] on Windows, install RISC-V GCC via ibex_soc.bat -> Install Missing Tools" ;;
            *) install_xpack_gcc || echo "[WARN] RISC-V GCC not installed - firmware rebuilds disabled" ;;
        esac
    fi
    have fusesoc || pip3 install --user --break-system-packages fusesoc 2>/dev/null \
                 || pip3 install --user fusesoc 2>/dev/null \
                 || echo "[INFO] fusesoc not installed (optional)"
    echo; do_setup
}

do_images() {
    echo "=== Program images ==="
    for g in assemble.py "assemble.py --sim" "lcd_spi_test.py --sim" i2c_test.py \
             xip_test.py periph_tests.py uart2_irq_test.py; do
        # shellcheck disable=SC2086
        (cd sw/asm-demo && $PYTHON $g) || return 1
    done
}

do_firmware() {
    echo "=== FreeRTOS firmware (${1:-hw}) ==="
    (cd sw/freertos && ./build.sh "${1:-hw}")
}

do_lint() {
    echo "=== verilator --lint-only (ibex_demo_system) ==="
    # shellcheck disable=SC2086
    "$VERILATOR" --lint-only --timing -Wno-fatal --top-module ibex_demo_system \
        -f dv/xsim/filelist.f $VLT_EXTRA $INCDIRS
}

do_sim() {
    tb="$1"
    [ "$(pass_of "$tb")" = "__NO_SUCH_TB__" ] && { echo "unknown tb '$tb' (one of: $TBS)"; return 2; }
    # tb_soc_dffram = tb_soc with the DFFRAM storage array (parameter, -G)
    src="dv/xsim/$tb.sv"; top="$tb"; gparam=""
    if [ "$tb" = "tb_soc_dffram" ]; then
        src="dv/xsim/tb_soc.sv"; top="tb_soc"; gparam="-GUseDffram=1"
    fi
    mkdir -p "build/verilator/$tb"
    echo "--- verilate $tb ---"
    # shellcheck disable=SC2086
    "$VERILATOR" --binary --timing -j "$JOBS" -Wno-fatal --quiet-stats \
        --top-module "$top" $gparam -Mdir "build/verilator/$tb" -o "${tb}_sim" $VLT_MAKEFLAGS \
        -f dv/xsim/filelist.f "$src" $DV_SRC $VLT_EXTRA $INCDIRS \
        > "build/verilator/$tb/build.log" 2>&1 \
        || { echo "VERILATE FAILED - build/verilator/$tb/build.log"; return 1; }
    echo "--- run $tb ---"
    "./build/verilator/$tb/${tb}_sim" 2>&1 | tee "build/verilator/$tb/run.log" \
        | grep -E "PASS|FAIL|RESULTS" || true
    grep -qF "$(pass_of "$tb")" "build/verilator/$tb/run.log"
}

do_regression() {
    declare -A results
    do_images; results[images]=$?
    if sw/freertos/build.sh --check-toolchain >/dev/null 2>&1; then
        do_firmware sim; results[freertos-build]=$?
    elif [ -f sw/freertos/build/freertos_demo_sim_flash.vmem ]; then
        echo "[WARN] no RISC-V GCC - reusing existing sim firmware image"
        results[freertos-build]=0
    else
        echo "[FAIL] no RISC-V GCC and no existing sim firmware image"
        results[freertos-build]=1
    fi
    for tb in $TBS; do do_sim "$tb"; results[$tb]=$?; done
    echo; echo "=== SCOREBOARD (Linux/Verilator) ==="
    all=0
    for k in images freertos-build $TBS; do
        if [ "${results[$k]}" -eq 0 ]; then s=PASS; else s=FAIL; all=1; fi
        printf "%-16s %s\n" "$k" "$s"
    done
    [ $all -eq 0 ] && echo "=== REGRESSION ALL GREEN ===" \
                   || echo "=== REGRESSION HAS FAILURES ==="
    return $all
}

# Bitstream + flash: the SAME .tcl scripts the Windows flow uses, driven by
# a Linux Vivado. (Board must be on USB for flashing; press PROG after.)
do_build() {
    viv=$(find_vivado) || { echo "ERROR: Vivado not found (set VIVADO=/path/to/vivado)"; return 1; }
    mkdir -p build/fpga
    echo "=== Bitstream (direct-XIP boot ROM, SRAM uninitialised) ==="
    "$viv" -mode batch -source build_fpga.tcl -nojournal -log build/fpga/build.log
}

do_flashfw() {
    viv=$(find_vivado) || { echo "ERROR: Vivado not found (set VIVADO=/path/to/vivado)"; return 1; }
    do_firmware hw || return 1
    do_build || return 1
    echo "=== Programming QSPI flash (bitstream + firmware @0x40_0000) ==="
    "$viv" -mode batch -source program_flash.tcl -nojournal \
        -log build/fpga/program_flash.log -tclargs sw/freertos/build/freertos_demo.bin \
        && echo "Done - press PROG on the board."
}

do_flashonly() {
    viv=$(find_vivado) || { echo "ERROR: Vivado not found (set VIVADO=/path/to/vivado)"; return 1; }
    fw="${1:-sw/freertos/prebuilt/freertos_demo.bin}"
    [ -f "$fw" ] || { echo "ERROR: firmware not found: $fw"; return 1; }
    [ -f build/fpga/top_artya7.bit ] || { echo "ERROR: no bitstream - run: $0 build"; return 1; }
    echo "=== Programming QSPI flash ($fw) ==="
    "$viv" -mode batch -source program_flash.tcl -nojournal \
        -log build/fpga/program_flash.log -tclargs "$fw" \
        && echo "Done - press PROG on the board."
}

do_menu() {
    echo "=============================================="
    echo "  minimal-ibex-soc - Linux flows"
    echo "=============================================="
    echo "  1) Environment check          (setup)"
    echo "  2) Install missing tools      (deps)"
    echo "  3) Build firmware             (firmware)"
    echo "  4) Full regression, Verilator (regression)"
    echo "  5) Lint RTL                   (lint)"
    echo "  6) Build bitstream, Vivado    (build)"
    echo "  7) Flash to board (QSPI)      (flashfw)"
    echo "  q) Quit"
    printf "Choice: "
    read -r c
    case "$c" in
        1) do_setup ;;  2) do_deps ;;      3) do_firmware hw ;;
        4) do_regression ;; 5) do_lint ;;  6) do_build ;;
        7) do_flashfw ;; *) exit 0 ;;
    esac
}

# ---- dispatch ---------------------------------------------------------------
case "${1:-__menu__}" in
    setup)      do_setup ;;
    deps)       do_deps ;;
    images)     do_images ;;
    firmware)   do_firmware "${2:-hw}" ;;
    lint)       do_lint ;;
    sim)        [ $# -ge 2 ] || { echo "usage: $0 sim <tb>"; exit 2; }
                do_images >/dev/null && do_sim "$2" ;;
    regression) do_regression ;;
    build)      do_build ;;
    flashfw)    do_flashfw ;;
    flashonly)  do_flashonly "${2:-}" ;;
    __menu__)   if [ -t 0 ]; then do_menu; else sed -n '2,25p' "$0" | sed 's/^# \{0,1\}//'; fi ;;
    help|*)     sed -n '2,25p' "$0" | sed 's/^# \{0,1\}//' ;;
esac
