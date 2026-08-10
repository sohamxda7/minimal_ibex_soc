@echo off
rem =========================================================================
rem One click: FreeRTOS onto the board, end to end.
rem   1. Build the FreeRTOS hardware firmware   (sw\freertos\build.bat)
rem   2. Build the XIP-boot bitstream           (SRAM = boot trampoline)
rem   3. Program bitstream + firmware into the onboard QSPI flash
rem After it finishes: press PROG (or power-cycle) on the board, open the
rem serial terminal at 115200, and you should see
rem     FreeRTOS on Ibex (XIP, 8KiB SRAM)
rem     tick=...
rem Docs: docs/FREERTOS_PORT.md section 3.
rem
rem   flash_freertos.bat        standard demo (blink + tick reports)
rem   flash_freertos.bat toy    + the toy task (LCD/BME280/OLED wired)
rem =========================================================================
setlocal
rem Locate Vivado dynamically: saved .toolpaths -> env -> PATH -> all-drive
rem scan -> ask-and-save. Shared logic: scripts\find_tools.cmd
call "%~dp0scripts\find_tools.cmd" vivado
set "VIVADO=%VIVADO_BAT%"
if "%VIVADO%"=="" (
    echo ERROR: Vivado not found - run setup_check.bat once to set it up.
    pause
    exit /b 1
)
cd /d "%~dp0"

set FWNAME=freertos_demo
if "%1"=="toy" set FWNAME=freertos_demo_toy

echo === [1/3] Building FreeRTOS firmware (%FWNAME%) ===
call sw\freertos\build.bat %1
if errorlevel 1 ( echo FIRMWARE BUILD FAILED & pause & exit /b 1 )

echo === [2/3] Building XIP-boot bitstream (SRAM = trampoline) ===
if not exist build\fpga mkdir build\fpga
call "%VIVADO%" -mode batch -source build_fpga.tcl -nojournal -log build\fpga\build.log -tclargs sw/asm-demo/xip_stub.vmem
if errorlevel 1 ( echo BITSTREAM BUILD FAILED - see build\fpga\build.log & pause & exit /b 1 )

echo === [3/3] Programming QSPI flash (bitstream + firmware @0x40_0000) ===
call "%VIVADO%" -mode batch -source program_flash.tcl -nojournal -log build\fpga\program_flash.log -tclargs sw/freertos/build/%FWNAME%.bin
if errorlevel 1 ( echo FLASH PROGRAMMING FAILED - see build\fpga\program_flash.log & pause & exit /b 1 )

echo.
echo DONE. Press PROG (or power-cycle) on the board, then open the serial
echo terminal at 115200 8N1 - expect the FreeRTOS banner and tick lines.
pause
