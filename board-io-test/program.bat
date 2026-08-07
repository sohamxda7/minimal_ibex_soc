@echo off
rem ==========================================================================
rem Loads the bitstream onto the Arty A7 over USB. Double-click to run.
rem Board must be plugged in (red power LED on).
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
    echo ERROR: Could not find Vivado. See README.md Step 1.
    pause
    exit /b 1
)

cd /d "%~dp0"
call "%VIVADO%" -mode batch -source scripts\program.tcl -nojournal -log build\program.log

echo.
echo If you see "BOARD PROGRAMMED!" above, the test design is running.
echo Open README.md and go through the test checklist.
pause
