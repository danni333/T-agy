#!/usr/bin/env bash

# ==============================================================================
# agy-termux: Bootstraper & Installer Script
# Optimized natively to deploy the Antigravity Memory Patcher in Termux.
# ==============================================================================

set -euo pipefail

# Visual color templates
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_err() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

echo -e "${CYAN}${BOLD}"
echo "=========================================================="
echo "          agy-termux Bash Installation Script             "
echo "=========================================================="
echo -e "${NC}"

# STEP 1: Verification of Termux native sandbox directories
log_info "Step 1/7: Verifying environment constraint..."
if [ ! -d "/data/data/com.termux" ]; then
    log_err "CRITICAL: This installer operates exclusively inside Android Termux."
    log_err "Missing folder path '/data/data/com.termux'. Setup Termux and run again."
    exit 1
fi
log_success "Termux environment verified successfully."

# STEP 2: Installing required dependencies via Termux package manager
log_info "Step 2/7: Installing Go Compiler (golang), Git, and Curl..."
# Force standard updates first to sync prefixes
pkg update -y || log_warn "Package index update returned non-zero. Attempting package installer..."
pkg install golang git curl -y

# STEP 3: Cloning target agy-termux repository into appropriate directory
log_info "Step 3/7: Cloning agy-termux source repository..."
REPO_URL="https://github.com/danni333/T-agy"
TARGET_DIR="$HOME/agy-termux"

if [ -d "$TARGET_DIR" ]; then
    log_warn "Target directory $TARGET_DIR already exists."
    log_info "Pulling latest changes in-place..."
    cd "$TARGET_DIR"
    git pull || log_warn "Git pull failed. Proceeding with existing source files."
else
    log_info "Cloning repo $REPO_URL to $TARGET_DIR..."
    git clone "$REPO_URL" "$TARGET_DIR"
fi

# STEP 4: Navigate to the cloned folder structure
log_info "Step 4/7: Navigating into the repository directory..."
cd "$TARGET_DIR"

# STEP 5: Compile the Go manager/wrapper with Android memory allocator rules (CGO_ENABLED=0)
log_info "Step 5/7: Compiling Go wrapper natively from './manager' directory..."
export CGO_ENABLED=0
export GOOS="android"
# Auto-detect target hardware architecture
ARCH=$(uname -m)
case "$ARCH" in
    aarch64) export GOARCH="arm64" ;;
    armv7l|armv8l) export GOARCH="arm" ;;
    x86_64) export GOARCH="amd64" ;;
    *) log_warn "Unknown CPU architecture '$ARCH'. Go will auto-resolve." ;;
esac

# Build with compressed binary instructions, without standard tcmalloc linkages
go build -ldflags "-s -w" -o agy-termux ./manager/main.go

# STEP 6: Move binary to highly accessible binary directories
log_info "Step 6/7: Displace or move compiled bin to user execution paths (~/bin)..."
mkdir -p "$HOME/bin"
cp agy-termux "$HOME/bin/agy-termux"
log_success "Binary deployed successfully to $HOME/bin/agy-termux"

# STEP 7: Create and verify system-level execution alias
log_info "Step 7/7: Installing CLI execution alias linked to 'agy'..."
PREFIX_BIN="/data/data/com.termux/files/usr/bin"

if [ -d "$PREFIX_BIN" ] && [ -w "$PREFIX_BIN" ]; then
    log_info "Configuring execution symlinks in system prefix: $PREFIX_BIN"
    ln -sf "$HOME/bin/agy-termux" "$PREFIX_BIN/agy-termux"
    ln -sf "$HOME/bin/agy-termux" "$PREFIX_BIN/agy"
    log_success "Aliases successfully registered inside $PREFIX_BIN!"
else
    # Fallback to appending alias configuration in bashrc if write permissions are blocked
    BASHRC="$HOME/.bashrc"
    log_warn "System prefix not writable or missing. Appending aliases to $BASHRC..."
    touch "$BASHRC"
    if ! grep -q "alias agy=" "$BASHRC"; then
        echo "alias agy-termux='$HOME/bin/agy-termux'" >> "$BASHRC"
        echo "alias agy='$HOME/bin/agy-termux'" >> "$BASHRC"
    fi
    log_success "Aliases appended to $BASHRC! Relocate shell or run: source ~/.bashrc"
fi

echo -e "\n${GREEN}${BOLD}==========================================================${NC}"
echo -e "${GREEN}${BOLD}agy-termux has been compiled & installed successfully!${NC}"
echo -e "You can run it natively via: ${BOLD}agy${NC} or ${BOLD}agy-termux${NC}"
echo -e "To update/compile Antigravity core natively, execute: ${BOLD}agy --update-core${NC}"
echo -e "${GREEN}${BOLD}==========================================================${NC}\n"
