# PWM-decision verification: tb_soc (exercises PWM via RGB commands) then
# a full bitstream build. RTL unchanged - this is fresh confirming evidence.
$ErrorActionPreference = "Continue"
. "$PSScriptRoot\find_vivado.ps1"
$viv  = Find-VivadoBin
$repo = Split-Path -Parent $PSScriptRoot
Set-Location $repo
$log = "$repo\build\pwm_check.log"
"=== PWM CHECK $(Get-Date) ===" | Out-File $log -Encoding ascii

& "$viv\xelab.bat" tb_soc -s soc_sim -timescale 1ns/1ps 2>&1 |
  Select-String "^ERROR|Built simulation" | Out-File $log -Append -Encoding ascii
& "$viv\xsim.bat" soc_sim -R 2>&1 |
  Select-String "PASS|FAIL|RESULTS" | Out-File $log -Append -Encoding ascii

"--- BITSTREAM ---" | Out-File $log -Append -Encoding ascii
& "$viv\vivado.bat" -mode batch -source build_fpga.tcl -nojournal -log build\fpga\build.log 2>&1 |
  Select-String "BUILD OK|^ERROR" | Select-Object -First 10 | Out-File $log -Append -Encoding ascii
if (Test-Path build\fpga\timing_summary.rpt) {
  Select-String -Path build\fpga\timing_summary.rpt -Pattern "All user specified timing constraints are met|constraints are not met" |
    Select-Object -First 1 -ExpandProperty Line | Out-File $log -Append -Encoding ascii
}
"PWM_CHECK_DONE" | Out-File $log -Append -Encoding ascii
