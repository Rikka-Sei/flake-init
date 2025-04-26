#!/usr/bin/env bash

# 确保 whiptail 已经安装
if ! command -v whiptail &> /dev/null; then
    echo "Error: whiptail command not found. Please install it (e.g., on NixOS: nix-shell -p newt)."
    exit 1
fi

# 加载依赖库
MAIN_script_path=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
source "${MAIN_script_path}/debugger.sh"
source "${MAIN_script_path}/i18n.sh"
source "${MAIN_script_path}/utils.sh"
source "${MAIN_script_path}/template/manifest.sh"

# 强制UTF-8环境
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# 初始化全局变量
project_name=""
selected_language=""
selected_outputs=""

# 欢迎消息
MAINfn_welcome(){
  whiptail --msgbox "$(_t "welcome_message")" 10 60
}


# 获取项目名
MAINfn_get_project_name(){
  project_name=$(whiptail --inputbox "$(_t "get_project_name")" 8 60 "my-project" 3>&1 1>&2 2>&3)
  cancelThenExit

  # 项目名称合法性检查
  if [ -z "$project_name" ]; then
    whiptail --msgbox "$(_t "invalid_project_name")" 8 40

    # 重新设置项目名
    MAINfn_get_project_name
  fi
}

# MAIN function
MAINfn(){
  MAINfn_welcome

  MAINfn_get_project_name
}
MAINfn