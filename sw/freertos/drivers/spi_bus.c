/*
 * Shared SPI-host bus arbitration + race-safe GPIO output (v1.1).
 *
 * The SPI host is one physical bus shared by three external devices (LCD,
 * PSRAM, mic ADC), each with its own chip-select on gp_o. And gp_o itself
 * is shared state (LEDs, display control, camera lines), so every update
 * must be an atomic read-modify-write. This file owns both problems:
 *
 *   - spi_bus_lock()/unlock(): FreeRTOS mutex around any bus session
 *   - gpio_out_update(): critical-section RMW on GPIO_OUT
 *   - spi_bus_send()/xfer(): byte primitives; xfer returns the received
 *     byte via the v1.1 SPI RX register (FIFO-empty + drain pacing, same
 *     discipline proven in sw/asm-demo/periph_tests.py and tb_psram)
 *
 * Call spi_bus_init() once before the scheduler starts.
 */

#include "FreeRTOS.h"
#include "semphr.h"
#include "task.h"

#include "soc.h"
#include "spi_bus.h"

static SemaphoreHandle_t s_bus_mutex;

void spi_bus_init( void )
{
    s_bus_mutex = xSemaphoreCreateMutex();   /* ~80 B from heap_4 */
    /* Idle all CS lines high before any device sees clock activity. */
    gpio_out_update( GPO_PSRAM_CS | GPO_ADC_CS | GPO_CAM_RRST,
                     GPO_PSRAM_CS | GPO_ADC_CS | GPO_CAM_RRST );
}

void gpio_out_update( uint32_t mask, uint32_t value )
{
    taskENTER_CRITICAL();
    {
        uint32_t out = soc_read32( GPIO_OUT_REG );
        soc_write32( GPIO_OUT_REG, ( out & ~mask ) | ( value & mask ) );
    }
    taskEXIT_CRITICAL();
}

void spi_bus_lock( void )
{
    ( void ) xSemaphoreTake( s_bus_mutex, portMAX_DELAY );
}

void spi_bus_unlock( void )
{
    ( void ) xSemaphoreGive( s_bus_mutex );
}

/* Wait until the TX FIFO is empty, then out-wait the final byte's shift
 * (the empty flag rises when the last byte STARTS shifting). */
static void prv_drain( void )
{
    while( ( soc_read32( SPI_STATUS_REG ) & SPI_STATUS_TX_EMPTY ) == 0u )
    {
    }

    for( volatile int i = 0; i < 30; i++ )
    {
    }
}

void spi_bus_send( uint8_t b )
{
    while( soc_read32( SPI_STATUS_REG ) & SPI_STATUS_TX_FULL )
    {
    }
    soc_write32( SPI_TX_REG, b );
    prv_drain();
}

uint8_t spi_bus_xfer( uint8_t b )
{
    spi_bus_send( b );
    return ( uint8_t ) ( soc_read32( SPI_RX_REG ) & 0xFFu );
}
