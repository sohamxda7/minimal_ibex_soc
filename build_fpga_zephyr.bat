@echo off
rem Builds the bitstream with the ZEPHYR image in SRAM (instead of the asm demo).
rem Prerequisite: west build done + bin2vmem produced build\zephyr_sram.vmem
rem (see zephyr-port\README.md).
setlocal
set VIVADO=
for /d %%v in ("C:\Xilinx\Vivado\*") do (
    if exist "%%v\bin\vivado.bat" set "VIVADO=%%v\bin\vivado.bat"
)
for /d %%v in ("C:\AMD\Vivado\*") do (
    if exist "%%v\bin\vivado.bat" set "VIVADO=%%v\bin\vivado.bat"
)
for /d %%v in ("C:\AMD\*") do (
    if exist "%%v\Vivado\bin\vivado.bat" set "VIVADO=%%v\Vivado\bin\vivado.bat"
)
if "%VIVADO%"=="" (
    echo ERROR: Vivado not found. Edit this file.
    pause
    exit /b 1
)
cd /d "%~dp0"
if not exist build\zephyr_sram.vmem (
    echo ERROR: build\zephyr_sram.vmem not found — build Zephyr first
    echo        ^(west build ... then bin2vmem, see zephyr-port\README.md^).
    pause
    exit /b 1
)
if not exist build\fpga mkdir build\fpga
call "%VIVADO%" -mode batch -source build_fpga.tcl -nojournal -log build\fpga\build.log -tclargs build/zephyr_sram.vmem
pause
