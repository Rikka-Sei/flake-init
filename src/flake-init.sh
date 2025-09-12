#!/usr/bin/env bash

# 确保 whiptail 已经安装
if ! command -v whiptail &> /dev/null; then
    echo "Error: whiptail command not found. Please install it (e.g., on NixOS: nix-shell -p newt)."
    exit 1
fi

# 加载依赖库
_Local=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
source "${_Local}/lib/loader.sh"
init_loader

require "lib.debugger"
require "lib.i18n"
require "lib.ui"
require "lib.utils"
require "template.language_selector"

# 强制UTF-8环境
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# 初始化 main 翻译
_main_init_i18n() {
    I18N_EN+=(
        ["main_welcome_message"]="Welcome to the NixOS Flake Initializer!\n\nThis script will help you create a flake.nix file for your programming project."
        ["main_get_project_name"]="Enter your project name:"
        ["main_project_name_title"]="Project Setup"
        ["main_invalid_project_name"]="Project name cannot be empty!"
        ["main_select_template"]="Select Template Type"
        ["main_template_generated"]="Template generated successfully in directory:"
    )
    
    I18N_ZH+=(
        ["main_welcome_message"]="欢迎使用 NixOS Flake 初始化工具！\n\n本脚本将帮助您为编程项目创建 flake.nix 配置文件。"
        ["main_get_project_name"]="请输入您的项目名："
        ["main_project_name_title"]="项目设置"
        ["main_invalid_project_name"]="项目名不能为空！"
        ["main_select_template"]="选择模板类型"
        ["main_template_generated"]="模板已成功生成到目录："
    )
}

# 初始化全局变量
project_name=""
selected_language=""
selected_outputs=""

# 欢迎消息
main_welcome(){
  ui_msgbox "$(_t "main_welcome_message")"
}


# 获取项目名
main_get_project_name(){
  project_name=$(ui_inputbox "$(_t "main_project_name_title")" "$(_t "main_get_project_name")" "my-project")
  cancelThenExit

  # 项目名称合法性检查
  if [ -z "$project_name" ]; then
    ui_msgbox "$(_t "main_invalid_project_name")"

    # 重新设置项目名
    main_get_project_name
  fi
}

# 模板选择和生成
main_template_workflow() {
    # 使用新的模板管理器
    if template_main_workflow "$project_name" "."; then
        ui_info "$(_t "main_template_generated") $project_name/"
    else
        ui_error "模板生成失败"
        return 1
    fi
}

# MAIN function
main(){
  _main_init_i18n
  
  main_welcome
  main_get_project_name
  main_template_workflow
}
main