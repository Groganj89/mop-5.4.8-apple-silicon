#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$ROOT_DIR/scripts"

echo
echo "=================================================="
echo " World of Warcraft: MoP 5.4.8 - Apple Silicon"
echo " Setup"
echo "=================================================="
echo
echo "This setup will:"
echo
echo "  1. Detect your Wine installation"
echo "  2. Create or reuse a dedicated Wine prefix"
echo "  3. Install the Microsoft .NET 8 Desktop Runtime"
echo "  4. Download the latest TwinStar Launcher"
echo "  5. Start TwinStar so it can download WoW"
echo
echo "No World of Warcraft files are distributed by"
echo "this project."
echo

# ------------------------------------------------------------
# Make helper scripts executable
# ------------------------------------------------------------

echo "Preparing scripts..."
echo

chmod +x "$SCRIPTS_DIR"/*.sh

# ------------------------------------------------------------
# Sanity checks
# ------------------------------------------------------------

REQUIRED_SCRIPTS=(
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
# Step 1 - Wine prefix
# ------------------------------------------------------------

echo "=================================================="
echo " Step 1/3 - Wine Prefix"
echo "=================================================="
echo

"$SCRIPTS_DIR/create-prefix.sh"

echo

# create-prefix.sh runs as a child process, so its exported
# WINEPREFIX does not propagate back into setup.sh.
#
# Use the same default prefix for subsequent scripts unless
# the user explicitly supplied WINEPREFIX before running setup.

if [[ -z "${WINEPREFIX:-}" ]]; then
    export WINEPREFIX="$HOME/Games/WoW-MoP/prefix"
fi

echo "Setup will use:"
echo "  $WINEPREFIX"
echo

# ------------------------------------------------------------
# Step 2 - .NET 8 Desktop Runtime
# ------------------------------------------------------------

echo "=================================================="
echo " Step 2/3 - .NET 8 Desktop Runtime"
echo "=================================================="
echo

"$SCRIPTS_DIR/install-dotnet.sh"

echo

# ------------------------------------------------------------
# Step 3 - TwinStar
# ------------------------------------------------------------

echo "=================================================="
echo " Step 3/3 - TwinStar Launcher"
echo "=================================================="
echo

"$SCRIPTS_DIR/install-twinstar.sh"

echo

# ------------------------------------------------------------
# TwinStar has now closed
# ------------------------------------------------------------

echo "=================================================="
echo " TwinStar Launcher Closed"
echo "=================================================="
echo

WOW_EXE=""

# Check the most likely locations first.
if [[ -f "$WINEPREFIX/drive_c/Wow-64.exe" ]]; then
    WOW_EXE="$WINEPREFIX/drive_c/Wow-64.exe"
elif [[ -f "$WINEPREFIX/drive_c/WoW/Wow-64.exe" ]]; then
    WOW_EXE="$WINEPREFIX/drive_c/WoW/Wow-64.exe"
else
    # Fall back to searching the prefix.
    WOW_EXE="$(
        find "$WINEPREFIX/drive_c" \
            -type f \
            -name "Wow-64.exe" \
            -print \
            -quit 2>/dev/null || true
    )"
fi

if [[ -z "$WOW_EXE" ]]; then
    echo "WoW-64.exe was not found in the Wine prefix."
    echo
    echo "If TwinStar is still downloading the client,"
    echo "finish the download first."
    echo
    echo "Then run:"
    echo
    echo "  ./scripts/isolate-user-folders.sh"
    echo "  ./scripts/run-wow.sh"
    echo
    exit 0
fi

echo "WoW client detected:"
echo "  $WOW_EXE"
echo

# ------------------------------------------------------------
# Isolate protected macOS folders
# ------------------------------------------------------------

echo "=================================================="
echo " Final Configuration"
echo "=================================================="
echo
echo "Isolating macOS protected user folders..."
echo

"$SCRIPTS_DIR/isolate-user-folders.sh"

echo

# ------------------------------------------------------------
# Complete
# ------------------------------------------------------------

echo "=================================================="
echo " Setup Complete!"
echo "=================================================="
echo
echo "World of Warcraft was found at:"
echo
echo "  $WOW_EXE"
echo
echo "Launch it with:"
echo
echo "  ./scripts/run-wow.sh"
echo
echo "The launcher will automatically force Wine's"
echo "builtin D3D9 implementation:"
echo
echo "  WINEDLLOVERRIDES=d3d9=b"
echo
echo "Have fun in Pandaria!"
echo