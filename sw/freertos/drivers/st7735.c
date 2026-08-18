/*
 * ST7735 128x160 TFT LCD driver over the SoC SPI host (0x4000_0500).
 *
 * No framebuffer: 128*160*2 = 40 KB does not exist in an 8 KiB-SRAM system,
 * so every primitive streams pixels straight into RAMWR. This is the C
 * counterpart of the assembly proof in sw/asm-demo/lcd_spi_test.py whose
 * 26-byte init/draw sequence was validated in dv/xsim/tb_lcd.sv.
 *
 * Control lines (GPIO_OUT low nibble, wiring per docs/PRODUCTION_PERIPHERALS.md sec. 8,
 * LCD on ChipKit headers A6-A11):
 *   bit0 = CS (active low)   bit1 = RST (active low)
 *   bit2 = DC (0=cmd 1=data) bit3 = BL (backlight, active high)
 *
 * SPI host: mode 0, MSB first, 5 MHz, TX +0, STATUS +4 (bit0 full, bit1 empty).
 *
 * Delays use vTaskDelay (the ST7735 needs 120 ms after SWRESET/SLPOUT), so
 * call init from a task, not before the scheduler starts.
 *
 * Text: classic public-domain 5x7 font in 6x8 cells -> 21 cols x 20 rows.
 * The 475-byte table is const, so it lives in XIP flash and costs no SRAM.
 */

#include "FreeRTOS.h"
#include "task.h"

#include "soc.h"
#include "st7735.h"
#include "spi_bus.h"

/* ---- ST7735 commands ---- */
#define CMD_SWRESET  0x01u
#define CMD_SLPOUT   0x11u
#define CMD_COLMOD   0x3Au
#define CMD_DISPON   0x29u
#define CMD_CASET    0x2Au
#define CMD_RASET    0x2Bu
#define CMD_RAMWR    0x2Cu
#define CMD_MADCTL   0x36u

#define GPIO_LCD_CS   0x1u
#define GPIO_LCD_RST  0x2u
#define GPIO_LCD_DC   0x4u
#define GPIO_LCD_BL   0x8u

/* GPIO_OUT is shared with the LED tasks: a raw read-modify-write here races
 * their updates (stale LED nibble written back whenever a task switch lands
 * between the read and the write). gpio_out_update() does the RMW inside a
 * critical section. */
static void prv_gpio_set( uint32_t mask, uint32_t value )
{
    gpio_out_update( mask, value );
}

static void prv_spi_byte( uint8_t b )
{
    while( soc_read32( SPI_STATUS_REG ) & SPI_STATUS_TX_FULL )
    {
    }
    soc_write32( SPI_TX_REG, b );
}

static void prv_spi_drain( void )
{
    while( ( soc_read32( SPI_STATUS_REG ) & SPI_STATUS_TX_EMPTY ) == 0u )
    {
    }
}

static void prv_cmd( uint8_t c )
{
    prv_spi_drain();
    prv_gpio_set( GPIO_LCD_DC, 0 );          /* command */
    prv_spi_byte( c );
    prv_spi_drain();
    prv_gpio_set( GPIO_LCD_DC, GPIO_LCD_DC ); /* back to data */
}

static void prv_data( uint8_t d )
{
    prv_spi_byte( d );
}

void st7735_init( void )
{
    /* CS low for the whole session, backlight on, hardware reset pulse */
    prv_gpio_set( GPIO_LCD_CS, 0 );
    prv_gpio_set( GPIO_LCD_BL, GPIO_LCD_BL );

    prv_gpio_set( GPIO_LCD_RST, 0 );
    vTaskDelay( pdMS_TO_TICKS( 10 ) );
    prv_gpio_set( GPIO_LCD_RST, GPIO_LCD_RST );
    vTaskDelay( pdMS_TO_TICKS( 120 ) );

    prv_cmd( CMD_SWRESET );
    vTaskDelay( pdMS_TO_TICKS( 120 ) );
    prv_cmd( CMD_SLPOUT );
    vTaskDelay( pdMS_TO_TICKS( 120 ) );

    prv_cmd( CMD_COLMOD );
    prv_data( 0x05 );                        /* RGB565 */
    prv_cmd( CMD_MADCTL );
    prv_data( 0x00 );
    prv_cmd( CMD_DISPON );
    vTaskDelay( pdMS_TO_TICKS( 20 ) );
}

