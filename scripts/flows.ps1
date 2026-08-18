# =============================================================================
# flows.ps1 - ALL user flows in one dispatcher (Windows PowerShell 5.1+).
#
# The ONLY user entry point is ibex_soc.bat (the GUI); every GUI button opens
# a console window running:  powershell -File scripts\flows.ps1 <flow> [arg]
# Flows can also be run from a terminal directly with the same command.
#
#   setup                 environment doctor + locate/save tool paths
#   xpr                   generate the Vivado GUI project (.xpr) for browsing
#   build                 synthesise the bitstream (build_fpga.tcl)
#   program               program the board over USB-JTAG (volatile, dev-only)
#   firmware [sim|toy]    build the FreeRTOS firmware variant
#   flashfw  [toy]        THE flow: firmware (prebuilt fallback if no GCC)
#                         -> XIP bitstream -> QSPI flash. Survives power-cycle.
#   flashonly [file.bin]  reflash firmware+bitstream only (default FreeRTOS bin)
#   regression            full suite: images + firmware + compile + 10 sims +
#                         bitstream + scoreboard (~45-60 min)
#
# Tool locating (same order + .toolpaths file as scripts/find_tools.cmd):
# saved answers -> env vars -> PATH -> common install roots on every existing
# drive -> WSL (GCC only) -> ask-and-save. GCC accepts several bin prefixes
# (lowRISC riscv32-unknown-elf-, Zephyr riscv64-zephyr-elf-, ...); a
# WSL-hosted toolchain is stored as RISCV_GCC_HOME=wsl:<linux path>.
# .toolpaths is per-PC and gitignored.
# =============================================================================
param(
    [Parameter(Mandatory = $true)][string]$Flow,
    [string]$Arg = ""
)
$ErrorActionPreference = "Continue"
$repo = Split-Path -Parent $PSScriptRoot
Set-Location $repo
$cfg = Join-Path $repo ".toolpaths"

# ---- .toolpaths load/save ---------------------------------------------------
function Get-SavedPaths {
    $h = @{}
    if (Test-Path $cfg) {
        foreach ($line in Get-Content $cfg) {
            $i = $line.IndexOf("=")
            if ($i -gt 0) { $h[$line.Substring(0, $i)] = $line.Substring($i + 1) }
        }
    }
    return $h
}

function Save-Paths([hashtable]$h) {
    $out = @()
    foreach ($k in $h.Keys) { if ($h[$k]) { $out += "$k=$($h[$k])" } }
    if ($out.Count -gt 0) { $out | Out-File $cfg -Encoding ascii }
}

function Ask-Path([string]$prompt) {
    # Interactive ask; swallow the error when stdin is not a console.
    try { return (Read-Host $prompt) } catch { return "" }
}

# ---- Vivado -----------------------------------------------------------------
function Find-Vivado([bool]$ask) {
    $saved = Get-SavedPaths
    $v = $saved["VIVADO_BAT"]
    if ($v -and (Test-Path $v)) { return $v }

    if ($env:XILINX_VIVADO -and (Test-Path "$env:XILINX_VIVADO\bin\vivado.bat")) {
        $v = "$env:XILINX_VIVADO\bin\vivado.bat"
    }
    if (-not $v) {
        $w = Get-Command vivado.bat -ErrorAction SilentlyContinue
        if ($w) { $v = $w.Source }
    }
    if (-not $v) {
        # Only drives that actually exist: on PS 5.1, Get-ChildItem -Directory
        # against a nonexistent drive is a parameter-BINDING error that
        # -ErrorAction cannot suppress (docs/WALKTHROUGH.md gotcha 21).
        foreach ($drive in (Get-PSDrive -PSProvider FileSystem | Where-Object { $null -ne $_.Free })) {
            $r = $drive.Root
            foreach ($pat in @("${r}Xilinx\Vivado\*", "${r}AMD\Vivado\*")) {
                foreach ($dir in (Get-ChildItem $pat -Directory -ErrorAction SilentlyContinue)) {
                    if (Test-Path "$($dir.FullName)\bin\vivado.bat") { $v = "$($dir.FullName)\bin\vivado.bat" }
                }
            }
            foreach ($pat in @("${r}AMD\*", "${r}Xilinx\*", "${r}AMDDesignTools\*")) {
                foreach ($dir in (Get-ChildItem $pat -Directory -ErrorAction SilentlyContinue)) {
                    if (Test-Path "$($dir.FullName)\Vivado\bin\vivado.bat") { $v = "$($dir.FullName)\Vivado\bin\vivado.bat" }
                }
            }
            if ($v) { break }
        }
    }
    if ((-not $v) -and $ask) {
        Write-Host ""
        Write-Host "Vivado was not found automatically (PATH; \Xilinx\, \AMD\, \AMDDesignTools\ on all drives)."
        $in = Ask-Path "Enter your Vivado install dir (e.g. D:\AMD\2026.1\Vivado), blank to abort"
        if ($in -and (Test-Path "$in\bin\vivado.bat")) { $v = "$in\bin\vivado.bat" }
        elseif ($in) { Write-Host "ERROR: $in\bin\vivado.bat does not exist." }
    }
    if ($v) { $saved["VIVADO_BAT"] = $v; Save-Paths $saved }
    return $v
}

