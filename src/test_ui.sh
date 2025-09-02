#!/usr/bin/env bash

# 测试 UI 封装库

_Local=$(dirname "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")
source "${_Local}/src/lib/loader.sh"
init_loader

require "lib.i18n"
require "lib.ui"

# 测试回调函数
test_callback() {
    local action="$1"
    local value="$2"
    echo "回调触发: action=$action, value='$value'"
}

echo "=== 测试 UI 库 ==="

# 测试消息框
echo "1. 测试消息框"
ui_msgbox "1. 测试消息框" "这是一个测试消息"

# 测试确认框
echo "2. 测试确认框"
if ui_yesno "2. 测试确认框" "你确定要继续吗？"; then
    echo "用户选择了：是"
else
    echo "用户选择了：否"
fi

# 测试输入框
echo "3. 测试输入框"
user_input=$(ui_inputbox "3. 测试输入框" "请输入你的名字：" "默认名字")
if [[ $? -eq 0 ]]; then
    echo "用户输入了：$user_input"
else
    echo "用户取消了输入"
fi

# 测试菜单
echo "4. 测试菜单"
choice=$(ui_menu "4. 测试菜单" "请选择一个选项：" 60 15 3 "" \
    "option1" "选项1" \
    "option2" "选项2" \
    "option3" "选项3")
if [[ $? -eq 0 ]]; then
    echo "用户选择了：$choice"
else
    echo "用户取消了选择"
fi

# 测试复选框
echo "5. 测试复选框"
selected=$(ui_checklist "5. 测试复选框" "请选择多个选项：" 60 15 3 "" \
    "item1" "项目1" "OFF" \
    "item2" "项目2" "ON" \
    "item3" "项目3" "OFF")
if [[ $? -eq 0 ]]; then
    echo "用户选择了：$selected"
else
    echo "用户取消了选择"
fi

# 测试进度条
echo "6. 测试进度条"
progress_callback() {
    for i in {0..100..10}; do
        ui_progress_emit "$i" "处理中... $i%"
        sleep 0.2
    done
}

ui_progress "6. 测试进度条" "正在处理..." "progress_callback"

# 测试错误/警告/信息框
echo "7. 测试错误提示框"
ui_error "这是一个错误消息"

echo "8. 测试警告提示框"
ui_warning "这是一个警告消息"

echo "9. 测试信息提示框"
ui_info "这是一个信息消息"

# 测试默认尺寸设置
echo "10. 测试默认尺寸设置"
ui_set_defaults 80 12
ui_msgbox "10. 测试默认尺寸设置" "这个对话框应该更宽更高"

# 测试取消检查函数
echo "11. 测试取消检查函数"
ui_yesno "11. 测试取消检查函数" "点击取消按钮测试 cancelThenExit"
cancelThenExit

echo "测试完成！"