void st7735_set_window( uint8_t x0, uint8_t y0, uint8_t x1, uint8_t y1 )
{
    prv_cmd( CMD_CASET );
    prv_data( 0 ); prv_data( x0 );
    prv_data( 0 ); prv_data( x1 );
    prv_cmd( CMD_RASET );
    prv_data( 0 ); prv_data( y0 );
    prv_data( 0 ); prv_data( y1 );
    prv_cmd( CMD_RAMWR );
}

void st7735_fill_rect( uint8_t x, uint8_t y, uint8_t w, uint8_t h, uint16_t rgb565 )
{
    uint32_t n = ( uint32_t ) w * ( uint32_t ) h;

    st7735_set_window( x, y, ( uint8_t ) ( x + w - 1u ), ( uint8_t ) ( y + h - 1u ) );

    while( n-- )
    {
        prv_spi_byte( ( uint8_t ) ( rgb565 >> 8 ) );
        prv_spi_byte( ( uint8_t ) rgb565 );
    }

    prv_spi_drain();
}

void st7735_fill_screen( uint16_t rgb565 )
{
    st7735_fill_rect( 0, 0, ST7735_WIDTH, ST7735_HEIGHT, rgb565 );
}

/* ---- text ----------------------------------------------------------------
 * Classic 5x7 column-major font, ASCII 32..126; bit0 of each column byte is
 * the top pixel row. */
