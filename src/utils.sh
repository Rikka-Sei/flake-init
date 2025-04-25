#!/usr/bin/env bash

cancelThenExit(){
    local return_code=$?
    # 如果没有传入参数，默认使用1作为退出码
    local exit_code=${1:-1}  

    if [ $return_code -ne 0 ]; then 
        exit $exit_code;
    fi
}