# ---- RISC-V GCC -------------------------------------------------------------
# Any bare-metal RISC-V GCC works; known bin prefixes, first match wins:
#   riscv32-unknown-elf-  lowRISC toolchain (the ARF standard; the tar.xz is
#                         Linux-only, so on Windows it is found INSIDE WSL and
#                         stored as RISCV_GCC_HOME=wsl:<linux path>)
#   riscv64-zephyr-elf-   Zephyr SDK (native Windows)
#   riscv64-unknown-elf- / riscv-none-elf-  other common bare-metal builds
$GccPrefixes = @("riscv32-unknown-elf-", "riscv64-zephyr-elf-",
                 "riscv64-unknown-elf-", "riscv-none-elf-")

function Get-GccPrefix([string]$root) {
    # The bin prefix present under $root ('' means none). Handles wsl: roots.
    if (-not $root) { return $null }
    if ($root -like "wsl:*") {
        $lin = $root.Substring(4)
        $probe = 'for p in riscv32-unknown-elf- riscv64-zephyr-elf- riscv64-unknown-elf- riscv-none-elf-; do if [ -x "{0}/bin/${{p}}gcc" ]; then echo "$p"; exit 0; fi; done' -f $lin
        $out = "$(& wsl -e sh -c $probe 2>$null | Select-Object -First 1)".Trim()
        if ($GccPrefixes -contains $out) { return $out }
        return $null
    }
    foreach ($p in $GccPrefixes) {
        if (Test-Path "$root\bin\${p}gcc.exe") { return $p }
    }
    return $null
}

function Find-WslGcc {
    # The lowRISC toolchain ships Linux binaries only - look inside WSL.
    if (-not (Get-Command wsl.exe -ErrorAction SilentlyContinue)) { return $null }
    $probe = 'for d in /opt/lowrisc-toolchain* /opt/riscv* /tools/riscv /tools/lowrisc-toolchain* $HOME/lowrisc-toolchain*; do if [ -x "$d/bin/riscv32-unknown-elf-gcc" ]; then echo "$d"; exit 0; fi; done; g=$(command -v riscv32-unknown-elf-gcc 2>/dev/null) && dirname "$(dirname "$g")"'
    $out = "$(& wsl -e sh -c $probe 2>$null | Select-Object -First 1)".Trim()
    if ($out.StartsWith("/")) { return "wsl:$out" }
    return $null
}

function Find-Gcc([bool]$ask) {
    $saved = Get-SavedPaths
    $g = $saved["RISCV_GCC_HOME"]
    $p = Get-GccPrefix $g

    if (-not $p) { $g = $env:RISCV_GCC_HOME; $p = Get-GccPrefix $g }
    if (-not $p) {
        foreach ($pre in $GccPrefixes) {
            $w = Get-Command "${pre}gcc.exe" -ErrorAction SilentlyContinue
            if ($w) { $g = Split-Path -Parent (Split-Path -Parent $w.Source); $p = $pre; break }
        }
    }
    if (-not $p) {
        # Install roots - only on drives that exist (gotcha 21, as above)
        $roots = @()
        foreach ($drive in (Get-PSDrive -PSProvider FileSystem | Where-Object { $null -ne $_.Free })) {
            $r = $drive.Root
            $roots += "${r}FPGA\zephyr-sdk"
            foreach ($pat in @("${r}zephyr-sdk*", "${r}lowrisc-toolchain*", "${r}FPGA\lowrisc-toolchain*")) {
                $roots += (Get-ChildItem $pat -Directory -ErrorAction SilentlyContinue | ForEach-Object FullName)
            }
        }
        foreach ($pat in @("$env:USERPROFILE\zephyr-sdk*", "$env:USERPROFILE\lowrisc-toolchain*")) {
            $roots += (Get-ChildItem $pat -Directory -ErrorAction SilentlyContinue | ForEach-Object FullName)
        }
        foreach ($r in $roots) {
            if (-not $r) { continue }
            foreach ($cand in @($r, "$r\gnu\riscv64-zephyr-elf")) {
                $p = Get-GccPrefix $cand
                if ($p) { $g = $cand; break }
            }
            if ($p) { break }
        }
    }
    if (-not $p) { $g = Find-WslGcc; $p = Get-GccPrefix $g }
    if ((-not $p) -and $ask) {
        Write-Host ""
        Write-Host "RISC-V GCC was not found (native or inside WSL). Install per docs\FREERTOS_PORT.md,"
        $in = Ask-Path "or enter a toolchain root (contains bin\<prefix>gcc.exe), blank to skip"
        if ($in) {
            $p = Get-GccPrefix $in
            if ($p) { $g = $in }
            else { Write-Host "ERROR: no bin\<prefix>gcc.exe under $in (prefixes: $($GccPrefixes -join ' '))." }
        }
    }
    if (-not $p) { return $null }
    $saved["RISCV_GCC_HOME"] = $g
    $saved["RISCV_PREFIX"]   = $p
    Save-Paths $saved
    $script:GccPrefix = $p
    return $g
}

