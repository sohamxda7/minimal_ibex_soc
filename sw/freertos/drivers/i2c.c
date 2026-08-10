/*
 * I2C master helper for the OpenCores i2c_master core at 0x4000_0400.
 *
 * Register map (4-byte stride, docs/ASIC_SPEC.md / soc.h): PRERlo +0x00,
 * PRERhi +0x04, CTR +0x08, TXR/RXR +0x0C, CR/SR +0x10.
 *
 * Prescale for 100 kHz SCL at 20 MHz sysclk: 20e6 / (5 * 100e3) - 1 = 39.
 * The same edge-discipline rules validated in dv/xsim/tb_i2c.sv apply on
 * hardware (Pmod JA1 = SCL G13, JA2 = SDA B11, XDC pull-ups enabled).
 *
 * All waits are bounded: a hung bus returns I2C_ERR_TIMEOUT instead of
 * wedging the calling task.
 */

#include "soc.h"
#include "i2c.h"

#define I2C_PRESCALE_100KHZ   39u
#define I2C_TIP_TIMEOUT       100000u   /* ~bus-seconds of margin at 20 MHz */

static int prv_wait_tip( void )
{
    uint32_t n = I2C_TIP_TIMEOUT;

    while( soc_read32( I2C_SR ) & I2C_SR_TIP )
    {
        if( --n == 0u )
        {
            return I2C_ERR_TIMEOUT;
        }
    }

    return I2C_OK;
}

void i2c_init( void )
{
    soc_write32( I2C_CTR, 0 );                    /* disable while configuring */
    soc_write32( I2C_PRER_LO, I2C_PRESCALE_100KHZ );
    soc_write32( I2C_PRER_HI, 0 );
    soc_write32( I2C_CTR, I2C_CTR_EN );
}

/* One byte, addressed register write:  S addr+W reg val P  */
int i2c_write_reg( uint8_t dev, uint8_t reg, uint8_t val )
{
    soc_write32( I2C_TXR, ( uint32_t ) ( dev << 1 ) );          /* addr + W */
    soc_write32( I2C_CR, I2C_CMD_STA | I2C_CMD_WR );
    if( prv_wait_tip() != I2C_OK ) return I2C_ERR_TIMEOUT;
    if( soc_read32( I2C_SR ) & I2C_SR_RXACK ) goto nack;

    soc_write32( I2C_TXR, reg );
    soc_write32( I2C_CR, I2C_CMD_WR );
    if( prv_wait_tip() != I2C_OK ) return I2C_ERR_TIMEOUT;
    if( soc_read32( I2C_SR ) & I2C_SR_RXACK ) goto nack;

    soc_write32( I2C_TXR, val );
    soc_write32( I2C_CR, I2C_CMD_WR | I2C_CMD_STO );
    if( prv_wait_tip() != I2C_OK ) return I2C_ERR_TIMEOUT;
    if( soc_read32( I2C_SR ) & I2C_SR_RXACK ) goto nack;

    return I2C_OK;

nack:
    soc_write32( I2C_CR, I2C_CMD_STO );
    ( void ) prv_wait_tip();
    return I2C_ERR_NACK;
}

/* Burst register write:  S addr+W reg d0 d1 ... P  */
int i2c_write_regs( uint8_t dev, uint8_t reg, const uint8_t * buf, uint32_t len )
{
    soc_write32( I2C_TXR, ( uint32_t ) ( dev << 1 ) );          /* addr + W */
    soc_write32( I2C_CR, I2C_CMD_STA | I2C_CMD_WR );
    if( prv_wait_tip() != I2C_OK ) return I2C_ERR_TIMEOUT;
    if( soc_read32( I2C_SR ) & I2C_SR_RXACK ) goto nack;

    soc_write32( I2C_TXR, reg );
    soc_write32( I2C_CR, I2C_CMD_WR );
    if( prv_wait_tip() != I2C_OK ) return I2C_ERR_TIMEOUT;
    if( soc_read32( I2C_SR ) & I2C_SR_RXACK ) goto nack;

    for( uint32_t i = 0; i < len; i++ )
    {
        uint32_t cmd = I2C_CMD_WR;

        if( i == len - 1u )
        {
            cmd |= I2C_CMD_STO;
        }

        soc_write32( I2C_TXR, buf[ i ] );
        soc_write32( I2C_CR, cmd );
        if( prv_wait_tip() != I2C_OK ) return I2C_ERR_TIMEOUT;
        if( soc_read32( I2C_SR ) & I2C_SR_RXACK ) goto nack;
    }

    return I2C_OK;

nack:
    soc_write32( I2C_CR, I2C_CMD_STO );
    ( void ) prv_wait_tip();
    return I2C_ERR_NACK;
}

/* Burst register read:  S addr+W reg Sr addr+R data... P  (NACK on last) */
int i2c_read_regs( uint8_t dev, uint8_t reg, uint8_t * buf, uint32_t len )
{
    if( len == 0u ) return I2C_OK;

    soc_write32( I2C_TXR, ( uint32_t ) ( dev << 1 ) );          /* addr + W */
    soc_write32( I2C_CR, I2C_CMD_STA | I2C_CMD_WR );
    if( prv_wait_tip() != I2C_OK ) return I2C_ERR_TIMEOUT;
    if( soc_read32( I2C_SR ) & I2C_SR_RXACK ) goto nack;

    soc_write32( I2C_TXR, reg );
    soc_write32( I2C_CR, I2C_CMD_WR );
    if( prv_wait_tip() != I2C_OK ) return I2C_ERR_TIMEOUT;
    if( soc_read32( I2C_SR ) & I2C_SR_RXACK ) goto nack;

    soc_write32( I2C_TXR, ( uint32_t ) ( ( dev << 1 ) | 1u ) ); /* repeated START, addr + R */
    soc_write32( I2C_CR, I2C_CMD_STA | I2C_CMD_WR );
    if( prv_wait_tip() != I2C_OK ) return I2C_ERR_TIMEOUT;
    if( soc_read32( I2C_SR ) & I2C_SR_RXACK ) goto nack;

    for( uint32_t i = 0; i < len; i++ )
    {
        uint32_t cmd = I2C_CMD_RD;

        if( i == len - 1u )
        {
            cmd |= I2C_CMD_NACK | I2C_CMD_STO;   /* NACK + STOP after last byte */
        }

        soc_write32( I2C_CR, cmd );
        if( prv_wait_tip() != I2C_OK ) return I2C_ERR_TIMEOUT;
        buf[ i ] = ( uint8_t ) soc_read32( I2C_RXR );
    }

    return I2C_OK;

nack:
    soc_write32( I2C_CR, I2C_CMD_STO );
    ( void ) prv_wait_tip();
    return I2C_ERR_NACK;
}

int i2c_read_reg( uint8_t dev, uint8_t reg, uint8_t * val )
{
    return i2c_read_regs( dev, reg, val, 1 );
}

/* Address probe:  S addr+W P  -- ACK means a device answered. */
int i2c_probe( uint8_t dev )
{
    int rc;

    soc_write32( I2C_TXR, ( uint32_t ) ( dev << 1 ) );
    soc_write32( I2C_CR, I2C_CMD_STA | I2C_CMD_WR );
    if( prv_wait_tip() != I2C_OK ) return I2C_ERR_TIMEOUT;
    rc = ( soc_read32( I2C_SR ) & I2C_SR_RXACK ) ? I2C_ERR_NACK : I2C_OK;
    soc_write32( I2C_CR, I2C_CMD_STO );
    ( void ) prv_wait_tip();

    return rc;
}
