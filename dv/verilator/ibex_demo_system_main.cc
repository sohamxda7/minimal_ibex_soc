// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "ibex_demo_system.h"

int main(int argc, char **argv) {
  // SRAM hierarchy in the new OBI/WB architecture:
  //   wrapper_top.u_sram_model  (sram_model.sv, 8 KiB = 2048 × 32-bit words)
  // This scope must export simutil_memload / simutil_set_mem / simutil_get_mem
  // (implemented in sram_model.sv) for VerilatorMemUtil to pre-load the ELF.
  //
  // The SRAM is mapped at 0x00102000 in the hardware address space
  // (see RegisterMemoryArea call in ibex_demo_system.cc and link.ld).
  DemoSystem demo_system(
      "TOP.top_verilator.u_ibex_demo_system.u_wrapper.u_sram_model",
      2048);  // 2048 words × 4 B = 8 KiB

  return demo_system.Main(argc, argv);
}
