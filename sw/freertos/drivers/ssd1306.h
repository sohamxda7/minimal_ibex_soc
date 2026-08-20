#ifndef IBEX_SSD1306_H
#define IBEX_SSD1306_H

#include <stdint.h>

#define SSD1306_ADDR  0x3Cu   /* 0x3D if the module's address jumper is set */

int ssd1306_init( uint8_t addr );
int ssd1306_clear( void );
int ssd1306_text( uint8_t col, uint8_t row, const char * s ); /* 21x8 cells */

/* Double-height text: 12x16 px per glyph, spans rows..rows+1. Column is
 * still a 6 px cell index, so col 0..9 for a full 3-char word at x=0. */
int ssd1306_text2x( uint8_t col, uint8_t row, const char * s );

/* Fill a pixel-column / page rectangle with one byte pattern (each byte is
 * 8 vertical pixels). Separators, bars, partial clears. */
int ssd1306_fill( uint8_t col0, uint8_t col1, uint8_t row0, uint8_t row1,
                  uint8_t pattern );

#endif
