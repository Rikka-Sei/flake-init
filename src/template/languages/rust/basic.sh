#!/usr/bin/env bash

# Rust 基础项目模板
# 创建带有 Cargo 的标准 Rust 项目

require "template.template_base"

# 注册 Rust 基础模板
_template_rust_basic_register() {
    template_register \
        "rust_basic" \
        "$(_t "rust_basic_name")" \
        "rust" \
        "$(_t "rust_category_description")" \
        "$(_t "rust_basic_description")" \
        "template_rust_basic_generate"
}

# 初始化 Rust 模板翻译
_template_rust_basic_init_i18n() {
    I18N_EN+=(
        ["rust_basic_name"]="Basic Rust Project"
        ["rust_basic_description"]="Standard Rust project with Cargo and flake.nix"
        ["rust_category_description"]="Modern systems programming language, memory safety, high performance"
        ["rust_select_files"]="Select files to generate:"
        ["rust_files_title"]="Project Files"
        ["rust_binary_name"]="Enter binary name:"
        ["rust_binary_title"]="Rust Configuration"
        ["rust_extra_packages"]="Additional Nix packages (space-separated):"
        ["rust_packages_title"]="Extra Packages"
        ["rust_generating_cargo"]="Generating Cargo.toml..."
        ["rust_generating_main"]="Creating main.rs..."
        ["rust_generating_flake"]="Generating flake.nix..."
        ["rust_generating_toolchain"]="Creating rust-toolchain.toml..."
        ["rust_generating_envrc"]="Creating .envrc..."
    )
    
    I18N_ZH+=(
        ["rust_basic_name"]="基础 Rust 项目"
        ["rust_basic_description"]="标准的 Rust 项目，包含 Cargo 和 flake.nix"
        ["rust_category_description"]="现代系统编程语言，内存安全，高性能"
        ["rust_select_files"]="选择要生成的文件："
        ["rust_files_title"]="项目文件"
        ["rust_binary_name"]="请输入二进制文件名："
        ["rust_binary_title"]="Rust 配置"
        ["rust_extra_packages"]="额外的 Nix 包（空格分隔）："
        ["rust_packages_title"]="额外包"
        ["rust_generating_cargo"]="正在生成 Cargo.toml..."
        ["rust_generating_main"]="正在创建 main.rs..."
        ["rust_generating_flake"]="正在生成 flake.nix..."
        ["rust_generating_toolchain"]="正在创建 rust-toolchain.toml..."
        ["rust_generating_envrc"]="正在创建 .envrc..."
    )
}

# Rust 基础模板生成器
template_rust_basic_generate() {
    local project_name="$1"
    local target_dir="$2"
    
    # 1. 使用复选框选择要生成的文件（默认全选）
    local selected_files
    selected_files=$(ui_checklist "$(_t "rust_files_title")" "$(_t "rust_select_files")" 80 20 10 "" \
        "cargo" "Cargo.toml" "ON" \
        "main" "src/main.rs" "ON" \
        "flake" "flake.nix" "ON" \
        "toolchain" "rust-toolchain.toml" "ON" \
        "envrc" ".envrc (direnv)" "ON")
    cancelThenExit
    
    # 解析选中的文件
    local create_cargo=false create_main=false create_flake=false create_toolchain=false create_envrc=false
    for file in $selected_files; do
        case "${file//\"/}" in
            "cargo") create_cargo=true ;;
            "main") create_main=true ;;
            "flake") create_flake=true ;;
            "toolchain") create_toolchain=true ;;
            "envrc") create_envrc=true ;;
        esac
    done
    
    # 2. 根据选择的文件收集必要的配置信息
    local binary_name extra_packages
    
    # 如果选择了 Cargo 或 flake，需要二进制名称
    if [[ "$create_cargo" == true || "$create_flake" == true ]]; then
        binary_name=$(ui_inputbox "$(_t "rust_binary_title")" "$(_t "rust_binary_name")" "$project_name")
        cancelThenExit
    fi
    
    # 如果选择了 flake，询问额外包
    if [[ "$create_flake" == true ]]; then
        extra_packages=$(ui_inputbox "$(_t "rust_packages_title")" "$(_t "rust_extra_packages")" "")
        if [[ $? -ne 0 ]]; then
            extra_packages=""
        fi
    fi
    
    # 3. 创建项目目录
    local project_path="$target_dir/$project_name"
    mkdir -p "$project_path/src"
    
    # 4. 按选择生成文件
    [[ "$create_cargo" == true ]] && {
        debuger info "Rust" "$(_t "rust_generating_cargo")"
        _generate_cargo_toml "$project_path" "$project_name" "$binary_name"
    }
    
    [[ "$create_main" == true ]] && {
        debuger info "Rust" "$(_t "rust_generating_main")"
        _generate_main_rs "$project_path"
    }
    
    [[ "$create_flake" == true ]] && {
        debuger info "Rust" "$(_t "rust_generating_flake")"
        _generate_rust_flake "$project_path" "$project_name" "$binary_name" "$extra_packages"
    }
    
    [[ "$create_toolchain" == true ]] && {
        debuger info "Rust" "$(_t "rust_generating_toolchain")"
        _generate_rust_toolchain "$project_path"
    }
    
    [[ "$create_envrc" == true ]] && {
        debuger info "Rust" "$(_t "rust_generating_envrc")"
        _generate_envrc "$project_path"
    }
    
    debuger success "Rust" "Rust 项目创建完成: $project_path"
}

