#!/usr/bin/env bash
# =============================================================================
# ibex_soc.sh - the Linux twin of ibex_soc.bat: ONE entry point, same flows.
# Run with no arguments for an interactive menu, or name a flow directly:
#
#   ./ibex_soc.sh setup            # tool doctor (verilator/python/gcc/vivado)
#   ./ibex_soc.sh profile <p>      # sim | fpga | full | auto - which half of
#                                  # the flow this box is for, so the tool you
#                                  # do NOT use is never reported as missing
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
#
# Verilator >= 5 is mandatory (--timing/--binary). Where the distro package
# is older - Ubuntu 22.04 ships 4.210 and NO apt package fixes that - `deps`
# BUILDS Verilator from source into ~/ibex-tools/verilator, the same way the
# Windows GUI downloads its toolchain. Tools are found by VERSION, not PATH
# order, so a stale 4.x first on PATH cannot mask a good build; every flow
# also offers to take a path and remembers it in .toolpaths.sh.
#
# Tool paths persist in .toolpaths.sh (gitignored), the twin of .toolpaths.
# Logs: build/verilator/<tb>/, build/fpga/.  Exit code 0 = green.
# =============================================================================
set -u
# A CDPATH in the user shell silently redirects every bare `cd` below
# (including `cd sw/freertos`), so kill it before anything else.
unset CDPATH
# BASH_SOURCE, not $0: if this file is ever *sourced*, $0 is the caller and
# we would cd into the caller's directory instead of the repo.
cd "$(dirname "${BASH_SOURCE[0]:-$0}")"

# Per-PC tool locations written by `deps` (RISCV_GCC_HOME, VIVADO, ...)
[ -f .toolpaths.sh ] && . ./.toolpaths.sh

# On MSYS2, fall back to the Windows GUI's .toolpaths for the RISC-V GCC
# (translate C:\ -> /c/; skip wsl:-hosted toolchains - unreachable from MSYS)
if [ -z "${RISCV_GCC_HOME:-}" ] && [ -f .toolpaths ]; then
    case "$(uname -o 2>/dev/null)" in
        Msys|Cygwin)
            _wingcc=$(sed -n 's/^RISCV_GCC_HOME=//p' .toolpaths | tr -d '\r')
            case "$_wingcc" in
                wsl:*|"") ;;
                *) if command -v cygpath >/dev/null 2>&1; then
                       RISCV_GCC_HOME=$(cygpath -u "$_wingcc")
                       RISCV_PREFIX=$(sed -n 's/^RISCV_PREFIX=//p' .toolpaths | tr -d '\r')
                       export RISCV_GCC_HOME RISCV_PREFIX
                   fi ;;
            esac ;;
    esac
fi

# A previously-installed xPack toolchain lives in ~/ibex-tools even when a
# FRESH CLONE has no .toolpaths.sh yet. Find it rather than telling the user
# to re-download 400+ MB (same principle as find_verilator: resolve what is
# already on the machine). Last glob match wins = newest version.
if [ -z "${RISCV_GCC_HOME:-}" ]; then
    for _g in "${IBEX_TOOLS_DIR:-$HOME/ibex-tools}"/xpack-riscv-none-elf-gcc-*/bin/riscv-none-elf-gcc; do
        if [ -x "$_g" ]; then
            RISCV_GCC_HOME="${_g%/bin/*}"
            RISCV_PREFIX="riscv-none-elf-"
            export RISCV_GCC_HOME RISCV_PREFIX
        fi
    done
fi

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

# The program image each bench loads. A MISSING one is not a clean error:
# the flash/SRAM model returns all-ones, the CPU fetches 0xFFFFFFFF and the
# run turns into an "Illegal instruction at PC 0x20400000" spew minutes
# later (reported from the field 2026-08-20). Check before verilating.
image_of() {
    case "$1" in
        tb_freertos) echo "sw/freertos/build/freertos_demo_sim_flash.vmem" ;;
        *)           echo "" ;;
    esac
}

PYTHON="${PYTHON:-python3}"
command -v "$PYTHON" >/dev/null 2>&1 || PYTHON=python
JOBS="$(nproc 2>/dev/null || echo 4)"
# set to 1 by regression once a firmware build has failed, so the per-TB
# auto-build does not repeat the same wall of errors for every testbench.
NO_AUTOBUILD=0

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

