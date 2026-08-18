#ifndef IBEX_ST7735_H
#define IBEX_ST7735_H

#include <stdint.h>

#define ST7735_WIDTH   128
#define ST7735_HEIGHT  160

/* 5x7 font in 6x8 cells */
#define ST7735_TEXT_COLS   21
#define ST7735_TEXT_ROWS   20

#define ST7735_RGB( r, g, b ) \
    ( ( uint16_t ) ( ( ( ( r ) & 0xF8u ) << 8 ) | ( ( ( g ) & 0xFCu ) << 3 ) | ( ( ( b ) & 0xF8u ) >> 3 ) ) )

void st7735_init( void );        /* call from a task (uses vTaskDelay) */
void st7735_set_window( uint8_t x0, uint8_t y0, uint8_t x1, uint8_t y1 );
void st7735_fill_rect( uint8_t x, uint8_t y, uint8_t w, uint8_t h, uint16_t rgb565 );
void st7735_fill_screen( uint16_t rgb565 );
void st7735_text( uint8_t col, uint8_t row, const char * s );   /* white on black */
void st7735_text_ex( uint8_t col, uint8_t row, const char * s,
                     uint16_t fg, uint16_t bg );

#endif
