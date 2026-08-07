@echo off
rem Builds the Arty A7 bitstream with plain Vivado (no FuseSoC needed).
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
    echo ERROR: Vivado not found under C:\Xilinx or C:\AMD. Edit this file.
    pause
    exit /b 1
)
cd /d "%~dp0"
if not exist build\fpga mkdir build\fpga
call "%VIVADO%" -mode batch -source build_fpga.tcl -nojournal -log build\fpga\build.log
pause
