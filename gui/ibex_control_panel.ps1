# =============================================================================
# minimal-ibex-soc Control Panel (Windows-only, WinForms - no dependencies
# beyond stock PowerShell). THE user interface for everything: environment
# doctor + tool setup, .xpr generation, bitstream build, FreeRTOS firmware
# + QSPI flashing, full regression, docs and live logs. (JTAG programming
# is dev-only and CLI-only: powershell -File scripts\flows.ps1 program)
#
# Launch: ibex_soc.bat (the one root script), or:
#   powershell -NoProfile -ExecutionPolicy Bypass -File gui\ibex_control_panel.ps1
#
# Every button opens its own console window running scripts\flows.ps1 <flow>
# (EDA tools hang under piped stdio - docs/WALKTHROUGH.md gotcha 16 - so
# flows always get a real console); the log pane tails build\*.log too.
# =============================================================================
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$repo = Split-Path -Parent $PSScriptRoot
Set-Location $repo

function Launch-Flow([string]$flow, [string]$flowArg) {
    # -NoExit keeps the console open so the user sees the result
    $a = @("-NoProfile","-ExecutionPolicy","Bypass","-NoExit",
           "-File","$repo\scripts\flows.ps1",$flow)
    if ($flowArg) { $a += $flowArg }
    Start-Process -FilePath "powershell.exe" -ArgumentList $a -WorkingDirectory $repo
}

# ---- window -----------------------------------------------------------------
$form               = New-Object Windows.Forms.Form
$form.Text          = "minimal-ibex-soc Control Panel  -  ASIC is the product; FPGA validates it"
$form.Size          = New-Object Drawing.Size(860, 640)
$form.StartPosition = "CenterScreen"
$form.MinimumSize   = $form.Size

$tip = New-Object Windows.Forms.ToolTip

function Add-Button([string]$text, [int]$x, [int]$y, [int]$w, [scriptblock]$onClick, [string]$hint) {
    $b = New-Object Windows.Forms.Button
    $b.Text     = $text
    $b.Location = New-Object Drawing.Point($x, $y)
    $b.Size     = New-Object Drawing.Size($w, 34)
    $b.Add_Click($onClick)
    if ($hint) { $tip.SetToolTip($b, $hint) }
    $form.Controls.Add($b)
    return $b
}

function Add-Label([string]$text, [int]$x, [int]$y, [bool]$bold) {
    $l = New-Object Windows.Forms.Label
    $l.Text     = $text
    $l.AutoSize = $true
    $l.Location = New-Object Drawing.Point($x, $y)
    if ($bold) { $l.Font = New-Object Drawing.Font("Segoe UI", 9, [Drawing.FontStyle]::Bold) }
    $form.Controls.Add($l)
    return $l
}

# ---- status line ------------------------------------------------------------
. "$repo\scripts\find_vivado.ps1"
$vivStatus = try { "Vivado: $(Find-VivadoBin)" } catch { "Vivado: NOT FOUND - run Environment Check" }
$pyStatus  = if (Get-Command python -ErrorAction SilentlyContinue) { "Python: OK" } else { "Python: MISSING" }
Add-Label "$vivStatus    |    $pyStatus    |    Repo: $repo" 12 10 $false | Out-Null
$hint = Add-Label "New PC?  1) Environment Check   2) Install Missing Tools   3) Flash to Board (QSPI)  -  then press PROG and open PuTTY at 115200" 12 28 $false
$hint.ForeColor = [Drawing.Color]::DarkGreen

# ---- row 1: setup / build / program ------------------------------------------
Add-Label "Setup and build" 12 48 $true | Out-Null
Add-Button "Environment Check" 12  70 150 { Launch-Flow "setup" "" } `
  "Step 1 - Doctor: Vivado/Python/GCC/git/paths/board. Asks + saves tool locations if missing." | Out-Null
Add-Button "Install Missing Tools" 170 70 150 { Launch-Flow "deps" "" } `
  "Step 2 - Auto-installs what the check flagged: Python (winget) + a native Windows RISC-V GCC (xPack, ~470 MB download, no WSL, no admin). Vivado stays a manual install." | Out-Null
Add-Button "Build Bitstream"   328 70 150 { Launch-Flow "build" "" } `
  "Synthesise the direct-XIP bitstream - no SRAM image baked (~15 min)." | Out-Null
Add-Button "Generate .xpr"     486 70 150 { Launch-Flow "xpr" "" } `
  "Vivado GUI project for browsing (build\vivado_project). Official build stays batch." | Out-Null
