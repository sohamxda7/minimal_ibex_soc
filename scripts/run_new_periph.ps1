# Compile everything (v1.1 RTL) + elab/run the 4 new peripheral testbenches.
$ErrorActionPreference = "Continue"
. "$PSScriptRoot\find_vivado.ps1"
$viv  = Find-VivadoBin
$repo = Split-Path -Parent $PSScriptRoot
Set-Location $repo
$log = "$repo\build\new_periph.log"
"=== NEW PERIPH $(Get-Date) ===" | Out-File $log -Encoding ascii

python sw\asm-demo\periph_tests.py *>> $log

& "$viv\xvlog.bat" -sv -f dv/xsim/filelist.f `
    dv/xsim/tb_soc.sv dv/xsim/tb_lcd.sv dv/xsim/tb_i2c.sv `
    dv/xsim/tb_xip.sv dv/xsim/tb_freertos.sv `
    dv/xsim/tb_psram.sv dv/xsim/tb_wifi.sv dv/xsim/tb_audio.sv dv/xsim/tb_cam.sv `
    dv/xsim/spi_nor_flash_model.sv dv/xsim/periph_models.sv dv/xsim/sim_stubs.sv `
    rtl/system/i2c_slave_bfm.sv `
    -i vendor/lowrisc_ip/ip/prim/rtl -i rtl/system `
    -i vendor/lowrisc_ibex/vendor/lowrisc_ip/dv/sv/dv_utils 2>&1 |
  Select-String "^ERROR" | Out-File $log -Append -Encoding ascii
"XVLOG_DONE" | Out-File $log -Append -Encoding ascii

$tests = @(
  @{tb="tb_psram"; snap="psram_sim"},
  @{tb="tb_wifi";  snap="wifi_sim"},
  @{tb="tb_audio"; snap="audio_sim"},
  @{tb="tb_cam";   snap="cam_sim"}
)
foreach ($t in $tests) {
  "--- $($t.tb) ---" | Out-File $log -Append -Encoding ascii
  & "$viv\xelab.bat" $t.tb -s $t.snap -timescale 1ns/1ps 2>&1 |
    Select-String "^ERROR|Built simulation" | Out-File $log -Append -Encoding ascii
  & "$viv\xsim.bat" $t.snap -R 2>&1 |
    Select-String "PASS|FAIL|ER|Error|psram WR|mcp3202|esp32|ov7670" |
    Select-Object -First 25 | Out-File $log -Append -Encoding ascii
}
"NEW_PERIPH_DONE" | Out-File $log -Append -Encoding ascii
