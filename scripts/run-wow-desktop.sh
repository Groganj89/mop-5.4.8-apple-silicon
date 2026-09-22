#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

find_wine

if ! find_prefix; then
    echo "ERROR: No Wine prefix could be found."
    exit 1
fi

if ! find_wow; then
    echo "ERROR: Wow-64.exe could not be found."
    exit 1
fi

show_environment

cd "$(dirname "$WOW_EXE")"

WINEDLLOVERRIDES="d3d9=b" \
"$WINE" explorer /desktop=WoW,1920x1080 \
"./$(basename "$WOW_EXE")"