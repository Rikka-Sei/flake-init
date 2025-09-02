#!/usr/bin/env bash

# whiptail UI 封装库
# 提供国际化支持、回调机制和进度条功能

# 依赖 i18n 模块
require "lib.i18n"

declare -g UI_DEFAULT_WIDTH=60
declare -g UI_DEFAULT_HEIGHT=10

# 初始化 UI 翻译
_init_ui_i18n() {
    # 扩展 i18n 字典，添加 UI 相关翻译
    I18N_EN+=(
        ["ui_ok"]="OK"
        ["ui_cancel"]="Cancel"
        ["ui_yes"]="Yes"
        ["ui_no"]="No"
        ["ui_back"]="Back"
        ["ui_next"]="Next"
        ["ui_select"]="Select"
        ["ui_loading"]="Loading..."
        ["ui_progress"]="Progress"
        ["ui_error"]="Error"
        ["ui_warning"]="Warning"
        ["ui_info"]="Information"
        ["ui_confirm"]="Confirm"
        ["ui_operation_cancelled"]="Operation cancelled."
    )
    
    I18N_ZH+=(
        ["ui_ok"]="确定"
        ["ui_cancel"]="取消"
        ["ui_yes"]="是"
        ["ui_no"]="否"
        ["ui_back"]="返回"
        ["ui_next"]="下一步"
        ["ui_select"]="选择"
        ["ui_loading"]="加载中..."
        ["ui_progress"]="进度"
        ["ui_error"]="错误"
        ["ui_warning"]="警告"
        ["ui_info"]="信息"
        ["ui_confirm"]="确认"
        ["ui_operation_cancelled"]="操作已取消。"
    )
}

# 获取本地化按钮文本
_ui_button() {
    local button_key="$1"
    _t "ui_${button_key}"
}

