#!/usr/bin/env bash

set -e

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

"$WINE" wineboot

echo
echo "Prefix created successfully:"
echo
echo "  $WINEPREFIX"
echo
echo "Next: install the Windows x64 .NET 8 Desktop Runtime."