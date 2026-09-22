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
echo "  3. Isolate Wine user folders from macOS"
echo "  4. Download the MoP 5.4.8 client"
echo
echo "No World of Warcraft files are distributed by"
echo "this project. Game files are downloaded from"
echo "third-party servers during setup."
echo

# ------------------------------------------------------------
# Prepare scripts
# ------------------------------------------------------------

echo "Preparing scripts..."
echo

chmod +x "$SCRIPTS_DIR"/*.sh

REQUIRED_SCRIPTS=(
    "common.sh"
    "install-wine.sh"
    "create-prefix.sh"
    "isolate-user-folders.sh"
    "download-client.sh"
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
# Step 2 - Prefix
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
# Step 3 - macOS folder isolation
# ------------------------------------------------------------

echo "=================================================="
echo " Step 3/4 - Wine Folder Isolation"
echo "=================================================="
echo

"$SCRIPTS_DIR/isolate-user-folders.sh"

echo

# ------------------------------------------------------------
# Step 4 - Download WoW
# ------------------------------------------------------------

echo "=================================================="
echo " Step 4/4 - MoP 5.4.8 Client"
echo "=================================================="
echo

"$SCRIPTS_DIR/download-client.sh"

echo

# ------------------------------------------------------------
# Verify WoW
# ------------------------------------------------------------

echo "=================================================="
echo " Verifying WoW Installation"
echo "=================================================="
echo

WOW_EXE="$WINEPREFIX/drive_c/WoW/Wow-64.exe"

if [[ ! -f "$WOW_EXE" ]]; then
    echo "ERROR: Wow-64.exe was not found:"
    echo
    echo "  $WOW_EXE"
    echo
    echo "The client download may not have completed."
    echo
    echo "Resume it with:"
    echo
    echo "  ./scripts/download-client.sh"
    exit 1
fi

export WOW_EXE

echo "WoW client detected:"
echo "  $WOW_EXE"
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