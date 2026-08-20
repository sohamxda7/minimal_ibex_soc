/* Polled UART driver for the minimal Ibex SoC. Baud is fixed in hardware
 * (2 Mbaud at 20 MHz -- rtl/system/uart.sv), nothing to configure. */

#include "soc.h"
#include "uart.h"

void uart_putc( char c )
{
    while( soc_read32( UART_STATUS_REG ) & UART_STATUS_TX_FULL )
    {
    }
    soc_write32( UART_TX_REG, ( uint32_t ) ( uint8_t ) c );
}

void uart_puts( const char * s )
{
    while( *s != '\0' )
    {
        uart_putc( *s++ );
    }
}

void uart_putu32( uint32_t v )
{
    char buf[ 11 ];
    int  i = 10;

    buf[ i ] = '\0';

    do
    {
        buf[ --i ] = ( char ) ( '0' + ( v % 10u ) );
        v /= 10u;
    } while( v != 0u );

    uart_puts( &buf[ i ] );
}

void uart_puthex8( uint8_t v )
{
    static const char hex[] = "0123456789ABCDEF";

    uart_putc( hex[ ( v >> 4 ) & 0xFu ] );
    uart_putc( hex[ v & 0xFu ] );
}

int uart_getc_nonblock( void )
{
    if( soc_read32( UART_STATUS_REG ) & UART_STATUS_RX_EMPTY )
    {
        return -1;
    }

    return ( int ) ( soc_read32( UART_RX_REG ) & 0xFFu );
}
