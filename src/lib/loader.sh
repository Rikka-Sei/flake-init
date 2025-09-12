#!/usr/bin/env bash

declare -g -A LOADED_MODULES=()
declare -g LOADER_BASE_DIR=""

# 获取调用者文件信息（排除 loader.sh 自身）
get_caller_info() {
    for ((i=1; i<${#BASH_SOURCE[@]}; i++)); do
        local current_file="${BASH_SOURCE[$i]}"
        if [[ "$(basename "$current_file")" != "loader.sh" ]]; then
            echo "$(basename "$current_file")"
            return 0
        fi
    done
    echo "unknown"
}

# 获取真正的调用者文件路径（用于相对导入）
get_caller_file() {
    for ((i=1; i<${#BASH_SOURCE[@]}; i++)); do
        local current_file="${BASH_SOURCE[$i]}"
        if [[ "$(basename "$current_file")" != "loader.sh" ]]; then
            echo "$current_file"
            return 0
        fi
    done
    echo ""
}

init_loader() {
    LOADER_BASE_DIR=$(dirname "$(readlink -f "${BASH_SOURCE[1]}")")
    
    load() {
        local module="$1"
        
        # 检查模块是否已加载
        [[ -n "${LOADED_MODULES[$module]}" ]] && return 0
        
        local file_path
        
        # 判断导入类型
        if [[ "$module" == .* ]]; then
            # 相对导入：从调用者文件所在目录加载
            local relative_module="${module#.}"
            local caller_file=$(get_caller_file)
            local caller_dir=$(dirname "$(readlink -f "$caller_file")")
            file_path="${caller_dir}/${relative_module//./\/}.sh"
            
            # 调试输出
            if type debuger >/dev/null 2>&1; then
                debuger log "Loader" "相对导入: $module"
                debuger log "Loader" "调用者文件: $caller_file"
                debuger log "Loader" "调用者目录: $caller_dir"
                debuger log "Loader" "最终路径: $file_path"
                debuger log "Loader" "文件存在: $([ -f "$file_path" ] && echo "是" || echo "否")"
            fi
        else
            # 绝对导入：从 main 函数所在文件位置加载
            file_path="${LOADER_BASE_DIR}/${module//./\/}.sh"
        fi
        
        if [[ -f "$file_path" ]]; then
            # 使用 source 加载文件，如果失败则立即退出
            if ! source "$file_path"; then
                local caller=$(get_caller_info)
                if type debuger >/dev/null 2>&1; then
                    debuger error "Loader" "Failed to source module '$module' from $file_path (called from: $caller)"
                else
                    echo "Error: Failed to source module '$module' from $file_path (called from: $caller)" >&2
                fi
                exit 1
            fi
            LOADED_MODULES[$module]=1
            return 0
        else
            local caller_file=$(get_caller_file)
            local caller_name=$(get_caller_info)
            if type debuger >/dev/null 2>&1; then
                debuger error "Loader" "Module '$module' not found at $file_path"
                debuger error "Loader" "  Called from: $caller_file"
            else
                echo "Error: Module '$module' not found at $file_path" >&2
                echo "  Called from: $caller_file" >&2
            fi
            return 1
        fi
    }
    
    # 必需模块加载
    require() {
        local module="$1"
        if ! load "$module"; then
            if type debuger >/dev/null 2>&1; then
                debuger error "Loader" "Fatal: Required module '$module' failed to load"
            else
                echo "Fatal: Required module '$module' failed to load" >&2
            fi
            exit 1
        fi
    }
    
    # 列出已加载模块
    list_loaded() {
        echo "Loaded modules:"
        for module in "${!LOADED_MODULES[@]}"; do
            echo "  - $module"
        done
    }
    
    # 导出函数供全局使用
    export -f load
    export -f require  
    export -f list_loaded
}

# 初始化加载器（当此脚本被source时自动执行）
# 注意：bash中source脚本时，脚本内容会在当前shell环境中执行，
# 因此这里的函数定义会直接添加到当前环境中