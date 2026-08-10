#ifndef IBEX_BME280_H
#define IBEX_BME280_H

#include <stdint.h>

#define BME280_ADDR_PRIMARY   0x76u   /* SDO low (most purple breakouts) */
#define BME280_ADDR_SECONDARY 0x77u   /* SDO high */
#define BME280_ERR_ID         (-3)

typedef struct
{
    uint8_t  addr;
    /* calibration (datasheet table 16) */
    uint16_t T1; int16_t T2, T3;
    uint16_t P1; int16_t P2, P3, P4, P5, P6, P7, P8, P9;
    uint8_t  H1; int16_t H2; uint8_t H3; int16_t H4, H5; int8_t H6;
} bme280_t;

typedef struct
{
    int32_t  temp_centi_c;    /* 2534  = 25.34 degC   */
    uint32_t press_pa;        /* 100523 = 1005.23 hPa */
    uint32_t hum_milli_pct;   /* 43250 = 43.250 %RH   */
} bme280_reading_t;

int bme280_init( bme280_t * dev, uint8_t addr );  /* probes ID, loads calibration */
int bme280_read( bme280_t * dev, bme280_reading_t * out ); /* forced-mode one-shot */

#endif
