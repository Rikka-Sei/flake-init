#!/usr/bin/env bash

cancelThenExit(){
    local return_code=$?
    # 如果没有传入参数，默认使用1作为退出码
    local exit_code=${1:-1}  

    if [ $return_code -ne 0 ]; then 
        exit $exit_code;
    fi

    # 链式传递，将上一个行为的状态继续传递下去
    return $return_code
}

# 将换行分隔的字符串转换为数组
# 用法: string_to_array "变量名" "字符串内容"
string_to_array() {
    local -n array_ref="$1"
    local input_string="$2"
    
    array_ref=()
    while IFS= read -r line; do
        [[ -n "$line" ]] && array_ref+=("$line")
    done <<< "$input_string"
}