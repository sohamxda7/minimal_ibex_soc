#ifndef IBEX_ESP_AT_H
#define IBEX_ESP_AT_H

#include <stdint.h>

#define ESP_AT_OK       0
#define ESP_AT_ERROR  (-1)
#define ESP_AT_TIMEOUT (-2)

/* Unsolicited-event callback: called from the high-priority RX task with
 * one NUL-terminated line (WIFI DISCONNECT, +IPD..., ready, ...). Keep it
 * short; heavy work belongs in an app task. */
typedef void ( * esp_at_event_cb_t )( const char * line );

int      esp_at_init( void );          /* enter interrupt mode (RX task + IRQ) */
void     esp_at_on_event( esp_at_event_cb_t cb );
void     esp_at_isr( void );           /* fast IRQ 1 hook - called by main.c   */
uint32_t esp_at_rx_dropped( void );    /* software-ring overflow count         */

void esp_at_drain( void );
int  esp_at_cmd( const char * cmd, char * resp, uint32_t len, uint32_t timeout_ticks );
int  esp_at_ping( void );                      /* "AT" -> OK              */
int  esp_at_join( const char * cmd_cwjap );    /* AT+CWJAP="ssid","pass"  */
void esp_at_send_raw( uint32_t psram_addr, uint32_t len );

#endif
