#!/usr/bin/env bash

declare -g -A LOADED_MODULES=()
declare -g LOADER_BASE_DIR=""

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
            local caller_dir=$(dirname "$(readlink -f "${BASH_SOURCE[1]}")")
            file_path="${caller_dir}/${relative_module//./\/}.sh"
        else
            # 绝对导入：从 main 函数所在文件位置加载
            file_path="${LOADER_BASE_DIR}/${module//./\/}.sh"
        fi
        
        if [[ -f "$file_path" ]]; then
            source "$file_path"
            LOADED_MODULES[$module]=1
            return 0
        else
            echo "Error: Module '$module' not found at $file_path" >&2
            return 1
        fi
    }
    
    # 必需模块加载
    require() {
        local module="$1"
        if ! load "$module"; then
            echo "Fatal: Required module '$module' failed to load" >&2
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