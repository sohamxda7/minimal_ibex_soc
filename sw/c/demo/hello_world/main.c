// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0.
// SPDX-License-Identifier: Apache-2.0
// Copyright lowRISC contributors.
 
// Licensed under the Apache License, Version 2.0.
 
// SPDX-License-Identifier: Apache-2.0
#include <stdbool.h>
#include "demo_system.h"
 
#include "gpio.h"
 
#include "pwm.h"
 
#include "timer.h"
void test_uart_irq_handler(void) __attribute__((interrupt));
void test_uart_irq_handler(void)
 
{
 
    int uart_in_char;
    while ((uart_in_char = uart_in(DEFAULT_UART)) != -1)
 
    {
 
        uart_out(DEFAULT_UART, uart_in_char);
 
        uart_out(DEFAULT_UART, '\r');
 
        uart_out(DEFAULT_UART, '\n');
 
    }
 
}
int main(void)
 
{
 
    install_exception_handler(UART_IRQ_NUM, &test_uart_irq_handler);
 
    uart_enable_rx_int();
    //------------------------------------------------------

    // Timer tick = 0.1 s at the 20 MHz system clock (2_000_000 cycles).
    // NOTE: this was 10000 (= 0.5 ms), which made the RGB brightness ramp
    // and colour cycle run ~200x too fast — the LEDs strobed colours at
    // ~kHz rates, which looks like flickering/"glitching" on the board.

    //------------------------------------------------------

    timer_init();

    timer_enable(2000000);
    uint64_t last_elapsed_time = get_elapsed_time();
    //------------------------------------------------------
 
    // LED pattern
 
    //------------------------------------------------------
 
    uint8_t led_pattern = 0x10;
 
    set_outputs(GPIO_OUT, led_pattern);
    //------------------------------------------------------
 
    // PWM variables (unchanged)
 
    //------------------------------------------------------
 
    uint32_t counter    = UINT8_MAX;
 
    uint32_t brightness = 0;
 
    bool ascending      = true;
 
    uint8_t color       = 7;
    while (1)
 
    {
 
        uint64_t cur_time = get_elapsed_time();
        if (cur_time != last_elapsed_time)
 
        {
 
            last_elapsed_time = cur_time;
            //--------------------------------------------------
 
            // UART
 
            //--------------------------------------------------
 
            set_global_interrupt_enable(0);
            puts("Tick ");
 
            puthex(cur_time);
 
            puts(" LED=");
 
            puthex(led_pattern);
 
            putchar('\n');
            set_global_interrupt_enable(1);
            //--------------------------------------------------
 
            // Rotate LED pattern
 
            //--------------------------------------------------
            switch (led_pattern)
 
            {
 
                case 0x10: led_pattern = 0x20; break;
 
                case 0x20: led_pattern = 0x40; break;
 
                case 0x40: led_pattern = 0x80; break;
 
                case 0x80: led_pattern = 0xF0; break;
 
                case 0xF0: led_pattern = 0xA0; break;
 
                case 0xA0: led_pattern = 0x50; break;
 
                case 0x50: led_pattern = 0x30; break;
 
                case 0x30: led_pattern = 0x10; break;
 
                default:   led_pattern = 0x10; break;
 
            }
            set_outputs(GPIO_OUT, led_pattern);
            //--------------------------------------------------
 
            // PWM (unchanged)
 
            //--------------------------------------------------
            for (int i = 0; i < NUM_PWM_MODULES; i++)
 
            {
 
                set_pwm(
 
                    PWM_FROM_ADDR_AND_INDEX(PWM_BASE, i),
 
                    ((1 << (i % 3)) & color) ? counter : 0,
 
                    brightness ? 1 << (brightness - 1) : 0
 
                );
 
            }
            if (ascending)
 
            {
 
                brightness++;
                if (brightness >= 5)
 
                    ascending = false;
 
            }
 
            else
 
            {
 
                brightness--;
                if (brightness == 0)
 
                {
 
                    ascending = true;
 
                    color++;
                    if (color >= 8)
 
                        color = 1;
 
                }
 
            }
 
        }
 
 
        // asm volatile("wfi");
 
    }
 
}
