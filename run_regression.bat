@echo off
rem One click: full regression - images, compile, all 5 simulations,
rem bitstream, timing check, PASS/FAIL scoreboard. ~45-60 minutes.
rem Log: build\regression.log
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\run_regression.ps1
if errorlevel 1 (
    echo.
    echo REGRESSION HAS FAILURES - see build\regression.log
) else (
    echo.
    echo REGRESSION ALL GREEN
)
pause
