@echo off
rem ===========================================================================
rem THE one entry point (double-click me). Opens the Windows GUI that does
rem everything: environment check + tool setup, Vivado .xpr generation,
rem bitstream build, board programming, FreeRTOS firmware + QSPI flashing
rem (works even without a RISC-V toolchain - prebuilt fallback), the full
rem 11-sim regression, docs, and live logs.
rem
rem Command-line equivalents (same flows, no GUI):
rem   powershell -NoProfile -ExecutionPolicy Bypass -File scripts\flows.ps1 <flow>
rem   flows: setup | xpr | build | program | firmware [sim|toy]
rem          flashfw [toy] | flashonly [file.bin] | regression
rem ===========================================================================
start "" powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0gui\ibex_control_panel.ps1"
