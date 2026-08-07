# ============================================================================
# Arty A7 pin constraints (same pinout for A7-35T and A7-100T)
# Verified against Digilent's Arty-A7-100-Master.xdc
# ============================================================================

# 100 MHz clock
set_property -dict { PACKAGE_PIN E3  IOSTANDARD LVCMOS33 } [get_ports clk100]
create_clock -period 10.000 -name sys_clk [get_ports clk100]

# Slide switches
set_property -dict { PACKAGE_PIN A8  IOSTANDARD LVCMOS33 } [get_ports {sw[0]}]
set_property -dict { PACKAGE_PIN C11 IOSTANDARD LVCMOS33 } [get_ports {sw[1]}]
set_property -dict { PACKAGE_PIN C10 IOSTANDARD LVCMOS33 } [get_ports {sw[2]}]
set_property -dict { PACKAGE_PIN A10 IOSTANDARD LVCMOS33 } [get_ports {sw[3]}]

# Push buttons
set_property -dict { PACKAGE_PIN D9  IOSTANDARD LVCMOS33 } [get_ports {btn[0]}]
set_property -dict { PACKAGE_PIN C9  IOSTANDARD LVCMOS33 } [get_ports {btn[1]}]
set_property -dict { PACKAGE_PIN B9  IOSTANDARD LVCMOS33 } [get_ports {btn[2]}]
set_property -dict { PACKAGE_PIN B8  IOSTANDARD LVCMOS33 } [get_ports {btn[3]}]

# Green LEDs
set_property -dict { PACKAGE_PIN H5  IOSTANDARD LVCMOS33 } [get_ports {led[0]}]
set_property -dict { PACKAGE_PIN J5  IOSTANDARD LVCMOS33 } [get_ports {led[1]}]
set_property -dict { PACKAGE_PIN T9  IOSTANDARD LVCMOS33 } [get_ports {led[2]}]
set_property -dict { PACKAGE_PIN T10 IOSTANDARD LVCMOS33 } [get_ports {led[3]}]

# RGB LEDs
set_property -dict { PACKAGE_PIN G6  IOSTANDARD LVCMOS33 } [get_ports led0_r]
set_property -dict { PACKAGE_PIN F6  IOSTANDARD LVCMOS33 } [get_ports led0_g]
set_property -dict { PACKAGE_PIN E1  IOSTANDARD LVCMOS33 } [get_ports led0_b]
set_property -dict { PACKAGE_PIN G3  IOSTANDARD LVCMOS33 } [get_ports led1_r]
set_property -dict { PACKAGE_PIN J4  IOSTANDARD LVCMOS33 } [get_ports led1_g]
set_property -dict { PACKAGE_PIN G4  IOSTANDARD LVCMOS33 } [get_ports led1_b]
set_property -dict { PACKAGE_PIN J3  IOSTANDARD LVCMOS33 } [get_ports led2_r]
set_property -dict { PACKAGE_PIN J2  IOSTANDARD LVCMOS33 } [get_ports led2_g]
set_property -dict { PACKAGE_PIN H4  IOSTANDARD LVCMOS33 } [get_ports led2_b]
set_property -dict { PACKAGE_PIN K1  IOSTANDARD LVCMOS33 } [get_ports led3_r]
set_property -dict { PACKAGE_PIN H6  IOSTANDARD LVCMOS33 } [get_ports led3_g]
set_property -dict { PACKAGE_PIN K2  IOSTANDARD LVCMOS33 } [get_ports led3_b]

# USB-UART bridge
set_property -dict { PACKAGE_PIN D10 IOSTANDARD LVCMOS33 } [get_ports uart_rxd_out]
set_property -dict { PACKAGE_PIN A9  IOSTANDARD LVCMOS33 } [get_ports uart_txd_in]

