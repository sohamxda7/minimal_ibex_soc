/*
 * Minimal Ibex SoC register map + accessors (docs/ASIC_SPEC.md section 3).
 * Single source of truth for firmware peripheral addresses.
 */

#ifndef IBEX_SOC_H
#define IBEX_SOC_H

#include <stdint.h>

#define SOC_CLK_HZ        20000000UL

/* ---- UART: RX +0, TX +4, STATUS +8 (bit0 rx_empty, bit1 tx_full) -------- */
#define UART_BASE         0x40000000UL
#define UART_RX_REG       ( UART_BASE + 0x0 )
#define UART_TX_REG       ( UART_BASE + 0x4 )
#define UART_STATUS_REG   ( UART_BASE + 0x8 )
#define UART_STATUS_RX_EMPTY  0x1u
#define UART_STATUS_TX_FULL   0x2u

/* ---- GPIO: OUT +0 (bits[7:4] LEDs, bits[3:0] display control), IN +8 ---- */
#define GPIO_BASE         0x40000100UL
#define GPIO_OUT_REG      ( GPIO_BASE + 0x0 )
#define GPIO_IN_RAW_REG   ( GPIO_BASE + 0x4 )   /* camera bus reads (no debounce) */
#define GPIO_IN_DBNC_REG  ( GPIO_BASE + 0x8 )
#define GPIO_LED_SHIFT    4
#define GPIO_LED_MASK     0xF0u
#define GPIO_DISP_MASK    0x0Fu   /* ST7735: bit0 CS, bit1 RST, bit2 DC, bit3 BL */
/* v1.1 production peripherals (gp_o[15:8], docs/PRODUCTION_PERIPHERALS.md) */
#define GPO_PSRAM_CS      ( 1u << 8 )    /* APS6404 PSRAM, active low  */
#define GPO_ADC_CS        ( 1u << 9 )    /* MCP3202 mic ADC, active low */
#define GPO_CAM_WEN       ( 1u << 10 )   /* OV7670-FIFO write enable    */
#define GPO_CAM_RRST      ( 1u << 11 )   /* FIFO read reset, ACTIVE LOW */
#define GPO_CAM_RCLK      ( 1u << 12 )   /* FIFO read clock             */
#define GPO_IDLE          ( GPO_PSRAM_CS | GPO_ADC_CS | GPO_CAM_RRST )
#define GPI_CAM_SHIFT     8              /* camera byte = raw gp_i[15:8] */

/* ---- Machine timer (CLINT-style): mtime +0/+4, mtimecmp +8/+12 ---------- */
#define TIMER_BASE        0x40000200UL
#define TIMER_MTIME       ( TIMER_BASE + 0x0 )
#define TIMER_MTIMEH      ( TIMER_BASE + 0x4 )
#define TIMER_MTIMECMP    ( TIMER_BASE + 0x8 )
#define TIMER_MTIMECMPH   ( TIMER_BASE + 0xC )

/* ---- I2C master (OpenCores; registers on 4-byte stride) ------------------ */
#define I2C_BASE          0x40000400UL
#define I2C_PRER_LO       ( I2C_BASE + 0x00 )
#define I2C_PRER_HI       ( I2C_BASE + 0x04 )
#define I2C_CTR           ( I2C_BASE + 0x08 )   /* bit7 core enable */
#define I2C_TXR           ( I2C_BASE + 0x0C )   /* write: data/addr byte */
#define I2C_RXR           ( I2C_BASE + 0x0C )   /* read: received byte */
#define I2C_CR            ( I2C_BASE + 0x10 )   /* write: command */
#define I2C_SR            ( I2C_BASE + 0x10 )   /* read: status */
#define I2C_CTR_EN        0x80u
#define I2C_CMD_STA       0x80u
#define I2C_CMD_STO       0x40u
#define I2C_CMD_RD        0x20u
#define I2C_CMD_WR        0x10u
#define I2C_CMD_NACK      0x08u
#define I2C_SR_RXACK      0x80u
#define I2C_SR_TIP        0x02u

/* ---- SPI host (mode 0, MSB first, 5 MHz): TX +0, STATUS +4 --------------- */
#define SPI_BASE          0x40000500UL
#define SPI_TX_REG        ( SPI_BASE + 0x0 )
#define SPI_STATUS_REG    ( SPI_BASE + 0x4 )
#define SPI_STATUS_TX_FULL   0x1u
#define SPI_STATUS_TX_EMPTY  0x2u
#define SPI_RX_REG        ( SPI_BASE + 0x8 )    /* v1.1: [7:0] rx byte, [15:8] seq */

/* ---- PWM, 12 ch (in both FPGA and ASIC - team-confirmed 2026-08-10) ------ */
#define PWM_BASE          0x40000600UL
#define PWM_CH_PULSE( n ) ( PWM_BASE + 8u * ( n ) )
#define PWM_CH_MAX( n )   ( PWM_BASE + 8u * ( n ) + 4u )
#define PWM_SPKR_CH       3               /* SPKR pad on the board top */

/* ---- UART2 (v1.1): ESP32 companion - WiFi/TCP-IP offload ------------------ */
#define UART2_BASE        0x40000700UL
#define UART2_RX_REG      ( UART2_BASE + 0x0 )
#define UART2_TX_REG      ( UART2_BASE + 0x4 )
#define UART2_STATUS_REG  ( UART2_BASE + 0x8 )

static inline uint32_t soc_read32( uint32_t addr )
{
    return *( volatile uint32_t * ) addr;
}

static inline void soc_write32( uint32_t addr, uint32_t val )
{
    *( volatile uint32_t * ) addr = val;
}

#endif /* IBEX_SOC_H */
