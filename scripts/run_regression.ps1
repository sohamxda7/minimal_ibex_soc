# =============================================================================
# FULL regression, one entry point: regenerate program images, compile all
# RTL + testbenches, run all 9 simulations, build the bitstream, verify
# timing, print a PASS/FAIL scoreboard. ~45-60 min on a 16 GB machine
# (everything sequential on purpose - concurrent xelab+vivado has killed
# builds on 16 GB before).
#
# Launch: run_regression.bat (double-click), or from an agent shell:
#   Start-Process powershell -ArgumentList "-NoProfile","-File","scripts\run_regression.ps1"
# (EDA tools hang under piped stdio - WALKTHROUGH.md gotcha 16.)
#
# Log: build\regression.log (ASCII - gotcha 17).  Exit code 0 = all green.
# =============================================================================
$ErrorActionPreference = "Continue"
$repo = Split-Path -Parent $PSScriptRoot
Set-Location $repo

. "$PSScriptRoot\find_vivado.ps1"
try { $viv = Find-VivadoBin } catch { Write-Host "ERROR: $_"; exit 1 }

New-Item -ItemType Directory -Force "$repo\build" | Out-Null
$log = "$repo\build\regression.log"
"=== FULL REGRESSION $(Get-Date) ===" | Out-File $log -Encoding ascii
$results = [ordered]@{}

function Log($s) { $s | Out-File $log -Append -Encoding ascii; Write-Host $s }

# ---- 1. Regenerate program images ------------------------------------------
Log "--- IMAGES ---"
python sw\asm-demo\assemble.py        *>> $log
python sw\asm-demo\assemble.py --sim  *>> $log
python sw\asm-demo\lcd_spi_test.py --sim *>> $log
python sw\asm-demo\i2c_test.py        *>> $log
python sw\asm-demo\xip_test.py        *>> $log
python sw\asm-demo\periph_tests.py    *>> $log
$results["images"] = ($LASTEXITCODE -eq 0)

# ---- 2. FreeRTOS firmware (sim variant feeds tb_freertos) ------------------
Log "--- FREERTOS BUILD ---"
$fw = & cmd /c "sw\freertos\build.bat sim" 2>&1 | Out-String
$fw | Out-File $log -Append -Encoding ascii
$results["freertos-build"] = ($fw -match "BUILD OK")

# ---- 3. Compile ------------------------------------------------------------
Log "--- XVLOG ---"
& "$viv\xvlog.bat" -sv -f dv/xsim/filelist.f `
    dv/xsim/tb_soc.sv dv/xsim/tb_lcd.sv dv/xsim/tb_i2c.sv `
    dv/xsim/tb_xip.sv dv/xsim/tb_freertos.sv `
    dv/xsim/tb_psram.sv dv/xsim/tb_wifi.sv dv/xsim/tb_audio.sv dv/xsim/tb_cam.sv `
    dv/xsim/spi_nor_flash_model.sv dv/xsim/periph_models.sv dv/xsim/sim_stubs.sv `
    rtl/system/i2c_slave_bfm.sv `
    -i vendor/lowrisc_ip/ip/prim/rtl -i rtl/system `
    -i vendor/lowrisc_ibex/vendor/lowrisc_ip/dv/sv/dv_utils 2>&1 |
  Select-String "^ERROR" | Out-File $log -Append -Encoding ascii
$results["compile"] = ((Select-String -Path $log -Pattern "^ERROR" -SimpleMatch -ErrorAction SilentlyContinue | Measure-Object).Count -eq 0)

# ---- 4. Simulations --------------------------------------------------------
$tests = @(
  @{tb="tb_soc";      snap="soc_sim";      pass="9 PASS, 0 FAIL"},
  @{tb="tb_lcd";      snap="lcd_sim";      pass="5 PASS, 0 FAIL"},
  @{tb="tb_i2c";      snap="i2c_sim";      pass="PASS: register"},
  @{tb="tb_xip";      snap="xip_sim";      pass="PASS: CPU executed"},
  @{tb="tb_freertos"; snap="freertos_sim"; pass="PASS: FreeRTOS"},
  @{tb="tb_psram";    snap="psram_sim";    pass="PASS: PSRAM"},
  @{tb="tb_wifi";     snap="wifi_sim";     pass="PASS: AT"},
  @{tb="tb_audio";    snap="audio_sim";    pass="PASS: 4 increasing"},
  @{tb="tb_cam";      snap="cam_sim";      pass="PASS: 16-byte"}
)
foreach ($t in $tests) {
  Log "--- SIM $($t.tb) ---"
  & "$viv\xelab.bat" $t.tb -s $t.snap -timescale 1ns/1ps 2>&1 |
    Select-String "^ERROR|Built simulation" | Out-File $log -Append -Encoding ascii
  $out = & "$viv\xsim.bat" $t.snap -R 2>&1 | Out-String
  ($out -split "`n" | Select-String "PASS|FAIL|RESULTS") | Out-File $log -Append -Encoding ascii
  $results[$t.tb] = ($out -match [regex]::Escape($t.pass))
}

# ---- 5. Bitstream ----------------------------------------------------------
Log "--- BITSTREAM ---"
$bs = & "$viv\vivado.bat" -mode batch -source build_fpga.tcl -nojournal -log build\fpga\build.log 2>&1 | Out-String
($bs -split "`n" | Select-String "BUILD OK|^ERROR") | Out-File $log -Append -Encoding ascii
$timing = ""
if (Test-Path build\fpga\timing_summary.rpt) {
  $timing = (Select-String -Path build\fpga\timing_summary.rpt -Pattern "All user specified timing constraints are met" -ErrorAction SilentlyContinue | Measure-Object).Count
}
$results["bitstream"] = (($bs -match "BUILD OK") -and ($timing -ge 1))

# ---- Scoreboard ------------------------------------------------------------
Log ""
Log "=== SCOREBOARD ==="
$allOk = $true
foreach ($k in $results.Keys) {
  $v = if ($results[$k]) { "PASS" } else { "FAIL"; }
  if (-not $results[$k]) { $allOk = $false }
  Log ("{0,-16} {1}" -f $k, $v)
}
Log ("=== REGRESSION {0} ===" -f $(if ($allOk) { "ALL GREEN" } else { "HAS FAILURES" }))
if (-not $allOk) { exit 1 }
exit 0
