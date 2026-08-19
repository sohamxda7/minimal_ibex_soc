# Compile order for xsim / Vivado (paths relative to repo root).
# Packages first, then primitives, then the cores, then the system.

# ---- packages ----
vendor/lowrisc_ip/ip/prim/rtl/prim_util_pkg.sv
vendor/lowrisc_ip/ip/prim/rtl/prim_count_pkg.sv
vendor/lowrisc_ip/ip/prim/rtl/prim_mubi_pkg.sv
vendor/lowrisc_ip/ip/prim/rtl/prim_secded_pkg.sv
vendor/lowrisc_ip/ip/prim/rtl/prim_ram_1p_pkg.sv
vendor/lowrisc_ip/ip/prim/rtl/prim_ram_2p_pkg.sv
vendor/lowrisc_ibex/rtl/ibex_pkg.sv
vendor/pulp_riscv_dbg/src/dm_pkg.sv
rtl/system/jtag_id_pkg.sv

# ---- primitive leaf cells (hand-written shims) + real prim RTL ----
dv/xsim/prim_shims.sv
vendor/lowrisc_ip/ip/prim/rtl/prim_count.sv
vendor/lowrisc_ip/ip/prim/rtl/prim_fifo_sync_cnt.sv
vendor/lowrisc_ip/ip/prim/rtl/prim_fifo_sync.sv
vendor/lowrisc_ip/ip/prim/rtl/prim_flop_2sync.sv
vendor/lowrisc_ip/ip/prim/rtl/prim_sync_reqack.sv
vendor/lowrisc_ip/ip/prim/rtl/prim_fifo_async_simple.sv

# ---- Ibex CPU core ----
vendor/lowrisc_ibex/rtl/ibex_alu.sv
vendor/lowrisc_ibex/rtl/ibex_branch_predict.sv
vendor/lowrisc_ibex/rtl/ibex_compressed_decoder.sv
vendor/lowrisc_ibex/rtl/ibex_controller.sv
vendor/lowrisc_ibex/rtl/ibex_core.sv
vendor/lowrisc_ibex/rtl/ibex_counter.sv
vendor/lowrisc_ibex/rtl/ibex_csr.sv
vendor/lowrisc_ibex/rtl/ibex_cs_registers.sv
vendor/lowrisc_ibex/rtl/ibex_decoder.sv
vendor/lowrisc_ibex/rtl/ibex_dummy_instr.sv
vendor/lowrisc_ibex/rtl/ibex_ex_block.sv
vendor/lowrisc_ibex/rtl/ibex_fetch_fifo.sv
vendor/lowrisc_ibex/rtl/ibex_icache.sv
vendor/lowrisc_ibex/rtl/ibex_id_stage.sv
vendor/lowrisc_ibex/rtl/ibex_if_stage.sv
vendor/lowrisc_ibex/rtl/ibex_load_store_unit.sv
vendor/lowrisc_ibex/rtl/ibex_lockstep.sv
vendor/lowrisc_ibex/rtl/ibex_multdiv_fast.sv
vendor/lowrisc_ibex/rtl/ibex_multdiv_slow.sv
vendor/lowrisc_ibex/rtl/ibex_pmp.sv
vendor/lowrisc_ibex/rtl/ibex_prefetch_buffer.sv
vendor/lowrisc_ibex/rtl/ibex_register_file_ff.sv
vendor/lowrisc_ibex/rtl/ibex_register_file_fpga.sv
vendor/lowrisc_ibex/rtl/ibex_register_file_latch.sv
vendor/lowrisc_ibex/rtl/ibex_top.sv
vendor/lowrisc_ibex/rtl/ibex_wb_stage.sv

# ---- RISC-V debug module ----
vendor/pulp_riscv_dbg/debug_rom/debug_rom.sv
vendor/pulp_riscv_dbg/debug_rom/debug_rom_one_scratch.sv
vendor/pulp_riscv_dbg/src/dm_sba.sv
vendor/pulp_riscv_dbg/src/dm_csrs.sv
vendor/pulp_riscv_dbg/src/dm_mem.sv
vendor/pulp_riscv_dbg/src/dmi_cdc.sv
vendor/pulp_riscv_dbg/src/dmi_jtag.sv
vendor/pulp_riscv_dbg/src/dmi_jtag_tap.sv
vendor/pulp_riscv_dbg/src/dmi_bscane_tap.sv

# ---- timer ----
vendor/lowrisc_ibex/shared/rtl/timer.sv

# ---- demo system RTL ----
rtl/system/debounce.sv
rtl/system/gpio.sv
rtl/system/uart.sv
rtl/system/spi_host.sv
rtl/system/spi_top.sv
rtl/system/boot_rom.sv
rtl/system/spi_flash_xip.sv
rtl/system/sram_controller.sv
rtl/system/sram_model.sv
rtl/system/dffram.sv
rtl/system/wb_interconnect.sv
rtl/system/obi2wb.sv
rtl/system/pwm.sv
rtl/system/pwm_wrapper.sv
rtl/system/i2c_wb_wrapper.v
rtl/system/i2c_master_top.v
rtl/system/i2c_master_byte_ctrl.v
rtl/system/i2c_master_bit_ctrl.v
rtl/system/dm_top.sv
rtl/system/wrapper_top.sv
rtl/system/ibex_demo_system.sv
