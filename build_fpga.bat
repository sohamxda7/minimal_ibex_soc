@echo off
rem Builds the Arty A7 bitstream with plain Vivado (no FuseSoC needed).
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
call "%VIVADO%" -mode batch -source build_fpga.tcl -nojournal -log build\fpga\build.log
pause
