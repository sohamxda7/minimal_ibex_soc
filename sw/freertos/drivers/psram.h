#ifndef IBEX_PSRAM_H
#define IBEX_PSRAM_H

#include <stdint.h>

#define PSRAM_SIZE_BYTES     ( 8u * 1024u * 1024u )
#define PSRAM_SCRATCH_ADDR   0x000010u

/* Suggested layout (docs/PRODUCTION_PERIPHERALS.md):        */
#define PSRAM_CAM_FRAME_ADDR 0x100000u   /* camera frames    */
#define PSRAM_AUDIO_ADDR     0x200000u   /* voice clips      */
#define PSRAM_NET_BUF_ADDR   0x300000u   /* network buffers  */

void psram_write( uint32_t addr, const uint8_t * buf, uint32_t len );
void psram_read( uint32_t addr, uint8_t * buf, uint32_t len );
int  psram_selftest( void );   /* 0 = OK */

#endif
