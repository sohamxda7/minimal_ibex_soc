// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0.
// SPDX-License-Identifier: Apache-2.0
//
// UART-interactive LED/RGB demo for the ARF Ibex SoC (20 MHz system clock).
//
// Serial console: 115200 8N1. Commands (single characters):
//   1..4  : green-LED pattern — walking / nibble flip / alternating / count
//   f m s : pattern speed — fast (50 ms) / medium (150 ms) / slow (400 ms)
//   r g b : force RGB LEDs to one colour (breathing continues)
//   w     : force white   |   a : automatic colour cycling (default)
//   other : echoed back
//
// -------------------------------------------------------------------------
// FIXES relative to the draft this replaces (see docs/UART_CONTROL.md):
//  1. timer_enable() was called on EVERY main-loop pass. timer_enable()
//     zeroes time_elapsed and pushes mtimecmp into the future, so the timer
//     interrupt (almost) never fired and patterns never advanced. It is now
//     called once at startup and again only when the speed changes.
//  2. Speed table was inverted (FAST=50000 was the *largest* delay) and all
//     values were ~500x too fast for the 20 MHz clock (0.75-2.5 ms ticks),
//     which also flooded the UART (a status line takes ~2.6 ms at 115200).
//  3. Patterns 2/4 wrote gp_o[3:0], which are the DISP_CTRL/LCD lines on
//     Arty — only gp_o[7:4] are LEDs. All patterns now use the LED nibble.
//  4. Status spam: one line per tick floods the console at fast speeds;
//     status is now printed every 16th tick and on every command.
//  5. RGB control over UART (the actual goal) was missing — added r/g/b/w/a.
//  6. puthex(115200) printed "1C200" labelled as the baud rate; now literal.
// -------------------------------------------------------------------------

#include <stdbool.h>

#include "demo_system.h"
#include "gpio.h"
#include "pwm.h"
#include "timer.h"

// Timer tick counts @ 20 MHz for the three speeds
#define SPEED_FAST   1000000u   //  50 ms per pattern step
#define SPEED_MEDIUM 3000000u   // 150 ms per pattern step
#define SPEED_SLOW   8000000u   // 400 ms per pattern step

// RGB colour bit masks as used by the PWM loop: bit0=Blue, bit1=Green, bit2=Red
#define RGB_AUTO 0xFFu          // sentinel: keep cycling automatically

// Written by the UART IRQ handler, read by the main loop.
// (32-bit aligned accesses are atomic on RV32, volatile prevents caching.)
static volatile uint8_t  g_pattern_mode  = 0;
static volatile uint32_t g_speed_delay   = SPEED_MEDIUM;
static volatile bool     g_speed_changed = false;
static volatile uint8_t  g_rgb_force     = RGB_AUTO;

void uart_cmd_irq_handler(void) __attribute__((interrupt));

void uart_cmd_irq_handler(void) {
  int c;
  while ((c = uart_in(DEFAULT_UART)) != -1) {
    switch (c) {
      // ---- green-LED patterns ----
      case '1': g_pattern_mode = 0; puts("-> Pattern 1 (Walking 1)\r\n");     break;
      case '2': g_pattern_mode = 1; puts("-> Pattern 2 (Nibble flip)\r\n");   break;
      case '3': g_pattern_mode = 2; puts("-> Pattern 3 (Alternating)\r\n");   break;
      case '4': g_pattern_mode = 3; puts("-> Pattern 4 (Binary count)\r\n");  break;

      // ---- speed (re-armed by the main loop, not here: keep the ISR short
      //      and timer_enable() resets the elapsed-tick counter) ----
      case 'f': case 'F':
        g_speed_delay = SPEED_FAST;   g_speed_changed = true;
        puts("-> Speed: FAST\r\n");   break;
      case 'm': case 'M':
        g_speed_delay = SPEED_MEDIUM; g_speed_changed = true;
        puts("-> Speed: MEDIUM\r\n"); break;
      case 's': case 'S':
        g_speed_delay = SPEED_SLOW;   g_speed_changed = true;
        puts("-> Speed: SLOW\r\n");   break;

      // ---- RGB control ----
      case 'r': case 'R': g_rgb_force = 0x4;      puts("-> RGB: RED\r\n");   break;
      case 'g': case 'G': g_rgb_force = 0x2;      puts("-> RGB: GREEN\r\n"); break;
      case 'b': case 'B': g_rgb_force = 0x1;      puts("-> RGB: BLUE\r\n");  break;
      case 'w': case 'W': g_rgb_force = 0x7;      puts("-> RGB: WHITE\r\n"); break;
      case 'a': case 'A': g_rgb_force = RGB_AUTO; puts("-> RGB: AUTO\r\n");  break;

      default:
        uart_out(DEFAULT_UART, (char)c);   // echo anything unrecognised
        break;
    }
  }
}

