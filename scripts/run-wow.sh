#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

find_wine

if ! find_prefix; then
    echo "ERROR: No Wine prefix could be found."
    echo
    echo "Run:"
    echo "  ./scripts/create-prefix.sh"
    exit 1
fi

if ! find_wow; then
    echo "ERROR: Wow-64.exe could not be found in:"
    echo "  $WINEPREFIX/drive_c"
    echo
    echo "Install/download the MoP client into this prefix first."
    exit 1
fi

show_environment

cd "$(dirname "$WOW_EXE")"

echo "Launching World of Warcraft using Wine builtin D3D9..."
echo

WINEDLLOVERRIDES="d3d9=b" \
"$WINE" "./$(basename "$WOW_EXE")"