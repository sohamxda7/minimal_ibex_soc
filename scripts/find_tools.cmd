@echo off
rem ===========================================================================
rem Shared tool locator - the single place any .bat finds its binaries.
rem
rem   call scripts\find_tools.cmd vivado   -> sets VIVADO_BAT
rem   call scripts\find_tools.cmd gcc      -> sets RISCV_GCC_HOME
rem   call scripts\find_tools.cmd all      -> both (gcc missing = warning only)
rem
rem Search order (first hit wins):
rem   1. .toolpaths in the repo root (answers saved from a previous run)
rem   2. environment variables (VIVADO_BAT / XILINX_VIVADO / RISCV_GCC_HOME)
rem   3. the PATH (where vivado.bat / where riscv64-zephyr-elf-gcc.exe)
rem   4. common install roots on every drive C..G:
rem        <d>:\Xilinx\Vivado\<ver>  <d>:\AMD\Vivado\<ver>
rem        <d>:\AMD\<ver>\Vivado     <d>:\Xilinx\<ver>\Vivado
rem        <d>:\FPGA\zephyr-sdk  <d>:\zephyr-sdk*  %USERPROFILE%\zephyr-sdk*
rem   5. ASK the user for the install directory, validate it, and SAVE the
rem      answer to .toolpaths so it is never asked again on this PC.
rem
rem .toolpaths is per-PC and gitignored. Delete it (or run setup_check.bat)
rem if a tool moves. Exit code 1 = the requested tool is missing.
rem Intentionally NO setlocal: results must land in the caller's environment.
rem ===========================================================================
set "_FT_WANT=%~1"
if "%_FT_WANT%"=="" set "_FT_WANT=all"
set "_FT_CFG=%~dp0..\.toolpaths"

rem ---- 1. load saved answers (validated - stale entries are ignored) -------
if exist "%_FT_CFG%" (
  for /f "usebackq tokens=1,* delims==" %%a in ("%_FT_CFG%") do (
    if /i "%%a"=="VIVADO_BAT"     if not defined VIVADO_BAT     set "VIVADO_BAT=%%b"
    if /i "%%a"=="RISCV_GCC_HOME" if not defined RISCV_GCC_HOME set "RISCV_GCC_HOME=%%b"
  )
)
if defined VIVADO_BAT     if not exist "%VIVADO_BAT%"                                  set "VIVADO_BAT="
if defined RISCV_GCC_HOME if not exist "%RISCV_GCC_HOME%\bin\riscv64-zephyr-elf-gcc.exe" set "RISCV_GCC_HOME="

set "_FT_RC=0"
if /i not "%_FT_WANT%"=="gcc"    call :find_vivado
if /i not "%_FT_WANT%"=="vivado" call :find_gcc
call :save_cfg
set "_FT_WANT=" & set "_FT_CFG=" & set "_FT_IN=" & set "_FT_BIN="
exit /b %_FT_RC%

rem ===========================================================================
:find_vivado
if defined VIVADO_BAT exit /b 0

rem 2. environment (Xilinx settings scripts export XILINX_VIVADO)
if defined XILINX_VIVADO if exist "%XILINX_VIVADO%\bin\vivado.bat" set "VIVADO_BAT=%XILINX_VIVADO%\bin\vivado.bat"
if defined VIVADO_BAT exit /b 0

rem 3. PATH
for /f "delims=" %%p in ('where vivado.bat 2^>nul') do if not defined VIVADO_BAT set "VIVADO_BAT=%%p"
if defined VIVADO_BAT exit /b 0

rem 4. common install roots, every drive
for %%d in (C D E F G) do (
  for /d %%v in ("%%d:\Xilinx\Vivado\*") do if exist "%%v\bin\vivado.bat"        set "VIVADO_BAT=%%v\bin\vivado.bat"
  for /d %%v in ("%%d:\AMD\Vivado\*")    do if exist "%%v\bin\vivado.bat"        set "VIVADO_BAT=%%v\bin\vivado.bat"
  for /d %%v in ("%%d:\AMD\*")           do if exist "%%v\Vivado\bin\vivado.bat" set "VIVADO_BAT=%%v\Vivado\bin\vivado.bat"
  for /d %%v in ("%%d:\Xilinx\*")        do if exist "%%v\Vivado\bin\vivado.bat" set "VIVADO_BAT=%%v\Vivado\bin\vivado.bat"
)
if defined VIVADO_BAT exit /b 0

