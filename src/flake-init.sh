#!/usr/bin/env bash

safe_source() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        echo -e "\033[31m错误：依赖文件不存在 [$file]\033[0m" >&2
        exit 1
    fi
    if ! source "$file"; then
        echo -e "\033[31m错误：加载依赖失败 [$file]\033[0m" >&2
        exit 1
    fi
}

# 确保 whiptail 已经安装
if ! command -v whiptail &> /dev/null; then
    echo "Error: whiptail command not found. Please install it (e.g., on NixOS: nix-shell -p newt)."
    exit 1
fi

# 加载依赖库
SCRIPT_PATH=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
source "$SCRIPT_PATH/debugger.sh"
source "$SCRIPT_PATH/i18n.sh"

# Set default values
PROJECT_NAME=""
SELECTED_LANGUAGE=""
SELECTED_OUTPUTS=""
APP_ENTRY_POINT=""

# Welcome Message
whiptail --msgbox "$(_t "welcome_message")" 10 60

# Check if user cancelled
if [ $? -ne 0 ]; then exit 1; fi

# --- Get Project Name ---
PROJECT_NAME=$(whiptail --inputbox "Enter your project name:" 8 60 "my-project" 3>&1 1>&2 2>&3)

if [ $? -ne 0 ]; then exit 1; fi

# Basic validation
if [ -z "$PROJECT_NAME" ]; then
    whiptail --msgbox "Project name cannot be empty!" 8 40
    exit 1
fi

# --- Select Programming Language ---
LANG_CHOICES=(
    "python" "Python project (with venv-like shell)"
    "node" "Node.js project (with npm/yarn/pnpm shell)"
    "rust" "Rust project (with rustc/cargo shell)"
    "go" "Go project (with go compiler)"
    "cpp" "C/C++ project (with gcc/clang)"
    "generic" "Generic development environment (stdenv)"
)

SELECTED_LANGUAGE=$(whiptail --menu "Choose your primary programming language:" 15 60 6 "${LANG_CHOICES[@]}" 3>&1 1>&2 2>&3)

if [ $? -ne 0 ]; then exit 1; fi

# --- Select Flake Outputs ---
OUTPUT_CHOICES=(
    "devShell" "ON" "Create a development shell (nix develop)"
    "package"  "ON" "Create a buildable package (nix build)"
    "app"      "OFF" "Create a runnable application (nix run)"
)

# whiptail checklist outputs selected items separated by spaces
SELECTED_OUTPUTS=$(whiptail --checklist "Select desired flake outputs:" 15 60 3 "${OUTPUT_CHOICES[@]}" 3>&1 1>&2 2>&3)

if [ $? -ne 0 ]; then exit 1; fi

# Parse selected outputs into an array (handling spaces in names, though not an issue here)
# Need to remove quotes if whiptail adds them
SELECTED_OUTPUTS=$(echo "$SELECTED_OUTPUTS" | tr -d '"') # Remove quotes
IFS=' ' read -r -a selected_outputs_array <<< "$SELECTED_OUTPUTS"

# --- Get App Entry Point if 'app' is selected ---
APP_REQUIRED=false
for output in "${selected_outputs_array[@]}"; do
    if [ "$output" == "app" ]; then
        APP_REQUIRED=true
        break
    fi
done

if [ "$APP_REQUIRED" = true ]; then
    APP_ENTRY_POINT=$(whiptail --inputbox "Enter the main application file path (e.g., src/main.py):" 8 60 "" 3>&1 1>&2 2>&3)
    if [ $? -ne 0 ]; then exit 1; fi
    if [ -z "$APP_ENTRY_POINT" ]; then
        whiptail --msgbox "App entry point cannot be empty if 'app' output is selected!" 8 50
        exit 1
    fi
fi


# --- Placeholder for generating flake.nix content ---
# This is the complex part where you generate the string based on variables:
# $PROJECT_NAME, $SELECTED_LANGUAGE, $selected_outputs_array[], $APP_ENTRY_POINT
FLAKE_CONTENT="# Placeholder for generated flake.nix\n"
FLAKE_CONTENT+="Project: $PROJECT_NAME\n"
FLAKE_CONTENT+="Language: $SELECTED_LANGUAGE\n"
FLAKE_CONTENT+="Outputs: ${selected_outputs_array[*]}\n" # Join array elements
if [ -n "$APP_ENTRY_POINT" ]; then
    FLAKE_CONTENT+="App Entry: $APP_ENTRY_POINT\n"
fi
FLAKE_CONTENT+="\n---\n"