int main(void) {
  install_exception_handler(UART_IRQ_NUM, &uart_cmd_irq_handler);
  uart_enable_rx_int();

  puts("\r\n========================================\r\n");
  puts("ARF Ibex SoC - UART-interactive demo\r\n");
  puts("Baudrate: 115200   Clock: 20 MHz\r\n");
  puts("  [1-4]   LED pattern    [f/m/s] speed\r\n");
  puts("  [r/g/b/w] RGB colour   [a] RGB auto\r\n");
  puts("========================================\r\n");

  // Timer: armed ONCE here; re-armed only on a speed change (fix #1).
  timer_init();
  timer_enable(g_speed_delay);
  set_global_interrupt_enable(1);

  uint64_t last_elapsed_time = get_elapsed_time();

  uint8_t  led_pattern = 0x10;   // gp_o[7:4] are the LEDs on Arty (fix #3)
  set_outputs(GPIO_OUT, led_pattern);

  uint32_t counter    = UINT8_MAX;
  uint32_t brightness = 0;
  bool     ascending  = true;
  uint8_t  color      = 4;       // start on red

  while (1) {
    // Re-arm the timer only when the user changed the speed (fix #1)
    if (g_speed_changed) {
      g_speed_changed = false;
      timer_enable(g_speed_delay);
      last_elapsed_time = get_elapsed_time();
    }

    uint64_t cur_time = get_elapsed_time();
    if (cur_time != last_elapsed_time) {
      last_elapsed_time = cur_time;

      // Rate-limited status line: every 16th tick (fix #4)
      if ((cur_time & 0xF) == 0) {
        set_global_interrupt_enable(0);
        puts("Tick ");     puthex((uint32_t)cur_time);
        puts(" Mode=");    puthex(g_pattern_mode);
        puts(" LED=");     puthex(led_pattern);
        putchar('\n');
        set_global_interrupt_enable(1);
      }

      // ---- green-LED patterns, LED nibble gp_o[7:4] only (fix #3) ----
      switch (g_pattern_mode) {
        case 0:  // walking single bit
          led_pattern = (uint8_t)(led_pattern << 1);
          if ((led_pattern & 0xF0) == 0) led_pattern = 0x10;
          led_pattern &= 0xF0;
          break;
        case 1:  // nibble flip: all on <-> all off
          led_pattern = (led_pattern == 0xF0) ? 0x00 : 0xF0;
          break;
        case 2:  // alternating pairs
          led_pattern = (led_pattern == 0xA0) ? 0x50 : 0xA0;
          break;
        case 3:  // binary count on the 4 LEDs
          led_pattern = (uint8_t)((led_pattern + 0x10) & 0xF0);
          break;
        default:
          led_pattern = 0x10;
          break;
      }
      set_outputs(GPIO_OUT, led_pattern);

      // ---- RGB breathing; colour forced or auto-cycled (fix #5) ----
      uint8_t rgb = (g_rgb_force != RGB_AUTO) ? g_rgb_force : color;
      for (int i = 0; i < NUM_PWM_MODULES; i++) {
        set_pwm(PWM_FROM_ADDR_AND_INDEX(PWM_BASE, i),
                ((1u << (i % 3)) & rgb) ? counter : 0,
                brightness ? 1u << (brightness - 1) : 0);
      }

      if (ascending) {
        brightness++;
        if (brightness >= 5) ascending = false;
      } else {
        brightness--;
        if (brightness == 0) {
          ascending = true;
          if (g_rgb_force == RGB_AUTO) {   // only auto-advance in auto mode
            color++;
            if (color >= 8) color = 1;
          }
        }
      }
    }

    asm volatile("wfi");   // sleep until the next interrupt
  }
}
