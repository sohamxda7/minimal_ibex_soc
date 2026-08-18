@echo off
rem ===========================================================================
rem Shared tool locator - the single place any .bat finds its binaries.
rem
rem   call scripts\find_tools.cmd vivado   -> sets VIVADO_BAT
rem   call scripts\find_tools.cmd gcc      -> sets RISCV_GCC_HOME + RISCV_PREFIX
rem   call scripts\find_tools.cmd all      -> both (gcc missing = warning only)
rem
rem Search order (first hit wins):
rem   1. .toolpaths in the repo root (answers saved from a previous run)
rem   2. environment variables (VIVADO_BAT / XILINX_VIVADO / RISCV_GCC_HOME)
rem   3. the PATH (where vivado.bat / where <prefix>gcc.exe)
rem   4. common install roots on every drive C..G:
rem        <d>:\Xilinx\Vivado\<ver>  <d>:\AMD\Vivado\<ver>
rem        <d>:\AMD\<ver>\Vivado     <d>:\Xilinx\<ver>\Vivado
rem        <d>:\AMDDesignTools\<ver>\Vivado (2025.x+ default root)
rem        <d>:\FPGA\zephyr-sdk  <d>:\zephyr-sdk*  <d>:\lowrisc-toolchain*
rem        <d>:\xpack-riscv-none-elf-gcc* (also under \FPGA and the profile;
rem        this is what the GUI's Install Missing Tools button installs)
rem        %USERPROFILE%\zephyr-sdk*  %USERPROFILE%\lowrisc-toolchain*
rem   4b. GCC only: inside WSL (/opt/lowrisc-toolchain*, /opt/riscv*,
rem        /tools/riscv, ~/lowrisc-toolchain*) - the lowRISC toolchain tar.xz
rem        ships Linux binaries only. Found there, RISCV_GCC_HOME=wsl:<path>
rem        and sw\freertos\build.bat compiles through wsl (build.sh).
rem   5. ASK the user for the install directory, validate it, and SAVE the
rem      answer to .toolpaths so it is never asked again on this PC.
rem
rem GCC bin prefixes accepted, first match wins (RISCV_PREFIX gets the match):
rem   riscv32-unknown-elf-  riscv64-zephyr-elf-  riscv64-unknown-elf-
rem   riscv-none-elf-
rem
rem .toolpaths is per-PC and gitignored. Delete it (or run the setup flow)
rem if a tool moves. Exit code 1 = the requested tool is missing.
rem Intentionally NO setlocal: results must land in the caller's environment.
rem ===========================================================================
set "_FT_WANT=%~1"
if "%_FT_WANT%"=="" set "_FT_WANT=all"
set "_FT_CFG=%~dp0..\.toolpaths"
set "_FT_PREFIXES=riscv32-unknown-elf- riscv64-zephyr-elf- riscv64-unknown-elf- riscv-none-elf-"

rem ---- 1. load saved answers (validated - stale entries are ignored) -------
if exist "%_FT_CFG%" (
  for /f "usebackq tokens=1,* delims==" %%a in ("%_FT_CFG%") do (
    if /i "%%a"=="VIVADO_BAT"     if not defined VIVADO_BAT     set "VIVADO_BAT=%%b"
    if /i "%%a"=="RISCV_GCC_HOME" if not defined RISCV_GCC_HOME set "RISCV_GCC_HOME=%%b"
  )
)
if defined VIVADO_BAT     if not exist "%VIVADO_BAT%" set "VIVADO_BAT="
if defined RISCV_GCC_HOME call :gcc_validate

set "_FT_RC=0"
if /i not "%_FT_WANT%"=="gcc"    call :find_vivado
if /i not "%_FT_WANT%"=="vivado" call :find_gcc
call :save_cfg
set "_FT_WANT=" & set "_FT_CFG=" & set "_FT_IN=" & set "_FT_BIN="
set "_FT_PREFIXES=" & set "_FT_WSL=" & set "_FT_HOME="
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
  for /d %%v in ("%%d:\Xilinx\Vivado\*")    do if exist "%%v\bin\vivado.bat"        set "VIVADO_BAT=%%v\bin\vivado.bat"
  for /d %%v in ("%%d:\AMD\Vivado\*")       do if exist "%%v\bin\vivado.bat"        set "VIVADO_BAT=%%v\bin\vivado.bat"
  for /d %%v in ("%%d:\AMD\*")              do if exist "%%v\Vivado\bin\vivado.bat" set "VIVADO_BAT=%%v\Vivado\bin\vivado.bat"
  for /d %%v in ("%%d:\Xilinx\*")           do if exist "%%v\Vivado\bin\vivado.bat" set "VIVADO_BAT=%%v\Vivado\bin\vivado.bat"
  for /d %%v in ("%%d:\AMDDesignTools\*")   do if exist "%%v\Vivado\bin\vivado.bat" set "VIVADO_BAT=%%v\Vivado\bin\vivado.bat"
)
if defined VIVADO_BAT exit /b 0

rem 5. ask the user (blank answer or non-interactive stdin -> give up)
echo.
echo Vivado was not found automatically (PATH, C..G: \Xilinx\, \AMD\, \AMDDesignTools\).
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

