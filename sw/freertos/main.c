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

#include "drivers/spi_bus.h"
#include "drivers/esp_at.h"

/* Heap lives in .noinit: not zeroed at boot (see FreeRTOSConfig.h). */
uint8_t ucHeap[ configTOTAL_HEAP_SIZE ]
    __attribute__( ( aligned( portBYTE_ALIGNMENT ), section( ".noinit" ) ) );

#ifdef SIM_BUILD
#define REPORT_PERIOD_TICKS   1
#define RGB_PERIOD_TICKS      1
#define STEP_FAST             1
#define STEP_MED              2
#define STEP_SLOW             4
#else
#define REPORT_PERIOD_TICKS   pdMS_TO_TICKS( 1000 )
#define RGB_PERIOD_TICKS      pdMS_TO_TICKS( 50 )
#define STEP_FAST             pdMS_TO_TICKS( 50 )    /* asm-demo speeds */
#define STEP_MED              pdMS_TO_TICKS( 150 )
#define STEP_SLOW             pdMS_TO_TICKS( 400 )
#endif

/* ---- unified console state (the old asm-demo command set, now in the
 * one-and-only FreeRTOS firmware) ------------------------------------------ */
static volatile uint8_t    g_mode = 1;              /* patterns 1..4          */
static volatile TickType_t g_step = 0;              /* set in main            */
static volatile int8_t     g_rgb  = -1;             /* -1 auto; 0 R,1 G,2 B,3 W */

/* LED patterns on gp_o[7:4]; while any button is held, mirror the switches
 * (SW = gp_i[7:4], BTN = gp_i[3:0], debounced register). */
static void prvBlinkyTask( void * pvParameters )
{
    uint32_t ulPat = 1, ulCnt = 0, ulNib;

    ( void ) pvParameters;

    for( ; ; )
    {
        uint32_t ulIn = soc_read32( GPIO_IN_DBNC_REG );

        if( ulIn & 0x0Fu )                       /* button held: mirror SW  */
        {
            ulNib = ( ulIn >> 4 ) & 0xFu;
        }
        else
        {
            switch( g_mode )
            {
                default:
                case 1: ulPat = ( ( ulPat << 1 ) | ( ulPat >> 3 ) ) & 0xFu;
                        ulNib = ulPat; break;    /* walking                 */
                case 2: ulPat = ( ~ulPat ) & 0xFu;
                        ulNib = ulPat; break;    /* nibble flip             */
                case 3: ulPat = ( ulPat == 0xAu ) ? 0x5u : 0xAu;
                        ulNib = ulPat; break;    /* alternating A/5         */
                case 4: ulCnt++; ulNib = ulCnt & 0xFu; break; /* binary     */
            }
        }

        gpio_out_update( GPIO_LED_MASK, ulNib << GPIO_LED_SHIFT );
        vTaskDelay( g_step );
    }
}

/* RGB LED0 via PWM ch0..2 (0=Blue 1=Green 2=Red): brightness breathes;
 * colour auto-cycles unless forced by r/g/b/w. */
static void prvRgbTask( void * pvParameters )
{
    uint32_t ulBri = 0, ulDir = 1, ulHue = 0, ulTick = 0;

    ( void ) pvParameters;

    for( int i = 0; i < 3; i++ )
    {
        soc_write32( PWM_CH_MAX( i ), 255 );
    }

    for( ; ; )
    {
        if( ulDir ) { ulBri += 8; if( ulBri >= 248 ) ulDir = 0; }
        else        { ulBri -= 8; if( ulBri <= 8 )   ulDir = 1; }

        if( ( g_rgb < 0 ) && ( ( ++ulTick & 0x3Fu ) == 0 ) )
        {
            ulHue = ( ulHue + 1 ) % 3;           /* auto colour cycle       */
        }

        for( int i = 0; i < 3; i++ )
        {
            uint32_t on;
            if( g_rgb == 3 )      on = 1;                        /* white  */
            else if( g_rgb >= 0 ) on = ( ( 2 - i ) == g_rgb );   /* forced */
            else                  on = ( ( uint32_t ) i == ulHue );
            soc_write32( PWM_CH_PULSE( i ), on ? ulBri : 0 );
        }

        vTaskDelay( RGB_PERIOD_TICKS );
    }
}

/* The PuTTY command console - the asm demo's interface, verbatim:
 * 1-4 patterns, f/m/s speed, r/g/b/w force colour, a auto, else echo. */
static void prvConsoleTask( void * pvParameters )
{
    ( void ) pvParameters;

    for( ; ; )
    {
        int c = uart_getc_nonblock();

        if( c < 0 )
        {
            vTaskDelay( 1 );
            continue;
        }

        switch( c )
        {
            case '1': case '2': case '3': case '4':
                g_mode = ( uint8_t ) ( c - '0' ); break;
            case 'f': g_step = STEP_FAST;   break;
            case 'm': g_step = STEP_MED;    break;
            case 's': g_step = STEP_SLOW;   break;
            case 'r': g_rgb = 0;  break;
            case 'g': g_rgb = 1;  break;
            case 'b': g_rgb = 2;  break;
            case 'w': g_rgb = 3;  break;
            case 'a': g_rgb = -1; break;
            default: break;
        }

        uart_putc( ( char ) c );                 /* echo-ack, as before     */
    }
}

#ifdef TOY_DEMO

#include "drivers/i2c.h"
#include "drivers/bme280.h"
#include "drivers/ssd1306.h"
#include "drivers/st7735.h"

/* The "toy interfacing" final test (docs/PRODUCTION_PERIPHERALS.md sec. 8): LCD banner over
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

    g_step = STEP_MED;

    xTaskCreate( prvBlinkyTask, "blink", configMINIMAL_STACK_SIZE, NULL, 1, NULL );
    xTaskCreate( prvRgbTask, "rgb", 100, NULL, 1, NULL );
    xTaskCreate( prvConsoleTask, "console", 120, NULL, 2, NULL );
    xTaskCreate( prvReportTask, "report", 120, NULL, 2, NULL );
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
 * freertos_risc_v_interrupt_handler / vector table in startup.S), with full
 * context saved - FromISR APIs and vTaskSwitchContext are legal here.
 * Fast IRQ 1 (mcause 17) = UART2 RX, unmasked only by esp_at_init(). */
void freertos_risc_v_application_interrupt_handler( void )
{
    uint32_t cause;

    __asm__ volatile ( "csrr %0, mcause" : "=r" ( cause ) );

    if( ( cause & 0x1Fu ) == 17u )
    {
        esp_at_isr();
        return;
    }

    uart_puts( "IRQ?\r\n" );             /* breadcrumb: nothing else enabled */
}

void freertos_risc_v_application_exception_handler( void )
{
    uart_puts( "EXC?\r\n" );

    for( ; ; )
    {
    }
}
