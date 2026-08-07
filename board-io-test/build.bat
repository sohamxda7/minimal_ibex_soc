@echo off
rem ==========================================================================
rem Builds the FPGA bitstream. Just double-click this file.
rem Takes roughly 3-6 minutes. Result: build\arty_io_test.bit
rem ==========================================================================
setlocal

set VIVADO=
for /d %%v in ("C:\Xilinx\Vivado\*") do (
    if exist "%%v\bin\vivado.bat" set "VIVADO=%%v\bin\vivado.bat"
)
for /d %%v in ("C:\AMD\Vivado\*") do (
    if exist "%%v\bin\vivado.bat" set "VIVADO=%%v\bin\vivado.bat"
)
for /d %%v in ("C:\Xilinx\*\Vivado\*") do (
    if exist "%%v\bin\vivado.bat" set "VIVADO=%%v\bin\vivado.bat"
)
for /d %%v in ("C:\AMD\*\Vivado\*") do (
    if exist "%%v\bin\vivado.bat" set "VIVADO=%%v\bin\vivado.bat"
)
rem 2026.x unified layout: C:\AMD\<version>\Vivado\bin
for /d %%v in ("C:\AMD\*") do (
    if exist "%%v\Vivado\bin\vivado.bat" set "VIVADO=%%v\Vivado\bin\vivado.bat"
)

if "%VIVADO%"=="" (
    echo.
    echo ERROR: Could not find Vivado under C:\Xilinx or C:\AMD.
    echo Install Vivado first ^(see README.md, Step 1^), or if you installed
    echo it somewhere else, edit this file and set VIVADO to the full path
    echo of vivado.bat, e.g.:
    echo    set VIVADO=D:\MyTools\Vivado\2024.2\bin\vivado.bat
    echo.
    pause
    exit /b 1
)

echo Using Vivado: %VIVADO%
echo Building... this takes a few minutes. Log: build\build.log
cd /d "%~dp0"
if not exist build mkdir build
call "%VIVADO%" -mode batch -source scripts\build.tcl -nojournal -log build\build.log

echo.
echo Done. If you see "BUILD OK" above, run program.bat next.
pause