# Pmod JA
set_property -dict { PACKAGE_PIN G13 IOSTANDARD LVCMOS33 } [get_ports {ja[0]}]
set_property -dict { PACKAGE_PIN B11 IOSTANDARD LVCMOS33 } [get_ports {ja[1]}]
set_property -dict { PACKAGE_PIN A11 IOSTANDARD LVCMOS33 } [get_ports {ja[2]}]
set_property -dict { PACKAGE_PIN D12 IOSTANDARD LVCMOS33 } [get_ports {ja[3]}]
set_property -dict { PACKAGE_PIN D13 IOSTANDARD LVCMOS33 } [get_ports {ja[4]}]
set_property -dict { PACKAGE_PIN B18 IOSTANDARD LVCMOS33 } [get_ports {ja[5]}]
set_property -dict { PACKAGE_PIN A18 IOSTANDARD LVCMOS33 } [get_ports {ja[6]}]
set_property -dict { PACKAGE_PIN K16 IOSTANDARD LVCMOS33 } [get_ports {ja[7]}]

# Pmod JB
set_property -dict { PACKAGE_PIN E15 IOSTANDARD LVCMOS33 } [get_ports {jb[0]}]
set_property -dict { PACKAGE_PIN E16 IOSTANDARD LVCMOS33 } [get_ports {jb[1]}]
set_property -dict { PACKAGE_PIN D15 IOSTANDARD LVCMOS33 } [get_ports {jb[2]}]
set_property -dict { PACKAGE_PIN C15 IOSTANDARD LVCMOS33 } [get_ports {jb[3]}]
set_property -dict { PACKAGE_PIN J17 IOSTANDARD LVCMOS33 } [get_ports {jb[4]}]
set_property -dict { PACKAGE_PIN J18 IOSTANDARD LVCMOS33 } [get_ports {jb[5]}]
set_property -dict { PACKAGE_PIN K15 IOSTANDARD LVCMOS33 } [get_ports {jb[6]}]
set_property -dict { PACKAGE_PIN J15 IOSTANDARD LVCMOS33 } [get_ports {jb[7]}]

# Pmod JC
set_property -dict { PACKAGE_PIN U12 IOSTANDARD LVCMOS33 } [get_ports {jc[0]}]
set_property -dict { PACKAGE_PIN V12 IOSTANDARD LVCMOS33 } [get_ports {jc[1]}]
set_property -dict { PACKAGE_PIN V10 IOSTANDARD LVCMOS33 } [get_ports {jc[2]}]
set_property -dict { PACKAGE_PIN V11 IOSTANDARD LVCMOS33 } [get_ports {jc[3]}]
set_property -dict { PACKAGE_PIN U14 IOSTANDARD LVCMOS33 } [get_ports {jc[4]}]
set_property -dict { PACKAGE_PIN V14 IOSTANDARD LVCMOS33 } [get_ports {jc[5]}]
set_property -dict { PACKAGE_PIN T13 IOSTANDARD LVCMOS33 } [get_ports {jc[6]}]
set_property -dict { PACKAGE_PIN U13 IOSTANDARD LVCMOS33 } [get_ports {jc[7]}]

# Pmod JD
set_property -dict { PACKAGE_PIN D4  IOSTANDARD LVCMOS33 } [get_ports {jd[0]}]
set_property -dict { PACKAGE_PIN D3  IOSTANDARD LVCMOS33 } [get_ports {jd[1]}]
set_property -dict { PACKAGE_PIN F4  IOSTANDARD LVCMOS33 } [get_ports {jd[2]}]
set_property -dict { PACKAGE_PIN F3  IOSTANDARD LVCMOS33 } [get_ports {jd[3]}]
set_property -dict { PACKAGE_PIN E2  IOSTANDARD LVCMOS33 } [get_ports {jd[4]}]
set_property -dict { PACKAGE_PIN D2  IOSTANDARD LVCMOS33 } [get_ports {jd[5]}]
set_property -dict { PACKAGE_PIN H2  IOSTANDARD LVCMOS33 } [get_ports {jd[6]}]
set_property -dict { PACKAGE_PIN G2  IOSTANDARD LVCMOS33 } [get_ports {jd[7]}]

# Internal pull-ups on all Pmod pins, so the "touch test" mode (pins as
# inputs) reads a clean 1 until a pin is grounded
set_property PULLUP true [get_ports {ja[*]}]
set_property PULLUP true [get_ports {jb[*]}]
set_property PULLUP true [get_ports {jc[*]}]
set_property PULLUP true [get_ports {jd[*]}]

# Configuration settings
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
