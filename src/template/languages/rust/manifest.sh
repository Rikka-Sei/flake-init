#!/usr/bin/env bash

# Rust 语言模板管理
# 负责 Rust 相关模板的发现、注册和选择

require ".i18n"
require ".ui"
require ".utils"
require ".debugger"

# Rust 语言元信息
rust_language_meta() {
    echo "rust" "现代系统编程语言，内存安全，高性能"
}

# 发现 Rust 模板
rust_discover_templates() {
    local rust_dir="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
    local -a templates=()
    
    # 扫描当前目录下的所有模板文件（除了 manifest.sh）
    for template_file in "$rust_dir"/*.sh; do
        local filename=$(basename "$template_file")
        
        # 跳过 manifest.sh 自身
        [[ "$filename" == "manifest.sh" ]] && continue
        
        # 获取模板ID（文件名去掉.sh）
        local template_id="${filename%.sh}"
        
        # 加载模板文件
        source "$template_file"
        
        # 获取模板信息（假设有标准函数）
        if type "_template_rust_${template_id}_get_info" >/dev/null 2>&1; then
            local info
            info=$(_template_rust_${template_id}_get_info)
            # 解析 "id|显示名称" 格式
            local display_name="${info#*|}"
            templates+=("$template_id" "$display_name")
        else
            # 如果没有标准函数，使用文件名
            templates+=("$template_id" "Rust-${template_id}")
        fi
    done
    
    printf '%s\n' "${templates[@]}"
}

# Rust 模板选择和生成主函数
rust_handle_templates() {
    local project_name="$1"
    local target_dir="$2"
    
    # 获取可用模板
    local template_output
    template_output=$(rust_discover_templates)
    
    local -a template_list
    string_to_array template_list "$template_output"
    
    debuger info "RustManifest" "模板列表长度: ${#template_list[@]}"
    debuger info "RustManifest" "模板列表内容: ${template_list[*]}"
    
    if [[ ${#template_list[@]} -eq 0 ]]; then
        ui_error "没有可用的 Rust 模板"
        return 1
    elif [[ ${#template_list[@]} -eq 2 ]]; then
        # 只有一个模板，直接使用
        local template_id="${template_list[0]}"
        debuger info "RustManifest" "直接使用唯一模板: $template_id"
        rust_generate_template "$template_id" "$project_name" "$target_dir"
    else
        # 多个模板，让用户选择
        debuger info "RustManifest" "显示模板选择菜单"
        local selected_template
        selected_template=$(ui_menu "选择 Rust 模板" "请选择要使用的模板：" 80 20 10 "" "${template_list[@]}")
        cancelThenExit
        
        rust_generate_template "$selected_template" "$project_name" "$target_dir"
    fi
}

# 生成 Rust 模板
rust_generate_template() {
    local template_id="$1"
    local project_name="$2"
    local target_dir="$3"
    
    # 使用 require 加载模板文件
    require "template.languages.rust.${template_id}"
    
    # 调用具体的模板生成函数
    local generator_function="template_rust_${template_id}_generate"
    
    debuger info "RustGenerate" "调用生成器: $generator_function"
    
    if type "$generator_function" >/dev/null 2>&1; then
        "$generator_function" "$project_name" "$target_dir"
    else
        ui_error "模板生成器函数不存在: $generator_function"
        return 1
    fi
}