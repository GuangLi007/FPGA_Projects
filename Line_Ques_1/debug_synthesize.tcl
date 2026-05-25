# Vivado工程创建脚本 - 由FPGABuilder生成 BY YiHok
# 项目: Line_Ques_1
# 器件: xc7a35tfgg484-2

# 创建工程
create_project Line_Ques_1 "./build" -part xc7a35tfgg484-2 -force

# 设置工程属性
set_property default_lib work [current_project]
set_property target_language Verilog [current_project]

# 设置IP库路径
set_property IP_REPO_PATHS [list {ip_repo}] [current_project]
update_ip_catalog

# 添加源文件

# 设置顶层模块

# 未指定顶层模块，使用Vivado默认行为

# 运行综合

set_property strategy "Vivado Synthesis Defaults" [get_runs synth_1]

launch_runs synth_1
wait_on_run synth_1

if {[get_property PROGRESS [get_runs synth_1]] != "100%"} {
    error "综合失败"
}

puts "综合完成"