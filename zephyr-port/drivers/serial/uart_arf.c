/*
 * Zephyr serial driver for the ARF minimal UART (rtl/system/uart.sv).
 *
 * Register map (offsets from base 0x4000_0000):
 *   +0x0 RX     read: oldest byte in the RX FIFO (check STATUS first!)
 *   +0x4 TX     write: push byte into the TX FIFO
 *   +0x8 STATUS bit0 = RX FIFO empty, bit1 = TX FIFO full
 *
 * Polling implementation — sufficient for console/printk/shell. The
 * interrupt-driven API can be added later using the Ibex fast IRQ line
 * (uart_irq = "RX FIFO not empty", see uart.sv).
 */

#define DT_DRV_COMPAT arf_uart

#include <zephyr/device.h>
#include <zephyr/drivers/uart.h>
#include <zephyr/sys/sys_io.h>

#define ARF_UART_RX_OFF     0x0
#define ARF_UART_TX_OFF     0x4
#define ARF_UART_STATUS_OFF 0x8

#define ARF_UART_STATUS_RX_EMPTY BIT(0)
#define ARF_UART_STATUS_TX_FULL  BIT(1)

struct uart_arf_config {
	mem_addr_t base;
};

static int uart_arf_poll_in(const struct device *dev, unsigned char *c)
{
	const struct uart_arf_config *cfg = dev->config;

	if (sys_read32(cfg->base + ARF_UART_STATUS_OFF) & ARF_UART_STATUS_RX_EMPTY) {
		return -1;
	}
	*c = (unsigned char)(sys_read32(cfg->base + ARF_UART_RX_OFF) & 0xFF);
	return 0;
}

static void uart_arf_poll_out(const struct device *dev, unsigned char c)
{
	const struct uart_arf_config *cfg = dev->config;

	while (sys_read32(cfg->base + ARF_UART_STATUS_OFF) & ARF_UART_STATUS_TX_FULL) {
		/* wait for space in the 128-byte TX FIFO */
	}
	sys_write32((uint32_t)c, cfg->base + ARF_UART_TX_OFF);
}

static int uart_arf_init(const struct device *dev)
{
	/* Baud rate is fixed in hardware (ClockFrequency/BaudRate RTL
	 * parameters); nothing to configure at runtime. */
	ARG_UNUSED(dev);
	return 0;
}

static DEVICE_API(uart, uart_arf_api) = {
	.poll_in  = uart_arf_poll_in,
	.poll_out = uart_arf_poll_out,
};

#define UART_ARF_INIT(n)                                                     \
	static const struct uart_arf_config uart_arf_cfg_##n = {             \
		.base = DT_INST_REG_ADDR(n),                                 \
	};                                                                   \
	DEVICE_DT_INST_DEFINE(n, uart_arf_init, NULL, NULL,                  \
			      &uart_arf_cfg_##n, PRE_KERNEL_1,               \
			      CONFIG_SERIAL_INIT_PRIORITY, &uart_arf_api);

DT_INST_FOREACH_STATUS_OKAY(UART_ARF_INIT)
