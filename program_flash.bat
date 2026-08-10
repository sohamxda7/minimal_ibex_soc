@echo off
rem Program bitstream + XIP firmware into the Arty's QSPI flash.
rem Usage: program_flash.bat [firmware.bin]   (default: FreeRTOS demo)
rem For the full one-click chain (firmware + bitstream + flash) use
rem flash_freertos.bat instead.
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
if not exist build\fpga mkdir build\fpga
call "%VIVADO%" -mode batch -nojournal -log build\fpga\program_flash.log -source program_flash.tcl -tclargs %*
pause
