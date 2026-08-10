#ifndef IBEX_I2C_H
#define IBEX_I2C_H

#include <stdint.h>

#define I2C_OK            0
#define I2C_ERR_NACK    (-1)
#define I2C_ERR_TIMEOUT (-2)

void i2c_init( void );                                        /* 100 kHz */
int  i2c_probe( uint8_t dev );
int  i2c_write_reg( uint8_t dev, uint8_t reg, uint8_t val );
int  i2c_write_regs( uint8_t dev, uint8_t reg, const uint8_t * buf, uint32_t len );
int  i2c_read_reg( uint8_t dev, uint8_t reg, uint8_t * val );
int  i2c_read_regs( uint8_t dev, uint8_t reg, uint8_t * buf, uint32_t len );

#endif
