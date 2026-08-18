/*
 * Linker script: FreeRTOS on the minimal Ibex SoC, ASIC-representative
 * configuration (docs/ASIC_SPEC.md):
 *
 *   FLASH  = XIP window at 0x2040_0000 (Arty onboard QSPI flash, firmware at
 *            flash offset 0x40_0000 behind the ~3.7 MB A7-100T bitstream).
 *            Code + constants execute/read in place, ~read-only, slow.
 *   RAM    = the entire 8 KiB SRAM (0x0010_2000). Data, BSS, heap, stacks.
 *
 * SRAM+0x00..0x8F is RESERVED (kept out of RAM below): the boot ROM jumps
 * to the trampoline at SRAM+0x80 on EVERY reset, not just the first one.
 * The original layout let .bss overwrite it ("served its purpose by then"),
 * which made any warm reset (e.g. the Arty's ck_rst glitching when a serial
 * program closes the port) a crash-loop until reconfiguration - found on
 * hardware 2026-08-18. startup.S also re-writes the trampoline at boot
 * (self-healing after an SRAM-resident DV program has replaced it).
 */

OUTPUT_ARCH( "riscv" )
ENTRY( _start )

MEMORY
{
  FLASH (rx)  : ORIGIN = 0x20400000, LENGTH = 4M
  RAM   (rwx) : ORIGIN = 0x00102090, LENGTH = 8K - 0x90
}

SECTIONS
{
  /* _start must be the first word of the flash image: the boot trampoline
     jumps blindly to 0x20400000. */
  .text :
  {
    KEEP(*(.text.start))
    *(.vectors)
    *(.text .text.*)
  } > FLASH

  .rodata :
  {
    *(.rodata .rodata.*)
    *(.srodata .srodata.*)
  } > FLASH

  . = ALIGN(4);
  __data_load_start = LOADADDR(.data);

  .data :
  {
    . = ALIGN(4);
    __data_start = .;
    *(.data .data.*)
    *(.sdata .sdata.*)
    . = ALIGN(4);
    __data_end = .;
  } > RAM AT > FLASH

  .bss (NOLOAD) :
  {
    . = ALIGN(4);
    __bss_start = .;
    *(.bss .bss.*)
    *(.sbss .sbss.*)
    *(COMMON)
    . = ALIGN(4);
    __bss_end = .;
  } > RAM

  /* Not zeroed at boot: the FreeRTOS heap (heap_4 initialises itself). */
  .noinit (NOLOAD) :
  {
    . = ALIGN(16);
    *(.noinit .noinit.*)
  } > RAM

  /* Startup/main() stack: everything from end of .bss to the top of SRAM.
     After vTaskStartScheduler() this region is dead (tasks run on heap
     stacks, ISRs on the static xISRStack), so it doubles as headroom. */
  __stack_top = ORIGIN(RAM) + LENGTH(RAM);

  PROVIDE(__freertos_irq_stack_top = __stack_top); /* not used; port has xISRStack */

  /DISCARD/ : { *(.eh_frame .eh_frame_hdr) }
}
