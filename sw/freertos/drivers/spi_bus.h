#ifndef IBEX_SPI_BUS_H
#define IBEX_SPI_BUS_H

#include <stdint.h>

void    spi_bus_init( void );              /* before vTaskStartScheduler */
void    spi_bus_lock( void );              /* around every device session */
void    spi_bus_unlock( void );
void    spi_bus_send( uint8_t b );         /* blocking single byte out */
uint8_t spi_bus_xfer( uint8_t b );         /* out + received byte back */

/* Atomic read-modify-write on the shared GPIO OUT register. */
void    gpio_out_update( uint32_t mask, uint32_t value );

#endif
