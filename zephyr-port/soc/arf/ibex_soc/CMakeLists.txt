# ARF Ibex SoC — uses the generic RISC-V arch support; nothing extra yet.
zephyr_include_directories(.)
set(SOC_LINKER_SCRIPT ${ZEPHYR_BASE}/include/zephyr/arch/riscv/common/linker.ld CACHE INTERNAL "")
