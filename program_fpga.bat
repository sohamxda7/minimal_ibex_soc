@echo off
rem Programs the Arty A7 with the Ibex SoC bitstream.
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
call "%VIVADO%" -mode batch -source program_fpga.tcl -nojournal -log build\fpga\program.log
pause
