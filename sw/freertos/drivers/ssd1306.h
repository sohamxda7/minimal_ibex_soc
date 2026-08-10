#ifndef IBEX_SSD1306_H
#define IBEX_SSD1306_H

#include <stdint.h>

#define SSD1306_ADDR  0x3Cu   /* 0x3D if the module's address jumper is set */

int ssd1306_init( uint8_t addr );
int ssd1306_clear( void );
int ssd1306_text( uint8_t col, uint8_t row, const char * s ); /* 21x8 cells */

#endif
