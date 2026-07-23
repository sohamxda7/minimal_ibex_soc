// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "i2c.h"

#include "dev_access.h"

/**********************************************************************
 * Internal Register Access
 **********************************************************************/

static inline void i2c_write_reg(i2c_t i2c,
                                 uint32_t reg,
                                 uint8_t value)
{
    DEV_WRITE((uint32_t)i2c + reg, value);
}

static inline uint8_t i2c_read_reg(i2c_t i2c,
                                   uint32_t reg)
{
    return (uint8_t)DEV_READ((uint32_t)i2c + reg);
}

/**********************************************************************
 * Wait until current command finishes
 **********************************************************************/

/*static int i2c_wait(i2c_t i2c)
{
    uint8_t status;

    do
    {
        status = i2c_read_reg(i2c, I2C_CSR_REG);

    } while (status & I2C_SR_TIP);

    if (status & I2C_SR_RXACK)
        return -1;

    return 0;
}*/

//static int i2c_wait(i2c_t i2c)
//{
  //  uint8_t status;

    /* Wait for TIP to assert - guards against the 1-cycle race
     * between writing CR and TIP being registered. */
    /*do
    {
        status = i2c_read_reg(i2c, I2C_CSR_REG);
    } while (!(status & I2C_SR_TIP));*/

    /* Now wait for the command to actually complete. */
    /*do
    {
        status = i2c_read_reg(i2c, I2C_CSR_REG);
    } while (status & I2C_SR_TIP);

    if (status & I2C_SR_RXACK)
        return -1;

    return 0;
}*/

static int i2c_wait_tx(i2c_t i2c)
{
    uint8_t status;

    do
    {
        status = i2c_read_reg(i2c, I2C_CSR_REG);
    } while (!(status & I2C_SR_TIP));

    do
    {
        status = i2c_read_reg(i2c, I2C_CSR_REG);
    } while (status & I2C_SR_TIP);

    if (status & I2C_SR_RXACK)
        return -1;   // slave did not ACK — genuine failure for a WRITE

    return 0;
}

static int i2c_wait_rx(i2c_t i2c)
{
    uint8_t status;

    do
    {
        status = i2c_read_reg(i2c, I2C_CSR_REG);
    } while (!(status & I2C_SR_TIP));

    do
    {
        status = i2c_read_reg(i2c, I2C_CSR_REG);
    } while (status & I2C_SR_TIP);

    // RXACK here reflects the ACK/NACK bit the MASTER itself drove
    // (per the CR_ACK bit you set), not a slave response — so it is
    // not a failure condition for a read completion.
    return 0;
}

/**********************************************************************
 * Controller enable/disable
 **********************************************************************/

void i2c_enable(i2c_t i2c)
{
    i2c_write_reg(i2c,
                  I2C_CTR_REG,
                  I2C_CTR_EN);
}

void i2c_disable(i2c_t i2c)
{
    i2c_write_reg(i2c,
                  I2C_CTR_REG,
                  0x00);
}

void i2c_enable_irq(i2c_t i2c)
{
    i2c_write_reg(i2c,
                  I2C_CTR_REG,
                  I2C_CTR_EN |
                  I2C_CTR_IEN);
}

void i2c_disable_irq(i2c_t i2c)
{
    i2c_write_reg(i2c,
                  I2C_CTR_REG,
                  I2C_CTR_EN);
}

/**********************************************************************
 * Initialize I2C Controller
 **********************************************************************/

void i2c_init(i2c_t i2c,
              uint16_t prescaler)
{
    i2c_disable(i2c);

    i2c_write_reg(i2c,
                  I2C_PRER_LO_REG,
                  prescaler & 0xff);

    i2c_write_reg(i2c,
                  I2C_PRER_HI_REG,
                  prescaler >> 8);

    i2c_enable(i2c);
}

/**********************************************************************
 * Internal byte transmit
 **********************************************************************/

/*static int i2c_tx_byte(i2c_t i2c,
                       uint8_t data,
                       uint8_t command)
{
    i2c_write_reg(i2c,
                  I2C_TXRX_REG,
                  data);

    i2c_write_reg(i2c,
                  I2C_CSR_REG,
                  command);

    return i2c_wait(i2c);
}*/

/**********************************************************************
 * Internal byte receive
 **********************************************************************/

/*static int i2c_rx_byte(i2c_t i2c,
                       uint8_t *data,
                       uint8_t command)
{
    i2c_write_reg(i2c,
                  I2C_CSR_REG,
                  command);

    if (i2c_wait(i2c))
        return -1;

    *data = i2c_read_reg(i2c,
                         I2C_TXRX_REG);

    return 0;
}*/

static int i2c_tx_byte(i2c_t i2c, uint8_t data, uint8_t command)
{
    i2c_write_reg(i2c, I2C_TXRX_REG, data);
    i2c_write_reg(i2c, I2C_CSR_REG, command);
    return i2c_wait_tx(i2c);
}

static int i2c_rx_byte(i2c_t i2c, uint8_t *data, uint8_t command)
{
    i2c_write_reg(i2c, I2C_CSR_REG, command);

    if (i2c_wait_rx(i2c))
        return -1;

    *data = i2c_read_reg(i2c, I2C_TXRX_REG);
    return 0;
}

/**********************************************************************
 * Write one byte to an I2C slave register
 *
 * Sequence:
 *
 * START
 * Slave Address + Write
 * Register Address
 * Data
 * STOP
 *
 **********************************************************************/
int i2c_write(i2c_t i2c,
              uint8_t slave_addr,
              uint8_t reg_addr,
              uint8_t data)
{
    /* Slave Address + Write */
    if (i2c_tx_byte(i2c,
                    (slave_addr << 1),
                    I2C_CR_STA | I2C_CR_WR))
    {
        return -1;
    }

    /* Register Address */
    if (i2c_tx_byte(i2c,
                    reg_addr,
                    I2C_CR_WR))
    {
        return -1;
    }

    /* Data + STOP */
    if (i2c_tx_byte(i2c,
                    data,
                    I2C_CR_WR | I2C_CR_STO))
    {
        return -1;
    }

    return 0;
}


/**********************************************************************
 * Read one byte from an I2C slave register
 *
 * Sequence:
 *
 * START
 * Slave Address + Write
 * Register Address
 *
 * REPEATED START
 * Slave Address + Read
 *
 * READ BYTE
 * STOP
 *
 **********************************************************************/
int i2c_read(i2c_t i2c,
             uint8_t slave_addr,
             uint8_t reg_addr,
             uint8_t *data)
{
    if (data == 0)
    {
        return -1;
    }

    /* Slave Address + Write */
    if (i2c_tx_byte(i2c,
                    (slave_addr << 1),
                    I2C_CR_STA | I2C_CR_WR))
    {
        return -1;
    }

    /* Register Address */
    if (i2c_tx_byte(i2c,
                    reg_addr,
                    I2C_CR_WR))
    {
        return -1;
    }

    /* Repeated START + Slave Address + Read */
    if (i2c_tx_byte(i2c,
                    (slave_addr << 1) | 1,
                    I2C_CR_STA | I2C_CR_WR))
    {
        return -1;
    }

    /*
     * ACK bit = 1
     * Send NACK after receiving one byte.
     */

    if (i2c_rx_byte(i2c,
                    data,
                    I2C_CR_RD |
                    I2C_CR_ACK |
                    I2C_CR_STO))
    {
        return -1;
    }

    return 0;
}
