/*
 * FreeRTOS demo for the minimal Ibex SoC -- ASIC-representative build
 * (8 KiB SRAM, code XIP from SPI flash). Two tasks prove preemptive
 * scheduling end to end:
 *
 *   blinky  (prio 1): walks a pattern on LEDs gp_o[7:4] every wake.
 *   report  (prio 2): prints the tick count over the UART every wake.
 *
 * The pre-scheduler banner prints first: if you see the banner but no tick
 * lines, C runtime + XIP are fine and the problem is in interrupts/context
 * switching. That split saved us once already -- keep it.
 */

#include "FreeRTOS.h"
#include "task.h"

#include "soc.h"
#include "uart.h"

/* Heap lives in .noinit: not zeroed at boot (see FreeRTOSConfig.h). */
uint8_t ucHeap[ configTOTAL_HEAP_SIZE ]
    __attribute__( ( aligned( portBYTE_ALIGNMENT ), section( ".noinit" ) ) );

#ifdef SIM_BUILD
#define BLINKY_PERIOD_TICKS   1
#define REPORT_PERIOD_TICKS   1
#else
#define BLINKY_PERIOD_TICKS   pdMS_TO_TICKS( 250 )
#define REPORT_PERIOD_TICKS   pdMS_TO_TICKS( 1000 )
#endif

static void prvBlinkyTask( void * pvParameters )
{
    uint32_t ulPattern = 1;

    ( void ) pvParameters;

    for( ; ; )
    {
        /* Touch only the LED nibble; bits [3:0] belong to the display. */
        uint32_t ulOut = soc_read32( GPIO_OUT_REG ) & ~GPIO_LED_MASK;
        soc_write32( GPIO_OUT_REG, ulOut | ( ( ulPattern & 0xFu ) << GPIO_LED_SHIFT ) );
        ulPattern = ( ulPattern << 1 ) | ( ulPattern >> 3 ); /* rotate 4-bit */
        vTaskDelay( BLINKY_PERIOD_TICKS );
    }
}

#ifdef TOY_DEMO

#include "drivers/i2c.h"
#include "drivers/bme280.h"
#include "drivers/ssd1306.h"
#include "drivers/st7735.h"

/* The "toy interfacing" final test (docs/TOY_INTERFACING.md): LCD banner over
 * SPI, then a BME280 reading every 2 s to UART + OLED. Needs the purchased
 * hardware wired per the doc's tables, so it only runs in TOY_DEMO builds. */
static void prvToyTask( void * pvParameters )
{
    static bme280_t xSensor;          /* static: keep task stack small */
    bme280_reading_t xReading;
    int rcSensor, rcOled;

    ( void ) pvParameters;

    st7735_init();
    st7735_fill_screen( ST7735_RGB( 0, 0, 0 ) );
    st7735_fill_rect( 10, 10, 108, 30, ST7735_RGB( 0xFF, 0x80, 0x00 ) );

    i2c_init();
    rcOled   = ssd1306_init( SSD1306_ADDR );
    rcSensor = bme280_init( &xSensor, BME280_ADDR_PRIMARY );

    uart_puts( "toy: lcd up, oled=" );
    uart_putu32( ( uint32_t ) -rcOled );
    uart_puts( " bme=" );
    uart_putu32( ( uint32_t ) -rcSensor );
    uart_puts( " (0=ok)\r\n" );

    if( rcOled == I2C_OK )
    {
        ssd1306_text( 0, 0, "IBEX SOC + FreeRTOS" );
    }

    for( ; ; )
    {
        if( ( rcSensor == I2C_OK ) && ( bme280_read( &xSensor, &xReading ) == I2C_OK ) )
        {
            uart_puts( "T=" );
            uart_putu32( ( uint32_t ) xReading.temp_centi_c );
            uart_puts( "cC P=" );
            uart_putu32( xReading.press_pa );
            uart_puts( "Pa H=" );
            uart_putu32( xReading.hum_milli_pct );
            uart_puts( "m%\r\n" );

            if( rcOled == I2C_OK )
            {
                char line[ 12 ] = "T=      cC ";
                uint32_t t = ( uint32_t ) xReading.temp_centi_c;
                for( int i = 7; i >= 2 && t != 0u; i-- )
                {
                    line[ i ] = ( char ) ( '0' + ( t % 10u ) );
                    t /= 10u;
                }
                ssd1306_text( 0, 2, line );
            }
        }

        vTaskDelay( pdMS_TO_TICKS( 2000 ) );
    }
}

#endif /* TOY_DEMO */

static void prvReportTask( void * pvParameters )
{
    ( void ) pvParameters;

    for( ; ; )
    {
        uart_puts( "tick=" );
        uart_putu32( ( uint32_t ) xTaskGetTickCount() );
        uart_puts( "\r\n" );
        vTaskDelay( REPORT_PERIOD_TICKS );
    }
}

int main( void )
{
    uart_puts( "FreeRTOS on Ibex (XIP, 8KiB SRAM)\r\n" );

    xTaskCreate( prvBlinkyTask, "blink", configMINIMAL_STACK_SIZE, NULL, 1, NULL );
    xTaskCreate( prvReportTask, "report", 140, NULL, 2, NULL );
#ifdef TOY_DEMO
    xTaskCreate( prvToyTask, "toy", 160, NULL, 1, NULL );
#endif

    vTaskStartScheduler();

    /* Only reachable if the heap could not hold the idle task. */
    uart_puts( "SCHED FAIL\r\n" );

    for( ; ; )
    {
    }

    return 0;
}

/* ---- hooks / diagnostics -------------------------------------------------- */

void vAssertCalled( unsigned long ulLine )
{
    taskDISABLE_INTERRUPTS();
    uart_puts( "ASSERT line " );
    uart_putu32( ( uint32_t ) ulLine );
    uart_puts( "\r\n" );

    for( ; ; )
    {
    }
}

/* The V11 RISC-V port calls this for any non-timer interrupt (routed through
 * freertos_risc_v_interrupt_handler). Nothing to service yet -- the UART fast
 * IRQ is not enabled in mie -- but leave a breadcrumb if one ever fires. */
void freertos_risc_v_application_interrupt_handler( void )
{
    uart_puts( "IRQ?\r\n" );
}

void freertos_risc_v_application_exception_handler( void )
{
    uart_puts( "EXC?\r\n" );

    for( ; ; )
    {
    }
}
