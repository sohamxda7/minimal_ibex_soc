@echo off
rem =========================================================================
rem Environment doctor - one click, changes nothing, tells you exactly what
rem is missing and how to fix it before you try to build anything.
rem Documented in docs/WALKTHROUGH.md ("Start here" flow).
rem =========================================================================
setlocal EnableDelayedExpansion
cd /d "%~dp0"
set FAIL=0
echo ============================================================
echo  minimal-ibex-soc environment check
echo ============================================================
echo.

rem ---- 1. Vivado + RISC-V GCC via the shared locator ----------------------
rem (.toolpaths -> env -> PATH -> all-drive scan -> ask-and-save)
call "%~dp0scripts\find_tools.cmd" all
if defined VIVADO_BAT (
    echo [OK]   Vivado:            !VIVADO_BAT!
) else (
    echo [FAIL] Vivado not found anywhere ^(PATH, all drives^) and no path given.
    echo        Install Vivado ML Standard ^(free^) with Artix-7 support and
    echo        cable drivers ^(docs/WALKTHROUGH.md section 2^), or re-run this
    echo        script and type the install dir when asked.
    set FAIL=1
)

rem ---- 2. Python 3 --------------------------------------------------------
python --version >nul 2>&1
if not errorlevel 1 (
    for /f "tokens=*" %%p in ('python --version 2^>^&1') do echo [OK]   Python:            %%p
) else (
    echo [FAIL] python not on PATH. Install Python 3 ^(python.org or Store^)
    echo        and reopen this window.
    set FAIL=1
)

rem ---- 3. RISC-V GCC (needed only for FreeRTOS / C firmware) --------------
if defined RISCV_GCC_HOME (
    echo [OK]   RISC-V GCC:        %RISCV_GCC_HOME%\bin
) else (
    echo [WARN] RISC-V GCC not found ^(PATH, zephyr-sdk locations on all drives^).
    echo        Only needed for FreeRTOS/C firmware ^(the asm demo needs no
    echo        toolchain^). Install per docs/FREERTOS_PORT.md, or run
    echo        sw\freertos\build.bat which will ask for the path and save it.
)

rem ---- 4. Git -------------------------------------------------------------
git --version >nul 2>&1
if not errorlevel 1 (
    for /f "tokens=*" %%g in ('git --version') do echo [OK]   Git:               %%g
) else (
    echo [WARN] git not on PATH - fine for building, needed for contributing.
)

rem ---- 5. Repo location sanity -------------------------------------------
echo %CD%| findstr /i "OneDrive" >nul
if not errorlevel 1 (
    echo [FAIL] Repo is inside OneDrive: %CD%
    echo        Vivado breaks on synced/spaced paths. Move to C:\FPGA\.
    set FAIL=1
) else (
    echo %CD%| findstr /C:" " >nul
    if not errorlevel 1 (
        echo [FAIL] Repo path contains spaces: %CD%
        echo        Move to a space-free path like C:\FPGA\minimal-ibex-soc.
        set FAIL=1
    ) else (
        echo [OK]   Repo path:         %CD%
    )
)

rem ---- 6. Board (optional) ------------------------------------------------
where /q pnputil && (
    pnputil /enum-devices /connected 2>nul | findstr /i "FT2232 Digilent" >nul
    if not errorlevel 1 (
        echo [OK]   Board:             Digilent/FTDI device detected
    ) else (
        echo [INFO] Board:             not detected ^(fine if not plugged in^)
    )
)

echo.
if "%FAIL%"=="1" (
    echo RESULT: FIX THE [FAIL] ITEMS ABOVE, then re-run this script.
) else (
    echo RESULT: environment ready. Next: build_fpga.bat, or run_regression.bat
    echo         for the full simulation suite. See docs/README.md.
)
echo ============================================================
pause
