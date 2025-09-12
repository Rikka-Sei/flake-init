#!/usr/bin/env bash

# 通用语言模板处理流程
# 被各语言的 manifest.sh 调用，提供标准化的模板发现、选择和生成功能

require "lib.i18n"
require "lib.ui"
require "lib.utils"
require "lib.debugger"

# 初始化通用 manifest 翻译
_language_manifest_init_i18n() {
    I18N_EN+=(
        ["manifest_template_list_length"]="Template list length:"
        ["manifest_template_list_content"]="Template list content:"
        ["manifest_using_single_template"]="Using single template:"
        ["manifest_showing_template_menu"]="Showing template selection menu"
        ["manifest_calling_generator"]="Calling generator:"
        ["manifest_generator_not_found"]="Template generator function not found:"
        ["manifest_no_templates"]="No available templates"
        ["manifest_select_template_title"]="Select Template"
        ["manifest_select_template_prompt"]="Please select the template to use:"
    )
    
    I18N_ZH+=(
        ["manifest_template_list_length"]="模板列表长度:"
        ["manifest_template_list_content"]="模板列表内容:"
        ["manifest_using_single_template"]="直接使用唯一模板:"
        ["manifest_showing_template_menu"]="显示模板选择菜单"
        ["manifest_calling_generator"]="调用生成器:"
        ["manifest_generator_not_found"]="模板生成器函数不存在:"
        ["manifest_no_templates"]="没有可用的模板"
        ["manifest_select_template_title"]="选择模板"
        ["manifest_select_template_prompt"]="请选择要使用的模板："
    )
}
# 立即初始化
_language_manifest_init_i18n

# 通用模板发现函数
# 参数1: 结果数组的变量名（传递引用）
# 需要语言特定的 manifest.sh 提供 LANG_* 变量
_language_discover_templates() {
    local -n result_array_ref="$1"  # 使用nameref获取数组引用
    local lang_dir="$LANG_DIR"
    local lang_prefix="$LANG_PREFIX"
    
    # 清空结果数组
    result_array_ref=()
    
    # 扫描语言目录下的所有模板文件（除了 manifest.sh）
    for template_file in "$lang_dir"/*.sh; do
        local filename=$(basename "$template_file")
        
        # 跳过 manifest.sh 自身
        [[ "$filename" == "manifest.sh" ]] && continue
        
        # 获取模板ID（文件名去掉.sh）
        local template_id="${filename%.sh}"
        
        # 使用 require 加载模板文件
        require "template.languages.${lang_prefix}.${template_id}"
        
        # 获取模板信息（假设有标准函数）
        if type "_template_${lang_prefix}_${template_id}_get_info" >/dev/null 2>&1; then
            local info
            info=$(_template_${lang_prefix}_${template_id}_get_info)
            # 解析 "id|显示名称" 格式
            local display_name="${info#*|}"
            result_array_ref+=("$template_id" "$display_name")
        else
            # 如果没有标准函数，使用文件名
            result_array_ref+=("$template_id" "${lang_prefix^}-${template_id}")
        fi
    done
}

# 通用模板处理主函数
# 需要语言特定的 manifest.sh 提供配置变量：
# - LANG_NAME: 语言名称（用于调试日志）
# - LANG_PREFIX: 语言前缀（用于函数名）
# - LANG_DIR: 语言模板目录路径
# - LANG_SELECT_TITLE: 可选，模板选择标题
# - LANG_SELECT_PROMPT: 可选，模板选择提示
language_handle_templates() {
    local project_name="$1"
    local target_dir="$2"
    
    # 检查必需的变量是否已设置
    if [[ -z "$LANG_NAME" || -z "$LANG_PREFIX" || -z "$LANG_DIR" ]]; then
        ui_error "语言配置变量未正确设置 (LANG_NAME, LANG_PREFIX, LANG_DIR)"
        return 1
    fi
    
    # 获取可用模板
    local -a template_list
    _language_discover_templates template_list
    
    debuger log "${LANG_NAME}Manifest" "$(_t "manifest_template_list_length") ${#template_list[@]}"
    debuger log "${LANG_NAME}Manifest" "$(_t "manifest_template_list_content") ${template_list[*]}"
    
    if [[ ${#template_list[@]} -eq 0 ]]; then
        ui_error "$(_t "manifest_no_templates")"
        return 1
    elif [[ ${#template_list[@]} -eq 2 ]]; then
        # 只有一个模板，直接使用
        local template_id="${template_list[0]}"
        debuger log "${LANG_NAME}Manifest" "$(_t "manifest_using_single_template") $template_id"
        _language_generate_template "$template_id" "$project_name" "$target_dir"
    else
        # 多个模板，让用户选择
        debuger log "${LANG_NAME}Manifest" "$(_t "manifest_showing_template_menu")"
        local selected_template
        
        # 使用语言特定的选择标题，如果未设置则使用通用标题
        local select_title="${LANG_SELECT_TITLE:-$(_t "manifest_select_template_title")}"
        local select_prompt="${LANG_SELECT_PROMPT:-$(_t "manifest_select_template_prompt")}"
        
        selected_template=$(ui_menu "$select_title" "$select_prompt" 80 20 10 "" "${template_list[@]}")
        cancelThenExit
        
        _language_generate_template "$selected_template" "$project_name" "$target_dir"
    fi
}

# 通用模板生成函数
_language_generate_template() {
    local template_id="$1"
    local project_name="$2"
    local target_dir="$3"
    
    # 使用 require 加载模板文件
    require "template.languages.${LANG_PREFIX}.${template_id}"
    
    # 调用具体的模板生成函数
    local generator_function="template_${LANG_PREFIX}_${template_id}_generate"
    
    debuger log "${LANG_NAME}Generate" "$(_t "manifest_calling_generator") $generator_function"
    
    if type "$generator_function" >/dev/null 2>&1; then
        "$generator_function" "$project_name" "$target_dir"
    else
        ui_error "$(_t "manifest_generator_not_found") $generator_function"
        return 1
    fi
}