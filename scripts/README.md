# Build-from-source installer scripts

These scripts build the `grod` CLI from the Rust source in this repository and install the resulting binary into `~/.local/bin` (macOS/Linux) or `%USERPROFILE%\.local\bin` (Windows).

## Requirements

- [Rust](https://rustup.rs/) with `cargo`
- On Windows: PowerShell 5.1 or later

## Usage

### macOS / Linux / Git Bash

```sh
bash scripts/build-and-install.sh
```

### Windows PowerShell

```powershell
powershell -ExecutionPolicy Bypass -File scripts\build-and-install.ps1
```

## What the scripts do

1. Detect the operating system.
2. Verify that `cargo` is installed.
3. Run `cargo build -p xai-grok-pager-bin --release`.
4. Copy the built executable into `~/.local/bin` as `grod` (or `grod.exe`).
5. Run `grod --version` to confirm the binary works.
6. Check whether `~/.local/bin` is on `PATH` and, if not, print OS-specific instructions for adding it.

> **Note:** The internal crate name is `xai-grok-pager-bin` and the built artifact is `xai-grok-pager`. The installed command is renamed to `grod` for convenience.
