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
 */

#include "FreeRTOS.h"
#include "task.h"

#include "soc.h"
#include "st7735.h"

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

static void prv_gpio_set( uint32_t mask, uint32_t value )
{
    uint32_t out = soc_read32( GPIO_OUT_REG );

    soc_write32( GPIO_OUT_REG, ( out & ~mask ) | ( value & mask ) );
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
