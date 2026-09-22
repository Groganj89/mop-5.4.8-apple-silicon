#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

find_wine

echo "Detected Wine:"
echo "  $WINE"
"$WINE" --version
echo

if [[ -n "${WINEPREFIX:-}" ]]; then
    TARGET_PREFIX="$WINEPREFIX"
else
    TARGET_PREFIX="$HOME/Games/WoW-MoP/prefix"
fi

echo "Wine prefix:"
echo "  $TARGET_PREFIX"
echo

mkdir -p "$(dirname "$TARGET_PREFIX")"

export WINEPREFIX="$TARGET_PREFIX"

if [[ -d "$WINEPREFIX/drive_c" ]]; then
    echo "Existing Wine prefix detected."
    echo "Initialising/updating prefix..."
else
    echo "Creating Wine prefix..."
fi

echo

"$WINE" wineboot

echo
echo "Wine prefix ready:"
echo
echo "  $WINEPREFIX"
echo