# 消息框
ui_msgbox() {
    local title="$1"
    local message="$2"
    local width="${3:-$UI_DEFAULT_WIDTH}"
    local height="${4:-$UI_DEFAULT_HEIGHT}"
    
    # 如果只有一个参数，则视为message，title为空
    if [[ $# -eq 1 ]]; then
        message="$1"
        title=""
    fi
    
    if [[ -n "$title" ]]; then
        whiptail --title "$title" \
                 --msgbox "$message" \
                 --ok-button "$(_ui_button "ok")" \
                 "$height" "$width"
    else
        whiptail --msgbox "$message" \
                 --ok-button "$(_ui_button "ok")" \
                 "$height" "$width"
    fi
}

# 确认对话框
ui_yesno() {
    local title="$1"
    local message="$2"
    local width="${3:-$UI_DEFAULT_WIDTH}"
    local height="${4:-$UI_DEFAULT_HEIGHT}"
    local callback="${5:-}"
    
    whiptail --title "$title" \
             --yesno "$message" \
             --yes-button "$(_ui_button "yes")" \
             --no-button "$(_ui_button "no")" \
             "$height" "$width"
    
    local result=$?
    
    # 执行回调
    if [[ -n "$callback" && $(type -t "$callback") == "function" ]]; then
        if [[ $result -eq 0 ]]; then
            "$callback" "yes"
        else
            "$callback" "no"
        fi
    fi
    
    return $result
}

# 输入框
ui_inputbox() {
    local title="$1"
    local message="$2"
    local default_value="${3:-}"
    local width="${4:-$UI_DEFAULT_WIDTH}"
    local height="${5:-8}"
    local callback="${6:-}"
    
    local result
    result=$(whiptail --title "$title" \
                     --inputbox "$message" \
                     --ok-button "$(_ui_button "ok")" \
                     --cancel-button "$(_ui_button "cancel")" \
                     "$height" "$width" "$default_value" \
                     3>&1 1>&2 2>&3)
    
    local exit_code=$?
    
    # 执行回调
    if [[ -n "$callback" && $(type -t "$callback") == "function" ]]; then
        if [[ $exit_code -eq 0 ]]; then
            "$callback" "ok" "$result"
        else
            "$callback" "cancel" ""
        fi
    fi
    
    # 返回结果到stdout
    if [[ $exit_code -eq 0 ]]; then
        echo "$result"
        return 0
    else
        return 1
    fi
}

# 菜单选择
ui_menu() {
    local title="$1"
    local message="$2"
    local width="${3:-$UI_DEFAULT_WIDTH}"
    local height="${4:-15}"
    local menu_height="${5:-6}"
    local callback="${6:-}"
    shift 6
    
    local result
    result=$(whiptail --title "$title" \
                     --menu "$message" \
                     --ok-button "$(_ui_button "select")" \
                     --cancel-button "$(_ui_button "cancel")" \
                     "$height" "$width" "$menu_height" \
                     "$@" \
                     3>&1 1>&2 2>&3)
    
    local exit_code=$?
    
    # 执行回调
    if [[ -n "$callback" && $(type -t "$callback") == "function" ]]; then
        if [[ $exit_code -eq 0 ]]; then
            "$callback" "select" "$result"
        else
            "$callback" "cancel" ""
        fi
    fi
    
    # 返回结果
    if [[ $exit_code -eq 0 ]]; then
        echo "$result"
        return 0
    else
        return 1
    fi
}

# 复选框列表
ui_checklist() {
    local title="$1"
    local message="$2"
    local width="${3:-$UI_DEFAULT_WIDTH}"
    local height="${4:-15}"
    local list_height="${5:-6}"
    local callback="${6:-}"
    shift 6
    
    local result
    result=$(whiptail --title "$title" \
                     --checklist "$message" \
                     --ok-button "$(_ui_button "ok")" \
                     --cancel-button "$(_ui_button "cancel")" \
                     "$height" "$width" "$list_height" \
                     "$@" \
                     3>&1 1>&2 2>&3)
    
    local exit_code=$?
    
    # 执行回调
    if [[ -n "$callback" && $(type -t "$callback") == "function" ]]; then
        if [[ $exit_code -eq 0 ]]; then
            "$callback" "ok" "$result"
        else
            "$callback" "cancel" ""
        fi
    fi
    
    # 返回结果
    if [[ $exit_code -eq 0 ]]; then
        echo "$result"
        return 0
    else
        return 1
    fi
}

# 进度输出伴生函数
ui_progress_emit() {
    local percent="$1"
    local message="${2:-}"
    
    if [[ -n "$message" ]]; then
        echo "XXX"
        echo "$percent"
        echo "$message"
        echo "XXX"
    else
        echo "$percent"
    fi
}

# 进度条 (通过回调函数输出进度)
ui_progress() {
    local title="$1"
    local message="$2"
    local callback="$3"
    local width="${4:-$UI_DEFAULT_WIDTH}"
    local height="${5:-8}"
    
    {
        "$callback"
    } | whiptail --title "$title" \
                 --gauge "$message" \
                 "$height" "$width" 0
}

# 错误提示框
ui_error() {
    local message="$1"
    local width="${2:-$UI_DEFAULT_WIDTH}"
    local height="${3:-$UI_DEFAULT_HEIGHT}"
    
    ui_msgbox "$(_ui_button "error")" "$message" "$width" "$height"
}

# 警告提示框  
ui_warning() {
    local message="$1"
    local width="${2:-$UI_DEFAULT_WIDTH}"
    local height="${3:-$UI_DEFAULT_HEIGHT}"
    
    ui_msgbox "$(_ui_button "warning")" "$message" "$width" "$height"
}

# 信息提示框
ui_info() {
    local message="$1"
    local width="${2:-$UI_DEFAULT_WIDTH}"
    local height="${3:-$UI_DEFAULT_HEIGHT}"
    
    ui_msgbox "$(_ui_button "info")" "$message" "$width" "$height"
}

# 设置默认尺寸
ui_set_defaults() {
    local width="$1"
    local height="$2"
    UI_DEFAULT_WIDTH="$width"
    UI_DEFAULT_HEIGHT="$height"
}

# 初始化UI模块
_init_ui_i18n