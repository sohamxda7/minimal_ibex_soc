#ifndef IBEX_UART_H
#define IBEX_UART_H

#include <stdint.h>

void uart_putc( char c );
void uart_puts( const char * s );
void uart_putu32( uint32_t v );
int  uart_getc_nonblock( void );   /* -1 if RX FIFO empty */

#endif
