# ============================================================================
# Build script: source files -> bitstream, no GUI needed.
# Run via build.bat, or manually:  vivado -mode batch -source scripts/build.tcl
# ============================================================================

# Arty A7-100T. If you ever use an Arty A7-35T instead, change this line to:
#   set part xc7a35ticsg324-1L
set part xc7a100tcsg324-1

# Work from the project root (one level up from this script)
cd [file dirname [file dirname [file normalize [info script]]]]
file mkdir build

create_project -in_memory -part $part

read_verilog [glob src/*.v]
read_xdc constraints/arty_a7.xdc

synth_design -top top -part $part
opt_design
place_design
route_design

report_timing_summary -file build/timing_summary.rpt
report_utilization    -file build/utilization.rpt

write_bitstream -force build/arty_io_test.bit

puts "=============================================="
puts "  BUILD OK  ->  build/arty_io_test.bit"
puts "  Next step: run program.bat with the board"
puts "  plugged in."
puts "=============================================="
