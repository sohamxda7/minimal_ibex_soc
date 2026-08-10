# Bitstream build (8 KiB SRAM + QSPI XIP wiring + STARTUPE2).
$ErrorActionPreference = "Continue"
$viv  = "C:\AMD\2026.1\Vivado\bin"
$repo = "C:\FPGA\minimal-ibex-soc"
Set-Location $repo
$log = "$repo\build\bitstream_run.log"
"=== BITSTREAM $(Get-Date) ===" | Out-File $log -Encoding ascii

& "$viv\vivado.bat" -mode batch -source build_fpga.tcl -nojournal -log build\fpga\build.log 2>&1 |
  Select-String "BUILD OK|^ERROR|CRITICAL WARNING" | Select-Object -First 30 |
  Out-File $log -Append -Encoding ascii
if (Test-Path build\fpga\timing_summary.rpt) {
  Select-String -Path build\fpga\timing_summary.rpt -Pattern "All user specified timing constraints are met|constraints are not met" |
    Select-Object -First 1 -ExpandProperty Line | Out-File $log -Append -Encoding ascii
}
"BITSTREAM_DONE" | Out-File $log -Append -Encoding ascii
