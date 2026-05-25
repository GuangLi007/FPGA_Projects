open_hw_manager
connect_hw_server
open_hw_target
set dev [get_hw_devices]
set_property PROGRAM.FILE /home/kl/My_Project/FPGA/USART_Loopback/output/Usart_top.bit $dev
program_hw_devices $dev
puts "Programmed."
disconnect_hw_server
close_hw_manager