Add-Button "Full Regression"   644 70 150 { Launch-Flow "regression" "" } `
  "Images + firmware + compile + all 11 simulations + bitstream + scoreboard (~1 h)." | Out-Null

# ---- row 2: firmware / board ---------------------------------------------------
# ONE image, no variant picker: the dropdown cost a bench session (2026-08-18 -
# "standard demo" was flashed with an LCD wired, screen stayed dark). The
# hardware firmware now always includes console + LEDs/RGB + the LCD status
# screen (missing parts tolerated). JTAG programming is dev-only, CLI-only:
#   powershell -File scripts\flows.ps1 program
Add-Label "FreeRTOS firmware and board" 12 112 $true | Out-Null
Add-Button "Build Firmware" 12 132 160 { Launch-Flow "firmware" "" } `
  "Compile the firmware with the RISC-V GCC (console + LEDs/RGB + LCD status screen - one image)." | Out-Null
Add-Button "Flash to Board (QSPI)" 182 132 160 { Launch-Flow "flashfw" "" } `
  "THE flow: BUILDS the firmware (offers the automatic GCC install if missing; prebuilt only on your explicit choice) + XIP bitstream + QSPI flash. Survives power-cycle. Includes the LCD status screen - wired or not." | Out-Null
Add-Button "Verilator Regression" 352 132 160 { Launch-Flow "simregression" "" } `
  "Open-source simulation, NO Vivado needed: runs all 11 sims through MSYS2's Verilator (the same ibex_soc.sh Linux uses). Tells you how to install MSYS2 if it is missing." | Out-Null
Add-Button "Tool Profile" 522 132 120 { Launch-Flow "profile" "" } `
  "Which half of the flow this PC is for: sim (Verilator only - Vivado never reported missing), fpga (Vivado only), full, or auto. Set with: flows.ps1 profile <sim|fpga|full|auto>." | Out-Null

# ---- row 3: docs + logs ---------------------------------------------------------
Add-Label "Docs and logs" 12 178 $true | Out-Null
Add-Button "Open Fork Guide"  12 200 160 { Start-Process "$repo\README.md" } `
  "README.md - the front page: quick start, constraints, doc index." | Out-Null
Add-Button "Open Walkthrough" 182 200 160 { Start-Process "$repo\docs\WALKTHROUGH.md" } `
  "Clean PC to working board, all gotchas." | Out-Null
Add-Button "Open Test Report" 352 200 160 { Start-Process "$repo\docs\BRINGUP_TEST_REPORT.md" } `
  "Every recorded result." | Out-Null

$logPick = New-Object Windows.Forms.ComboBox
$logPick.Location = New-Object Drawing.Point(522, 202)
$logPick.Size     = New-Object Drawing.Size(220, 30)
$logPick.DropDownStyle = "DropDownList"
$form.Controls.Add($logPick)

$logBox = New-Object Windows.Forms.TextBox
$logBox.Multiline  = $true
$logBox.ReadOnly   = $true
$logBox.ScrollBars = "Vertical"
$logBox.Font       = New-Object Drawing.Font("Consolas", 9)
$logBox.Location   = New-Object Drawing.Point(12, 244)
$logBox.Size       = New-Object Drawing.Size(816, 330)
$logBox.Anchor     = "Top,Bottom,Left,Right"
$form.Controls.Add($logBox)

function Refresh-LogList {
    $sel = $logPick.SelectedItem
    $logPick.Items.Clear()
    Get-ChildItem "$repo\build" -Filter "*.log" -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending | ForEach-Object { [void]$logPick.Items.Add($_.Name) }
    if ($logPick.Items.Count -gt 0) {
        $idx = if ($sel) { $logPick.Items.IndexOf($sel) } else { -1 }
        $logPick.SelectedIndex = if ($idx -ge 0) { $idx } else { 0 }
    }
}

function Refresh-LogView {
    if (-not $logPick.SelectedItem) { return }
    $f = "$repo\build\$($logPick.SelectedItem)"
    if (Test-Path $f) {
        $txt = (Get-Content $f -Tail 200 -ErrorAction SilentlyContinue) -join "`r`n"
        if ($logBox.Text -ne $txt) {
            $logBox.Text = $txt
            $logBox.SelectionStart = $logBox.Text.Length
            $logBox.ScrollToCaret()
        }
    }
}

$timer = New-Object Windows.Forms.Timer
$timer.Interval = 2000
$timer.Add_Tick({ Refresh-LogView })
$timer.Start()
$logPick.Add_SelectedIndexChanged({ Refresh-LogView })
$form.Add_Shown({ Refresh-LogList; Refresh-LogView })
Add-Button "Refresh Logs" 752 200 76 { Refresh-LogList; Refresh-LogView } "Rescan build\*.log" | Out-Null

[void]$form.ShowDialog()
