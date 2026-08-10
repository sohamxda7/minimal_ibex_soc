/*
 * Audio path (v1.1): MCP3202 SPI ADC (mic via MAX9814 preamp) in,
 * PWM channel 3 (SPKR pad -> PAM8302 amplifier) out. Bulk clips live in
 * external PSRAM - 8 KiB SRAM never holds more than a bounce buffer.
 *
 * Rates are vTaskDelay-paced -> capped by the tick (20 Hz hw / 200 Hz sim);
 * good for level metering, clip capture at low rates, and tones. True
 * 8 kHz streaming needs an mtime-based busy pacer - documented as the
 * hardware-bring-up follow-up in docs/PRODUCTION_PERIPHERALS.md.
 * Validated against mcp3202_model in tb_audio (sample ramp + PWM checks).
 */

#include "FreeRTOS.h"
#include "task.h"

#include "soc.h"
#include "drivers/spi_bus.h"
#include "drivers/psram.h"
#include "audio.h"

/* One MCP3202 conversion: 3-byte SPI session, 12-bit result.
 * Byte stream (model + datasheet single-ended ch0): resp[1] low nibble =
 * sample[11:8], resp[2] = sample[7:0]. */
uint16_t audio_mic_sample( void )
{
    uint8_t b1, b2;

    spi_bus_lock();
    gpio_out_update( GPO_ADC_CS, 0 );

    ( void ) spi_bus_xfer( 0x01 );        /* start bit                */
    b1 = spi_bus_xfer( 0xA0 );            /* single-ended ch0, MSBF   */
    b2 = spi_bus_xfer( 0x00 );

    gpio_out_update( GPO_ADC_CS, GPO_ADC_CS );
    spi_bus_unlock();

    return ( uint16_t ) ( ( ( b1 & 0x0Fu ) << 8 ) | b2 );
}

/* Record n 8-bit samples (12-bit >> 4) into PSRAM at rate_hz (tick-paced). */
void audio_record( uint32_t psram_addr, uint32_t n, uint32_t rate_hz )
{
    TickType_t period = configTICK_RATE_HZ / ( rate_hz ? rate_hz : 1u );

    if( period == 0u ) period = 1u;

    for( uint32_t i = 0; i < n; i++ )
    {
        uint8_t s = ( uint8_t ) ( audio_mic_sample() >> 4 );

        psram_write( psram_addr + i, &s, 1 );
        vTaskDelay( period );
    }
}

/* Play n 8-bit samples from PSRAM through the speaker PWM (tick-paced). */
void audio_play( uint32_t psram_addr, uint32_t n, uint32_t rate_hz )
{
    TickType_t period = configTICK_RATE_HZ / ( rate_hz ? rate_hz : 1u );

    if( period == 0u ) period = 1u;

    soc_write32( PWM_CH_MAX( PWM_SPKR_CH ), 255 );

    for( uint32_t i = 0; i < n; i++ )
    {
        uint8_t s;

        psram_read( psram_addr + i, &s, 1 );
        soc_write32( PWM_CH_PULSE( PWM_SPKR_CH ), s );
        vTaskDelay( period );
    }

    soc_write32( PWM_CH_PULSE( PWM_SPKR_CH ), 0 );   /* silence */
}

/* Simple beep: square-ish duty toggle for roughly ms milliseconds. */
void audio_beep( uint32_t ms )
{
    soc_write32( PWM_CH_MAX( PWM_SPKR_CH ), 255 );
    soc_write32( PWM_CH_PULSE( PWM_SPKR_CH ), 128 );
    vTaskDelay( pdMS_TO_TICKS( ms ) );
    soc_write32( PWM_CH_PULSE( PWM_SPKR_CH ), 0 );
}
