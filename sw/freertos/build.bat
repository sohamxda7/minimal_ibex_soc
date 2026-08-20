@echo off
rem =========================================================================
rem Build FreeRTOS firmware for the minimal Ibex SoC (XIP + 8 KiB SRAM).
rem
rem Toolchain: any bare-metal RISC-V GCC, located by scripts\find_tools.cmd
rem (multi-prefix; docs/FREERTOS_PORT.md section 2). Two homes supported:
rem   native  RISCV_GCC_HOME=C:\...        e.g. the Zephyr SDK
rem   WSL     RISCV_GCC_HOME=wsl:/opt/...  e.g. the lowRISC toolchain, whose
rem           tar.xz ships Linux binaries only - the compile runs inside WSL
rem           via build.sh, the vmem/budget steps stay on Windows.
rem No make needed -- the file list is short enough to compile in one call.
rem
rem   build.bat           THE hardware image -> build\freertos_demo.bin/.vmem
rem                       (console + LEDs/RGB + LCD status screen + sensors:
rem                       one image since 2026-08-18 - the LCD task is
rem                       missing-part tolerant, so it ships in every build)
rem   build.bat sim       simulation image (-DSIM_BUILD: fast tick/delays,
rem                       no LCD task - keeps tb_freertos fast)
rem   build.bat toy       accepted alias of the default hardware image
rem =========================================================================
setlocal
rem Toolchain located dynamically (saved .toolpaths -> RISCV_GCC_HOME env ->
rem PATH -> install-root scan on all drives -> WSL -> ask-and-save):
call "%~dp0..\..\scripts\find_tools.cmd" gcc
if not defined RISCV_GCC_HOME (
    echo ERROR: RISC-V GCC not found. Install per docs\FREERTOS_PORT.md,
    echo or re-run and type the toolchain root when asked.
    exit /b 1
)
set HERE=%~dp0
set KERNEL=%HERE%..\..\vendor\freertos_kernel
set PORT=%KERNEL%\portable\GCC\RISC-V

set NAME=freertos_demo
set DEFS=-DTOY_DEMO
set "VARIANT=%1"
if not defined VARIANT set "VARIANT=hw"
if "%VARIANT%"=="sim" (
    set NAME=freertos_demo_sim
    set DEFS=-DSIM_BUILD
)
rem "toy" is an accepted alias of the default: the LCD/sensor task is part
rem of every hardware image (it tolerates missing parts - bounded I2C waits).

rem ---- checkout guard ---------------------------------------------------
rem A half-copied tree otherwise fails as a wall of "No such file or
rem directory" from gcc that names 12 files and explains nothing.
set "MISSING="
for %%f in ("startup.S" "main.c" "uart.c" "soc.h" "FreeRTOSConfig.h" "link_xip.ld" ^
            "drivers\i2c.c" "drivers\st7735.c" "drivers\spi_bus.c" "drivers\psram.c" ^
            "drivers\esp_at.c" "drivers\audio.c" "drivers\camera.c" ^
            "drivers\bme280.c" "drivers\ssd1306.c") do (
    if not exist "%HERE%%%~f" (
        echo ERROR: missing source "%HERE%%%~f"
        set "MISSING=1"
    )
)
if not exist "%KERNEL%\tasks.c" (
    echo ERROR: missing "%KERNEL%\tasks.c" ^(the vendored FreeRTOS kernel^)
    set "MISSING=1"
)
if defined MISSING (
    echo        Incomplete checkout. Restore with:  git checkout -- .
    exit /b 1
)

if not exist "%HERE%build" mkdir "%HERE%build"

rem ---- WSL toolchain: compile via build.sh inside WSL, finish on Windows --
if /i "%RISCV_GCC_HOME:~0,4%"=="wsl:" (
    wsl --cd "%HERE:~0,-1%" -e bash ./build.sh %VARIANT% "%RISCV_GCC_HOME:~4%"
    if errorlevel 1 exit /b 1
    goto :finish
)

rem ---- native toolchain ---------------------------------------------------
if not defined RISCV_PREFIX for %%p in (riscv32-unknown-elf- riscv64-zephyr-elf- riscv64-unknown-elf- riscv-none-elf-) do if not defined RISCV_PREFIX if exist "%RISCV_GCC_HOME%\bin\%%pgcc.exe" set "RISCV_PREFIX=%%p"
if not defined RISCV_PREFIX (
    echo ERROR: no ^<prefix^>gcc.exe under "%RISCV_GCC_HOME%\bin".
    exit /b 1
)
set GCC=%RISCV_GCC_HOME%\bin\%RISCV_PREFIX%gcc.exe
set OBJCOPY=%RISCV_GCC_HOME%\bin\%RISCV_PREFIX%objcopy.exe
set OBJDUMP=%RISCV_GCC_HOME%\bin\%RISCV_PREFIX%objdump.exe

rem Older GCC (e.g. the lowRISC toolchain's 10.2) rejects the modern _zicsr
rem march spelling; there the CSR ops are still part of plain rv32imc.
set MARCH=rv32imc_zicsr
echo int _march_probe; > "%HERE%build\march_probe.c"
"%GCC%" -march=%MARCH% -mabi=ilp32 -c "%HERE%build\march_probe.c" -o "%HERE%build\march_probe.o" >nul 2>nul
if errorlevel 1 set MARCH=rv32imc

"%GCC%" %DEFS% ^
  -march=%MARCH% -mabi=ilp32 -mcmodel=medany ^
  -Os -g -ffunction-sections -fdata-sections -ffreestanding ^
  -I "%HERE%." -I "%KERNEL%\include" -I "%PORT%" ^
  -I "%PORT%\chip_specific_extensions\RV32I_CLINT_no_extensions" ^
  -T "%HERE%link_xip.ld" -nostartfiles -Wl,--gc-sections ^
  -Wl,-Map="%HERE%build\%NAME%.map" ^
  "%HERE%startup.S" "%HERE%main.c" "%HERE%uart.c" ^
  "%HERE%drivers\i2c.c" "%HERE%drivers\st7735.c" ^
  "%HERE%drivers\spi_bus.c" "%HERE%drivers\psram.c" ^
  "%HERE%drivers\esp_at.c" "%HERE%drivers\audio.c" "%HERE%drivers\camera.c" ^
  "%HERE%drivers\bme280.c" "%HERE%drivers\ssd1306.c" ^
  "%KERNEL%\tasks.c" "%KERNEL%\list.c" "%KERNEL%\queue.c" ^
  "%KERNEL%\portable\MemMang\heap_4.c" ^
  "%PORT%\port.c" "%PORT%\portASM.S" ^
  -o "%HERE%build\%NAME%.elf"
if errorlevel 1 exit /b 1

"%OBJCOPY%" -O binary "%HERE%build\%NAME%.elf" "%HERE%build\%NAME%.bin"
"%OBJDUMP%" -h "%HERE%build\%NAME%.elf" > "%HERE%build\%NAME%.sections.txt"

:finish
python "%HERE%..\tools\bin2flashvmem.py" "%HERE%build\%NAME%.bin" "%HERE%build\%NAME%_flash.vmem"
if errorlevel 1 exit /b 1

echo.
echo RAM budget (data+bss must fit 8192 bytes together with stacks):
findstr /i "data bss" "%HERE%build\%NAME%.sections.txt"
echo BUILD OK: sw\freertos\build\%NAME%_flash.vmem
endlocal
