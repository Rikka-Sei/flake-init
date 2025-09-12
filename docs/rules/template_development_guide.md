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

首先创建 `src/template/languages/{language}/manifest.sh`：

```bash
#!/usr/bin/env bash

# {Language} 语言模板管理
# 负责 {Language} 相关模板的发现、注册和选择

require ".i18n"
require ".ui"
require ".utils"
require ".debugger"

# 初始化 {Language} manifest 翻译
_${language}_manifest_init_i18n() {
    I18N_EN+=(
        ["${language}_language_description"]="Language description in English"
        ["${language}_no_templates"]="No available {Language} templates"
        ["${language}_select_template_title"]="Select {Language} Template"
        ["${language}_select_template_prompt"]="Please select the template to use:"
    )
    
    I18N_ZH+=(
        ["${language}_language_description"]="语言的中文描述"
        ["${language}_no_templates"]="没有可用的 {Language} 模板"
        ["${language}_select_template_title"]="选择 {Language} 模板"
        ["${language}_select_template_prompt"]="请选择要使用的模板："
    )
}

# 原地初始化
_${language}_manifest_init_i18n 

# {Language} 语言元信息
${language}_language_meta() {
    echo "${language}" "$(_t "${language}_language_description")"
}

# 发现 {Language} 模板
${language}_discover_templates() {
    local ${language}_dir="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
    local -a templates=()
    
    # 扫描当前目录下的所有模板文件（除了 manifest.sh）
    for template_file in "$${language}_dir"/*.sh; do
        local filename=$(basename "$template_file")
        
        # 跳过 manifest.sh 自身
        [[ "$filename" == "manifest.sh" ]] && continue
        
        # 获取模板ID（文件名去掉.sh）
        local template_id="${filename%.sh}"
        
        # 加载模板文件
        source "$template_file"
        
        # 获取模板信息
        if type "_template_${language}_${template_id}_get_info" >/dev/null 2>&1; then
            local info
            info=$(_template_${language}_${template_id}_get_info)
            local display_name="${info#*|}"
            templates+=("$template_id" "$display_name")
        else
            templates+=("$template_id" "${Language}-${template_id}")
        fi
    done
    
    printf '%s\n' "${templates[@]}"
}

# {Language} 模板选择和生成主函数
${language}_handle_templates() {
    local project_name="$1"
    local target_dir="$2"
    
    local template_output
    template_output=$(${language}_discover_templates)
    
    local -a template_list
    string_to_array template_list "$template_output"
    
    if [[ ${#template_list[@]} -eq 0 ]]; then
        ui_error "$(_t "${language}_no_templates")"
        return 1
    elif [[ ${#template_list[@]} -eq 2 ]]; then
        local template_id="${template_list[0]}"
        ${language}_generate_template "$template_id" "$project_name" "$target_dir"
    else
        local selected_template
        selected_template=$(ui_menu "$(_t "${language}_select_template_title")" "$(_t "${language}_select_template_prompt")" 80 20 10 "" "${template_list[@]}")
        cancelThenExit
        
        ${language}_generate_template "$selected_template" "$project_name" "$target_dir"
    fi
}

# 生成 {Language} 模板
${language}_generate_template() {
    local template_id="$1"
    local project_name="$2"
    local target_dir="$3"
    
    require "template.languages.${language}.${template_id}"
    
    local generator_function="template_${language}_${template_id}_generate"
    
    if type "$generator_function" >/dev/null 2>&1; then
        "$generator_function" "$project_name" "$target_dir"
    else
        ui_error "Template generator function not found: $generator_function"
        return 1
    fi
}
```

### 2.2 创建具体模板实现

创建 `src/template/languages/{language}/{template_type}.sh`：

```bash
#!/usr/bin/env bash

# {Language} {TemplateType} 项目模板
# 创建 {描述模板功能}

require ".i18n"
require ".ui" 
require ".utils"
require ".debugger"

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

### 3.1 用户体验原则

1. **渐进式配置收集**：按需收集配置信息，避免一次性询问太多问题
2. **合理的默认值**：提供符合惯例的默认配置
3. **清晰的进度反馈**：使用 `debuger` 函数提供操作进度信息
4. **错误处理**：使用 `cancelThenExit` 处理用户取消操作

### 3.2 代码组织原则

1. **函数命名规范**：
   - 公共函数：`${language}_function_name`
   - 内部函数：`_generate_*` 或 `_template_*`
   - 翻译初始化：`_${module}_init_i18n`

2. **模块化设计**：将复杂的生成逻辑拆分为独立的函数

3. **国际化支持**：所有用户可见的文本都必须支持中英文

### 3.3 技术要求

1. **依赖声明**：在文件开头使用 `require` 声明依赖
2. **错误处理**：关键操作后使用适当的错误检查
3. **路径处理**：使用绝对路径，避免相对路径问题
4. **权限检查**：生成文件前检查目标目录权限

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

## 6. 扩展和维护

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