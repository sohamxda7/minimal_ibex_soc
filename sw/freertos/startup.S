/*
 * Startup + interrupt vector table for FreeRTOS on the minimal Ibex SoC.
 *
 * Boot contract (docs/ASIC_SPEC.md section 4): the boot ROM (or the SRAM
 * trampoline in simulation) jumps to _start, which is the FIRST word of the
 * firmware image in the XIP window (0x2040_0000 on the Arty = flash offset
 * 0x40_0000, behind the bitstream).
 *
 * Ibex ONLY supports vectored interrupt mode: mtvec is 256-byte aligned and
 * interrupt cause i traps to base + 4*i; exceptions trap to base + 0. So we
 * cannot point mtvec at freertos_risc_v_trap_handler directly (that is the
 * direct-mode pattern). Instead the vector table below routes:
 *   base + 0        -> freertos_risc_v_exception_handler   (incl. ecall = yield)
 *   base + 4*7      -> freertos_risc_v_mtimer_interrupt_handler (tick)
 *   everything else -> freertos_risc_v_interrupt_handler   (ext/fast IRQs)
 * These per-cause entry points are provided by the FreeRTOS V11 RISC-V port
 * (vendor/freertos_kernel/portable/GCC/RISC-V/portASM.S) exactly for
 * vectored-mode CPUs like Ibex.
 */

    .section .text.start, "ax"
    .global _start
_start:
    /* Stack for startup + main() (tasks get heap stacks later) */
    la   sp, __stack_top

    /* Vectored trap base (Ibex hard-wires mtvec[1:0] = 01 = vectored) */
    la   t0, freertos_vector_table
    csrw mtvec, t0

    /* Re-arm the warm-reset path. The boot ROM jumps to SRAM+0x80 on EVERY
       reset (ck_rst warm resets included, not just reconfiguration), so a
       valid XIP trampoline must live there at all times. The linker keeps
       SRAM+0x00..0x8F out of .data/.bss; writing it here makes the image
       self-healing even after a DV program has occupied SRAM. */
    lui  t0, 0x102          /* t0 = 0x00102000 (SRAM base)               */
    li   t1, 0x204002b7     /* lui  t0, 0x20400                          */
    sw   t1, 0x80(t0)
    li   t2, 0x00028067     /* jalr zero, t0, 0  -> XIP entry 0x20400000 */
    sw   t2, 0x84(t0)

    /* Copy .data image from flash to SRAM */
    la   t0, __data_load_start
    la   t1, __data_start
    la   t2, __data_end
1:  bgeu t1, t2, 2f
    lw   t3, 0(t0)
    sw   t3, 0(t1)
    addi t0, t0, 4
    addi t1, t1, 4
    j    1b
2:
    /* Zero .bss */
    la   t1, __bss_start
    la   t2, __bss_end
3:  bgeu t1, t2, 4f
    sw   zero, 0(t1)
    addi t1, t1, 4
    j    3b
4:
    call main

hang:                       /* main() must not return */
    j    hang

/* ---------------------------------------------------------------------------
 * Vector table: 32 entries, 256-byte aligned (Ibex requirement).
 * Entry index = mcause exception code for interrupts.
 */
    .section .vectors, "ax"
    .align 8
    .global freertos_vector_table
freertos_vector_table:
    j freertos_risc_v_exception_handler         /*  0: exceptions + ecall     */
    j freertos_risc_v_interrupt_handler         /*  1: supervisor sw (n/a)    */
    j freertos_risc_v_interrupt_handler         /*  2:                        */
    j freertos_risc_v_interrupt_handler         /*  3: machine software       */
    j freertos_risc_v_interrupt_handler         /*  4:                        */
    j freertos_risc_v_interrupt_handler         /*  5:                        */
    j freertos_risc_v_interrupt_handler         /*  6:                        */
    j freertos_risc_v_mtimer_interrupt_handler  /*  7: machine timer -> tick  */
    j freertos_risc_v_interrupt_handler         /*  8:                        */
    j freertos_risc_v_interrupt_handler         /*  9:                        */
    j freertos_risc_v_interrupt_handler         /* 10:                        */
    j freertos_risc_v_interrupt_handler         /* 11: machine external       */
    j freertos_risc_v_interrupt_handler         /* 12:                        */
    j freertos_risc_v_interrupt_handler         /* 13:                        */
    j freertos_risc_v_interrupt_handler         /* 14:                        */
    j freertos_risc_v_interrupt_handler         /* 15:                        */
    j freertos_risc_v_interrupt_handler         /* 16: fast[0] = UART1        */
    j freertos_risc_v_interrupt_handler         /* 17: fast[1] = UART2 RX     */
    j freertos_risc_v_interrupt_handler         /* 18: fast[2]                */
    j freertos_risc_v_interrupt_handler         /* 19: fast[3]                */
    j freertos_risc_v_interrupt_handler         /* 20: fast[4]                */
    j freertos_risc_v_interrupt_handler         /* 21: fast[5]                */
    j freertos_risc_v_interrupt_handler         /* 22: fast[6]                */
    j freertos_risc_v_interrupt_handler         /* 23: fast[7]                */
    j freertos_risc_v_interrupt_handler         /* 24: fast[8]                */
    j freertos_risc_v_interrupt_handler         /* 25: fast[9]                */
    j freertos_risc_v_interrupt_handler         /* 26: fast[10]               */
    j freertos_risc_v_interrupt_handler         /* 27: fast[11]               */
    j freertos_risc_v_interrupt_handler         /* 28: fast[12]               */
    j freertos_risc_v_interrupt_handler         /* 29: fast[13]               */
    j freertos_risc_v_interrupt_handler         /* 30: fast[14]               */
    j freertos_risc_v_interrupt_handler         /* 31: NMI (base + 0x7C)      */