rem 3. PATH (any known prefix; derive the root from <root>\bin\<prefix>gcc.exe)
for %%p in (%_FT_PREFIXES%) do if not defined RISCV_GCC_HOME for /f "delims=" %%q in ('where %%pgcc.exe 2^>nul') do call :gcc_from_exe "%%q" "%%p"
if defined RISCV_GCC_HOME exit /b 0

rem 4. common install roots, every drive + user profile
for %%d in (C D E F G) do (
  call :gcc_probe_root "%%d:\FPGA\zephyr-sdk\gnu\riscv64-zephyr-elf"
  for /d %%v in ("%%d:\zephyr-sdk*")             do call :gcc_probe_root "%%v\gnu\riscv64-zephyr-elf"
  for /d %%v in ("%%d:\lowrisc-toolchain*")      do call :gcc_probe_root "%%v"
  for /d %%v in ("%%d:\FPGA\lowrisc-toolchain*") do call :gcc_probe_root "%%v"
  for /d %%v in ("%%d:\xpack-riscv-none-elf-gcc*")      do call :gcc_probe_root "%%v"
  for /d %%v in ("%%d:\FPGA\xpack-riscv-none-elf-gcc*") do call :gcc_probe_root "%%v"
)
for /d %%v in ("%USERPROFILE%\zephyr-sdk*")        do call :gcc_probe_root "%%v\gnu\riscv64-zephyr-elf"
for /d %%v in ("%USERPROFILE%\lowrisc-toolchain*") do call :gcc_probe_root "%%v"
for /d %%v in ("%USERPROFILE%\xpack-riscv-none-elf-gcc*") do call :gcc_probe_root "%%v"
if defined RISCV_GCC_HOME exit /b 0

rem 4b. inside WSL - the lowRISC toolchain tar.xz ships Linux binaries only
call :gcc_probe_wsl
if defined RISCV_GCC_HOME exit /b 0

rem 5. ask - but only when gcc was explicitly requested ('all' = warn later)
if /i "%_FT_WANT%"=="all" exit /b 0
echo.
echo RISC-V GCC was not found automatically (install roots, PATH, WSL).
echo Install per docs\FREERTOS_PORT.md, or point me at an existing one.
set "_FT_IN="
set /p _FT_IN=Enter the toolchain root (contains bin\<prefix>gcc.exe), blank to abort:
if not defined _FT_IN set "_FT_RC=1" & exit /b 1
call :gcc_probe_root "%_FT_IN%"
if defined RISCV_GCC_HOME (
  echo Saved. Future scripts will use it automatically.
  exit /b 0
)
echo ERROR: no bin\^<prefix^>gcc.exe under "%_FT_IN%" (prefixes: %_FT_PREFIXES%).
set "_FT_RC=1"
exit /b 1

:gcc_from_exe
if defined RISCV_GCC_HOME exit /b 0
for %%i in ("%~dp1..") do set "RISCV_GCC_HOME=%%~fi"
set "RISCV_PREFIX=%~2"
exit /b 0

:gcc_probe_root
rem sets RISCV_GCC_HOME + RISCV_PREFIX when %1 holds bin\<any prefix>gcc.exe
if defined RISCV_GCC_HOME exit /b 0
for %%p in (%_FT_PREFIXES%) do if not defined RISCV_GCC_HOME if exist "%~1\bin\%%pgcc.exe" (
  set "RISCV_GCC_HOME=%~f1"
  set "RISCV_PREFIX=%%p"
)
exit /b 0

:gcc_probe_wsl
where wsl.exe >nul 2>nul
if errorlevel 1 exit /b 0
set "_FT_WSL="
for /f "delims=" %%w in ('wsl -e sh -c "for d in /opt/lowrisc-toolchain* /opt/riscv* /tools/riscv /tools/lowrisc-toolchain* $HOME/lowrisc-toolchain*; do if [ -x $d/bin/riscv32-unknown-elf-gcc ]; then echo $d; exit 0; fi; done" 2^>nul') do if not defined _FT_WSL set "_FT_WSL=%%w"
if not defined _FT_WSL exit /b 0
if not "%_FT_WSL:~0,1%"=="/" exit /b 0
set "RISCV_GCC_HOME=wsl:%_FT_WSL%"
set "RISCV_PREFIX=riscv32-unknown-elf-"
exit /b 0

:gcc_validate
rem re-checks a saved/env RISCV_GCC_HOME; clears it (and the prefix) if stale
set "_FT_HOME=%RISCV_GCC_HOME%"
set "RISCV_GCC_HOME=" & set "RISCV_PREFIX="
if "%_FT_HOME:~0,4%"=="wsl:" (
  wsl -e test -x "%_FT_HOME:~4%/bin/riscv32-unknown-elf-gcc" >nul 2>nul
  if not errorlevel 1 set "RISCV_GCC_HOME=%_FT_HOME%" & set "RISCV_PREFIX=riscv32-unknown-elf-"
  exit /b 0
)
call :gcc_probe_root "%_FT_HOME%"
exit /b 0

rem ===========================================================================
:save_cfg
if not defined VIVADO_BAT if not defined RISCV_GCC_HOME exit /b 0
> "%_FT_CFG%" (
  if defined VIVADO_BAT     echo VIVADO_BAT=%VIVADO_BAT%
  if defined RISCV_GCC_HOME echo RISCV_GCC_HOME=%RISCV_GCC_HOME%
  if defined RISCV_PREFIX   echo RISCV_PREFIX=%RISCV_PREFIX%
)
exit /b 0