# 生成 Cargo.toml
_generate_cargo_toml() {
    local project_path="$1"
    local project_name="$2"
    local binary_name="$3"
    
    cat > "$project_path/Cargo.toml" << EOF
[package]
name = "$project_name"
version = "0.1.0"
edition = "2021"

[[bin]]
name = "$binary_name"
path = "src/main.rs"

[dependencies]
EOF
}

# 生成 flake.nix（参考你的项目结构）
_generate_rust_flake() {
    local project_path="$1"
    local project_name="$2"
    local binary_name="$3"
    local extra_packages="$4"
    
    # 处理额外的包
    local extra_pkgs=""
    if [[ -n "$extra_packages" ]]; then
        for pkg in $extra_packages; do
            extra_pkgs="$extra_pkgs            $pkg"$'\n'
        done
    fi
    
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
        # 读取 rust-toolchain.toml 配置
        overrides = (builtins.fromTOML (builtins.readFile (self + "/rust-toolchain.toml")));
        libPath = with pkgs; lib.makeLibraryPath [
          # 在这里添加项目需要的外部库
        ];
      in
      {
        devShells.default = pkgs.mkShell rec {
          nativeBuildInputs = [ pkgs.pkg-config ];
          buildInputs = with pkgs; [
            clang
            llvmPackages.bintools
            rustup
            openssl
$extra_pkgs          ];

          RUSTC_VERSION = overrides.toolchain.channel;
          
          # https://github.com/rust-lang/rust-bindgen#environment-variables
          LIBCLANG_PATH = pkgs.lib.makeLibraryPath [ pkgs.llvmPackages_latest.libclang.lib ];
          
          shellHook = ''
            export PATH=\$PATH:\''$\{CARGO_HOME:-~/.cargo}/bin
            export PATH=\$PATH:\''$\{RUSTUP_HOME:-~/.rustup}/toolchains/\$RUSTC_VERSION-x86_64-unknown-linux-gnu/bin/
            echo "$project_name 开发环境已准备就绪！"
            echo "二进制文件: $binary_name"
            echo ""
            echo "常用命令:"
            echo "  cargo build    # 构建项目"
            echo "  cargo run      # 运行项目"  
            echo "  cargo test     # 运行测试"
            echo "  cargo clippy   # 代码检查"
            echo "  cargo fmt      # 代码格式化"
          '';

          # Add precompiled library to rustc search path
          RUSTFLAGS = (builtins.map (a: ''-L \${a}/lib'') [
            # 在这里添加库（例如 pkgs.libvmi）
          ]);
          
          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath (buildInputs ++ nativeBuildInputs);
          
          # Add glibc, clang, glib, and other headers to bindgen search path
          BINDGEN_EXTRA_CLANG_ARGS =
          # 包含正常的包含路径
          (builtins.map (a: ''-I"\${a}/include"'') [
            # 在这里添加开发库（例如 pkgs.libvmi.dev）
            pkgs.glibc.dev
          ])
          # 包含特殊目录路径
          ++ [
            ''-I"\${pkgs.llvmPackages_latest.libclang.lib}/lib/clang/\${pkgs.llvmPackages_latest.libclang.version}/include"''
            ''-I"\${pkgs.glib.dev}/include/glib-2.0"''
            ''-I\${pkgs.glib.out}/lib/glib-2.0/include/''
          ];
        };
      }
    );
}
EOF
}

# 生成 rust-toolchain.toml
_generate_rust_toolchain() {
    local project_path="$1"
    
    cat > "$project_path/rust-toolchain.toml" << 'EOF'
[toolchain]
channel = "stable"
components = [ "rustc","cargo","rustfmt","rust-std","rust-analyzer","rust-src" ]
targets = [ "x86_64-unknown-linux-gnu" ]
profile = "minimal"
EOF
}

# 生成 .envrc
_generate_envrc() {
    local project_path="$1"
    
    cat > "$project_path/.envrc" << 'EOF'
use flake
EOF
}

# 生成 main.rs
_generate_main_rs() {
    local project_path="$1"
    
    cat > "$project_path/src/main.rs" << 'EOF'
fn main() {
    println!("Hello, world!");
}

#[cfg(test)]
mod tests {
    #[test]
    fn it_works() {
        assert_eq!(2 + 2, 4);
    }
}
EOF
}

# 初始化翻译和注册
_template_rust_basic_init_i18n
_template_rust_basic_register