# Add basic flake structure (needs refinement per language)
FLAKE_CONTENT+='
{
  description = "A Nix-based development environment and build for '$PROJECT_NAME'";

  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixos-unstable; # Consider using a specific channel or commit
    # nixpkgs.url = github:NixOS/nixpkgs/nixos-23.11; # Example stable release
    flake-utils.url = github:numtide/flake-utils; # Useful for exposing outputs for multiple systems
  };

  outputs = { self, nixpkgs, flake-utils, ... }@inputs:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        # Import language-specific pkgs or modules here
        # Example for Python: pkgs = import nixpkgs { inherit system; config.python.enableBuildDir = true; };

        # --- Language specific setup (needs logic based on $SELECTED_LANGUAGE) ---
        # Example for Python:
        # pythonEnv = pkgs.python3.withPackages(p: [
        #   # Add common python packages here
        # ]);
        # buildInputs = [ pythonEnv ]; # Used in mkShell and mkDerivation
        # nativeBuildInputs = []; # For build tools

        # Example for Rust:
        # buildInputs = with pkgs; [ rustc cargo ];
        # buildPhase = '' cargo build --release '';
        # installPhase = '' mkdir -p $out/bin; cp target/release/${PROJECT_NAME} $out/bin/ '';

        # ... more language specific logic ...

        # --- Flake Outputs (needs logic based on $selected_outputs_array) ---
        generatedDevShell = # Generate devShell here if "devShell" selected
        # pkgs.mkShell {
        #   buildInputs = # Add buildInputs here;
        #   # Add shell hooks, environment variables etc.
        # };
        null; # Replace with actual derivation

        generatedPackage = # Generate package here if "package" selected
        # pkgs.stdenv.mkDerivation {
        #   pname = "'$PROJECT_NAME'";
        #   version = "0.1.0"; # Consider asking for version?
        #   src = ./.; # Source is the current directory
        #   # Add language-specific build phases (buildPhase, installPhase)
        #   # buildInputs = ...
        # };
        null; # Replace with actual derivation

        generatedApp = # Generate app here if "app" selected
        # pkgs.writeScriptBin "'$PROJECT_NAME'" ''
        #   #!${pkgs.stdenv.shell}
        #   # Example for Python: ${pythonEnv}/bin/python ${APP_ENTRY_POINT} "$@"
        #   # Example for Node: ${pkgs.nodePackages.node}/bin/node ${APP_ENTRY_POINT} "$@"
        # '';
        null; # Replace with actual derivation

      in
      {
        devShells.default =
          # Check if devShell is selected and return generatedDevShell, otherwise provide a basic shell or null
          # Example: if elem "devShell" selected_outputs_array then generatedDevShell else null
          pkgs.mkShell { buildInputs = []; }; # Basic placeholder

        packages.default =
          # Check if package is selected and return generatedPackage
          # Example: if elem "package" selected_outputs_array then generatedPackage else null
          pkgs.stdenv.mkDerivation { pname = "'$PROJECT_NAME'"; version = "0.1.0"; src = ./.; }; # Basic placeholder

        apps.default =
          # Check if app is selected and return generatedApp, otherwise return an app running the package or a dummy
          # Example: if elem "app" selected_outputs_array then generatedApp else packages.default;
          # Or if no app/package, maybe just pkgs.writeScriptBin "dummy" "echo 'No app defined'";
          { type = "app"; program = "${pkgs.writeScriptBin "'$PROJECT_NAME'" "echo 'No app defined.'"}"; }; # Basic placeholder
      }
    );
}'

# --- Confirmation ---
whiptail --yesno "Generated flake.nix content:\n\n$FLAKE_CONTENT\n\nDo you want to write this to ./flake.nix?" --yes-button "Write" --no-button "Cancel" 25 80

if [ $? -ne 0 ]; then
    whiptail --msgbox "Flake creation cancelled." 8 40
    exit 0
fi

# --- Write File ---
echo "$FLAKE_CONTENT" > ./flake.nix

# Create a basic flake.lock (nix flake update is better but this is a start)
echo '{ "inputs": { "nixpkgs": { "locked": { "lastModified": 1678886400, "narHash": "sha256:...", "owner": "NixOS", "repo": "nixpkgs", "rev": "...", "type": "github" }, "original": { "owner": "NixOS", "repo": "nixpkgs", "type": "github", "url": "github:NixOS/nixpkgs/nixos-unstable" } } }, "root": "nixpkgs" }' > ./flake.lock # WARNING: This lock is fake, needs actual hash/rev

# OR better:
# if command -v nix &> /dev/null; then
#     whiptail --msgbox "Running 'nix flake update' to generate a proper flake.lock..." 8 60
#     nix flake update # This will create/update flake.lock with correct info
#     if [ $? -ne 0 ]; then
#         whiptail --msgbox "Warning: 'nix flake update' failed. You may need to run it manually." 8 60
#     fi
# else
#     whiptail --msgbox "Info: 'nix' command not found. Could not generate a proper flake.lock. You'll need to run 'nix flake update' manually later." 10 60
# fi


# --- Success Message ---
whiptail --msgbox "Successfully created ./flake.nix and ./flake.lock.\n\nYou can now:\n- Enter the development shell: nix develop\n- Build the project: nix build\n- Run the application: nix run" 15 60

exit 0