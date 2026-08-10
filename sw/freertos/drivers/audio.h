#ifndef IBEX_AUDIO_H
#define IBEX_AUDIO_H

#include <stdint.h>

uint16_t audio_mic_sample( void );                 /* one 12-bit conversion */
void audio_record( uint32_t psram_addr, uint32_t n, uint32_t rate_hz );
void audio_play( uint32_t psram_addr, uint32_t n, uint32_t rate_hz );
void audio_beep( uint32_t ms );

#endif
