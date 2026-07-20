#
# Build Grod from source and install the executable into ~/.local/bin.
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File scripts\build-and-install.ps1
#
# The script builds the release binary for the xai-grok-pager-bin crate,
# copies it into %USERPROFILE%\.local\bin as grod.exe, and prints instructions
# for adding that directory to PATH if it is not already there.

param()

$ErrorActionPreference = 'Stop'

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------

function Write-Log([string]$Message) {
    Write-Host "[grod-build] $Message"
}

function Write-Warn([string]$Message) {
    Write-Host "[grod-build] WARNING: $Message" -ForegroundColor Yellow
}

function Write-Fail([string]$Message) {
    Write-Host "[grod-build] ERROR: $Message" -ForegroundColor Red
    exit 1
}

# -----------------------------------------------------------------------------
# Detect OS
# -----------------------------------------------------------------------------

$OS = if ($IsWindows -or ($PSVersionTable.PSVersion.Major -lt 6 -and $env:OS -eq 'Windows_NT')) {
    'windows'
} elseif ($IsMacOS) {
    'macos'
} elseif ($IsLinux) {
    'linux'
} else {
    Write-Fail "Unsupported operating system."
}

Write-Log "Detected operating system: $OS"

if ($OS -ne 'windows') {
    Write-Log "This PowerShell script is intended for Windows."
    Write-Log "On macOS/Linux, please run: bash scripts/build-and-install.sh"
}

# -----------------------------------------------------------------------------
# Verify cargo is available
# -----------------------------------------------------------------------------

$cargo = Get-Command cargo -ErrorAction SilentlyContinue
if (-not $cargo) {
    Write-Fail "cargo was not found. Please install Rust: https://rustup.rs/"
}

$cargoVersion = (& cargo --version)
Write-Log "Using $cargoVersion"

# -----------------------------------------------------------------------------
# Build the release binary
# -----------------------------------------------------------------------------

Write-Log "Building grod from source (this may take a few minutes)..."
& cargo build -p xai-grok-pager-bin --release
if ($LASTEXITCODE -ne 0) {
    Write-Fail "cargo build failed with exit code $LASTEXITCODE"
}

# -----------------------------------------------------------------------------
# Locate the built executable
# -----------------------------------------------------------------------------

$sourceBin = Join-Path (Get-Location) 'target\release\xai-grok-pager.exe'
if (-not (Test-Path $sourceBin)) {
    Write-Fail "Expected binary not found after build: $sourceBin"
}

Write-Log "Built binary: $sourceBin"

# -----------------------------------------------------------------------------
# Install into ~/.local/bin
# -----------------------------------------------------------------------------

$installDir = Join-Path $env:USERPROFILE '.local\bin'
$destPath = Join-Path $installDir 'grod.exe'

Write-Log "Creating install directory: $installDir"
New-Item -ItemType Directory -Path $installDir -Force | Out-Null

Write-Log "Copying binary to $destPath"
Copy-Item -Path $sourceBin -Destination $destPath -Force

# -----------------------------------------------------------------------------
# Verify the installed binary
# -----------------------------------------------------------------------------

Write-Log "Verifying installation..."
try {
    $versionOutput = & $destPath --version 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $versionOutput) {
        throw "binary returned non-zero exit"
    }
    Write-Log "Installed: $versionOutput"
} catch {
    Write-Fail "Installed binary does not run: $destPath"
}

# -----------------------------------------------------------------------------
# Check PATH and offer to add it
# -----------------------------------------------------------------------------

$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
$pathEntries = if ($userPath) { $userPath -split ';' | Where-Object { $_ -ne '' } } else { @() }
$normalizedInstallDir = (Resolve-Path $installDir).Path.TrimEnd('\')
$onPath = $pathEntries | Where-Object { $_.TrimEnd('\') -eq $normalizedInstallDir }

if ($onPath) {
    Write-Log "$installDir is already on your User PATH."
    Write-Host
    Write-Log "Run 'grod' to get started."
} else {
    Write-Host
    Write-Warn "$installDir is NOT on your PATH."
    Write-Host
    Write-Log "Add it now by running these commands in an elevated PowerShell session:"
    Write-Host
    Write-Host "  `$newPath = `"$installDir;`$env:Path`""
    Write-Host "  [Environment]::SetEnvironmentVariable('Path', `$newPath, 'User')"
    Write-Host "  `$env:Path = `"$installDir;`$env:Path`""
    Write-Host
    Write-Host "  # Or, if you prefer Command Prompt (cmd.exe):"
    Write-Host "  setx PATH `"$installDir;%PATH%`""
    Write-Host
    Write-Log "After updating PATH, restart your terminal and run 'grod' to get started."
}

Write-Host
Write-Log "Installation complete: $destPath"
