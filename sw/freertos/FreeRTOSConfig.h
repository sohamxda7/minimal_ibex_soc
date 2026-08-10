/*
 * FreeRTOS configuration for the minimal Ibex SoC (docs/ASIC_SPEC.md).
 *
 * Sized for the ASIC-representative build: 8 KiB SRAM total, code XIP from
 * SPI flash. Every byte of RAM is accounted for -- see docs/FREERTOS_PORT.md
 * for the budget table before touching heap/stack numbers.
 *
 * SIM_BUILD: compiled into the simulation image (dv/xsim/tb_freertos.sv).
 * XIP instruction fetch takes ~6.4 us/word in sim (CLK_DIV=1), so the sim
 * variant runs a faster tick and 1-tick delays to finish in bounded time.
 */

#ifndef FREERTOS_CONFIG_H
#define FREERTOS_CONFIG_H

/* --- Ibex SoC hardware ---------------------------------------------------- */
/* CLINT-style machine timer: mtime @ +0/+4, mtimecmp @ +8/+12 */
#define configMTIME_BASE_ADDRESS        ( 0x40000200UL )
#define configMTIMECMP_BASE_ADDRESS     ( 0x40000208UL )
#define configCPU_CLOCK_HZ              ( 20000000UL )

/* --- Scheduler ------------------------------------------------------------ */
#define configUSE_PREEMPTION            1
#define configUSE_TIME_SLICING          1
#ifdef SIM_BUILD
#define configTICK_RATE_HZ              ( 200 )
#else
#define configTICK_RATE_HZ              ( 20 )   /* XIP ISR path is slow; keep tick coarse */
#endif
#define configMAX_PRIORITIES            ( 4 )
#define configMINIMAL_STACK_SIZE        ( 110 )  /* words; idle task */
#define configMAX_TASK_NAME_LEN         ( 8 )
#define configTICK_TYPE_WIDTH_IN_BITS   TICK_TYPE_WIDTH_32_BITS
#define configIDLE_SHOULD_YIELD         1

/* --- Memory: the 8 KiB budget --------------------------------------------- */
#define configSUPPORT_STATIC_ALLOCATION  0
#define configSUPPORT_DYNAMIC_ALLOCATION 1
#define configTOTAL_HEAP_SIZE           ( 4096 )  /* heap_4: TCBs + task stacks */
/* We place ucHeap in .noinit ourselves (main.c): heap_4 builds its own free
 * list, so zeroing it in crt0 would only burn ~20 ms of XIP fetches. */
#define configAPPLICATION_ALLOCATED_HEAP 1
#define configISR_STACK_SIZE_WORDS      ( 128 )   /* 512 B, static in .bss */
#define configCHECK_FOR_STACK_OVERFLOW  0         /* saves the 0xa5 stack fill; revisit on hw */
#define configUSE_MALLOC_FAILED_HOOK    0

/* --- Features off to save flash/RAM --------------------------------------- */
#define configUSE_IDLE_HOOK             0
#define configUSE_TICK_HOOK             0
#define configUSE_MUTEXES               0
#define configUSE_RECURSIVE_MUTEXES     0
#define configUSE_COUNTING_SEMAPHORES   0
#define configQUEUE_REGISTRY_SIZE       0
#define configUSE_QUEUE_SETS            0
#define configUSE_TRACE_FACILITY        0
#define configUSE_STATS_FORMATTING_FUNCTIONS 0
#define configGENERATE_RUN_TIME_STATS   0
#define configUSE_CO_ROUTINES           0
#define configUSE_TIMERS                0
#define configUSE_TASK_NOTIFICATIONS    1

/* --- API inclusions ------------------------------------------------------- */
#define INCLUDE_vTaskPrioritySet        0
#define INCLUDE_uxTaskPriorityGet       0
#define INCLUDE_vTaskDelete             0
#define INCLUDE_vTaskSuspend            0
#define INCLUDE_vTaskDelayUntil         1
#define INCLUDE_vTaskDelay              1
#define INCLUDE_xTaskGetSchedulerState  1

/* --- Diagnostics ---------------------------------------------------------- */
void vAssertCalled( unsigned long ulLine );
#define configASSERT( x )  if( ( x ) == 0 ) vAssertCalled( __LINE__ )

#endif /* FREERTOS_CONFIG_H */
