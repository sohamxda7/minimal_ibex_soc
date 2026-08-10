# Incremental: recompile the fixed spi_flash_xip.sv, re-elab + rerun tb_xip.
$ErrorActionPreference = "Continue"
. "$PSScriptRoot\find_vivado.ps1"
$viv  = Find-VivadoBin
$repo = Split-Path -Parent $PSScriptRoot
Set-Location $repo
$log = "$repo\build\rerun_xip.log"
"=== XIP RERUN $(Get-Date) ===" | Out-File $log -Encoding ascii

& "$viv\xvlog.bat" -sv rtl/system/spi_flash_xip.sv 2>&1 |
  Select-String "^ERROR" | Out-File $log -Append -Encoding ascii
& "$viv\xelab.bat" tb_xip -s xip_sim -timescale 1ns/1ps 2>&1 |
  Select-String "^ERROR|Built simulation" | Out-File $log -Append -Encoding ascii
& "$viv\xsim.bat" xip_sim -R 2>&1 |
  Select-String "PASS|FAIL|WARNING read outside|unsupported" |
  Out-File $log -Append -Encoding ascii
"XIP_RERUN_DONE" | Out-File $log -Append -Encoding ascii
