#ifndef IBEX_CAMERA_H
#define IBEX_CAMERA_H

#include <stdint.h>

#define CAM_OK        0
#define CAM_ERR_I2C (-1)
#define CAM_ERR_ID  (-2)

#define CAM_QVGA_BYTES ( 320u * 240u * 2u )   /* RGB565 = 150 KB -> PSRAM */

int      cam_init( void );                    /* SCCB probe + QVGA config */
void     cam_capture_arm( void );             /* capture one frame to FIFO */
uint32_t cam_read_to_psram( uint32_t psram_addr, uint32_t len );

#endif
