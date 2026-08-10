# Incremental: recompile models + tb_wifi, rerun the 3 failing peripheral tbs.
$ErrorActionPreference = "Continue"
. "$PSScriptRoot\find_vivado.ps1"
$viv  = Find-VivadoBin
$repo = Split-Path -Parent $PSScriptRoot
Set-Location $repo
$log = "$repo\build\rerun_fails.log"
"=== RERUN FAILS $(Get-Date) ===" | Out-File $log -Encoding ascii

& "$viv\xvlog.bat" -sv dv/xsim/periph_models.sv dv/xsim/tb_wifi.sv 2>&1 |
  Select-String "^ERROR" | Out-File $log -Append -Encoding ascii

$tests = @(
  @{tb="tb_psram"; snap="psram_sim"},
  @{tb="tb_wifi";  snap="wifi_sim"},
  @{tb="tb_cam";   snap="cam_sim"}
)
foreach ($t in $tests) {
  "--- $($t.tb) ---" | Out-File $log -Append -Encoding ascii
  & "$viv\xelab.bat" $t.tb -s $t.snap -timescale 1ns/1ps 2>&1 |
    Select-String "^ERROR|Built simulation" | Out-File $log -Append -Encoding ascii
  & "$viv\xsim.bat" $t.snap -R 2>&1 |
    Select-String "PASS|FAIL|dbg\]|psram|unsupported|ov7670 rd|esp32" |
    Select-Object -First 30 | Out-File $log -Append -Encoding ascii
}
"RERUN_FAILS_DONE" | Out-File $log -Append -Encoding ascii
