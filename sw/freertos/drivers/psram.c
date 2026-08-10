/*
 * External 8 MB SPI PSRAM (APS6404-class) - the system's bulk data memory
 * (v1.1). Everything big lives here: camera frames, audio clips, network
 * buffers. It is a warehouse, not a desk: driver-accessed storage, NOT
 * CPU-executable/stack memory (docs/PRODUCTION_PERIPHERALS.md).
 *
 * Commands used: 0x02 write / 0x03 read, 24-bit address, auto-increment,
 * SPI mode 0 on the shared SPI host (CS = gp_o[8]). Validated against
 * dv/xsim/periph_models.sv:spi_psram_model in tb_psram.
 */

#include "soc.h"
#include "drivers/spi_bus.h"
#include "psram.h"

static void prv_cs( int active )
{
    gpio_out_update( GPO_PSRAM_CS, active ? 0u : GPO_PSRAM_CS );
}

static void prv_cmd_addr( uint8_t cmd, uint32_t addr )
{
    spi_bus_send( cmd );
    spi_bus_send( ( uint8_t ) ( addr >> 16 ) );
    spi_bus_send( ( uint8_t ) ( addr >> 8 ) );
    spi_bus_send( ( uint8_t ) addr );
}

void psram_write( uint32_t addr, const uint8_t * buf, uint32_t len )
{
    spi_bus_lock();
    prv_cs( 1 );
    prv_cmd_addr( 0x02, addr );

    for( uint32_t i = 0; i < len; i++ )
    {
        spi_bus_send( buf[ i ] );
    }

    prv_cs( 0 );
    spi_bus_unlock();
}

void psram_read( uint32_t addr, uint8_t * buf, uint32_t len )
{
    spi_bus_lock();
    prv_cs( 1 );
    prv_cmd_addr( 0x03, addr );

    for( uint32_t i = 0; i < len; i++ )
    {
        buf[ i ] = spi_bus_xfer( 0xFF );
    }

    prv_cs( 0 );
    spi_bus_unlock();
}

/* Power-on sanity: write/readback 4 bytes at a scratch address. */
int psram_selftest( void )
{
    static const uint8_t pat[ 4 ] = { 0xA5, 0x5A, 0xC3, 0x3C };
    uint8_t back[ 4 ] = { 0 };

    psram_write( PSRAM_SCRATCH_ADDR, pat, 4 );
    psram_read( PSRAM_SCRATCH_ADDR, back, 4 );

    for( int i = 0; i < 4; i++ )
    {
        if( back[ i ] != pat[ i ] )
        {
            return -1;
        }
    }

    return 0;
}
