# =============================================================================
# Build a combined flash image (bitstream @0x0 + firmware @0x40_0000) and
# program it into the Arty A7-100T's onboard 16 MB QSPI flash (S25FL128).
#
#   vivado -mode batch -source program_flash.tcl
#   vivado -mode batch -source program_flash.tcl -tclargs sw/freertos/build/freertos_demo.bin
#
# After programming, press PROG on the board (or power-cycle): the FPGA
# configures itself from flash, and the SoC can then XIP the firmware at
# 0x2040_0000 (flash offset 0x40_0000 -- keep in sync with the boot
# trampoline in sw/asm-demo/xip_test.py and sw/freertos/link_xip.ld).
#
# Note: JTAG programming (program_fpga.tcl) still works and is faster for
# bitstream-only iteration; this flow is needed whenever the XIP firmware
# in flash must change.
# =============================================================================

set_param general.maxThreads 8    ;# Windows default is 2 - use the machine

set fw_bin "sw/freertos/build/freertos_demo.bin"
if {$argc >= 1} { set fw_bin [lindex $argv 0] }

set bit "build/fpga/top_artya7.bit"
if {![file exists $bit]}    { error "bitstream not found: $bit (run build_fpga.tcl first)" }
if {![file exists $fw_bin]} { error "firmware not found: $fw_bin (run sw\\freertos\\build.bat first)" }

set mcs "build/fpga/flash_image.mcs"
if {[catch {
    write_cfgmem -force -format mcs -size 16 -interface SPIx4 \
        -loadbit "up 0x0 $bit" \
        -loaddata "up 0x400000 $fw_bin" \
        $mcs
} err]} {
    if {[string match "*SPI_BUSWIDTH*" $err]} {
        puts "ERROR: this bitstream predates the QSPI-boot config fix (SPI_BUSWIDTH=1)."
        puts "Fix: git pull, then rebuild it - ibex_soc.bat -> Flash to Board (QSPI)"
        puts "(which rebuilds automatically), or the Build Bitstream button first."
    }
    error $err
}
puts "MCS written: $mcs"

open_hw_manager
connect_hw_server
open_hw_target
current_hw_device [lindex [get_hw_devices xc7a100t*] 0]
refresh_hw_device [current_hw_device]

create_hw_cfgmem -hw_device [current_hw_device] [lindex [get_cfgmem_parts {s25fl128sxxxxxx0-spi-x1_x2_x4}] 0]
set cfgmem [current_hw_cfgmem]
set_property PROGRAM.FILES [list $mcs] $cfgmem
set_property PROGRAM.ADDRESS_RANGE {use_file} $cfgmem
set_property PROGRAM.ERASE  1 $cfgmem
set_property PROGRAM.CFG_PROGRAM 1 $cfgmem
set_property PROGRAM.VERIFY 1 $cfgmem
create_hw_bitstream -hw_device [current_hw_device] [get_property PROGRAM.HW_CFGMEM_BITFILE [current_hw_device]]
program_hw_devices [current_hw_device]
program_hw_cfgmem -hw_cfgmem $cfgmem

puts "FLASH PROGRAMMED - press PROG or power-cycle the board"
close_hw_manager
