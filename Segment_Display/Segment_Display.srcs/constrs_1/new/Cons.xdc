set_property PACKAGE_PIN Y18 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -name clk -period 20.000 [get_ports clk]

set_property PACKAGE_PIN F15 [get_ports reset_n]
set_property IOSTANDARD LVCMOS33 [get_ports reset_n]

set_property PACKAGE_PIN M18 [get_ports ds]
set_property IOSTANDARD LVCMOS33 [get_ports ds]

set_property PACKAGE_PIN F4 [get_ports sh_cp]
set_property IOSTANDARD LVCMOS33 [get_ports sh_cp]

set_property PACKAGE_PIN C2 [get_ports st_cp]
set_property IOSTANDARD LVCMOS33 [get_ports st_cp]

set_property PACKAGE_PIN G22 [get_ports {sw[0]}]
set_property PACKAGE_PIN D22 [get_ports {sw[1]}]
set_property PACKAGE_PIN E22 [get_ports {sw[2]}]
set_property PACKAGE_PIN G21 [get_ports {sw[3]}]
set_property PACKAGE_PIN E21 [get_ports {sw[4]}]
set_property PACKAGE_PIN D21 [get_ports {sw[5]}]
set_property PACKAGE_PIN C22 [get_ports {sw[6]}]
set_property PACKAGE_PIN B22 [get_ports {sw[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[*]}]
