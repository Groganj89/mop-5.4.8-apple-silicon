#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

echo "========================================"
echo " .NET 8 Desktop Runtime Installer"
echo "========================================"
echo

# ------------------------------------------------------------
# Detect Wine
# ------------------------------------------------------------

find_wine

echo "Wine detected:"
echo "  $WINE"
"$WINE" --version
echo

# ------------------------------------------------------------
# Find or create prefix
# ------------------------------------------------------------

if ! find_prefix; then
    echo "No existing Wine prefix detected."
    echo
    echo "Creating default prefix..."
    echo

    export WINEPREFIX="$HOME/Games/WoW-MoP/prefix"

    mkdir -p "$(dirname "$WINEPREFIX")"

    "$WINE" wineboot

    echo
fi

echo "Using Wine prefix:"
echo "  $WINEPREFIX"
echo

# ------------------------------------------------------------
# Check whether .NET 8 Desktop Runtime is already installed
# ------------------------------------------------------------

DOTNET="$WINEPREFIX/drive_c/Program Files/dotnet/dotnet.exe"

if [[ -f "$DOTNET" ]]; then

    echo "Existing .NET installation detected."
    echo

    RUNTIMES="$(
        "$WINE" \
        "C:\\Program Files\\dotnet\\dotnet.exe" \
        --list-runtimes 2>/dev/null || true
    )"

    echo "$RUNTIMES"
    echo

    if echo "$RUNTIMES" | grep -q "Microsoft.WindowsDesktop.App 8\."; then
        echo ".NET 8 Desktop Runtime is already installed."
        echo
        exit 0
    fi
fi

# ------------------------------------------------------------
# Download current .NET 8 Desktop Runtime
# ------------------------------------------------------------

DOWNLOAD_DIR="$HOME/Downloads/WoW-MoP-Setup"
INSTALLER="$DOWNLOAD_DIR/windowsdesktop-runtime-8-x64.exe"

mkdir -p "$DOWNLOAD_DIR"

# Microsoft aka.ms link tracks the current .NET 8 Windows
# Desktop Runtime x64 installer.
DOTNET_URL="https://aka.ms/dotnet/8.0/windowsdesktop-runtime-win-x64.exe"

echo "Downloading current .NET 8 Desktop Runtime..."
echo
echo "Source:"
echo "  $DOTNET_URL"
echo

curl \
    --fail \
    --location \
    --progress-bar \
    "$DOTNET_URL" \
    --output "$INSTALLER"

echo
echo "Downloaded:"
echo "  $INSTALLER"
echo

# ------------------------------------------------------------
# Install into Wine prefix
# ------------------------------------------------------------

echo "Installing .NET 8 Desktop Runtime..."
echo

"$WINE" "$INSTALLER" \
    /install \
    /quiet \
    /norestart

echo
echo "Installer completed."
echo

# ------------------------------------------------------------
# Verify installation
# ------------------------------------------------------------

if [[ ! -f "$DOTNET" ]]; then
    echo "ERROR: dotnet.exe was not found after installation."
    echo
    echo "Expected:"
    echo "  $DOTNET"
    exit 1
fi

echo "Verifying installed runtimes..."
echo

RUNTIMES="$(
    "$WINE" \
    "C:\\Program Files\\dotnet\\dotnet.exe" \
    --list-runtimes 2>/dev/null || true
)"

echo "$RUNTIMES"
echo

if echo "$RUNTIMES" | grep -q "Microsoft.WindowsDesktop.App 8\."; then

    echo "========================================"
    echo " SUCCESS"
    echo "========================================"
    echo
    echo ".NET 8 Desktop Runtime is installed."
    echo
    echo "Wine prefix:"
    echo "  $WINEPREFIX"
    echo
    echo "Next:"
    echo "  ./scripts/install-twinstar.sh"
    echo

else

    echo "ERROR: Installation completed but"
    echo "Microsoft.WindowsDesktop.App 8.x"
    echo "was not detected."
    echo
    exit 1

fi