static const uint8_t prv_font5x7[ 95 ][ 5 ] = {
    { 0x00, 0x00, 0x00, 0x00, 0x00 }, /* ' ' */
    { 0x00, 0x00, 0x5F, 0x00, 0x00 }, /* !   */
    { 0x00, 0x07, 0x00, 0x07, 0x00 }, /* "   */
    { 0x14, 0x7F, 0x14, 0x7F, 0x14 }, /* #   */
    { 0x24, 0x2A, 0x7F, 0x2A, 0x12 }, /* $   */
    { 0x23, 0x13, 0x08, 0x64, 0x62 }, /* %   */
    { 0x36, 0x49, 0x55, 0x22, 0x50 }, /* &   */
    { 0x00, 0x05, 0x03, 0x00, 0x00 }, /* '   */
    { 0x00, 0x1C, 0x22, 0x41, 0x00 }, /* (   */
    { 0x00, 0x41, 0x22, 0x1C, 0x00 }, /* )   */
    { 0x08, 0x2A, 0x1C, 0x2A, 0x08 }, /* *   */
    { 0x08, 0x08, 0x3E, 0x08, 0x08 }, /* +   */
    { 0x00, 0x50, 0x30, 0x00, 0x00 }, /* ,   */
    { 0x08, 0x08, 0x08, 0x08, 0x08 }, /* -   */
    { 0x00, 0x60, 0x60, 0x00, 0x00 }, /* .   */
    { 0x20, 0x10, 0x08, 0x04, 0x02 }, /* /   */
    { 0x3E, 0x51, 0x49, 0x45, 0x3E }, /* 0   */
    { 0x00, 0x42, 0x7F, 0x40, 0x00 }, /* 1   */
    { 0x42, 0x61, 0x51, 0x49, 0x46 }, /* 2   */
    { 0x21, 0x41, 0x45, 0x4B, 0x31 }, /* 3   */
    { 0x18, 0x14, 0x12, 0x7F, 0x10 }, /* 4   */
    { 0x27, 0x45, 0x45, 0x45, 0x39 }, /* 5   */
    { 0x3C, 0x4A, 0x49, 0x49, 0x30 }, /* 6   */
    { 0x01, 0x71, 0x09, 0x05, 0x03 }, /* 7   */
    { 0x36, 0x49, 0x49, 0x49, 0x36 }, /* 8   */
    { 0x06, 0x49, 0x49, 0x29, 0x1E }, /* 9   */
    { 0x00, 0x36, 0x36, 0x00, 0x00 }, /* :   */
    { 0x00, 0x56, 0x36, 0x00, 0x00 }, /* ;   */
    { 0x00, 0x08, 0x14, 0x22, 0x41 }, /* <   */
    { 0x14, 0x14, 0x14, 0x14, 0x14 }, /* =   */
    { 0x41, 0x22, 0x14, 0x08, 0x00 }, /* >   */
    { 0x02, 0x01, 0x51, 0x09, 0x06 }, /* ?   */
    { 0x32, 0x49, 0x79, 0x41, 0x3E }, /* @   */
    { 0x7E, 0x11, 0x11, 0x11, 0x7E }, /* A   */
    { 0x7F, 0x49, 0x49, 0x49, 0x36 }, /* B   */
    { 0x3E, 0x41, 0x41, 0x41, 0x22 }, /* C   */
    { 0x7F, 0x41, 0x41, 0x22, 0x1C }, /* D   */
    { 0x7F, 0x49, 0x49, 0x49, 0x41 }, /* E   */
    { 0x7F, 0x09, 0x09, 0x09, 0x01 }, /* F   */
    { 0x3E, 0x41, 0x49, 0x49, 0x7A }, /* G   */
    { 0x7F, 0x08, 0x08, 0x08, 0x7F }, /* H   */
    { 0x00, 0x41, 0x7F, 0x41, 0x00 }, /* I   */
    { 0x20, 0x40, 0x41, 0x3F, 0x01 }, /* J   */
    { 0x7F, 0x08, 0x14, 0x22, 0x41 }, /* K   */
    { 0x7F, 0x40, 0x40, 0x40, 0x40 }, /* L   */
    { 0x7F, 0x02, 0x0C, 0x02, 0x7F }, /* M   */
    { 0x7F, 0x04, 0x08, 0x10, 0x7F }, /* N   */
    { 0x3E, 0x41, 0x41, 0x41, 0x3E }, /* O   */
    { 0x7F, 0x09, 0x09, 0x09, 0x06 }, /* P   */
    { 0x3E, 0x41, 0x51, 0x21, 0x5E }, /* Q   */
    { 0x7F, 0x09, 0x19, 0x29, 0x46 }, /* R   */
    { 0x46, 0x49, 0x49, 0x49, 0x31 }, /* S   */
    { 0x01, 0x01, 0x7F, 0x01, 0x01 }, /* T   */
    { 0x3F, 0x40, 0x40, 0x40, 0x3F }, /* U   */
    { 0x1F, 0x20, 0x40, 0x20, 0x1F }, /* V   */
    { 0x3F, 0x40, 0x38, 0x40, 0x3F }, /* W   */
    { 0x63, 0x14, 0x08, 0x14, 0x63 }, /* X   */
    { 0x07, 0x08, 0x70, 0x08, 0x07 }, /* Y   */
    { 0x61, 0x51, 0x49, 0x45, 0x43 }, /* Z   */
    { 0x00, 0x7F, 0x41, 0x41, 0x00 }, /* [   */
    { 0x02, 0x04, 0x08, 0x10, 0x20 }, /* \   */
    { 0x00, 0x41, 0x41, 0x7F, 0x00 }, /* ]   */
    { 0x04, 0x02, 0x01, 0x02, 0x04 }, /* ^   */
    { 0x40, 0x40, 0x40, 0x40, 0x40 }, /* _   */
    { 0x00, 0x01, 0x02, 0x04, 0x00 }, /* `   */
    { 0x20, 0x54, 0x54, 0x54, 0x78 }, /* a   */
    { 0x7F, 0x48, 0x44, 0x44, 0x38 }, /* b   */
    { 0x38, 0x44, 0x44, 0x44, 0x20 }, /* c   */
    { 0x38, 0x44, 0x44, 0x48, 0x7F }, /* d   */
    { 0x38, 0x54, 0x54, 0x54, 0x18 }, /* e   */
    { 0x08, 0x7E, 0x09, 0x01, 0x02 }, /* f   */
    { 0x0C, 0x52, 0x52, 0x52, 0x3E }, /* g   */
    { 0x7F, 0x08, 0x04, 0x04, 0x78 }, /* h   */
    { 0x00, 0x44, 0x7D, 0x40, 0x00 }, /* i   */
    { 0x20, 0x40, 0x44, 0x3D, 0x00 }, /* j   */
    { 0x7F, 0x10, 0x28, 0x44, 0x00 }, /* k   */
    { 0x00, 0x41, 0x7F, 0x40, 0x00 }, /* l   */
    { 0x7C, 0x04, 0x18, 0x04, 0x78 }, /* m   */
    { 0x7C, 0x08, 0x04, 0x04, 0x78 }, /* n   */
    { 0x38, 0x44, 0x44, 0x44, 0x38 }, /* o   */
    { 0x7C, 0x14, 0x14, 0x14, 0x08 }, /* p   */
    { 0x08, 0x14, 0x14, 0x18, 0x7C }, /* q   */
    { 0x7C, 0x08, 0x04, 0x04, 0x08 }, /* r   */
    { 0x48, 0x54, 0x54, 0x54, 0x20 }, /* s   */
    { 0x04, 0x3F, 0x44, 0x40, 0x20 }, /* t   */
    { 0x3C, 0x40, 0x40, 0x20, 0x7C }, /* u   */
    { 0x1C, 0x20, 0x40, 0x20, 0x1C }, /* v   */
    { 0x3C, 0x40, 0x30, 0x40, 0x3C }, /* w   */
    { 0x44, 0x28, 0x10, 0x28, 0x44 }, /* x   */
    { 0x0C, 0x50, 0x50, 0x50, 0x3C }, /* y   */
    { 0x44, 0x64, 0x54, 0x4C, 0x44 }, /* z   */
    { 0x00, 0x08, 0x36, 0x41, 0x00 }, /* {   */
    { 0x00, 0x00, 0x7F, 0x00, 0x00 }, /* |   */
    { 0x00, 0x41, 0x36, 0x08, 0x00 }, /* }   */
    { 0x08, 0x04, 0x08, 0x10, 0x08 }, /* ~   */
};

