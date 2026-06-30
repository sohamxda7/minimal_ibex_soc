// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#ifndef DEMO_SYSTEM_REGS_H__
#define DEMO_SYSTEM_REGS_H__

// ---------------------------------------------------------------------------
// Peripheral base addresses — must match wb_interconnect.sv / wrapper_top.sv
// ---------------------------------------------------------------------------
// All peripherals below are accessed via the CPU data bus through the OBI →
// Wishbone bridge (obi2wb → wb_interconnect inside wrapper_top).
//
// PREVIOUS (WRONG) addresses (0x8000_xxxx) came from the original Ibex Demo
// System register map that no longer matches the modified hardware.  These
// have been updated to the actual Wishbone decode addresses.
//
// Boot ROM  : 0x0010_0000 – 0x0010_0FFF  (4 KiB, instruction path only)
// SRAM      : 0x0010_2000 – 0x0010_3FFF  (8 KiB, data path only)

// UART — 256-byte window at 0x4000_0000
#define UART0_BASE 0x40000000

// GPIO — 256-byte window at 0x4000_0100
#define GPIO_BASE  0x40000100

// Timer — 256-byte window at 0x4000_0200
#define TIMER_BASE 0x40000200

// PWM — still on the legacy bus at 0x8000_3000 (connected to ibex_demo_system.sv
// bus, NOT through the wrapper_top OBI path).
// NOTE: PWM is currently INACCESSIBLE from the CPU data bus because CoreD host
// requests are routed exclusively through wrapper_top.  This base address is
// kept for reference; access will not work until PWM is moved to wrapper_top
// or CoreD is re-routed through the legacy bus.
#define PWM_BASE   0x40006000

// SPI host controller — 256-byte window at 0x4000_0500
#define SPI0_BASE  0x40000500

// I2C master — 256-byte window at 0x4000_0400
#define I2C0_BASE  0x40000400

// Simulation control (WFI-style halt) — no longer mapped in wrapper_top.
// The SIM_CTRL slot exists in the legacy bus enum but is not instantiated.
// Software using sim_halt() will hang waiting for an ACK that never arrives.
#define SIM_CTRL_BASE 0x00020000
#define SIM_CTRL_OUT  0x0
#define SIM_CTRL_CTRL 0x8

#endif  // DEMO_SYSTEM_REGS_H__
