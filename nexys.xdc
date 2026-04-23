# ============================================
# Nexys A7-50T Constraints
# Audio Visualizer (PDM) – projekt DE1 14
# ============================================

# 100 MHz clock
set_property PACKAGE_PIN E3 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.00 [get_ports clk]

# Reset (BTNC)
set_property PACKAGE_PIN N17 [get_ports rst]
set_property IOSTANDARD LVCMOS33 [get_ports rst]

# Tlačítka
set_property PACKAGE_PIN P17 [get_ports btn_l_i]
set_property IOSTANDARD LVCMOS33 [get_ports btn_l_i]

set_property PACKAGE_PIN M17 [get_ports btn_r_i]
set_property IOSTANDARD LVCMOS33 [get_ports btn_r_i]

set_property PACKAGE_PIN M18 [get_ports btn_u_i]
set_property IOSTANDARD LVCMOS33 [get_ports btn_u_i]

set_property PACKAGE_PIN P18 [get_ports btn_d_i]
set_property IOSTANDARD LVCMOS33 [get_ports btn_d_i]

# SW0 – Beat mode on/off
set_property PACKAGE_PIN J15 [get_ports sw0_i]
set_property IOSTANDARD LVCMOS33 [get_ports sw0_i]

# PDM Microphone
set_property PACKAGE_PIN J5 [get_ports mic_clk_o]
set_property IOSTANDARD LVCMOS33 [get_ports mic_clk_o]

set_property PACKAGE_PIN H5 [get_ports mic_data_i]
set_property IOSTANDARD LVCMOS33 [get_ports mic_data_i]

set_property PACKAGE_PIN F5 [get_ports mic_lr_sel_o]
set_property IOSTANDARD LVCMOS33 [get_ports mic_lr_sel_o]

# 16x LEDs
set_property PACKAGE_PIN H17 [get_ports {led_o[0]}]
set_property PACKAGE_PIN K15 [get_ports {led_o[1]}]
set_property PACKAGE_PIN J13 [get_ports {led_o[2]}]
set_property PACKAGE_PIN N14 [get_ports {led_o[3]}]
set_property PACKAGE_PIN R18 [get_ports {led_o[4]}]
set_property PACKAGE_PIN V17 [get_ports {led_o[5]}]
set_property PACKAGE_PIN U17 [get_ports {led_o[6]}]
set_property PACKAGE_PIN U16 [get_ports {led_o[7]}]
set_property PACKAGE_PIN V16 [get_ports {led_o[8]}]
set_property PACKAGE_PIN T15 [get_ports {led_o[9]}]
set_property PACKAGE_PIN U14 [get_ports {led_o[10]}]
set_property PACKAGE_PIN T16 [get_ports {led_o[11]}]
set_property PACKAGE_PIN V15 [get_ports {led_o[12]}]
set_property PACKAGE_PIN V14 [get_ports {led_o[13]}]
set_property PACKAGE_PIN V12 [get_ports {led_o[14]}]
set_property PACKAGE_PIN V11 [get_ports {led_o[15]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led_o[*]}]
