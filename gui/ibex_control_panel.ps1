# =============================================================================
# minimal-ibex-soc Control Panel (Windows-only, WinForms - no dependencies
# beyond stock PowerShell). One window for the whole flow: environment
# doctor, bitstream build, board programming, FreeRTOS flash, firmware
# builds, full regression, docs and live logs.
#
# Launch: control_panel.bat (repo root), or:
#   powershell -NoProfile -ExecutionPolicy Bypass -File gui\ibex_control_panel.ps1
#
# Every action runs DETACHED in its own console window (EDA tools hang under
# piped stdio - docs/WALKTHROUGH.md gotcha 16); the log pane tails the
# corresponding build\*.log so progress is visible here too.
# =============================================================================
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$repo = Split-Path -Parent $PSScriptRoot
Set-Location $repo

function Launch-Detached([string]$cmd, [string[]]$cmdArgs) {
    Start-Process -FilePath $cmd -ArgumentList $cmdArgs -WorkingDirectory $repo
}

function Launch-Bat([string]$bat, [string]$batArg) {
    # cmd /k keeps the window open so the user sees the result + any pause
    $inner = "`"$repo\$bat`""
    if ($batArg) { $inner += " $batArg" }
    Launch-Detached "cmd.exe" @("/k", $inner)
}

function Launch-Ps1([string]$ps1) {
    Launch-Detached "powershell.exe" @("-NoProfile","-ExecutionPolicy","Bypass","-File","$repo\$ps1")
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

# ---- row 1: setup / build / program ------------------------------------------
Add-Label "Setup and build" 12 44 $true | Out-Null
Add-Button "Environment Check" 12  66 160 { Launch-Bat "setup_check.bat" "" } `
  "Doctor: Vivado/Python/GCC/git/paths. Asks + saves tool locations if missing." | Out-Null
Add-Button "Build Bitstream"   182 66 160 { Launch-Bat "build_fpga.bat" "" } `
  "Synthesise with the demo program baked into SRAM (~15 min)." | Out-Null
Add-Button "Program Board (JTAG)" 352 66 160 { Launch-Bat "program_fpga.bat" "" } `
  "Volatile: lost at power-cycle. Board must be connected." | Out-Null
Add-Button "Full Regression"   522 66 160 { Launch-Bat "run_regression.bat" "" } `
  "Images + firmware + compile + all simulations + bitstream + scoreboard (~1 h)." | Out-Null

# ---- row 2: firmware ----------------------------------------------------------
Add-Label "FreeRTOS firmware" 12 112 $true | Out-Null
$variant = New-Object Windows.Forms.ComboBox
$variant.Location = New-Object Drawing.Point(12, 134)
$variant.Size     = New-Object Drawing.Size(160, 30)
$variant.DropDownStyle = "DropDownList"
[void]$variant.Items.AddRange(@("standard demo", "toy (LCD+sensors)", "sim image"))
$variant.SelectedIndex = 0
$form.Controls.Add($variant)

function Get-VariantArg {
    switch ($variant.SelectedIndex) { 1 { "toy" } 2 { "sim" } default { "" } }
}

Add-Button "Build Firmware" 182 132 160 { Launch-Bat "sw\freertos\build.bat" (Get-VariantArg) } `
  "Compile the selected variant with the RISC-V GCC." | Out-Null
Add-Button "Flash to Board (QSPI)" 352 132 160 {
    $fw = if ($variant.SelectedIndex -eq 1) { "toy" } else { "" }
    Launch-Bat "flash_freertos.bat" $fw
} "End to end: firmware + XIP bitstream + QSPI flash. Survives power-cycle." | Out-Null

# ---- row 3: docs + logs ---------------------------------------------------------
Add-Label "Docs and logs" 12 178 $true | Out-Null
Add-Button "Open Fork Guide"  12 200 160 { Start-Process "$repo\docs\README.md" } `
  "docs/README.md - where to start, fixes, constraints." | Out-Null
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
