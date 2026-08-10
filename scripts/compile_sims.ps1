# Compile all RTL + testbenches for xsim. Mirrors the known-good launch
# pattern (detached powershell) from the bring-up regressions.
$ErrorActionPreference = "Continue"
. "$PSScriptRoot\find_vivado.ps1"
$viv  = Find-VivadoBin
$repo = Split-Path -Parent $PSScriptRoot
Set-Location $repo
New-Item -ItemType Directory -Force "$repo\build" | Out-Null
$log = "$repo\build\compile_sims.log"
"=== XVLOG $(Get-Date) ===" | Out-File $log -Encoding ascii

& "$viv\xvlog.bat" -sv -f dv/xsim/filelist.f `
    dv/xsim/tb_soc.sv dv/xsim/tb_lcd.sv dv/xsim/tb_i2c.sv `
    dv/xsim/tb_xip.sv dv/xsim/tb_freertos.sv `
    dv/xsim/spi_nor_flash_model.sv dv/xsim/sim_stubs.sv `
    rtl/system/i2c_slave_bfm.sv `
    -i vendor/lowrisc_ip/ip/prim/rtl -i rtl/system `
    -i vendor/lowrisc_ibex/vendor/lowrisc_ip/dv/sv/dv_utils 2>&1 |
  Select-String "^ERROR|^CRITICAL" | Out-File $log -Append -Encoding ascii

"XVLOG_DONE rc=$LASTEXITCODE" | Out-File $log -Append -Encoding ascii
