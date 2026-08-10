#ifndef IBEX_ESP_AT_H
#define IBEX_ESP_AT_H

#include <stdint.h>

#define ESP_AT_OK       0
#define ESP_AT_ERROR  (-1)
#define ESP_AT_TIMEOUT (-2)

void esp_at_drain( void );
int  esp_at_cmd( const char * cmd, char * resp, uint32_t len, uint32_t timeout_ticks );
int  esp_at_ping( void );                      /* "AT" -> OK              */
int  esp_at_join( const char * cmd_cwjap );    /* AT+CWJAP="ssid","pass"  */
void esp_at_send_raw( uint32_t psram_addr, uint32_t len );

#endif
