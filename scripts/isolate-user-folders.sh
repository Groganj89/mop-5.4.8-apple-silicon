#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

find_wine

if ! find_prefix; then
    echo "ERROR: No Wine prefix could be found."
    exit 1
fi

USERDIR="$WINEPREFIX/drive_c/users/$USER"

if [[ ! -d "$USERDIR" ]]; then
    echo "ERROR: Wine user directory not found:"
    echo "  $USERDIR"
    exit 1
fi

echo "Using Wine prefix:"
echo "  $WINEPREFIX"
echo
echo "Checking:"
echo "  $USERDIR"
echo

for folder in Desktop Documents Pictures Music Videos; do
    path="$USERDIR/$folder"

    if [[ -L "$path" ]]; then
        target="$(readlink "$path")"

        echo "$folder"
        echo "  mapped to: $target"

        rm "$path"
        mkdir -p "$path"

        echo "  replaced with prefix-local directory"
        echo

    elif [[ -d "$path" ]]; then
        echo "$folder"
        echo "  already prefix-local"
        echo

    else
        mkdir -p "$path"

        echo "$folder"
        echo "  created prefix-local directory"
        echo
    fi
done

echo "Remaining user-folder symlinks:"
echo

find "$USERDIR" -maxdepth 1 -type l -ls || true

echo
echo "Done."
echo "Downloads was intentionally left unchanged."