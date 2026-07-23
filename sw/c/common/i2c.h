// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#ifndef I2C_H__
#define I2C_H__

#include <stdint.h>

/**********************************************************************
 * Register Offsets
 *********************************************************************/
#define I2C_PRER_LO_REG      0x00
#define I2C_PRER_HI_REG      0x04
#define I2C_CTR_REG          0x08
#define I2C_TXRX_REG         0x0c
#define I2C_CSR_REG          0x10

/**********************************************************************
 * Control Register
 *********************************************************************/
#define I2C_CTR_EN           (1 << 7)
#define I2C_CTR_IEN          (1 << 6)

/**********************************************************************
 * Command Register Bits
 *********************************************************************/
#define I2C_CR_STA           (1 << 7)
#define I2C_CR_STO           (1 << 6)
#define I2C_CR_RD            (1 << 5)
#define I2C_CR_WR            (1 << 4)
#define I2C_CR_ACK           (1 << 3)
#define I2C_CR_IACK          (1 << 0)

/**********************************************************************
 * Status Register Bits
 *********************************************************************/
#define I2C_SR_RXACK         (1 << 7)
#define I2C_SR_BUSY          (1 << 6)
#define I2C_SR_AL            (1 << 5)
#define I2C_SR_TIP           (1 << 1)
#define I2C_SR_IF            (1 << 0)

/**********************************************************************
 * Device Handle
 *********************************************************************/
typedef void *i2c_t;

#define I2C_FROM_BASE_ADDR(addr) ((i2c_t)(addr))

/**********************************************************************
 * Driver API
 *********************************************************************/

/* Initialize the controller */
void i2c_init(i2c_t i2c, uint16_t prescaler);

/* Enable/Disable controller */
void i2c_enable(i2c_t i2c);
void i2c_disable(i2c_t i2c);

/* Enable/Disable interrupt generation */
void i2c_enable_irq(i2c_t i2c);
void i2c_disable_irq(i2c_t i2c);

/* Single-byte register transactions */
int i2c_write(i2c_t i2c,
              uint8_t slave_addr,
              uint8_t reg_addr,
              uint8_t data);

int i2c_read(i2c_t i2c,
             uint8_t slave_addr,
             uint8_t reg_addr,
             uint8_t *data);

#endif  // I2C_H__