# Verilator >= 5 is mandatory: every testbench here relies on --timing /
# --binary, which do not exist before 5.0. Distro packages are routinely
# too old (Ubuntu 22.04 ships 4.210), and an old one sitting first on PATH
# would otherwise mask a good build elsewhere - so resolve by VERSION, not
# by PATH order, across the usual install roots.
vlt_is5() {
    v=$( "$1" --version 2>/dev/null | awk '{print $2}' )
    maj=${v%%.*}
    [ "${maj:-0}" -ge 5 ]
}

find_verilator() {
    if [ -n "${VERILATOR:-}" ] && [ -x "$VERILATOR" ] && vlt_is5 "$VERILATOR"; then
        echo "$VERILATOR"; return 0
    fi

    # EVERY PATH entry, not just the first hit: `export PATH=~/verilator/bin`
    # in front of a distro 4.x (or the reverse) must not decide the outcome.
    old_ifs=$IFS; IFS=:
    for d in $PATH; do
        [ -n "$d" ] || continue
        if [ -x "$d/verilator" ] && vlt_is5 "$d/verilator"; then
            IFS=$old_ifs; echo "$d/verilator"; return 0
        fi
    done
    IFS=$old_ifs

    for c in "${IBEX_TOOLS_DIR:-$HOME/ibex-tools}/verilator/bin/verilator" \
             "$HOME/verilator/bin/verilator" \
             /opt/verilator/bin/verilator \
             /usr/local/bin/verilator /usr/bin/verilator; do
        if [ -x "$c" ] && vlt_is5 "$c"; then echo "$c"; return 0; fi
    done
    return 1
}

VERILATOR="$( find_verilator || echo "${VERILATOR:-verilator}" )"

vlt_version_ok() { have "$VERILATOR" && vlt_is5 "$VERILATOR"; }

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

# ---- tool profile: which HALF of the flow this machine is for ---------------
#   sim  - Verilator only  (simulation + lint; Vivado never needed)
#   fpga - Vivado only     (bitstream + flash; Verilator never needed)
#   full - both
#   auto - infer from what is installed (the default)
# A missing tool that the profile does not want is reported [SKIP], never
# [FAIL], and is never prompted for - so a Verilator-only box is "all green"
# without Vivado, and an FPGA-only box is all green without Verilator.
# Pin it with `./ibex_soc.sh profile sim` (remembered in .toolpaths.sh).
IBEX_PROFILE="${IBEX_PROFILE:-auto}"

effective_profile() {
    case "$IBEX_PROFILE" in
        sim|fpga|full) echo "$IBEX_PROFILE"; return ;;
    esac
    _v=0; _x=0
    vlt_version_ok && _v=1
    find_vivado >/dev/null 2>&1 && _x=1
    if   [ "$_v" = 1 ] && [ "$_x" = 0 ]; then echo sim
    elif [ "$_v" = 0 ] && [ "$_x" = 1 ]; then echo fpga
    else echo full; fi
}

wants_sim()  { [ "$( effective_profile )" != "fpga" ]; }
wants_fpga() { [ "$( effective_profile )" != "sim" ]; }

# Remember a per-PC tool location, the POSIX twin of the Windows GUI's
# .toolpaths: append + re-source so THIS process sees it immediately.
save_toolpath() {
    echo "export $1=\"$2\"" >> .toolpaths.sh
    # shellcheck disable=SC1091
    . ./.toolpaths.sh
    echo "  saved: $1=$2 (.toolpaths.sh, per-PC, gitignored)"
}

interactive() { [ -t 0 ]; }        # never block a CI / piped run on a prompt

# Accept a user-supplied Verilator location: the binary, its bin/, or the
# install prefix. Verifies the version before remembering it.
set_verilator() {
    a="${1%/}"
    [ -n "$a" ] || return 1
    for cand in "$a" "$a/verilator" "$a/bin/verilator"; do
        if [ -x "$cand" ] && vlt_is5 "$cand"; then
            VERILATOR="$cand"; export VERILATOR
            save_toolpath VERILATOR "$cand"
            return 0
        fi
    done
    echo "  not a Verilator >= 5: $a"
    return 1
}

