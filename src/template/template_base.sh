#!/usr/bin/env bash

# 模板基础架构
# 提供模板注册、配置和生成的核心API

require ".i18n"
require ".ui"
require ".utils"

# 全局模板数据存储
declare -g -A TEMPLATE_REGISTRY=()      # 已注册的模板
declare -g -A TEMPLATE_META=()          # 模板元数据
declare -g -A TEMPLATE_OPTIONS=()       # 模板配置选项
declare -g -A TEMPLATE_FILES=()         # 模板生成的文件列表

# 初始化模板系统翻译
_template_base_init_i18n() {
    I18N_EN+=(
        ["template_select_language"]="Select Project Language"
        ["template_select_template"]="Select Template Type"
        ["template_configure_options"]="Configure Template Options"
        ["template_generating"]="Generating project files..."
        ["template_generation_complete"]="Project template generated successfully!"
        ["template_no_templates"]="No templates available for this language."
        ["template_invalid_selection"]="Invalid template selection."
        ["template_generation_failed"]="Template generation failed."
    )
    
    I18N_ZH+=(
        ["template_select_language"]="选择项目语言"
        ["template_select_template"]="选择模板类型"
        ["template_configure_options"]="配置模板选项"
        ["template_generating"]="正在生成项目文件..."
        ["template_generation_complete"]="项目模板生成成功！"
        ["template_no_templates"]="该语言没有可用的模板。"
        ["template_invalid_selection"]="无效的模板选择。"
        ["template_generation_failed"]="模板生成失败。"
    )
}

# 注册模板
template_register() {
    local template_id="$1"
    local name="$2"
    local category="$3"
    local category_display="$4"
    local description="$5"
    local generator_function="$6"
    
    TEMPLATE_REGISTRY["$template_id"]="$generator_function"
    TEMPLATE_META["${template_id}_name"]="$name"
    TEMPLATE_META["${template_id}_category"]="$category"
    TEMPLATE_META["${template_id}_description"]="$description"
    TEMPLATE_META["category_${category}_display"]="$category_display"
    
    debuger info "Template" "已注册模板: $template_id ($name)"
}

# 获取模板分类列表
template_get_categories() {
    local -a categories=()
    local -A seen=()
    
    for key in "${!TEMPLATE_META[@]}"; do
        if [[ "$key" == *"_category" ]]; then
            local category="${TEMPLATE_META[$key]}"
            if [[ -z "${seen[$category]}" ]]; then
                # 直接使用存储的分类显示名称
                local display_key="category_${category}_display"
                local display_name="${TEMPLATE_META[$display_key]:-$category}"
                categories+=("$category" "$display_name")
                seen["$category"]=1
            fi
        fi
    done
    
    echo "${categories[@]}"
}

# 按分类获取模板列表
template_list_by_category() {
    local target_category="$1"
    local templates=()
    
    for key in "${!TEMPLATE_META[@]}"; do
        if [[ "$key" == *"_category" ]]; then
            local template_id="${key%_category}"
            local category="${TEMPLATE_META[$key]}"
            
            if [[ "$category" == "$target_category" ]]; then
                local name="${TEMPLATE_META[${template_id}_name]}"
                local desc="${TEMPLATE_META[${template_id}_description]}"
                templates+=("$template_id" "$name - $desc")
            fi
        fi
    done
    
    echo "${templates[@]}"
}

# 生成模板文件
template_generate() {
    local template_id="$1"
    local project_name="$2"
    local target_dir="${3:-.}"
    
    # 验证模板是否存在
    if [[ -z "${TEMPLATE_REGISTRY[$template_id]}" ]]; then
        ui_error "$(_t "template_invalid_selection")"
        return 1
    fi
    
    # 获取生成器函数
    local generator_function="${TEMPLATE_REGISTRY[$template_id]}"
    
    # 检查生成器函数是否存在
    if ! type -t "$generator_function" >/dev/null 2>&1; then
        ui_error "模板生成器函数 '$generator_function' 不存在"
        return 1
    fi
    
    # 显示生成进度
    ui_progress "$(_t "template_generating")" "$(_t "template_generating")" _template_generate_progress &
    local progress_pid=$!
    
    # 执行模板生成
    if "$generator_function" "$project_name" "$target_dir"; then
        kill $progress_pid 2>/dev/null
        ui_info "$(_t "template_generation_complete")"
        return 0
    else
        kill $progress_pid 2>/dev/null
        ui_error "$(_t "template_generation_failed")"
        return 1
    fi
}

# 进度条回调函数
_template_generate_progress() {
    for i in {1..100}; do
        ui_progress_emit "$i" "$(_t "template_generating")"
        sleep 0.05
    done
}

# 从模板文件生成目标文件（支持变量替换）
template_generate_file() {
    local template_file="$1"
    local target_file="$2"
    shift 2
    
    # 其余参数作为变量替换对
    local content
    content=$(cat "$template_file")
    
    # 执行变量替换
    while [[ $# -ge 2 ]]; do
        local var_name="$1"
        local var_value="$2"
        content="${content//\{\{$var_name\}\}/$var_value}"
        shift 2
    done
    
    # 确保目标目录存在
    mkdir -p "$(dirname "$target_file")"
    
    # 写入文件
    echo "$content" > "$target_file"
    
    debuger success "File" "已生成: $target_file"
}

# 模板选择主流程
template_select_and_generate() {
    local project_name="$1"
    local target_dir="${2:-.}"
    
    # 1. 选择语言分类
    local categories
    categories=$(template_get_categories)
    
    if [[ -z "$categories" ]]; then
        ui_error "$(_t "template_no_templates")"
        return 1
    fi
    
    local selected_category
    selected_category=$(ui_menu "$(_t "template_select_language")" "$(_t "template_select_language")" 70 15 8 "" $categories)
    cancelThenExit
    
    # 2. 选择具体模板
    local templates
    templates=$(template_list_by_category "$selected_category")
    
    if [[ -z "$templates" ]]; then
        ui_error "$(_t "template_no_templates")"
        return 1
    fi
    
    local selected_template
    selected_template=$(ui_menu "$(_t "template_select_template")" "$(_t "template_select_template")" 80 20 10 "" $templates)
    cancelThenExit
    
    # 3. 生成模板
    template_generate "$selected_template" "$project_name" "$target_dir"
}

# 初始化模板基础系统
_template_base_init_i18n