rem 5. ask the user (blank answer or non-interactive stdin -> give up)
echo.
echo Vivado was not found automatically (PATH, C..G: \Xilinx\, \AMD\).
set "_FT_IN="
set /p _FT_IN=Enter your Vivado install dir (e.g. D:\AMD\2026.1\Vivado), blank to abort:
if not defined _FT_IN set "_FT_RC=1" & exit /b 1
if exist "%_FT_IN%\bin\vivado.bat" (
  set "VIVADO_BAT=%_FT_IN%\bin\vivado.bat"
  echo Saved. Future scripts will use it automatically.
  exit /b 0
)
echo ERROR: "%_FT_IN%\bin\vivado.bat" does not exist.
set "_FT_RC=1"
exit /b 1

rem ===========================================================================
:find_gcc
if defined RISCV_GCC_HOME exit /b 0

rem 3. PATH (derive the toolchain root from the exe location: <root>\bin\gcc)
for /f "delims=" %%p in ('where riscv64-zephyr-elf-gcc.exe 2^>nul') do call :gcc_from_exe "%%p"
if defined RISCV_GCC_HOME exit /b 0

rem 4. common install roots, every drive + user profile
for %%d in (C D E F G) do (
  if exist "%%d:\FPGA\zephyr-sdk\gnu\riscv64-zephyr-elf\bin\riscv64-zephyr-elf-gcc.exe" set "RISCV_GCC_HOME=%%d:\FPGA\zephyr-sdk\gnu\riscv64-zephyr-elf"
  for /d %%v in ("%%d:\zephyr-sdk*") do if exist "%%v\gnu\riscv64-zephyr-elf\bin\riscv64-zephyr-elf-gcc.exe" set "RISCV_GCC_HOME=%%v\gnu\riscv64-zephyr-elf"
)
for /d %%v in ("%USERPROFILE%\zephyr-sdk*") do if exist "%%v\gnu\riscv64-zephyr-elf\bin\riscv64-zephyr-elf-gcc.exe" set "RISCV_GCC_HOME=%%v\gnu\riscv64-zephyr-elf"
if defined RISCV_GCC_HOME exit /b 0

rem 5. ask - but only when gcc was explicitly requested ('all' = warn later)
if /i "%_FT_WANT%"=="all" exit /b 0
echo.
echo RISC-V GCC (riscv64-zephyr-elf) was not found automatically.
echo Install per docs\FREERTOS_PORT.md, or point me at an existing one.
set "_FT_IN="
set /p _FT_IN=Enter the toolchain root (contains bin\riscv64-zephyr-elf-gcc.exe), blank to abort:
if not defined _FT_IN set "_FT_RC=1" & exit /b 1
if exist "%_FT_IN%\bin\riscv64-zephyr-elf-gcc.exe" (
  set "RISCV_GCC_HOME=%_FT_IN%"
  echo Saved. Future scripts will use it automatically.
  exit /b 0
)
echo ERROR: "%_FT_IN%\bin\riscv64-zephyr-elf-gcc.exe" does not exist.
set "_FT_RC=1"
exit /b 1

:gcc_from_exe
if defined RISCV_GCC_HOME exit /b 0
for %%i in ("%~dp1..") do set "RISCV_GCC_HOME=%%~fi"
exit /b 0

rem ===========================================================================
:save_cfg
if not defined VIVADO_BAT if not defined RISCV_GCC_HOME exit /b 0
> "%_FT_CFG%" (
  if defined VIVADO_BAT     echo VIVADO_BAT=%VIVADO_BAT%
  if defined RISCV_GCC_HOME echo RISCV_GCC_HOME=%RISCV_GCC_HOME%
)
exit /b 0
