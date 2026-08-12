@echo off
rem One click: generate the Vivado GUI project (.xpr) for browsing.
rem The official build stays build_fpga.bat (batch flow).
setlocal
call "%~dp0scripts\find_tools.cmd" vivado
if not defined VIVADO_BAT ( echo ERROR: Vivado not found - run setup_check.bat & pause & exit /b 1 )
cd /d "%~dp0"
call "%VIVADO_BAT%" -mode batch -nojournal -log build\gen_project.log -source gen_project.tcl
pause