# Both helpers stream tool stdout to the console via Write-Host (NOT the
# pipeline) so callers can consume the integer return value without
# swallowing the output the user is watching.
function Invoke-Vivado([string]$tcl, [string]$log, [string[]]$tclArgs) {
    $v = Find-Vivado $true
    if (-not $v) { Write-Host "ERROR: Vivado not found - run the setup flow."; exit 1 }
    New-Item -ItemType Directory -Force (Split-Path $log) | Out-Null
    $a = @("-mode", "batch", "-source", $tcl, "-nojournal", "-log", $log)
    if ($tclArgs -and $tclArgs.Count -gt 0) { $a += "-tclargs"; $a += $tclArgs }
    & $v @a | ForEach-Object { Write-Host $_ }
    return $LASTEXITCODE
}

function Build-Firmware([string]$variant) {
    # build.bat locates GCC itself; seed home+prefix so it never asks here
    $g = Find-Gcc $false
    if ($g) {
        $env:RISCV_GCC_HOME = $g
        if ($script:GccPrefix) { $env:RISCV_PREFIX = $script:GccPrefix }
    }
    cmd /c "sw\freertos\build.bat $variant" | ForEach-Object { Write-Host $_ }
    return $LASTEXITCODE
}

# =============================================================================
switch ($Flow.ToLower()) {

    "setup" {
        Write-Host "============================================================"
        Write-Host " minimal-ibex-soc environment check"
        Write-Host "============================================================"
        $fail = $false

        $v = Find-Vivado $true
        if ($v) { Write-Host "[OK]   Vivado:      $v" }
        else {
            Write-Host "[FAIL] Vivado not found. Install Vivado ML Standard (free) with"
            Write-Host "       Artix-7 support + cable drivers (docs/WALKTHROUGH.md sec. 2)."
            $fail = $true
        }

        $py = Get-Command python -ErrorAction SilentlyContinue
        if ($py) { Write-Host "[OK]   Python:      $(& python --version 2>&1)" }
        else {
            Write-Host "[FAIL] python not on PATH. Install:  winget install Python.Python.3.12"
            $fail = $true
        }

        $g = Find-Gcc $false
        if ($g -and ($g -like "wsl:*")) {
            Write-Host "[OK]   RISC-V GCC:  $($g.Substring(4)) (inside WSL, $($script:GccPrefix)gcc)"
        } elseif ($g) {
            Write-Host "[OK]   RISC-V GCC:  $g\bin ($($script:GccPrefix)gcc)"
        } else {
            Write-Host "[WARN] RISC-V GCC not found (native or inside WSL). NOT a blocker for"
            Write-Host "       board testing - the flash flow falls back to the committed"
            Write-Host "       prebuilt firmware (sw\freertos\prebuilt). Needed only to CHANGE"
            Write-Host "       firmware: install per docs/FREERTOS_PORT.md section 2"
            Write-Host "       (lowRISC toolchain in WSL, or the Zephyr SDK natively)."
        }

        $git = Get-Command git -ErrorAction SilentlyContinue
        if ($git) { Write-Host "[OK]   Git:         $(& git --version)" }
        else { Write-Host "[WARN] git not on PATH - fine for building, needed for contributing." }

        if ($repo -match "OneDrive") {
            Write-Host "[FAIL] Repo is inside OneDrive: $repo - Vivado breaks on synced"
            Write-Host "       paths. Move to C:\FPGA\."
            $fail = $true
        } elseif ($repo -match " ") {
            Write-Host "[FAIL] Repo path contains spaces: $repo - move to C:\FPGA\minimal-ibex-soc."
            $fail = $true
        } else { Write-Host "[OK]   Repo path:   $repo" }

        $board = Get-PnpDevice -PresentOnly -ErrorAction SilentlyContinue |
                 Where-Object { $_.FriendlyName -match "Digilent|FT2232|USB Serial" }
        if ($board) { Write-Host "[OK]   Board:       Digilent/FTDI device detected" }
        else { Write-Host "[INFO] Board:       not detected (fine if not plugged in)" }

        Write-Host ""
        if ($fail) { Write-Host "RESULT: FIX THE [FAIL] ITEMS ABOVE, then re-run Environment Check." }
        else { Write-Host "RESULT: environment ready. Next: Flash to Board, or Full Regression." }
        Write-Host "============================================================"
    }

    "xpr" {
        # The .xpr is for BROWSING in the Vivado GUI (the team's request);
        # the official build stays the batch flow below.
        $rc = Invoke-Vivado "gen_project.tcl" "build\gen_project.log" @()
        if ($rc -eq 0) { Write-Host "`nPROJECT OK -> build\vivado_project\ (open the .xpr in Vivado)" }
    }

    "build" {
        Invoke-Vivado "build_fpga.tcl" "build\fpga\build.log" @() | Out-Null
    }

    "program" {
        Invoke-Vivado "program_fpga.tcl" "build\fpga\program.log" @() | Out-Null
    }

    "firmware" {
        Build-Firmware $Arg | Out-Null
    }

    "flashfw" {
        $fw = "freertos_demo"
        if ($Arg -eq "toy") { $fw = "freertos_demo_toy" }

        Write-Host "=== [1/3] Building FreeRTOS firmware ($fw) ==="
        $rc = Build-Firmware $Arg
        if ($rc -ne 0) {
            if (Test-Path "sw\freertos\prebuilt\$fw.bin") {
                Write-Host ""
                Write-Host "*** USING PREBUILT FIRMWARE ***"
                Write-Host "Local build failed - most likely no RISC-V GCC on this machine."
                Write-Host "Falling back to the committed sw\freertos\prebuilt\$fw.bin."
                Write-Host "Fine for board bring-up / IO tests. To CHANGE firmware, install"
                Write-Host "the toolchain: docs\FREERTOS_PORT.md section 2."
                Write-Host ""
                New-Item -ItemType Directory -Force "sw\freertos\build" | Out-Null
                Copy-Item "sw\freertos\prebuilt\$fw.bin" "sw\freertos\build\$fw.bin" -Force
            } else {
                Write-Host "FIRMWARE BUILD FAILED - and no prebuilt exists for $fw."
                Write-Host "(The toy variant always needs a local toolchain.)"
                exit 1
            }
        }

        Write-Host "=== [2/3] Building XIP-boot bitstream (SRAM = trampoline) ==="
        $rc = Invoke-Vivado "build_fpga.tcl" "build\fpga\build.log" @("sw/asm-demo/xip_stub.vmem")
        if ($rc -ne 0) { Write-Host "BITSTREAM BUILD FAILED - see build\fpga\build.log"; exit 1 }

        Write-Host "=== [3/3] Programming QSPI flash (bitstream + firmware @0x40_0000) ==="
        $rc = Invoke-Vivado "program_flash.tcl" "build\fpga\program_flash.log" @("sw/freertos/build/$fw.bin")
        if ($rc -ne 0) { Write-Host "FLASH PROGRAMMING FAILED - see build\fpga\program_flash.log"; exit 1 }

        Write-Host ""
        Write-Host "DONE. Press PROG (or power-cycle) on the board, then open the serial"
        Write-Host "terminal at 115200 8N1 - expect the FreeRTOS banner and tick lines."
    }

    "flashonly" {
        $bin = $Arg
        if (-not $bin) { $bin = "sw/freertos/build/freertos_demo.bin" }
        Invoke-Vivado "program_flash.tcl" "build\fpga\program_flash.log" @($bin) | Out-Null
    }

    "regression" {
        & "$PSScriptRoot\run_regression.ps1"
        if ($LASTEXITCODE -eq 0) { Write-Host "`nREGRESSION ALL GREEN" }
        else { Write-Host "`nREGRESSION HAS FAILURES - see build\regression.log" }
    }

    default {
        Write-Host "Unknown flow '$Flow'. Valid: setup xpr build program firmware flashfw flashonly regression"
        exit 1
    }
}
