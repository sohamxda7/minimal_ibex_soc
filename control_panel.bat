@echo off
rem One click: the Windows GUI control panel (setup, build, program, flash,
rem regression, docs, live logs). Windows-only by design.
start "" powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0gui\ibex_control_panel.ps1"