/* One 6x8 cell per character (5 font columns + 1 blank, 8 pixel rows),
 * streamed row-major straight into RAMWR like every other primitive. */
void st7735_text_ex( uint8_t col, uint8_t row, const char * s,
                     uint16_t fg, uint16_t bg )
{
    while( ( *s != '\0' ) && ( col < ST7735_TEXT_COLS ) )
    {
        uint8_t c = ( uint8_t ) *s++;
        const uint8_t * glyph;
        uint8_t x = ( uint8_t ) ( col * 6u );
        uint8_t y = ( uint8_t ) ( row * 8u );

        if( ( c < 32u ) || ( c > 126u ) )
        {
            c = '?';
        }
        glyph = prv_font5x7[ c - 32u ];

        st7735_set_window( x, y, ( uint8_t ) ( x + 5u ), ( uint8_t ) ( y + 7u ) );

        for( uint8_t py = 0; py < 8u; py++ )
        {
            for( uint8_t px = 0; px < 6u; px++ )
            {
                uint16_t rgb = bg;

                if( ( px < 5u ) && ( py < 7u ) &&
                    ( ( glyph[ px ] >> py ) & 1u ) )
                {
                    rgb = fg;
                }
                prv_spi_byte( ( uint8_t ) ( rgb >> 8 ) );
                prv_spi_byte( ( uint8_t ) rgb );
            }
        }

        prv_spi_drain();
        col++;
    }
}

void st7735_text( uint8_t col, uint8_t row, const char * s )
{
    st7735_text_ex( col, row, s, ST7735_RGB( 0xFF, 0xFF, 0xFF ),
                    ST7735_RGB( 0, 0, 0 ) );
}
