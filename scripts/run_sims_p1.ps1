# Elab + run: tb_soc, tb_lcd, tb_i2c (8 KiB SRAM validation) and tb_xip
# (first run against unmodified spi_flash_xip controller).
$ErrorActionPreference = "Continue"
$viv  = "C:\AMD\2026.1\Vivado\bin"
$repo = "C:\FPGA\minimal-ibex-soc"
Set-Location $repo
$log = "$repo\build\sims_p1.log"
"=== SIMS P1 $(Get-Date) ===" | Out-File $log -Encoding ascii

$tests = @(
  @{tb="tb_soc"; snap="soc_sim";  tag="SOC-DEMO"},
  @{tb="tb_lcd"; snap="lcd_sim";  tag="LCD-SPI"},
  @{tb="tb_i2c"; snap="i2c_sim";  tag="I2C"},
  @{tb="tb_xip"; snap="xip_sim";  tag="XIP"}
)
foreach ($t in $tests) {
  "--- ELAB $($t.tag) ---" | Out-File $log -Append -Encoding ascii
  & "$viv\xelab.bat" $t.tb -s $t.snap -timescale 1ns/1ps 2>&1 |
    Select-String "^ERROR|Built simulation" | Out-File $log -Append -Encoding ascii
  "--- RUN $($t.tag) ---" | Out-File $log -Append -Encoding ascii
  & "$viv\xsim.bat" $t.snap -R 2>&1 |
    Select-String "PASS|FAIL|RESULTS|WARNING read outside|unsupported cmd" |
    Out-File $log -Append -Encoding ascii
}
"SIMS_P1_DONE" | Out-File $log -Append -Encoding ascii
