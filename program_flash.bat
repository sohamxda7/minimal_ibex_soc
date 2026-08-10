@echo off
rem Program bitstream + XIP firmware into the Arty's QSPI flash.
rem Usage: program_flash.bat [firmware.bin]   (default: FreeRTOS demo)
rem For the full one-click chain (firmware + bitstream + flash) use
rem flash_freertos.bat instead.
setlocal
set VIVADO=
for /d %%v in ("C:\Xilinx\Vivado\*") do if exist "%%v\bin\vivado.bat" set "VIVADO=%%v\bin\vivado.bat"
for /d %%v in ("C:\AMD\Vivado\*")    do if exist "%%v\bin\vivado.bat" set "VIVADO=%%v\bin\vivado.bat"
for /d %%v in ("C:\AMD\*")           do if exist "%%v\Vivado\bin\vivado.bat" set "VIVADO=%%v\Vivado\bin\vivado.bat"
if "%VIVADO%"=="" (
    echo ERROR: Vivado not found - run setup_check.bat
    pause
    exit /b 1
)
cd /d "%~dp0"
if not exist build\fpga mkdir build\fpga
call "%VIVADO%" -mode batch -nojournal -log build\fpga\program_flash.log -source program_flash.tcl -tclargs %*
pause
