#!/usr/bin/env bash

# 调试系统 - 保持原有API，优化内部实现
# 按业界标准重新排序等级：debug < info < warn < error
# 同时保留原有的 log, success, line 等级

# 默认调试等级
debug="info"

# 将等级名称转换为数字（按业界标准重新排序）
convert_level() {
    case $1 in
        log)     return 1 ;;  # 详细日志（类似debug）
        info)    return 2 ;;  # 信息
        success) return 2 ;;  # 成功消息（与info同级）
        warn)    return 3 ;;  # 警告
        error)   return 4 ;;  # 错误
        line)    return 0 ;;  # 分隔线（特殊处理，总是显示）
        *)       return 99 ;; # 无效等级
    esac
}

# 主调试函数 - 保持原有API
debuger() {
    # 获取当前设置的调试等级
    convert_level $debug
    option_level=$?

    # 获取输入消息的等级
    convert_level $1
    input_level=$?

    # 错误处理 - 保持原有行为
    if [ "$option_level" -eq 99 ] || [ "$input_level" -eq 99 ]; then
        echo -e "[\033[31mInner Error\033[0m] Please check your shell script"
        echo -e "Input Str:"
        echo -e "1: $1"
        echo -e "2: $2"
        echo -e "3: $3"
        exit 1
    fi

    # line 类型特殊处理 - 总是显示
    if [ "$1" = "line" ]; then
        echo ""
        return 0
    fi

    # 按等级过滤输出 - 只有等级足够高的消息才显示
    if [ "$input_level" -ge "$option_level" ]; then
        case $1 in
            log)
                echo -e "[\033[48;5;235m\033[93m$2\033[0m] $3"
                return 0
            ;;
            info)
                echo -e "[\033[37m$2\033[0m] $3"
                return 0
                ;;
            success)
                echo -e "[\033[32m$2\033[0m] $3"
                return 0
                ;;
            warn)
                echo -e "[\033[33m$2\033[0m] $3"
                return 0
                ;;
            error)
                echo -e "[\033[31m$2\033[0m] $3"
                return 0
                ;;
            *)
                echo -e "[\033[31mInner Error\033[0m] Please check your shell script"
                echo -e "Input Str:"
                echo -e "1: $1"
                echo -e "2: $2"
                echo -e "3: $3"
                exit 1
                ;;
        esac
    fi
}

# 检查成功函数 - 保持原有API
check_success() {
    if [ $? -ne 0 ]; then
        debuger error "Fail" "$1"
        exit 1
    else
        debuger success "OK" "$1"
    fi
}