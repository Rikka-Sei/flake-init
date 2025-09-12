#!/usr/bin/env bash

# Rust 语言模板配置
# 设置 Rust 相关的配置变量供通用模板系统使用

require "lib.i18n"
require "template.language_manifest"

# 初始化 Rust 特定翻译
_rust_manifest_init_i18n() {
    I18N_EN+=(
        ["rust_language_description"]="Modern systems programming language, memory safety, high performance"
        ["rust_select_template_title"]="Select Rust Template"
        ["rust_select_template_prompt"]="Please select the template to use:"
    )
    
    I18N_ZH+=(
        ["rust_language_description"]="现代系统编程语言，内存安全，高性能"
        ["rust_select_template_title"]="选择 Rust 模板"
        ["rust_select_template_prompt"]="请选择要使用的模板："
    )
}
# 立即初始化
_rust_manifest_init_i18n

# 设置语言配置变量
LANG_NAME="Rust"
LANG_PREFIX="rust"
LANG_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
LANG_SELECT_TITLE="$(_t "rust_select_template_title")"
LANG_SELECT_PROMPT="$(_t "rust_select_template_prompt")"

# Rust 语言元信息
rust_language_meta() {
    echo "rust" "$(_t "rust_language_description")"
}

# Rust 模板处理函数 - 使用通用模板系统
rust_handle_templates() {
    language_handle_templates "$@"
}