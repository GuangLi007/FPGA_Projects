set project_name "HDMI_Simple"
set part_number "xc7a35tfgg484-2"
set project_dir "/home/kl/My_Project/FPGA/HDMI_Simple"
set build_dir "$project_dir"

file delete -force "$build_dir/HDMI_Simple.cache"
file delete -force "$build_dir/HDMI_Simple.hw"
file delete -force "$build_dir/HDMI_Simple.ip_user_files"
file delete -force "$build_dir/HDMI_Simple.runs"
file delete -force "$build_dir/HDMI_Simple.xpr"

create_project $project_name $build_dir -part $part_number -force

set_property default_lib work [current_project]
set_property target_language Verilog [current_project]

add_files [glob "$project_dir/*.v"]
add_files -fileset constrs_1 [glob "$project_dir/*.xdc"]

set_property top hdmi_top [get_filesets sources_1]

launch_runs synth_1 -jobs 4
wait_on_run synth_1

launch_runs impl_1 -jobs 4
wait_on_run impl_1

open_run impl_1
write_bitstream -force "$build_dir/HDMI_Simple.bit"
puts "Build Completed Successfully!"
