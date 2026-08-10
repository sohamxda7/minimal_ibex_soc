/*
 * OV7670 + AL422 FIFO camera (v1.1): snapshot capture into external PSRAM.
 *
 * Why this works in 8 KiB: the camera MODULE carries a 384 KB FIFO. The
 * sensor streams a frame into that FIFO at pixel rate; we then read it out
 * byte-by-byte at CPU pace over gp_i[15:8] (RAW input register - the
 * debounced one would add ~25 us per byte) and spill into PSRAM through a
 * small bounce buffer. Snapshots, not video - the honest ceiling recorded
 * in docs/ASIC_SPEC.md section 9.
 *
 * Sensor register setup goes over the existing I2C master (SCCB protocol,
 * address 0x21) using drivers/i2c.h - see cam_init(). FIFO readout is
 * validated against ov7670_fifo_model in tb_cam; WEN/VSYNC capture framing
 * is a hardware-bring-up item (needs the real sensor's VSYNC timing).
 */

#include "FreeRTOS.h"
#include "task.h"

#include "soc.h"
#include "drivers/spi_bus.h"
#include "drivers/psram.h"
#include "drivers/i2c.h"
#include "camera.h"

#define OV7670_SCCB_ADDR  0x21u

static void prv_pulse_delay( void )
{
    for( volatile int i = 0; i < 4; i++ )
    {
    }
}

int cam_init( void )
{
    uint8_t id;

    /* PID register 0x0A reads 0x76 on a live OV7670 */
    if( i2c_read_reg( OV7670_SCCB_ADDR, 0x0A, &id ) != I2C_OK )
    {
        return CAM_ERR_I2C;
    }

    if( id != 0x76u )
    {
        return CAM_ERR_ID;
    }

    /* QVGA RGB565: COM7=0x14, COM15=0xD0 (bring-up minimal set) */
    ( void ) i2c_write_reg( OV7670_SCCB_ADDR, 0x12, 0x14 );
    ( void ) i2c_write_reg( OV7670_SCCB_ADDR, 0x40, 0xD0 );

    return CAM_OK;
}

/* Arm the FIFO for one frame (WEN high across the next VSYNC). */
void cam_capture_arm( void )
{
    gpio_out_update( GPO_CAM_WEN, GPO_CAM_WEN );
    vTaskDelay( pdMS_TO_TICKS( 100 ) );          /* > one frame time */
    gpio_out_update( GPO_CAM_WEN, 0 );
}

/* Read len FIFO bytes into PSRAM at psram_addr. Returns len. */
uint32_t cam_read_to_psram( uint32_t psram_addr, uint32_t len )
{
    uint8_t chunk[ 32 ];
    uint32_t done = 0;

    /* Reset the FIFO read pointer: RRST low across an RCLK pulse */
    gpio_out_update( GPO_CAM_RRST, 0 );
    prv_pulse_delay();
    gpio_out_update( GPO_CAM_RCLK, GPO_CAM_RCLK );
    prv_pulse_delay();
    gpio_out_update( GPO_CAM_RCLK, 0 );
    gpio_out_update( GPO_CAM_RRST, GPO_CAM_RRST );

    while( done < len )
    {
        uint32_t n = ( ( len - done ) > sizeof( chunk ) ) ? sizeof( chunk )
                                                          : ( len - done );

        for( uint32_t i = 0; i < n; i++ )
        {
            chunk[ i ] = ( uint8_t )
                ( soc_read32( GPIO_IN_RAW_REG ) >> GPI_CAM_SHIFT );

            gpio_out_update( GPO_CAM_RCLK, GPO_CAM_RCLK );
            prv_pulse_delay();
            gpio_out_update( GPO_CAM_RCLK, 0 );
            prv_pulse_delay();
        }

        psram_write( psram_addr + done, chunk, n );
        done += n;
    }

    return done;
}
