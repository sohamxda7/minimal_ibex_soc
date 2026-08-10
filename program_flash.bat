@echo off
rem Program bitstream + XIP firmware into the Arty's QSPI flash.
rem Usage: program_flash.bat [firmware.bin]   (default: FreeRTOS demo)
call C:\AMD\2026.1\Vivado\bin\vivado.bat -mode batch -nojournal -log build\fpga\program_flash.log -source program_flash.tcl -tclargs %*
