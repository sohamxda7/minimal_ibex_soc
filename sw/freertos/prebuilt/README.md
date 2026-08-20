# Prebuilt FreeRTOS firmware

`freertos_demo.bin` is a **committed, ready-to-flash** build of THE unified
firmware (console + LED/RGB/switch control + tick reports + the LCD
status screen and sensor support - one image since 2026-08-18), so that
lab machines **without the RISC-V GCC toolchain** can still run the full
Phase-1, Phase-2a and Phase-2b hardware validation:

```
ibex_soc.bat  ->  Flash to Board (QSPI)
```

(CLI: `powershell -File scripts\flows.ps1 flashfw`). The flow is
**build-first**: with no toolchain it offers the automatic GCC install,
and this file is flashed only when you explicitly answer `p` at that
prompt (loud `USING PREBUILT FIRMWARE` notice). Fine for board bring-up
and IO testing.

**When you must NOT rely on it:** if you are changing anything under
`sw/freertos/`, install the toolchain (docs/FREERTOS_PORT.md section 2)
so you flash what you actually edited.

**Regenerating** (maintainers, after any firmware change):

```
sw\freertos\build.bat
copy sw\freertos\build\freertos_demo.bin sw\freertos\prebuilt\freertos_demo.bin
```

then commit with the message noting the source commit. CI-less policy:
whoever changes `sw/freertos/**` refreshes this file in the same PR.

There is only one hardware image (the LCD/sensor task tolerates missing
parts), so this single prebuilt covers everything; only the `sim`
testbench variant is not committed.
