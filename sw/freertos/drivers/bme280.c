/*
 * BME280 temperature / pressure / humidity sensor over I2C (addr 0x76,
 * SDO to GND on the common purple breakout; 0x77 if SDO is high).
 *
 * Forced-mode, one measurement per call: lowest power and no configuration
 * drift to worry about. Compensation formulas are the fixed-point versions
 * from the Bosch datasheet section 4.2.3 (32-bit only -- no 64-bit math on
 * RV32IMC, saves libgcc pulls). Pressure uses the 32-bit variant, accurate
 * to ~1 Pa above 30 kPa, fine for a bring-up toy.
 *
 * RAM cost: 33 bytes of calibration in the device struct, nothing else.
 */

#include "FreeRTOS.h"
#include "task.h"

#include "drivers/i2c.h"
#include "bme280.h"

#define REG_ID         0xD0u
#define REG_RESET      0xE0u
#define REG_CTRL_HUM   0xF2u
#define REG_STATUS     0xF3u
#define REG_CTRL_MEAS  0xF4u
#define REG_CALIB00    0x88u
#define REG_CALIB26    0xE1u
#define REG_DATA       0xF7u

#define BME280_CHIP_ID 0x60u

static uint16_t prv_u16le( const uint8_t * p ) { return ( uint16_t ) ( p[ 0 ] | ( p[ 1 ] << 8 ) ); }
static int16_t  prv_s16le( const uint8_t * p ) { return ( int16_t ) prv_u16le( p ); }

int bme280_init( bme280_t * dev, uint8_t addr )
{
    uint8_t id;
    uint8_t c1[ 26 ];
    uint8_t c2[ 7 ];
    int rc;

    dev->addr = addr;

    rc = i2c_read_reg( addr, REG_ID, &id );
    if( rc != I2C_OK ) return rc;
    if( id != BME280_CHIP_ID ) return BME280_ERR_ID;

    /* Calibration block 1: 0x88..0xA1 */
    rc = i2c_read_regs( addr, REG_CALIB00, c1, 26 );
    if( rc != I2C_OK ) return rc;
    /* Calibration block 2: 0xE1..0xE7 (humidity) */
    rc = i2c_read_regs( addr, REG_CALIB26, c2, 7 );
    if( rc != I2C_OK ) return rc;

    dev->T1 = prv_u16le( &c1[ 0 ] );
    dev->T2 = prv_s16le( &c1[ 2 ] );
    dev->T3 = prv_s16le( &c1[ 4 ] );
    dev->P1 = prv_u16le( &c1[ 6 ] );
    dev->P2 = prv_s16le( &c1[ 8 ] );
    dev->P3 = prv_s16le( &c1[ 10 ] );
    dev->P4 = prv_s16le( &c1[ 12 ] );
    dev->P5 = prv_s16le( &c1[ 14 ] );
    dev->P6 = prv_s16le( &c1[ 16 ] );
    dev->P7 = prv_s16le( &c1[ 18 ] );
    dev->P8 = prv_s16le( &c1[ 20 ] );
    dev->P9 = prv_s16le( &c1[ 22 ] );
    dev->H1 = c1[ 25 ];
    dev->H2 = prv_s16le( &c2[ 0 ] );
    dev->H3 = c2[ 2 ];
    dev->H4 = ( int16_t ) ( ( c2[ 3 ] << 4 ) | ( c2[ 4 ] & 0x0Fu ) );
    dev->H5 = ( int16_t ) ( ( c2[ 5 ] << 4 ) | ( c2[ 4 ] >> 4 ) );
    dev->H6 = ( int8_t ) c2[ 6 ];

    /* Humidity oversampling x1 (must be written before ctrl_meas) */
    return i2c_write_reg( addr, REG_CTRL_HUM, 0x01 );
}

