# 模板开发指南

本文档详细说明如何为 flake-init 项目创建新的编程语言模板，包括不同类型的项目模板（如基础项目、Web 框架项目等）。

## 目录结构规范

```
src/template/languages/{language}/
├── manifest.sh          # 语言元信息和模板管理
├── {template_type}.sh   # 具体模板实现
└── README.md            # 语言模板文档（可选）
```

## 1. 学习资源和既定模式

### 1.1 架构模式参考

在开始开发新模板前，需要从以下地方学习既定模式：

**现有实现参考：**
- `src/template/languages/rust/` - 参考现有的 Rust 模板实现
- `src/template/languages/rust/manifest.sh` - 学习语言 manifest 结构
- `src/template/languages/rust/basic.sh` - 学习具体模板的实现模式

**核心库参考：**
- `src/lib/i18n.sh` - 国际化实现模式
- `src/lib/ui.sh` - 用户界面组件使用方法
- `src/lib/loader.sh` - 模块加载系统使用方法

### 1.2 Nix/NixOS 学习资源

**官方文档：**
- [Nix Manual](https://nixos.org/manual/nix/stable/) - Nix 包管理器文档
- [NixOS Manual](https://nixos.org/manual/nixos/stable/) - NixOS 系统文档
- [Nixpkgs Manual](https://nixos.org/manual/nixpkgs/stable/) - Nixpkgs 包集合文档

**Flake 相关：**
- [Nix Flakes](https://nixos.wiki/wiki/Flakes) - Flake 概念和用法
- [flake-utils](https://github.com/numtide/flake-utils) - Flake 工具库

**开发环境：**
- [Development environments](https://nixos.wiki/wiki/Development_environment_with_nix-shell)
- [direnv integration](https://github.com/nix-community/nix-direnv)

### 1.3 特定语言/框架资源

**获取模板信息的地方：**
1. **官方脚手架工具** - 如 `cargo new`, `create-react-app`, `django-admin startproject`
2. **GitHub 模板仓库** - 搜索 `{language}-template` 或 `{framework}-starter`
3. **官方文档的快速开始部分** - 通常包含最小可运行示例
4. **社区最佳实践** - 如 Awesome 系列仓库
5. **现有 Nix 社区模板** - 在 [Nix Community](https://github.com/nix-community) 中查找

**具体示例：**
- **Rust Web (Yew)**: 
  - [Yew 官方文档](https://yew.rs/)
  - [Yew examples](https://github.com/yewstack/yew/tree/master/examples)
  - 现有的 `trunk` + `wasm-pack` Nix 配置

- **Python (Django)**:
  - [Django 官方教程](https://docs.djangoproject.com/en/stable/intro/tutorial01/)
  - [nixpkgs Python 文档](https://nixos.org/manual/nixpkgs/stable/#python)

## 2. 实现步骤

### 2.1 创建语言 Manifest

基于新的通用模板系统，创建 `src/template/languages/{language}/manifest.sh`：

```bash
#!/usr/bin/env bash

# {Language} 语言模板配置
# 设置 {Language} 相关的配置变量供通用模板系统使用

require "lib.i18n"
require "template.language_manifest"

# 初始化 {Language} 特定翻译
_${language}_manifest_init_i18n() {
    I18N_EN+=(
        ["${language}_language_description"]="Language description in English"
        ["${language}_select_template_title"]="Select {Language} Template"
        ["${language}_select_template_prompt"]="Please select the template to use:"
    )
    
    I18N_ZH+=(
        ["${language}_language_description"]="语言的中文描述"
        ["${language}_select_template_title"]="选择 {Language} 模板"
        ["${language}_select_template_prompt"]="请选择要使用的模板："
    )
}
# 立即初始化
_${language}_manifest_init_i18n

# 设置语言配置变量
LANG_NAME="{Language}"
LANG_PREFIX="${language}"
LANG_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
LANG_SELECT_TITLE="$(_t "${language}_select_template_title")"
LANG_SELECT_PROMPT="$(_t "${language}_select_template_prompt")"

# {Language} 语言元信息
${language}_language_meta() {
    echo "${language}" "$(_t "${language}_language_description")"
}

# {Language} 模板处理函数 - 使用通用模板系统
${language}_handle_templates() {
    language_handle_templates "$@"
}
```

**关键变化说明：**

1. **依赖简化**: 只需要 `lib.i18n` 和 `template.language_manifest`
2. **配置变量**: 通过设置 `LANG_*` 变量来配置通用模板系统
3. **代码大幅简化**: 从 ~100 行缩减到 ~30 行
4. **统一处理**: 所有复杂逻辑都交给通用模板系统处理

### 2.2 创建具体模板实现

创建 `src/template/languages/{language}/{template_type}.sh`：

```bash
#!/usr/bin/env bash

# {Language} {TemplateType} 项目模板
# 创建 {描述模板功能}

require "lib.i18n"
require "lib.ui" 
require "lib.utils"
require "lib.debugger"

# 获取 {Language} {TemplateType} 模板信息
_template_${language}_${template_type}_get_info() {
    echo "${template_type}|$(_t "${language}_${template_type}_name")"
}

# 初始化 {Language} {TemplateType} 模板翻译
_template_${language}_${template_type}_init_i18n() {
    I18N_EN+=(
        ["${language}_${template_type}_name"]="Template Name in English"
        ["${language}_${template_type}_description"]="Template description"
        # 添加更多翻译键...
    )
    
    I18N_ZH+=(
        ["${language}_${template_type}_name"]="模板中文名"
        ["${language}_${template_type}_description"]="模板描述"
        # 添加更多翻译键...
    )
}

# {Language} {TemplateType} 模板生成器
template_${language}_${template_type}_generate() {
    local project_name="$1"
    local target_dir="$2"
    
    # 1. 收集用户配置
    local user_input
    user_input=$(ui_inputbox "配置标题" "配置提示" "默认值")
    cancelThenExit
    
    # 2. 创建项目目录结构
    local project_path="$target_dir/$project_name"
    mkdir -p "$project_path"
    
    # 3. 生成项目文件
    _generate_${template_type}_files "$project_path" "$project_name" "$user_input"
    
    # 4. 生成 flake.nix
    _generate_${language}_${template_type}_flake "$project_path" "$project_name"
    
    debuger success "${Language}" "项目创建完成: $project_path"
}

# 生成项目文件的具体实现
_generate_${template_type}_files() {
    local project_path="$1"
    local project_name="$2"
    local config="$3"
    
    # 实现具体的文件生成逻辑
}

# 生成 flake.nix
_generate_${language}_${template_type}_flake() {
    local project_path="$1" 
    local project_name="$2"
    
    cat > "$project_path/flake.nix" << EOF
{
  description = "$project_name development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.\${system};
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # 添加项目依赖
          ];
          
          shellHook = ''
            echo "$project_name 开发环境已准备就绪！"
            # 添加环境设置
          '';
        };
      }
    );
}
EOF
}

# 初始化翻译
_template_${language}_${template_type}_init_i18n
```

## 3. 开发指导原则

### 3.1 模板系统架构

新的模板系统采用三层架构：

1. **语言选择器** (`language_selector.sh`): 负责扫描和选择编程语言
2. **通用模板系统** (`language_manifest.sh`): 提供标准化的模板发现、选择和生成流程
3. **语言特定配置** (`languages/{lang}/manifest.sh`): 只需设置配置变量

**通用模板系统提供的功能：**
- 自动模板发现（避免子shell问题）
- 统一的用户选择界面
- 标准化的错误处理
- 调试信息输出
- 模块加载管理

### 3.2 用户体验原则

1. **渐进式配置收集**：按需收集配置信息，避免一次性询问太多问题
2. **合理的默认值**：提供符合惯例的默认配置
3. **清晰的进度反馈**：使用 `debuger` 函数提供操作进度信息
4. **错误处理**：使用 `cancelThenExit` 处理用户取消操作

### 3.3 代码组织原则

1. **函数命名规范**：
   - 公共函数：`${language}_function_name`
   - 内部函数：`_generate_*` 或 `_template_*`
   - 翻译初始化：`_${module}_init_i18n`

2. **模块化设计**：将复杂的生成逻辑拆分为独立的函数

3. **国际化支持**：所有用户可见的文本都必须支持中英文

### 3.4 技术要求

1. **依赖声明**：
   - **绝对导入**：`require "lib.i18n"` (用于引用 src/lib/ 下的库)
   - **相对导入**：`require ".language_manifest"` (用于同目录文件)
   - 避免混合使用

2. **模块加载**：
   - 优先使用 `require` 而不是直接 `source`
   - 利用模块缓存避免重复加载
   - 获得更好的错误处理和调试信息

3. **错误处理**：关键操作后使用适当的错误检查
4. **路径处理**：使用绝对路径，避免相对路径问题
5. **权限检查**：生成文件前检查目标目录权限

## 4. 测试和验证

### 4.1 功能测试

```bash
# 测试模板发现
cd src && bash -c "source flake-init.sh && ${language}_discover_templates"

# 测试模板生成
mkdir -p /tmp/test-project
cd src && bash -c "source flake-init.sh && template_${language}_${template_type}_generate test-project /tmp/test-project"
```

### 4.2 集成测试

```bash
# 完整流程测试
nix run . # 运行完整的 flake-init 流程
```

### 4.3 生成结果验证

1. **文件结构检查**：确认生成的目录结构正确
2. **flake.nix 语法检查**：`nix flake check`
3. **开发环境测试**：`nix develop` 进入开发环境测试
4. **项目构建测试**：在生成的项目中执行构建命令

## 5. 最佳实践示例

### 5.1 收集配置的最佳实践

```bash
# 使用复选框让用户选择特性
local selected_features
selected_features=$(ui_checklist "项目特性" "选择要启用的特性：" 80 20 10 "" \
    "web" "Web API 支持" "ON" \
    "db" "数据库集成" "OFF" \
    "test" "测试框架" "ON")
cancelThenExit

# 解析选择结果
local enable_web=false enable_db=false enable_test=false
for feature in $selected_features; do
    case "${feature//\"/}" in
        "web") enable_web=true ;;
        "db") enable_db=true ;;
        "test") enable_test=true ;;
    esac
done
```

### 5.2 条件生成文件的最佳实践

```bash
# 根据用户选择生成不同文件
[[ "$enable_web" == true ]] && {
    debuger info "Generator" "生成 Web 相关文件..."
    _generate_web_files "$project_path"
}

[[ "$enable_db" == true ]] && {
    debuger info "Generator" "生成数据库配置..."
    _generate_db_config "$project_path"
}
```

### 5.3 flake.nix 模板最佳实践

```nix
{
  description = "项目描述";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    # 添加特定语言/框架的输入
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.\${system};
        # 条件性包含依赖
        webDeps = if enableWeb then [ pkgs.nodejs ] else [];
        dbDeps = if enableDb then [ pkgs.postgresql ] else [];
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # 基础依赖
          ] ++ webDeps ++ dbDeps;
          
          shellHook = ''
            # 环境设置
          '';
        };
        
        # 可选：提供包输出
        packages.default = pkgs.stdenv.mkDerivation {
          # 包定义
        };
      }
    );
}
```

## 6. 通用模板系统配置说明

### 6.1 必需的配置变量

每个语言的 `manifest.sh` 必须设置以下变量：

```bash
# 必需变量
LANG_NAME="显示名称"           # 用于调试日志，如 "Rust"
LANG_PREFIX="前缀"             # 用于函数名，如 "rust"
LANG_DIR="目录路径"            # 模板文件所在目录

# 可选变量（有默认值）
LANG_SELECT_TITLE="选择标题"   # 模板选择对话框标题
LANG_SELECT_PROMPT="选择提示" # 模板选择提示文本
```

### 6.2 模板发现机制

通用系统会自动：

1. **扫描模板文件**: 查找 `LANG_DIR` 下的所有 `.sh` 文件（除了 `manifest.sh`）
2. **加载模板**: 使用 `require` 加载每个模板文件
3. **获取信息**: 调用 `_template_${LANG_PREFIX}_${template_id}_get_info` 函数
4. **构建列表**: 生成模板选择列表供用户选择

### 6.3 错误处理增强

通用系统提供的错误处理：

- **模块加载失败**: 显示具体的调用者信息
- **配置验证**: 检查必需变量是否设置
- **模板验证**: 确认生成器函数存在
- **用户取消**: 统一处理用户取消操作

## 7. 扩展和维护

### 6.1 添加新的模板类型

1. 在对应语言目录下创建新的 `{template_type}.sh` 文件
2. 实现标准的函数接口
3. 添加相应的国际化翻译
4. 更新语言的 README.md 文档

### 6.2 版本兼容性

1. **向后兼容**：新版本应保持对现有模板的兼容
2. **弃用警告**：对于需要移除的功能，先添加弃用警告
3. **迁移指南**：提供从旧版本迁移到新版本的指南

### 6.3 文档更新

每个新模板都应该包含：
1. 模板功能描述
2. 生成的文件结构说明
3. 开发环境使用指南
4. 常见问题和解决方案

---

通过遵循此指南，您可以为 flake-init 项目贡献高质量、一致性和用户友好的模板。记住始终从用户体验的角度考虑设计决策，并保持代码的可维护性。