#!/usr/bin/env bash

# 模板发现和注册系统
# 自动扫描和加载可用的项目模板

require ".utils"
require ".debugger"
require "template.template_base"

SCRIPT_PATH=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")

# 初始化模板发现系统
template_manifest_init() {
    debuger info "Manifest" "初始化模板发现系统"
    
    # 自动发现并加载所有模板
    _template_discover_all
}

# 发现所有可用模板
_template_discover_all() {
    local template_dir="$SCRIPT_PATH/languages"
    
    # 确保模板目录存在
    if [[ ! -d "$template_dir" ]]; then
        debuger warn "Manifest" "模板目录不存在: $template_dir"
        return 1
    fi
    
    # 使用 while 读取避免子shell问题
    while IFS= read -r -d '' template_file; do
        local relative_path="${template_file#$template_dir/}"
        local module_path="template.languages.${relative_path%.sh}"
        module_path="${module_path//\//.}"
        
        debuger info "Manifest" "发现模板: $module_path"
        
        # 尝试加载模板模块
        if require "$module_path" 2>/dev/null; then
            debuger success "Manifest" "已加载模板: $module_path"
        else
            debuger warn "Manifest" "模板加载失败: $module_path"
        fi
    done < <(find "$template_dir" -type f -name "*.sh" -print0)
}

# 列出所有已注册的模板
template_list_all() {
    if [[ ${#TEMPLATE_REGISTRY[@]} -eq 0 ]]; then
        debuger warn "Manifest" "没有已注册的模板"
        return 1
    fi
    
    debuger info "Manifest" "已注册的模板:"
    for template_id in "${!TEMPLATE_REGISTRY[@]}"; do
        local name="${TEMPLATE_META[${template_id}_name]}"
        local category="${TEMPLATE_META[${template_id}_category]}"
        local description="${TEMPLATE_META[${template_id}_description]}"
        debuger info "Template" "  - $template_id: $name ($category) - $description"
    done
}

# 验证模板是否有效
template_validate() {
    local template_id="$1"
    
    # 检查模板是否已注册
    if [[ -z "${TEMPLATE_REGISTRY[$template_id]}" ]]; then
        debuger error "Validate" "模板未注册: $template_id"
        return 1
    fi
    
    # 检查生成器函数是否存在
    local generator_function="${TEMPLATE_REGISTRY[$template_id]}"
    if ! type -t "$generator_function" >/dev/null 2>&1; then
        debuger error "Validate" "生成器函数不存在: $generator_function"
        return 1
    fi
    
    debuger success "Validate" "模板验证通过: $template_id"
    return 0
}

# 导出模板信息为JSON格式（用于调试）
template_export_info() {
    echo "{"
    echo "  \"templates\": {"
    local first=true
    for template_id in "${!TEMPLATE_REGISTRY[@]}"; do
        [[ "$first" == "false" ]] && echo ","
        first=false
        
        echo "    \"$template_id\": {"
        echo "      \"name\": \"${TEMPLATE_META[${template_id}_name]}\","
        echo "      \"category\": \"${TEMPLATE_META[${template_id}_category]}\","
        echo "      \"description\": \"${TEMPLATE_META[${template_id}_description]}\","
        echo "      \"generator\": \"${TEMPLATE_REGISTRY[$template_id]}\""
        echo -n "    }"
    done
    echo ""
    echo "  }"
    echo "}"
}

