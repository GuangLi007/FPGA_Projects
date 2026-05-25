set outputDir /home/kl/My_Project/FPGA/USART_Loopback/output
set srcDir    /home/kl/My_Project/FPGA/USART_Loopback/src

create_project USART_Loopback ./USART_Loopback -part xc7a35tfgg484-2

add_files -fileset sources_1 [glob $srcDir/hdl/*.v]
add_files -fileset constrs_1 [glob $srcDir/constrs/*.xdc]

set_property top Usart_top [current_fileset]

synth_design -top Usart_top -part xc7a35tfgg484-2
opt_design
place_design
route_design
write_bitstream -force $outputDir/Usart_top.bit

puts ""
puts "=== Build complete ==="
puts "Bitstream: $outputDir/Usart_top.bit"
