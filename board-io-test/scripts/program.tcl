# ============================================================================
# Program script: loads build/arty_io_test.bit onto the board over USB.
# Run via program.bat. The board must be plugged in and powered (red LD13 on).
# NOTE: this loads the FPGA's volatile memory - unplugging the board erases
# it. That is normal; just run program.bat again.
# ============================================================================

cd [file dirname [file dirname [file normalize [info script]]]]

if {![file exists build/arty_io_test.bit]} {
    puts "ERROR: build/arty_io_test.bit not found. Run build.bat first."
    exit 1
}

open_hw_manager
connect_hw_server
open_hw_target

set dev [lindex [get_hw_devices] 0]
current_hw_device $dev
set_property PROGRAM.FILE build/arty_io_test.bit $dev
program_hw_devices $dev

close_hw_manager

puts "=============================================="
puts "  BOARD PROGRAMMED!"
puts "  The green LEDs should be chasing right now."
puts "=============================================="
