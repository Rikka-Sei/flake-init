# list | load <rule_name>

管理项目规则文档的 Claude Code 命令。

## 子命令

### list
列出所有可用的规则文档文件。

**语法：** `rules list`

**功能：**
- 扫描 `docs/rules/` 目录
- 显示所有 `.md` 规则文件
- 提供文件的简要描述（如果可以从文件中提取）

### load
加载并显示指定的规则文档内容。

**语法：** `rules load <rule_name>`

**参数：**
- `rule_name`: 规则文件名（不需要 `.md` 扩展名）

**功能：**
- 读取 `docs/rules/{rule_name}.md` 文件内容
- 完整显示规则文档内容
- 如果文件不存在则显示错误信息

## 使用示例

```bash
# 列出所有规则文件
rules list

# 加载模板开发指南
rules load template_development_guide
```

## 实现

当用户执行这些命令时，Claude Code 将：

1. **`rules list`**: 
   - 使用 Glob 工具扫描 `docs/rules/*.md`
   - 列出找到的所有规则文件
   - 尝试从每个文件的第一行提取标题作为描述

2. **`rules load <rule_name>`**:
   - 使用 Read 工具读取 `docs/rules/{rule_name}.md`
   - 完整显示文件内容
   - 处理文件不存在的错误情况

这些命令帮助开发者快速访问和查看项目的规则文档，特别是在开发新模板或遵循项目规范时。