# Git 提交命令

## 描述
使用带签名的 git commit 提交代码变更，等效于 fish shell 中的 gitsign 函数。

## 用法
```bash
git -c user.signingkey=3927D7F5365B0203! commit -S -m "<commit_message>"
```

## 参数
- `user.signingkey=3927D7F5365B0203!`: 指定签名密钥ID
- `-S`: 启用 GPG 签名
- `-m "<message>"`: 提交消息

## 提交消息格式
遵循 conventional commits 规范：
- `feat:` - 新功能
- `fix:` - 修复bug
- `refactor:` - 重构代码
- `docs:` - 文档更新
- `test:` - 添加测试

## 示例
```bash
# 提交新功能
git -c user.signingkey=3927D7F5365B0203! commit -S -m "feat: 添加用户认证功能"

# 提交bug修复
git -c user.signingkey=3927D7F5365B0203! commit -S -m "fix: 修复登录验证问题"

# 多行提交消息
git -c user.signingkey=3927D7F5365B0203! commit -S -m "feat: 实现模块化架构

- 添加模块加载器
- 重构目录结构
- 更新依赖关系"
```

## 智能提交命令 (commit)

### 描述
自动分析暂存文件变更，生成合适的提交消息并执行签名提交。

### 实现
```bash
commit() {
    # 检查是否有暂存文件
    if ! git diff --staged --quiet; then
        # 分析变更类型和内容
        local staged_files=$(git diff --staged --name-status)
        local changes=$(git diff --staged)
        
        # 根据文件变更生成提交消息
        local commit_type="feat"
        local description=""
        local details=""
        
        # 分析变更类型
        if echo "$staged_files" | grep -q "^A.*\.sh$"; then
            commit_type="feat"
            description="添加新的脚本模块"
        elif echo "$staged_files" | grep -q "^M.*\.sh$"; then
            if echo "$changes" | grep -q "function\|def\|class"; then
                commit_type="feat"
                description="添加新功能"
            else
                commit_type="fix"
                description="修复问题"
            fi
        elif echo "$staged_files" | grep -q "^R"; then
            commit_type="refactor"
            description="重构代码结构"
        fi
        
        # 生成详细说明
        while IFS=$'\t' read -r status file; do
            case "$status" in
                A) details="$details\n- 添加 $file" ;;
                M) details="$details\n- 修改 $file" ;;
                D) details="$details\n- 删除 $file" ;;
                R*) details="$details\n- 重构 $file" ;;
            esac
        done <<< "$staged_files"
        
        # 执行提交
        local message="$commit_type: $description$details"
        git -c user.signingkey=3927D7F5365B0203! commit -S -m "$message"
    else
        echo "没有暂存的文件可提交"
    fi
}
```

### 使用方法
```bash
git add .
commit  # 自动分析并提交
```

## 约束规则
- **禁止添加 Claude 标识**：提交消息中不得包含任何表明是 AI 助手完成的标记
- **禁止自动签名**：不得在提交消息中添加 "Generated with Claude" 等标识
- **保持简洁**：提交消息应简洁明了，专注于变更内容本身

## 注意事项
- 确保 GPG 密钥已正确配置
- 提交前使用 `git status` 检查暂存状态
- 使用 `git diff --staged` 预览暂存的更改
- 提交消息必须是纯粹的代码变更描述，不包含任何 AI 相关标识