ask_verilator() {
    interactive || return 1
    printf "  Path to a Verilator >= 5 (binary, bin/ or prefix; blank to skip): "
    read -r a || return 1
    [ -n "$a" ] || return 1
    set_verilator "$a"
}

# Ask for a bare-metal RISC-V GCC toolchain ROOT (the dir holding bin/*-gcc).
ask_riscv_gcc() {
    interactive || return 1
    printf "  RISC-V GCC toolchain root (contains bin/riscv*-gcc; blank to skip): "
    read -r a || return 1
    [ -n "$a" ] || return 1
    a="${a%/}"
    for p in riscv32-unknown-elf- riscv64-zephyr-elf- riscv64-unknown-elf- riscv-none-elf-; do
        if [ -x "$a/bin/${p}gcc" ]; then
            RISCV_GCC_HOME="$a"; RISCV_PREFIX="$p"
            export RISCV_GCC_HOME RISCV_PREFIX
            save_toolpath RISCV_GCC_HOME "$a"
            save_toolpath RISCV_PREFIX "$p"
            return 0
        fi
    done
    echo "  no bin/riscv*-gcc under: $a"
    return 1
}

# Ask for Vivado (the binary or an install root).
ask_vivado() {
    interactive || return 1
    printf "  Vivado path (bin/vivado or install root; blank to skip): "
    read -r a || return 1
    [ -n "$a" ] || return 1
    a="${a%/}"
    for cand in "$a" "$a/bin/vivado" "$a/Vivado/bin/vivado"; do
        if [ -x "$cand" ]; then
            VIVADO="$cand"; export VIVADO
            save_toolpath VIVADO "$cand"
            return 0
        fi
    done
    echo "  no vivado executable under: $a"
    return 1
}

# Build Verilator 5 from source into ~/ibex-tools/verilator. This is the
# Linux equivalent of the Windows GUI's automatic toolchain download: on
# Ubuntu 22.04 and friends the packaged Verilator is 4.x and NO package
# manager can supply 5.x, so "install the dependency" means building it.
# ~5-10 min on a modern box.
install_verilator_src() {
    dest="${IBEX_TOOLS_DIR:-$HOME/ibex-tools}/verilator"
    src="${dest}-src"
    SUDO=""; [ "$(id -u)" != 0 ] && have sudo && SUDO=sudo

    echo "Installing Verilator build prerequisites..."
    if have apt-get; then
        $SUDO apt-get install -y git help2man perl python3 make autoconf g++ \
            flex bison ccache libfl2 libfl-dev zlib1g-dev || true
    elif have dnf; then
        $SUDO dnf install -y git help2man perl python3 make autoconf gcc-c++ \
            flex bison ccache zlib-devel || true
    elif have pacman; then
        pacman -S --noconfirm --needed git autoconf flex bison || true
    fi

    have git || { echo "ERROR: git is required to build Verilator"; return 1; }

    tag=$( curl -sL https://api.github.com/repos/verilator/verilator/releases/latest \
           | grep -m1 '"tag_name"' | sed 's/.*"\(v[^"]*\)".*/\1/' )
    [ -n "$tag" ] || tag=v5.026      # offline fallback: a known-good release

    echo "Building Verilator $tag from source (5-10 min, $JOBS jobs)..."
    rm -rf "$src"
    git clone --depth 1 --branch "$tag" \
        https://github.com/verilator/verilator "$src" || return 1
    ( cd "$src" && autoconf && ./configure --prefix="$dest" \
      && make -j"$JOBS" && make install ) || return 1

    [ -x "$dest/bin/verilator" ] || { echo "ERROR: Verilator build failed"; return 1; }

    rm -rf "$src"
    VERILATOR="$dest/bin/verilator"; export VERILATOR
    save_toolpath VERILATOR "$VERILATOR"
    echo "Verilator $tag installed -> $VERILATOR"
}

