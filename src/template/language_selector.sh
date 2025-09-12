#!/usr/bin/env bash

# 模板管理器 - 负责语言发现和模板选择流程

require "lib.i18n"
require "lib.ui"
require "lib.utils"
require "lib.debugger"
require ".language_manifest"

# 初始化语言选择器翻译
_language_selector_init_i18n() {
    I18N_EN+=(
        ["template_no_languages"]="No programming languages found"
        ["template_select_language"]="Select Programming Language"
        ["template_handler_missing"]="Language handler function not found"
    )
    
    I18N_ZH+=(
        ["template_no_languages"]="没有找到可用的编程语言"
        ["template_select_language"]="选择编程语言"
        ["template_handler_missing"]="语言处理函数不存在"
    )
}

# 获取可用的编程语言列表
template_get_languages() {
    local template_dir="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/languages"
    local -a languages=()
    
    # 扫描 languages 目录
    for lang_dir in "$template_dir"/*/; do
        [[ -d "$lang_dir" ]] || continue
        
        local lang_name=$(basename "$lang_dir")
        local manifest_file="$lang_dir/manifest.sh"
        
        # 检查是否有 manifest.sh
        if [[ -f "$manifest_file" ]]; then
            # 使用 require 系统加载 manifest
            local module_path="template.languages.${lang_name}.manifest"
            if require "$module_path" 2>/dev/null; then
                local meta_function="${lang_name}_language_meta"
                if type "$meta_function" >/dev/null 2>&1; then
                    local lang_info
                    lang_info=$($meta_function)
                    languages+=($lang_info)
                else
                    # fallback 到语言名
                    languages+=("$lang_name" "$lang_name")
                fi
            fi
        fi
    done
    
    echo "${languages[@]}"
}

# 模板选择和生成主流程
template_main_workflow() {
    local project_name="$1"
    local target_dir="${2:-.}"
    
    # 初始化翻译
    _language_selector_init_i18n
    
    # 1. 获取可用语言
    local -a language_list
    language_list=($(template_get_languages))
    
    if [[ ${#language_list[@]} -eq 0 ]]; then
        ui_error "$(_t "template_no_languages")"
        return 1
    fi
    
    # 2. 选择编程语言
    local selected_language
    selected_language=$(ui_menu "$(_t "template_select_language")" "$(_t "template_select_language")" 80 20 10 "" "${language_list[@]}")
    cancelThenExit
    
    # 3. 确保语言 manifest 已加载并调用处理函数
    require "template.languages.${selected_language}.manifest"
    
    local handler_function="${selected_language}_handle_templates"
    
    if type "$handler_function" >/dev/null 2>&1; then
        "$handler_function" "$project_name" "$target_dir"
    else
        ui_error "$(_t "template_handler_missing"): $handler_function"
        return 1
    fi
}
