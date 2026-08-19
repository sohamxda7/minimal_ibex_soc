# =============================================================================
# flows.ps1 - ALL user flows in one dispatcher (Windows PowerShell 5.1+).
#
# The ONLY user entry point is ibex_soc.bat (the GUI); every GUI button opens
# a console window running:  powershell -File scripts\flows.ps1 <flow> [arg]
# Flows can also be run from a terminal directly with the same command.
#
#   setup                 environment doctor + locate/save tool paths
#   deps [force]          INSTALL missing tools: Python (winget) + a native
#                         Windows RISC-V GCC (xPack riscv-none-elf-gcc,
#                         auto-download to C:\FPGA, no WSL, no admin).
#                         'force' reinstalls GCC even if one was found.
#   xpr                   generate the Vivado GUI project (.xpr) for browsing
#   build                 synthesise the bitstream (build_fpga.tcl)
#   program               program the board over USB-JTAG (volatile, dev-only)
#   firmware [sim]        build the FreeRTOS firmware (ONE hardware image:
#                         console + LEDs/RGB + LCD status screen; "toy" is
#                         an accepted alias of the default; sim = testbench)
#   flashfw               THE flow: BUILD firmware (no GCC? offers the
#                         automatic toolchain install; the committed prebuilt
#                         only on explicit choice) -> XIP bitstream -> QSPI
#                         flash. Survives power-cycle.
#   flashonly [file.bin]  reflash firmware+bitstream only (default FreeRTOS bin)
#   regression            full suite: images + firmware + compile + 11 sims +
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
            foreach ($pat in @("${r}zephyr-sdk*", "${r}lowrisc-toolchain*", "${r}FPGA\lowrisc-toolchain*",
                               "${r}xpack-riscv-none-elf-gcc*", "${r}FPGA\xpack-riscv-none-elf-gcc*")) {
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

# One-click installer for the pinned xPack RISC-V GCC (native Windows zip,
# official xpack-dev-tools releases - no WSL, no admin). Asks first (Enter =
# go), downloads to C:\FPGA, saves .toolpaths. Returns $true when a working
# toolchain is in place afterwards. Used by the deps flow AND by flashfw's
# build-first policy. Write-Host only (see note below).
function Install-XpackGcc {
    $ver     = "15.2.0-1"
    $zipName = "xpack-riscv-none-elf-gcc-$ver-win32-x64.zip"
    $url     = "https://github.com/xpack-dev-tools/riscv-none-elf-gcc-xpack/releases/download/v$ver/$zipName"
    $instDir = "C:\FPGA"
    $gccHome = "$instDir\xpack-riscv-none-elf-gcc-$ver"
    Write-Host ""
    Write-Host "About to install the xPack RISC-V GCC (native Windows - no WSL):"
    Write-Host "  what:  $zipName  (~470 MB download, ~1.7 GB on disk)"
    Write-Host "  from:  github.com/xpack-dev-tools  (official xPack releases)"
    Write-Host "  to:    $gccHome"
    $ans = Ask-Path "Press Enter to install, or type n to skip"
    if ($ans -match '^[nN]') {
        Write-Host "Skipped GCC install."
        return $false
    }
    $ok = Test-Path "$gccHome\bin\riscv-none-elf-gcc.exe"
    if ($ok) {
        Write-Host "[OK]   Already extracted at $gccHome - reusing."
    } else {
        if (((Get-PSDrive C).Free / 1GB) -lt 3) {
            Write-Host "[FAIL] Less than 3 GB free on C: - free some space first."
            return $false
        }
        New-Item -ItemType Directory -Force $instDir | Out-Null
        $zip = "$instDir\$zipName"
        [Net.ServicePointManager]::SecurityProtocol = `
            [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
        $oldPP = $ProgressPreference; $ProgressPreference = "SilentlyContinue"
        Write-Host "[....] Downloading (a few minutes; the window is NOT stuck)..."
        Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing
        Write-Host "[....] Extracting to $instDir (another couple of minutes)..."
        Expand-Archive -Path $zip -DestinationPath $instDir -Force
        $ProgressPreference = $oldPP
        Remove-Item $zip -Force
        $ok = Test-Path "$gccHome\bin\riscv-none-elf-gcc.exe"
    }
    if ($ok) {
        $saved = Get-SavedPaths
        $saved["RISCV_GCC_HOME"] = $gccHome
        $saved["RISCV_PREFIX"]   = "riscv-none-elf-"
        Save-Paths $saved
        $script:GccPrefix = "riscv-none-elf-"
        Write-Host "[OK]   RISC-V GCC installed: $(& "$gccHome\bin\riscv-none-elf-gcc.exe" --version | Select-Object -First 1)"
        Write-Host "       Saved to .toolpaths - every flow finds it from now on."
        return $true
    }
    Write-Host "[FAIL] Extraction did not produce $gccHome\bin\riscv-none-elf-gcc.exe"
    Write-Host "       (download interrupted?). Re-run to retry."
    return $false
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
            Write-Host "[WARN] RISC-V GCC not found (native or inside WSL). EASY FIX: click"
            Write-Host "       'Install Missing Tools' in the GUI (or: flows.ps1 deps) - it"
            Write-Host "       downloads a native Windows GCC automatically. The Flash to"
            Write-Host "       Board flow also offers this install itself; the committed"
            Write-Host "       prebuilt firmware (sw\freertos\prebuilt) is flashed only on"
            Write-Host "       your explicit choice. Docs: FREERTOS_PORT.md section 2."
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

    "deps" {
        # One-click installer for what a fresh PC is missing. GCC comes from
        # the official xPack releases: a native Windows zip, no WSL, no
        # admin rights, prefix riscv-none-elf- (already known to every
        # locator). 'force' (the optional arg) reinstalls GCC regardless.
        Write-Host "============================================================"
        Write-Host " minimal-ibex-soc dependency installer"
        Write-Host "============================================================"

        # ---- Python (runs the image/vmem generators) ------------------------
        if (Get-Command python -ErrorAction SilentlyContinue) {
            Write-Host "[OK]   Python already installed: $(& python --version 2>&1)"
        } elseif (Get-Command winget -ErrorAction SilentlyContinue) {
            Write-Host "[....] Installing Python via winget (no admin needed)..."
            winget install -e --id Python.Python.3.12 --accept-package-agreements --accept-source-agreements | ForEach-Object { Write-Host $_ }
            Write-Host "[NOTE] PATH updates land in NEW consoles - reopen this flow if"
            Write-Host "       python is still not found afterwards."
        } else {
            Write-Host "[FAIL] Python missing and winget unavailable on this Windows -"
            Write-Host "       install Python 3.x from python.org (tick 'Add to PATH')."
        }

        # ---- RISC-V GCC (compiles the FreeRTOS firmware) --------------------
        $g = Find-Gcc $false
        if ($g -and ($Arg -ne "force")) {
            Write-Host "[OK]   RISC-V GCC already present: $g ($($script:GccPrefix)gcc)"
        } else {
            Install-XpackGcc | Out-Null
        }

        # ---- Vivado (too big + licensed to auto-install) --------------------
        $v = Find-Vivado $false
        if ($v) { Write-Host "[OK]   Vivado already installed: $v" }
        else {
            Write-Host "[INFO] Vivado cannot be auto-installed (30+ GB, needs an AMD"
            Write-Host "       account). Install Vivado ML Standard once by hand -"
            Write-Host "       docs/WALKTHROUGH.md section 2 - then re-run Environment Check."
        }
        Write-Host ""
        Write-Host "Done. Run Environment Check - it should now be all green."
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
        # ONE hardware image since 2026-08-18 ("toy" arg is a harmless alias):
        # the LCD/sensor task ships in every build, so the variant-picker trap
        # (standard image flashed, wired LCD stays dark) cannot recur.
        $fw = "freertos_demo"

        Write-Host "=== [1/3] Building FreeRTOS firmware ($fw) ==="
        # BUILD-FIRST policy (Soham, 2026-08-18): flash what you build. The
        # committed prebuilt is used only on your explicit say-so; a failed
        # build with a working toolchain is a hard stop, never a fallback.
        $usePrebuilt = $false
        $g = Find-Gcc $false
        if (-not $g) {
            Write-Host ""
            Write-Host "No RISC-V GCC on this PC. The policy is to BUILD the firmware you"
            Write-Host "flash - the committed prebuilt is a fallback, not the normal path."
            Write-Host "  [Enter]  install the toolchain now (automatic, ~470 MB, no admin)"
            Write-Host "  [p]      flash the committed prebuilt just this once"
            Write-Host "  [n]      abort"
            $ans = Ask-Path "Choice"
            if ($ans -match '^[nN]') { exit 1 }
            elseif ($ans -match '^[pP]') { $usePrebuilt = $true }
            else {
                if (-not (Install-XpackGcc)) { Write-Host "ABORTED - no toolchain."; exit 1 }
                $g = Find-Gcc $false
                if (-not $g) { Write-Host "ERROR: toolchain installed but not detected - run Environment Check."; exit 1 }
            }
        }

        if ($usePrebuilt) {
            if (-not (Test-Path "sw\freertos\prebuilt\$fw.bin")) {
                Write-Host "No prebuilt exists for $fw."
                exit 1
            }
            Write-Host ""
            Write-Host "*** USING PREBUILT FIRMWARE (your explicit choice) ***"
            Write-Host "Fine for board bring-up / IO tests. To flash your own changes,"
            Write-Host "install the toolchain (GUI: Install Missing Tools)."
            Write-Host ""
            New-Item -ItemType Directory -Force "sw\freertos\build" | Out-Null
            Copy-Item "sw\freertos\prebuilt\$fw.bin" "sw\freertos\build\$fw.bin" -Force
        } else {
            $rc = Build-Firmware $Arg
            if ($rc -ne 0) {
                Write-Host "FIRMWARE BUILD FAILED - fix the compiler error above."
                Write-Host "(No silent prebuilt fallback: you should flash what you build."
                Write-Host "To flash the known-good prebuilt explicitly instead:"
                Write-Host "  powershell -File scripts\flows.ps1 flashonly sw\freertos\prebuilt\$fw.bin )"
                exit 1
            }
        }

        Write-Host "=== [2/3] Building XIP-boot bitstream (direct-XIP boot ROM, SRAM uninitialised) ==="
        $rc = Invoke-Vivado "build_fpga.tcl" "build\fpga\build.log" @()
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
        Write-Host "Unknown flow '$Flow'. Valid: setup deps xpr build program firmware flashfw flashonly regression"
        exit 1
    }
}
