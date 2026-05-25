open_hw_manager
connect_hw_server
open_hw_target
current_hw_device [get_hw_devices]
refresh_hw_device -update_hw_probes false [get_hw_devices]
set_property PROBES.FILE {} [get_hw_devices]
set_property FULL_PROBES.FILE {} [get_hw_devices]
set_property PROGRAM.FILE {/home/kl/My_Project/FPGA/USART_RX/USART_RX/USART_RX.runs/impl_1/Usart_top.bit} [get_hw_devices]
program_hw_devices [get_hw_devices]
puts "Programming complete!"