# ---- flows ------------------------------------------------------------------
# NOTE: build.sh is invoked as `bash build.sh`, never `./build.sh`. A clone
# whose executable bits were lost (scripts authored on Windows, a zip
# export, a copy across a filesystem without permissions) would otherwise
# fail the toolchain probe with "Permission denied" - which 2>/dev/null
# hides - and the flow would report "RISC-V GCC not found" immediately
# after successfully saving a perfectly good path, then ask again on every
# run. Reported from the field 2026-08-20; gotcha 34c.
do_setup() {
    echo "=== Environment check (Linux flow) ==="
    ok=0
    # Checkout integrity FIRST: a half-copied tree fails later in ways that
    # read as tool problems (gcc "No such file or directory", missing TBs).
    # MSYS2 often has no git of its own even when Windows does - look there
    # too, so the Windows/Verilator host is covered as well.
    GIT="$( command -v git 2>/dev/null )"
    if [ -z "$GIT" ]; then
        for g in "/c/Program Files/Git/cmd/git.exe" "/c/Program Files/Git/bin/git.exe"; do
            [ -x "$g" ] && { GIT="$g"; break; }
        done
    fi
    if [ -n "$GIT" ] && "$GIT" rev-parse --git-dir >/dev/null 2>&1; then
        gone=$( "$GIT" ls-files --deleted 2>/dev/null )
        n=$( printf '%s' "$gone" | grep -c . || true )
        if [ "${n:-0}" -gt 0 ]; then
            echo "[FAIL] checkout incomplete: $n tracked file(s) missing from the tree"
            printf '%s\n' "$gone" | head -6 | sed 's/^/         /'
            [ "$n" -gt 6 ] && echo "         ... and $((n - 6)) more"
            echo "       restore with:  git checkout -- .   (discards local deletions)"
            ok=1
        else
            echo "[ OK ] checkout complete ($("$GIT" ls-files | wc -l) tracked files)"
        fi
    fi
    if vlt_version_ok; then
        echo "[ OK ] verilator: $("$VERILATOR" --version)"
    elif ! wants_sim; then
        echo "[SKIP] verilator - not needed for profile 'fpga' (bitstream/flash only)"
    else
        vfound=$( command -v verilator 2>/dev/null )
        if [ -n "$vfound" ]; then
            echo "[FAIL] verilator too old: $("$vfound" --version 2>&1) at $vfound"
            echo "       need >= 5 for --timing/--binary (no distro ships it on"
            echo "       Ubuntu 22.04 - it must be built, or point me at one)."
        else
            echo "[FAIL] verilator >= 5 not found (need --timing/--binary)."
        fi
        if ask_verilator; then
            echo "[ OK ] verilator: $("$VERILATOR" --version)"
        else
            echo "       Fix it with: $0 deps   (builds Verilator 5 from source)"
            ok=1
        fi
    fi
    if have "$PYTHON"; then echo "[ OK ] python: $("$PYTHON" --version 2>&1)"
    else echo "[FAIL] python3 not found. Run: $0 deps"; ok=1; fi
    if have make && have g++; then echo "[ OK ] make + g++"
    else echo "[FAIL] make/g++ missing. Run: $0 deps"; ok=1; fi
    if bash sw/freertos/build.sh --check-toolchain 2>/dev/null; then
        echo "[ OK ] RISC-V GCC (firmware builds enabled)"
    else
        echo "[WARN] RISC-V GCC not found - firmware cannot be rebuilt (sims can"
        echo "       reuse an existing sw/freertos/build image)."
        if ask_riscv_gcc && bash sw/freertos/build.sh --check-toolchain 2>/dev/null; then
            echo "[ OK ] RISC-V GCC (firmware builds enabled)"
        else
            echo "       Fix it with: $0 deps   (downloads the xPack toolchain)"
        fi
    fi
    if v=$(find_vivado); then echo "[ OK ] vivado: $v (bitstream/flash flows enabled)"
    elif ! wants_fpga; then
        echo "[SKIP] vivado - not needed for profile 'sim' (simulation/lint only)"
    else
        echo "[INFO] Vivado not found - sim flows unaffected; build/flashfw need it"
        if ask_vivado; then echo "[ OK ] vivado: $VIVADO"; fi
    fi
    # pip install --user lands in ~/.local/bin, which login shells may not have
    # on PATH yet - look there too
    fs=""
    if have fusesoc; then fs=$(command -v fusesoc)
    elif [ -x "$HOME/.local/bin/fusesoc" ]; then fs="$HOME/.local/bin/fusesoc"; fi
    if [ -n "$fs" ]; then
        fsv=$( "$fs" --version 2>&1 | tr -d '\r' )
        case "${fsv%%.*}" in
            0|1) echo "[WARN] fusesoc $fsv at $fs is ancient (need >= 2 for CAPI2)."
                 echo "       pip install --user --upgrade fusesoc   (optional - the"
                 echo "       native flows above do not use it)" ;;
            *)   echo "[ OK ] fusesoc: $fsv ($fs)" ;;
        esac
    else
        echo "[INFO] fusesoc not installed (optional): pip install fusesoc"
    fi
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
    # pick the new paths up in THIS process too (deps runs setup right after)
    . ./.toolpaths.sh
    echo "RISC-V GCC installed -> $root (recorded in .toolpaths.sh)"
}

