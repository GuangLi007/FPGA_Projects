create_project USART_RX /home/kl/My_Project/FPGA/USART_RX/USART_RX -part xc7a35tfgg484-2 -force
set_property target_language Verilog [current_project]

add_files -fileset sources_1 /home/kl/My_Project/FPGA/USART_RX/src/hdl/Usart_top.v
add_files -fileset sources_1 /home/kl/My_Project/FPGA/USART_RX/src/hdl/Uart_Byte_Rx.v
add_files -fileset constrs_1 /home/kl/My_Project/FPGA/USART_RX/src/constrs/cons.xdc

set_property top Usart_top [current_fileset]

launch_runs synth_1 -jobs 4
wait_on_run synth_1

launch_runs impl_1 -jobs 4
wait_on_run impl_1

launch_runs impl_1 -to_step write_bitstream
wait_on_run impl_1

puts "Build complete!"
