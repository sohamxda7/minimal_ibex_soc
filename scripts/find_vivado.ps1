# ===========================================================================
# Shared Vivado locator for the PowerShell runners. Dot-source it:
#     . "$PSScriptRoot\find_vivado.ps1"
#     $viv = Find-VivadoBin        # e.g. C:\AMD\2026.1\Vivado\bin, or throws
#
# Same search order as scripts\find_tools.cmd (keep the two in sync):
#   .toolpaths (saved answers) -> env vars -> PATH -> drive scan.
# NO interactive prompt here - these runners are often launched detached.
# If nothing is found, run setup_check.bat once: it asks and saves the path.
# ===========================================================================
function Find-VivadoBin {
    $repo = Split-Path -Parent $PSScriptRoot

    # 1. saved answer
    $cfg = Join-Path $repo ".toolpaths"
    if (Test-Path $cfg) {
        foreach ($line in Get-Content $cfg) {
            if ($line -match "^VIVADO_BAT=(.+)$") {
                $bat = $Matches[1].Trim()
                if (Test-Path $bat) { return (Split-Path -Parent $bat) }
            }
        }
    }

    # 2. environment
    if ($env:VIVADO_BAT -and (Test-Path $env:VIVADO_BAT)) {
        return (Split-Path -Parent $env:VIVADO_BAT)
    }
    if ($env:XILINX_VIVADO -and (Test-Path "$($env:XILINX_VIVADO)\bin\vivado.bat")) {
        return "$($env:XILINX_VIVADO)\bin"
    }

    # 3. PATH
    $cmd = Get-Command vivado.bat -ErrorAction SilentlyContinue
    if ($cmd) { return (Split-Path -Parent $cmd.Source) }

    # 4. common install roots on every filesystem drive
    $found = $null
    foreach ($drive in (Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Free -ne $null })) {
        $r = $drive.Root
        foreach ($pat in @("${r}Xilinx\Vivado\*", "${r}AMD\Vivado\*", "${r}AMD\*", "${r}Xilinx\*")) {
            Get-ChildItem $pat -Directory -ErrorAction SilentlyContinue | ForEach-Object {
                foreach ($cand in @("$($_.FullName)\bin", "$($_.FullName)\Vivado\bin")) {
                    if (Test-Path "$cand\vivado.bat") { $found = $cand }
                }
            }
        }
    }
    if ($found) { return $found }

    throw "Vivado not found (PATH, .toolpaths, common roots on all drives). Run setup_check.bat once - it will ask for the install dir and save it."
}