do_deps() {
    echo "=== Installing dependencies ==="
    SUDO=""; [ "$(id -u)" != 0 ] && have sudo && SUDO=sudo
    # Do not (re)install the distro Verilator when a good 5.x is already
    # here: on Ubuntu 22.04 that prints "verilator is already the newest
    # version (4.038)" right above a working 5.x and reads as a downgrade.
    # Empty = the package is simply omitted from the install list.
    VLTPKG=verilator
    vlt_version_ok && VLTPKG=""
    have pacman && [ -n "$VLTPKG" ] && VLTPKG=mingw-w64-ucrt-x86_64-verilator
    # shellcheck disable=SC2086  ($VLTPKG is deliberately unquoted: it may be empty)
    if have apt-get; then                       # Ubuntu / Debian
        # NOT gcc-riscv64-unknown-elf: that package ships without any libc
        # (no stdlib.h) and cannot build the firmware - xPack fallback below.
        $SUDO apt-get update
        $SUDO apt-get install -y $VLTPKG make g++ python3 python3-pip curl || true
    elif have dnf; then                         # RHEL / Fedora / Rocky
        $SUDO dnf install -y $VLTPKG make gcc-c++ python3 python3-pip curl || true
        echo "(RHEL has no packaged bare-metal RISC-V GCC - xPack fallback below)"
    elif have pacman; then                      # MSYS2 (dev convenience)
        pacman -S --noconfirm --needed make mingw-w64-ucrt-x86_64-gcc \
            $VLTPKG mingw-w64-ucrt-x86_64-python \
            mingw-w64-ucrt-x86_64-python-pip || true
    else
        echo "ERROR: no supported package manager (apt/dnf/pacman)."; return 1
    fi
    # Re-resolve: the package manager may have just supplied a good one.
    VERILATOR="$( find_verilator || echo "${VERILATOR:-verilator}" )"

    if ! vlt_version_ok; then
        echo
        echo "The packaged Verilator is older than 5 (Ubuntu 22.04 ships 4.210)"
        echo "and no package manager can supply 5.x - it has to be built."
        if interactive; then
            printf "Build Verilator from source now? [Y/n/path] "
            read -r a
            case "$a" in
                [Nn]*)   echo "  skipped - sims will not run until this is fixed" ;;
                /*|~*|.*) set_verilator "$a" || install_verilator_src ;;
                *)       install_verilator_src ;;
            esac
        else
            install_verilator_src           # unattended (CI): just do it
        fi
    fi
    if ! bash sw/freertos/build.sh --check-toolchain >/dev/null 2>&1; then
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

do_profile() {
    case "${1:-}" in
        sim|fpga|full|auto)
            [ -f .toolpaths.sh ] && sed -i '/^export IBEX_PROFILE=/d' .toolpaths.sh
            save_toolpath IBEX_PROFILE "$1"
            IBEX_PROFILE="$1"
            echo "profile: $IBEX_PROFILE (effective: $( effective_profile ))"
            ;;
        ""|show)
            echo "profile: $IBEX_PROFILE (effective: $( effective_profile ))"
            echo "  sim  - Verilator only; Vivado never reported as missing"
            echo "  fpga - Vivado only; Verilator never reported as missing"
            echo "  full - both"
            echo "  auto - infer from what is installed (default)"
            echo "set with: $0 profile <sim|fpga|full|auto>"
            ;;
        *) echo "usage: $0 profile <sim|fpga|full|auto>"; return 2 ;;
    esac
}

# Every sim flow needs Verilator 5 - say so once, clearly, instead of
# letting the user decode "Unsupported: --timing" from a build log.
require_verilator() {
    vlt_version_ok && return 0
    echo "ERROR: Verilator >= 5 is required (--timing/--binary)."
    if v=$( command -v verilator 2>/dev/null ); then
        echo "       found: $("$v" --version 2>&1) at $v"
    fi
    echo "       Run '$0 deps' to build it, or '$0 setup' to point at one."
    return 1
}

do_images() {
    if ! have "$PYTHON"; then
        echo "ERROR: python3 not found - it generates every program image."
        echo "       Run '$0 deps'."
        return 1
    fi
    echo "=== Program images ==="
    for g in assemble.py "assemble.py --sim" "lcd_spi_test.py --sim" i2c_test.py \
             xip_test.py periph_tests.py uart2_irq_test.py; do
        # shellcheck disable=SC2086
        (cd sw/asm-demo && $PYTHON $g) || return 1
    done
}

do_firmware() {
    echo "=== FreeRTOS firmware (${1:-hw}) ==="
    (cd sw/freertos && bash ./build.sh "${1:-hw}")
}

do_lint() {
    require_verilator || return 1
    echo "=== verilator --lint-only (ibex_demo_system) ==="
    # shellcheck disable=SC2086
    "$VERILATOR" --lint-only --timing -Wno-fatal --top-module ibex_demo_system \
        -f dv/xsim/filelist.f $VLT_EXTRA $INCDIRS
}

do_sim() {
    tb="$1"
    [ "$(pass_of "$tb")" = "__NO_SUCH_TB__" ] && { echo "unknown tb '$tb' (one of: $TBS)"; return 2; }
    require_verilator || return 1

    img=$( image_of "$tb" )
    if [ -n "$img" ] && [ ! -f "$img" ]; then
        echo "$tb needs $img (not present)."
        if [ "${NO_AUTOBUILD:-0}" = 1 ]; then
            echo "  skipped: the firmware build above already failed - fix that first"
            return 1
        elif bash sw/freertos/build.sh --check-toolchain >/dev/null 2>&1; then
            echo "  building it: $0 firmware sim"
            do_firmware sim || return 1
        else
            echo "ERROR: no RISC-V GCC, so the image cannot be built."
            echo "       Run '$0 deps' (installs the xPack toolchain), or"
            echo "       '$0 setup' to point at an existing one."
            return 1
        fi
    fi

    # tb_soc_dffram = tb_soc with the DFFRAM storage array (parameter, -G)
    src="dv/xsim/$tb.sv"; top="$tb"; gparam=""
    if [ "$tb" = "tb_soc_dffram" ]; then
        src="dv/xsim/tb_soc.sv"; top="tb_soc"; gparam="-GUseDffram=1"
    fi
    mkdir -p "build/verilator/$tb"
    echo "--- verilate $tb ---"
    # shellcheck disable=SC2086
    # (no --quiet-stats: only added in Verilator 5.022; Ubuntu 24.04 ships 5.020
    #  and the output goes to build.log anyway)
    "$VERILATOR" --binary --timing -j "$JOBS" -Wno-fatal \
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
    require_verilator || return 1
    declare -A results
    do_images; results[images]=$?
    if bash sw/freertos/build.sh --check-toolchain >/dev/null 2>&1; then
        do_firmware sim; results[freertos-build]=$?
        [ "${results[freertos-build]}" -eq 0 ] || NO_AUTOBUILD=1
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
    echo "  8) Tool profile (sim/fpga/full)  (profile)"
    echo "  q) Quit"
    printf "Choice: "
    read -r c
    case "$c" in
        1) do_setup ;;  2) do_deps ;;      3) do_firmware hw ;;
        4) do_regression ;; 5) do_lint ;;  6) do_build ;;
        7) do_flashfw ;;
        8) printf "  profile [sim|fpga|full|auto]: "; read -r pf; do_profile "$pf" ;;
        *) exit 0 ;;
    esac
}

# ---- dispatch ---------------------------------------------------------------
case "${1:-__menu__}" in
    setup)      do_setup ;;
    profile)    do_profile "${2:-}" ;;
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
