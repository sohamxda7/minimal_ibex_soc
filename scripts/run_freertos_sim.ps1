# Elab + run tb_freertos (FreeRTOS booting over XIP). Longest sim in the
# suite: ~20+ ms of simulated time at 128 sysclks per instruction fetch.
$ErrorActionPreference = "Continue"
$viv  = "C:\AMD\2026.1\Vivado\bin"
$repo = "C:\FPGA\minimal-ibex-soc"
Set-Location $repo
$log = "$repo\build\freertos_sim.log"
"=== FREERTOS SIM $(Get-Date) ===" | Out-File $log -Encoding ascii

& "$viv\xelab.bat" tb_freertos -s freertos_sim -timescale 1ns/1ps 2>&1 |
  Select-String "^ERROR|Built simulation" | Out-File $log -Append -Encoding ascii
& "$viv\xsim.bat" freertos_sim -R 2>&1 |
  Select-String "PASS|FAIL|ASSERT|EXC|tick=|\[tb\]|unsupported" |
  Out-File $log -Append -Encoding ascii
"FREERTOS_SIM_DONE" | Out-File $log -Append -Encoding ascii
