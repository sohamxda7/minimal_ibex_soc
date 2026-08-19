# =============================================================================
# Generate a Vivado GUI project (.xpr) from the same sources as the batch
# flow - for teammates who want the FuseSoC-style project view for browsing,
# schematic/hierarchy inspection or interactive synthesis. The OFFICIAL build
# remains the non-project batch flow (the Build Bitstream flow): this project is a
# viewer, not a second build system.
#   vivado -mode batch -source gen_project.tcl   (or ibex_soc.bat -> Generate .xpr)
# Output: build/vivado_project/minimal_ibex_soc.xpr
# =============================================================================
cd [file dirname [file normalize [info script]]]
set part xc7a100tcsg324-1
create_project -force minimal_ibex_soc build/vivado_project -part $part

set fl [open dv/xsim/filelist.f r]
set srcs {}
while {[gets $fl line] >= 0} {
    set line [string trim $line]
    if {$line eq "" || [string index $line 0] eq "#"} { continue }
    lappend srcs $line
}
close $fl
add_files -norecurse $srcs
add_files -norecurse rtl/fpga/top_artya7.sv
add_files -fileset constrs_1 data/pins_artya7.xdc
set_property top top_artya7 [current_fileset]
# No SRAMInitFile: the boot ROM jumps directly into the XIP window
# (rtl/system/boot.mem, 2026-08-19) — SRAM ships uninitialised like silicon.
set_property include_dirs {vendor/lowrisc_ip/ip/prim/rtl rtl/system} [current_fileset]
update_compile_order -fileset sources_1
puts "PROJECT OK -> build/vivado_project/minimal_ibex_soc.xpr"
