#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$ROOT_DIR/scripts"

echo
echo "=================================================="
echo " World of Warcraft: MoP 5.4.8 - Apple Silicon"
echo " Automated Setup"
echo "=================================================="
echo
echo "This setup will:"
echo
echo "  1. Check Rosetta and install Wine Staging"
echo "  2. Create or reuse a dedicated Wine prefix"
echo "  3. Install the Microsoft .NET 8 Desktop Runtime"
echo "  4. Download the latest TwinStar Launcher"
echo "  5. Start TwinStar so it can download WoW"
echo "  6. Configure the Wine environment for WoW"
echo
echo "No World of Warcraft files are distributed by"
echo "this project."
echo

# ------------------------------------------------------------
# Prepare scripts
# ------------------------------------------------------------

echo "Preparing scripts..."
echo

chmod +x "$SCRIPTS_DIR"/*.sh

REQUIRED_SCRIPTS=(
    "install-wine.sh"
    "create-prefix.sh"
    "install-dotnet.sh"
    "install-twinstar.sh"
    "isolate-user-folders.sh"
    "run-wow.sh"
)

for script in "${REQUIRED_SCRIPTS[@]}"; do
    if [[ ! -f "$SCRIPTS_DIR/$script" ]]; then
        echo "ERROR: Required script is missing:"
        echo "  scripts/$script"
        exit 1
    fi
done

echo "Scripts ready."
echo

# ------------------------------------------------------------
# Step 1 - Wine
# ------------------------------------------------------------

echo "=================================================="
echo " Step 1/4 - Wine Staging"
echo "=================================================="
echo

"$SCRIPTS_DIR/install-wine.sh"

echo

# ------------------------------------------------------------
# Discover Wine
# ------------------------------------------------------------

source "$SCRIPTS_DIR/common.sh"

find_wine

export WINE

echo "Using Wine:"
echo "  $WINE"
"$WINE" --version
echo

# ------------------------------------------------------------
# Prefix
# ------------------------------------------------------------

echo "=================================================="
echo " Step 2/4 - Wine Prefix"
echo "=================================================="
echo

if [[ -z "${WINEPREFIX:-}" ]]; then
    export WINEPREFIX="$HOME/Games/WoW-MoP/prefix"
fi

"$SCRIPTS_DIR/create-prefix.sh"

echo
echo "Using prefix:"
echo "  $WINEPREFIX"
echo

# ------------------------------------------------------------
# .NET
# ------------------------------------------------------------

echo "=================================================="
echo " Step 3/4 - .NET 8 Desktop Runtime"
echo "=================================================="
echo

"$SCRIPTS_DIR/install-dotnet.sh"

echo

# ------------------------------------------------------------
# TwinStar
# ------------------------------------------------------------

echo "=================================================="
echo " Step 4/4 - TwinStar Launcher"
echo "=================================================="
echo

"$SCRIPTS_DIR/install-twinstar.sh"

echo

# ------------------------------------------------------------
# Find WoW
# ------------------------------------------------------------

echo "=================================================="
echo " Checking WoW Installation"
echo "=================================================="
echo

WOW_EXE="$(
    find "$WINEPREFIX/drive_c" \
        -type f \
        -name "Wow-64.exe" \
        -print \
        -quit 2>/dev/null || true
)"

if [[ -z "$WOW_EXE" ]]; then
    echo "Wow-64.exe was not found."
    echo
    echo "If TwinStar has not finished downloading the"
    echo "client, reopen it with:"
    echo
    echo "  ./scripts/install-twinstar.sh"
    echo
    echo "Once the download is complete, run:"
    echo
    echo "  ./scripts/isolate-user-folders.sh"
    echo "  ./scripts/run-wow.sh"
    echo
    exit 0
fi

export WOW_EXE

echo "WoW client detected:"
echo "  $WOW_EXE"
echo

# ------------------------------------------------------------
# macOS folder isolation
# ------------------------------------------------------------

echo "=================================================="
echo " Final Configuration"
echo "=================================================="
echo

"$SCRIPTS_DIR/isolate-user-folders.sh"

echo

# ------------------------------------------------------------
# Finished
# ------------------------------------------------------------

echo "=================================================="
echo " Setup Complete"
echo "=================================================="
echo
echo "WoW:"
echo "  $WOW_EXE"
echo
echo "Wine:"
echo "  $WINE"
echo
echo "Prefix:"
echo "  $WINEPREFIX"
echo
echo "Launch with:"
echo
echo "  ./scripts/run-wow.sh"
echo
echo "Graphics backend:"
echo "  Direct3D 9 -> WineD3D"
echo
echo "Have fun in Pandaria!"
echo