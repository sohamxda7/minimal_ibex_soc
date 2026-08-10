@echo off
rem =========================================================================
rem Build FreeRTOS firmware for the minimal Ibex SoC (XIP + 8 KiB SRAM).
rem
rem Toolchain: the RISC-V GCC that ships inside the Zephyr SDK install at
rem C:\FPGA\zephyr-sdk (kept as our C compiler; see docs/FREERTOS_PORT.md).
rem No make needed -- the file list is short enough to compile in one call.
rem
rem   build.bat           hardware image  -> build\freertos_demo.bin/.vmem
rem   build.bat sim       simulation image (-DSIM_BUILD: fast tick/delays)
rem   build.bat toy       hardware image + toy task (LCD/BME280/OLED wired)
rem =========================================================================
setlocal
rem Toolchain located dynamically (saved .toolpaths -> RISCV_GCC_HOME env ->
rem PATH -> zephyr-sdk scan on all drives -> ask-and-save):
call "%~dp0..\..\scripts\find_tools.cmd" gcc
if not defined RISCV_GCC_HOME (
    echo ERROR: RISC-V GCC not found. Install per docs\FREERTOS_PORT.md,
    echo or re-run and type the toolchain root when asked.
    exit /b 1
)
set GCC=%RISCV_GCC_HOME%\bin\riscv64-zephyr-elf-gcc.exe
set OBJCOPY=%RISCV_GCC_HOME%\bin\riscv64-zephyr-elf-objcopy.exe
set OBJDUMP=%RISCV_GCC_HOME%\bin\riscv64-zephyr-elf-objdump.exe
set HERE=%~dp0
set KERNEL=%HERE%..\..\vendor\freertos_kernel
set PORT=%KERNEL%\portable\GCC\RISC-V

set NAME=freertos_demo
set DEFS=
if "%1"=="sim" (
    set NAME=freertos_demo_sim
    set DEFS=-DSIM_BUILD
)
if "%1"=="toy" (
    set NAME=freertos_demo_toy
    set DEFS=-DTOY_DEMO
)

if not exist "%HERE%build" mkdir "%HERE%build"

"%GCC%" %DEFS% ^
  -march=rv32imc_zicsr -mabi=ilp32 -mcmodel=medany ^
  -Os -g -ffunction-sections -fdata-sections -ffreestanding ^
  -I "%HERE%." -I "%KERNEL%\include" -I "%PORT%" ^
  -I "%PORT%\chip_specific_extensions\RV32I_CLINT_no_extensions" ^
  -T "%HERE%link_xip.ld" -nostartfiles -Wl,--gc-sections ^
  -Wl,-Map="%HERE%build\%NAME%.map" ^
  "%HERE%startup.S" "%HERE%main.c" "%HERE%uart.c" ^
  "%HERE%drivers\i2c.c" "%HERE%drivers\st7735.c" ^
  "%HERE%drivers\bme280.c" "%HERE%drivers\ssd1306.c" ^
  "%KERNEL%\tasks.c" "%KERNEL%\list.c" "%KERNEL%\queue.c" ^
  "%KERNEL%\portable\MemMang\heap_4.c" ^
  "%PORT%\port.c" "%PORT%\portASM.S" ^
  -o "%HERE%build\%NAME%.elf"
if errorlevel 1 exit /b 1

"%OBJCOPY%" -O binary "%HERE%build\%NAME%.elf" "%HERE%build\%NAME%.bin"
"%OBJDUMP%" -h "%HERE%build\%NAME%.elf" > "%HERE%build\%NAME%.sections.txt"
python "%HERE%..\tools\bin2flashvmem.py" "%HERE%build\%NAME%.bin" "%HERE%build\%NAME%_flash.vmem"
if errorlevel 1 exit /b 1

echo.
echo RAM budget (data+bss must fit 8192 bytes together with stacks):
"%OBJDUMP%" -h "%HERE%build\%NAME%.elf" | findstr /i "data bss"
echo BUILD OK: sw\freertos\build\%NAME%_flash.vmem
endlocal
