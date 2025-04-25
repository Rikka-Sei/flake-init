#!/usr/bin/env bash

declare -A I18N_EN I18N_ZH I18N

# 设置语言，默认从环境变量获取，如果没有则使用英语
# 处理语言环境变量中的编码后缀(如zh_CN.UTF-8)
LANG_ENV=${LANG:-"en"}
LANG_ENV=${LANG%%.*}  # 移除.UTF-8等后缀

# 英文翻译
I18N_EN=(
    ["welcome_message"]="Welcome to the NixOS Flake Initializer!\n\nThis script will help you create a flake.nix file for your programming project."
    ["enter_name"]="Please enter your name:"
)

# 中文翻译
I18N_ZH=(
    ["welcome_message"]="欢迎使用 NixOS Flake 初始化工具！\n\n本脚本将帮助您为编程项目创建 flake.nix 配置文件。" 
    ["enter_name"]="请输入您的姓名："
)

# 遵守 [language][_TERRITORY] 注册语言
# language (ISO 639 语言代码)：https://en.wikipedia.org/wiki/List_of_ISO_639_language_codes
# territory (ISO 3166 国家代码): https://en.wikipedia.org/wiki/ISO_3166-1#Current_codes
I18N["en_US"]="I18N_EN"
I18N["zh_CN"]="I18N_ZH"

# 获取翻译
_t() {
    local key=$1
    local lang=${2:-$LANG_ENV}  # 允许临时覆盖语言
    
    # 检查语言是否支持
    if [[ -z "${I18N[$lang]}" ]]; then
        echo "[unsupported language: $lang]" >&2
        return 1
    fi
    
    local dict_name=${I18N[$lang]}
    declare -n dict="$dict_name"
    
    # 检查键是否存在
    if [[ -z "${dict[$key]}" ]]; then
        echo "[translation missing: $key]" >&2
        return 1
    fi
    
    echo "${dict[$key]}"
}