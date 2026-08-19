# ============================================================================
# Plain-Vivado batch build for the Arty A7 — no FuseSoC / Python needed.
#
#   Run from the REPO ROOT:
#     vivado -mode batch -source build_fpga.tcl
#   (or ibex_soc.bat -> Build Bitstream)
#
# Produces build/fpga/top_artya7.bit. Since 2026-08-19 the boot ROM jumps
# DIRECTLY into the XIP window (rtl/system/boot.mem) — SRAM ships
# uninitialised, exactly like silicon, and every bitstream boots from the
# QSPI flash with no SRAM trampoline bake.
# ============================================================================

# Arty A7-100T. For the A7-35T use: xc7a35ticsg324-1L
set part xc7a100tcsg324-1

# Optional SRAM init image (.vmem). Default: NONE — boot must not depend on
# SRAM contents (silicon SRAM powers up random). A DV/bring-up image can
# still be baked in explicitly:
#   vivado -mode batch -source build_fpga.tcl -tclargs sw/asm-demo/xip_stub.vmem
set sram_image ""
if {$argc > 0} { set sram_image [lindex $argv 0] }

# Work from the repo root (directory of this script) so the relative
# $readmemh paths inside the RTL (boot.mem, sram vmem) resolve.
cd [file dirname [file normalize [info script]]]
file mkdir build/fpga

create_project -in_memory -part $part

# Same compile list as the xsim flow, minus the sim-only files
set f [open dv/xsim/filelist.f r]
while {[gets $f line] >= 0} {
    set line [string trim $line]
    if {$line eq "" || [string index $line 0] eq "#"} { continue }
    read_verilog -sv $line
}
close $f

# FPGA top level + clock generator (20 MHz PLL)
read_verilog -sv rtl/fpga/top_artya7.sv
read_verilog -sv vendor/lowrisc_ibex/shared/rtl/fpga/xilinx/clkgen_xil7series.sv

read_xdc data/pins_artya7.xdc

# FPGA_XILINX selects the BUFGCE clock gate in dv/xsim/prim_shims.sv and the
# BSCANE2-based JTAG tap in the debug module.
set synth_args [list -top top_artya7 -part $part \
    -include_dirs {vendor/lowrisc_ip/ip/prim/rtl rtl/system vendor/lowrisc_ibex/vendor/lowrisc_ip/dv/sv/dv_utils} \
    -verilog_define FPGA_XILINX=1]
if {$sram_image ne ""} { lappend synth_args -generic SRAMInitFile=$sram_image }
synth_design {*}$synth_args

opt_design
place_design
route_design

report_timing_summary -file build/fpga/timing_summary.rpt
report_utilization    -file build/fpga/utilization.rpt

write_bitstream -force build/fpga/top_artya7.bit

puts "=============================================="
puts "  BUILD OK  ->  build/fpga/top_artya7.bit"
puts "  Program the board: ibex_soc.bat -> Program Board (JTAG)"
puts "=============================================="
