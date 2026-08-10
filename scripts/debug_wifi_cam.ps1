# Debug run: tb_wifi + tb_cam with UNFILTERED xsim output (first 150 lines each).
$ErrorActionPreference = "Continue"
. "$PSScriptRoot\find_vivado.ps1"
$viv  = Find-VivadoBin
$repo = Split-Path -Parent $PSScriptRoot
Set-Location $repo
$log = "$repo\build\dbg_wc.log"
"=== DBG $(Get-Date) ===" | Out-File $log -Encoding ascii

& "$viv\xvlog.bat" -sv dv/xsim/periph_models.sv dv/xsim/tb_wifi.sv dv/xsim/tb_cam.sv 2>&1 |
  Select-String "^ERROR" | Out-File $log -Append -Encoding ascii

foreach ($t in @(@{tb="tb_wifi";snap="wifi_sim"}, @{tb="tb_cam";snap="cam_sim"})) {
  "--- $($t.tb) ---" | Out-File $log -Append -Encoding ascii
  & "$viv\xelab.bat" $t.tb -s $t.snap -timescale 1ns/1ps 2>&1 |
    Select-String "^ERROR" | Out-File $log -Append -Encoding ascii
  & "$viv\xsim.bat" $t.snap -R 2>&1 | Select-Object -First 220 |
    Out-File $log -Append -Encoding ascii
}
"DBG_DONE" | Out-File $log -Append -Encoding ascii
