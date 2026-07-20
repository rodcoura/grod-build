#!/bin/bash
#
# Build Grod from source and install the executable into ~/.local/bin.
#
# Usage:
#   bash scripts/build-and-install.sh
#
# The script builds the release binary for the xai-grok-pager-bin crate,
# copies it into ~/.local/bin as `grod`, and prints instructions for adding
# ~/.local/bin to PATH if it is not already there.

set -euo pipefail

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------

log() {
    echo "[grod-build] $*"
}

warn() {
    echo "[grod-build] WARNING: $*" >&2
}

fail() {
    echo "[grod-build] ERROR: $*" >&2
    exit 1
}

# -----------------------------------------------------------------------------
# Detect OS
# -----------------------------------------------------------------------------

OS=""
case "$(uname -s)" in
    Darwin) OS="macos" ;;
    Linux)  OS="linux" ;;
    MINGW* | MSYS* | CYGWIN*) OS="windows" ;;
    *)      fail "Unsupported OS: $(uname -s)" ;;
esac

log "Detected operating system: $OS"

# -----------------------------------------------------------------------------
# Verify cargo is available
# -----------------------------------------------------------------------------

if ! command -v cargo >/dev/null 2>&1; then
    fail "cargo was not found. Please install Rust: https://rustup.rs/"
fi

CARGO_VERSION=$(cargo --version)
log "Using $CARGO_VERSION"

# -----------------------------------------------------------------------------
# Build the release binary
# -----------------------------------------------------------------------------

log "Building grod from source (this may take a few minutes)..."
cargo build -p xai-grok-pager-bin --release

# -----------------------------------------------------------------------------
# Locate the built executable
# -----------------------------------------------------------------------------

if [ "$OS" = "windows" ]; then
    SOURCE_BIN="target/release/xai-grok-pager.exe"
    DEST_BIN="grod.exe"
else
    SOURCE_BIN="target/release/xai-grok-pager"
    DEST_BIN="grod"
fi

if [ ! -f "$SOURCE_BIN" ]; then
    fail "Expected binary not found after build: $SOURCE_BIN"
fi

log "Built binary: $SOURCE_BIN"

# -----------------------------------------------------------------------------
# Install into ~/.local/bin
# -----------------------------------------------------------------------------

INSTALL_DIR="$HOME/.local/bin"
DEST_PATH="$INSTALL_DIR/$DEST_BIN"

log "Creating install directory: $INSTALL_DIR"
mkdir -p "$INSTALL_DIR"

log "Copying binary to $DEST_PATH"
cp -f "$SOURCE_BIN" "$DEST_PATH"

if [ "$OS" != "windows" ]; then
    chmod +x "$DEST_PATH"
fi

# -----------------------------------------------------------------------------
# Verify the installed binary
# -----------------------------------------------------------------------------

log "Verifying installation..."
if ! "$DEST_PATH" --version >/dev/null 2>&1; then
    fail "Installed binary does not run: $DEST_PATH"
fi

INSTALLED_VERSION=$("$DEST_PATH" --version 2>/dev/null | head -n1)
log "Installed: $INSTALLED_VERSION"

# -----------------------------------------------------------------------------
# Check PATH and print OS-specific instructions
# -----------------------------------------------------------------------------

path_has_dir() {
    case ":$PATH:" in
        *":$1:"*) return 0 ;;
        *)        return 1 ;;
    esac
}

if path_has_dir "$INSTALL_DIR"; then
    log "$INSTALL_DIR is already on PATH."
    echo
    log "Run 'grod' to get started."
else
    echo
    warn "$INSTALL_DIR is NOT on your PATH."
    echo
    log "Add it now by following the steps for your shell/OS:"
    echo

    case "$OS" in
        macos)
            echo "  # For zsh (default on macOS):"
            echo "  echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.zshrc"
            echo "  source ~/.zshrc"
            echo
            echo "  # For bash:"
            echo "  echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.bash_profile"
            echo "  source ~/.bash_profile"
            ;;
        linux)
            echo "  # For bash:"
            echo "  echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.bashrc"
            echo "  source ~/.bashrc"
            echo
            echo "  # For zsh:"
            echo "  echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.zshrc"
            echo "  source ~/.zshrc"
            ;;
        windows)
            echo "  # In PowerShell (run as Administrator is NOT required for User PATH):"
            echo "  \$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')"
            echo "  [Environment]::SetEnvironmentVariable('Path', \"\$env:USERPROFILE\\.local\\bin;\$userPath\", 'User')"
            echo "  \$env:Path = \"\$env:USERPROFILE\\.local\\bin;\$env:Path\""
            echo
            echo "  # In Command Prompt (cmd.exe):"
            echo "  setx PATH \"%USERPROFILE%\\.local\\bin;%PATH%\""
            ;;
    esac

    echo
    log "After updating PATH, run 'grod' to get started."
fi

echo
log "Installation complete: $DEST_PATH"
