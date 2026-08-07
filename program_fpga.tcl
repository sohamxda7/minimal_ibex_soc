# Loads build/fpga/top_artya7.bit onto the Arty A7 over USB.
cd [file dirname [file normalize [info script]]]
if {![file exists build/fpga/top_artya7.bit]} {
    puts "ERROR: build/fpga/top_artya7.bit not found. Run build_fpga.bat first."
    exit 1
}
open_hw_manager
connect_hw_server
open_hw_target
set dev [lindex [get_hw_devices] 0]
current_hw_device $dev
set_property PROGRAM.FILE build/fpga/top_artya7.bit $dev
program_hw_devices $dev
close_hw_manager
puts "=============================================="
puts "  BOARD PROGRAMMED — open PuTTY at 115200."
puts "  Expect: 'IBEX-SOC UP n' lines + LED walk +"
puts "  RGB breathing. Typing echoes back."
puts "=============================================="