int bme280_read( bme280_t * dev, bme280_reading_t * out )
{
    uint8_t  raw[ 8 ];
    uint8_t  status;
    int      rc;
    int32_t  adc_T, adc_P, adc_H;
    int32_t  var1, var2, t_fine;
    uint32_t p;

    /* Forced mode, temp+press oversampling x1 -> one-shot measurement */
    rc = i2c_write_reg( dev->addr, REG_CTRL_MEAS, 0x25 );
    if( rc != I2C_OK ) return rc;

    /* Max measurement time at x1 oversampling is ~10 ms */
    for( int i = 0; i < 5; i++ )
    {
        vTaskDelay( pdMS_TO_TICKS( 10 ) > 0 ? pdMS_TO_TICKS( 10 ) : 1 );
        rc = i2c_read_reg( dev->addr, REG_STATUS, &status );
        if( rc != I2C_OK ) return rc;
        if( ( status & 0x08u ) == 0u ) break;    /* measuring bit clear */
    }

    rc = i2c_read_regs( dev->addr, REG_DATA, raw, 8 );
    if( rc != I2C_OK ) return rc;

    adc_P = ( int32_t ) ( ( ( uint32_t ) raw[ 0 ] << 12 ) | ( ( uint32_t ) raw[ 1 ] << 4 ) | ( raw[ 2 ] >> 4 ) );
    adc_T = ( int32_t ) ( ( ( uint32_t ) raw[ 3 ] << 12 ) | ( ( uint32_t ) raw[ 4 ] << 4 ) | ( raw[ 5 ] >> 4 ) );
    adc_H = ( int32_t ) ( ( ( uint32_t ) raw[ 6 ] << 8 ) | raw[ 7 ] );

    /* --- temperature (datasheet 4.2.3), result in 0.01 degC --- */
    var1 = ( ( ( ( adc_T >> 3 ) - ( ( int32_t ) dev->T1 << 1 ) ) ) * ( ( int32_t ) dev->T2 ) ) >> 11;
    var2 = ( ( ( ( ( adc_T >> 4 ) - ( ( int32_t ) dev->T1 ) ) *
                ( ( adc_T >> 4 ) - ( ( int32_t ) dev->T1 ) ) ) >> 12 ) *
            ( ( int32_t ) dev->T3 ) ) >> 14;
    t_fine = var1 + var2;
    out->temp_centi_c = ( t_fine * 5 + 128 ) >> 8;

    /* --- pressure, 32-bit variant, result in Pa --- */
    var1 = ( t_fine >> 1 ) - 64000;
    var2 = ( ( ( var1 >> 2 ) * ( var1 >> 2 ) ) >> 11 ) * ( ( int32_t ) dev->P6 );
    var2 = var2 + ( ( var1 * ( ( int32_t ) dev->P5 ) ) << 1 );
    var2 = ( var2 >> 2 ) + ( ( ( int32_t ) dev->P4 ) << 16 );
    var1 = ( ( ( dev->P3 * ( ( ( var1 >> 2 ) * ( var1 >> 2 ) ) >> 13 ) ) >> 3 ) +
             ( ( ( ( int32_t ) dev->P2 ) * var1 ) >> 1 ) ) >> 18;
    var1 = ( ( 32768 + var1 ) * ( ( int32_t ) dev->P1 ) ) >> 15;

    if( var1 == 0 )
    {
        out->press_pa = 0;    /* avoid divide by zero */
    }
    else
    {
        p = ( ( ( uint32_t ) ( ( ( int32_t ) 1048576 ) - adc_P ) - ( uint32_t ) ( var2 >> 12 ) ) ) * 3125u;

        if( p < 0x80000000u )
        {
            p = ( p << 1 ) / ( ( uint32_t ) var1 );
        }
        else
        {
            p = ( p / ( uint32_t ) var1 ) * 2u;
        }

        var1 = ( ( ( int32_t ) dev->P9 ) * ( ( int32_t ) ( ( ( p >> 3 ) * ( p >> 3 ) ) >> 13 ) ) ) >> 12;
        var2 = ( ( ( int32_t ) ( p >> 2 ) ) * ( ( int32_t ) dev->P8 ) ) >> 13;
        out->press_pa = ( uint32_t ) ( ( int32_t ) p + ( ( var1 + var2 + dev->P7 ) >> 4 ) );
    }

    /* --- humidity, result in %RH * 1024 --- */
    var1 = t_fine - ( ( int32_t ) 76800 );
    var1 = ( ( ( ( adc_H << 14 ) - ( ( ( int32_t ) dev->H4 ) << 20 ) -
                ( ( ( int32_t ) dev->H5 ) * var1 ) ) + ( ( int32_t ) 16384 ) ) >> 15 ) *
           ( ( ( ( ( ( ( var1 * ( ( int32_t ) dev->H6 ) ) >> 10 ) *
                    ( ( ( var1 * ( ( int32_t ) dev->H3 ) ) >> 11 ) + ( ( int32_t ) 32768 ) ) ) >> 10 ) +
                ( ( int32_t ) 2097152 ) ) * ( ( int32_t ) dev->H2 ) + 8192 ) >> 14 );
    var1 = var1 - ( ( ( ( ( var1 >> 15 ) * ( var1 >> 15 ) ) >> 7 ) * ( ( int32_t ) dev->H1 ) ) >> 4 );
    if( var1 < 0 ) var1 = 0;
    if( var1 > 419430400 ) var1 = 419430400;
    out->hum_milli_pct = ( uint32_t ) ( ( ( uint32_t ) ( var1 >> 12 ) ) * 1000u / 1024u );

    return I2C_OK;
}
