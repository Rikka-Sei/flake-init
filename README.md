# flake 脚手架

一个用于快速创建 NixOS Flake 项目模板的工具，支持多种编程语言和开发环境配置。

## 支持的环境和模板

| 支持环境 | 模板列表 |
|----------|----------|
| **rust** | **basic** - 基础 Rust 项目 |

## 使用

一般只需要
```
nix run github:Rikka-Sei/flake-init

# 或者下面的写法也可以
nix run github:Rikka-Sei/flake-init#flake-init
```
对于非标准仓库（不是来自Github的仓库）
```
nix run git+ssh://git@<ip/domain>/<username>/flake-init
```

如果脚本版本更新了，可以使用下面的写法来刷新本地缓存

```
nix run --refresh github:Rikka-Sei/flake-init
```

## 环境变量

### 调试等级控制

通过 `DEBUG_LEVEL` 环境变量可以控制输出的调试信息等级：

```bash
# 显示详细调试信息（包括模板发现、选择等内部过程）
DEBUG_LEVEL=log nix run --refresh github:Rikka-Sei/flake-init

# 默认等级，显示一般信息和进度
DEBUG_LEVEL=info nix run --refresh github:Rikka-Sei/flake-init

# 只显示警告和错误信息
DEBUG_LEVEL=warn nix run --refresh github:Rikka-Sei/flake-init
```

**支持的调试等级：**
- `log` - 详细调试信息（最详细）
- `info` - 一般信息和进度（默认）
- `success` - 成功消息
- `warn` - 警告信息
- `error` - 仅错误信息（最简洁）
