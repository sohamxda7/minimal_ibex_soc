# Prebuilt FreeRTOS firmware

`freertos_demo.bin` is a **committed, ready-to-flash** build of the standard
unified firmware (console + LED/RGB/switch control + tick reports), so that
lab machines **without the RISC-V GCC toolchain** can still run the full
Phase-1 hardware validation:

```
ibex_soc.bat  ->  Flash to Board (QSPI)
```

(CLI: `powershell -File scripts\flows.ps1 flashfw`) automatically falls
back to this file when the local firmware build fails
(no toolchain). You will see a loud `USING PREBUILT FIRMWARE` warning —
that is fine for board bring-up and IO testing.

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

Only the standard demo is prebuilt. The `toy` variant needs the purchased
Phase-2 hardware wired anyway, so it always requires a local toolchain.
