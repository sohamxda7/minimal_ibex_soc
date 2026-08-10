/*
 * ESP32 AT-command client over UART2 (v1.1) - the chip's entire WiFi and
 * internet story. The ESP32 module owns the radio and the TCP/IP stack;
 * this driver sends it text commands and collects replies. Validated
 * against dv/xsim/periph_models.sv:esp32_at_model in tb_wifi.
 *
 * The full ESP-AT command set (CWJAP to join WiFi, CIPSTART/CIPSEND for
 * TCP, HTTPCLIENT, MQTT...) all flows through esp_at_cmd(); the two
 * convenience wrappers here cover bring-up. Replies stream into a small
 * SRAM window; anything bulky (camera upload) goes out with
 * esp_at_send_raw() reading straight from PSRAM.
 */

#include "FreeRTOS.h"
#include "task.h"

#include "soc.h"
#include "drivers/psram.h"
#include "esp_at.h"

static void prv_putc( char c )
{
    while( soc_read32( UART2_STATUS_REG ) & 0x2u )   /* tx_full */
    {
    }
    soc_write32( UART2_TX_REG, ( uint32_t ) ( uint8_t ) c );
}

static int prv_getc( void )
{
    if( soc_read32( UART2_STATUS_REG ) & 0x1u )      /* rx_empty */
    {
        return -1;
    }

    return ( int ) ( soc_read32( UART2_RX_REG ) & 0xFFu );
}

void esp_at_drain( void )
{
    while( prv_getc() >= 0 )
    {
    }
}

/* Send "<cmd>\r\n", collect the reply until "OK"/"ERROR"/timeout.
 * Returns ESP_AT_OK / ESP_AT_ERROR / ESP_AT_TIMEOUT; reply text (NUL
 * terminated, truncated to len-1) lands in resp when non-NULL. */
int esp_at_cmd( const char * cmd, char * resp, uint32_t len, uint32_t timeout_ticks )
{
    TickType_t deadline = xTaskGetTickCount() + timeout_ticks;
    uint32_t   n = 0;
    char       prev = 0;

    esp_at_drain();

    for( const char * p = cmd; *p != '\0'; p++ )
    {
        prv_putc( *p );
    }
    prv_putc( '\r' );
    prv_putc( '\n' );

    for( ; ; )
    {
        int c = prv_getc();

        if( c < 0 )
        {
            if( xTaskGetTickCount() >= deadline )
            {
                if( resp != NULL ) resp[ n < len ? n : len - 1u ] = '\0';
                return ESP_AT_TIMEOUT;
            }

            taskYIELD();
            continue;
        }

        if( ( resp != NULL ) && ( n < len - 1u ) )
        {
            resp[ n ] = ( char ) c;
        }
        n++;

        if( ( prev == 'O' ) && ( c == 'K' ) )
        {
            if( resp != NULL ) resp[ n < len ? n : len - 1u ] = '\0';
            return ESP_AT_OK;
        }

        if( ( prev == 'O' ) && ( c == 'R' ) )    /* ...ERR"OR" */
        {
            if( resp != NULL ) resp[ n < len ? n : len - 1u ] = '\0';
            return ESP_AT_ERROR;
        }

        prev = ( char ) c;
    }
}

int esp_at_ping( void )
{
    return esp_at_cmd( "AT", NULL, 0, pdMS_TO_TICKS( 1000 ) );
}

int esp_at_join( const char * cmd_cwjap )
{
    /* caller formats: AT+CWJAP="ssid","pass" - joining can take ~10 s */
    return esp_at_cmd( cmd_cwjap, NULL, 0, pdMS_TO_TICKS( 15000 ) );
}

/* Stream len bytes out of PSRAM to the ESP32 (for use inside a CIPSEND
 * session). 64-byte SRAM bounce buffer - PSRAM is the bulk store. */
void esp_at_send_raw( uint32_t psram_addr, uint32_t len )
{
    uint8_t chunk[ 64 ];

    while( len > 0u )
    {
        uint32_t n = ( len > sizeof( chunk ) ) ? sizeof( chunk ) : len;

        psram_read( psram_addr, chunk, n );

        for( uint32_t i = 0; i < n; i++ )
        {
            prv_putc( ( char ) chunk[ i ] );
        }

        psram_addr += n;
        len -= n;
    }
}
