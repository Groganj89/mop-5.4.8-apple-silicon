#!/usr/bin/env bash

# Shared environment discovery for wow-mop-apple-silicon.

find_wine() {
    # Allow the user to explicitly override detection.
    if [[ -n "${WINE:-}" && -x "${WINE}" ]]; then
        return 0
    fi

    local candidates=(
        "$HOME/Games/Wine/Wine Staging.app/Contents/Resources/wine/bin/wine"
        "/Applications/Wine Staging.app/Contents/Resources/wine/bin/wine"
        "$HOME/Applications/Wine Staging.app/Contents/Resources/wine/bin/wine"
        "/opt/homebrew/bin/wine"
        "/opt/homebrew/bin/wine64"
        "/usr/local/bin/wine"
        "/usr/local/bin/wine64"
    )

    local candidate

    for candidate in "${candidates[@]}"; do
        if [[ -x "$candidate" ]]; then
            WINE="$candidate"
            export WINE
            return 0
        fi
    done

    # Finally try PATH.
    if command -v wine >/dev/null 2>&1; then
        WINE="$(command -v wine)"
        export WINE
        return 0
    fi

    if command -v wine64 >/dev/null 2>&1; then
        WINE="$(command -v wine64)"
        export WINE
        return 0
    fi

    echo "ERROR: Wine could not be found."
    echo
    echo "Install Wine Staging, or specify it manually:"
    echo
    echo '  export WINE="/path/to/wine"'
    exit 1
}

find_prefix() {
    # Explicit override always wins.
    if [[ -n "${WINEPREFIX:-}" && -d "${WINEPREFIX}" ]]; then
        export WINEPREFIX
        return 0
    fi

    local candidates=(
        "$HOME/Games/TwinStar/prefix-wine11"
        "$HOME/Games/TwinStar/prefix"
        "$HOME/Games/WoW/prefix-wine11"
        "$HOME/Games/WoW/prefix"
        "$HOME/.wine"
    )

    local candidate

    # Prefer a prefix that actually contains Wow-64.exe.
    for candidate in "${candidates[@]}"; do
        if [[ -f "$candidate/drive_c/Wow-64.exe" ]]; then
            WINEPREFIX="$candidate"
            export WINEPREFIX
            return 0
        fi
    done

    # Otherwise use an existing Wine prefix.
    for candidate in "${candidates[@]}"; do
        if [[ -d "$candidate/drive_c" ]]; then
            WINEPREFIX="$candidate"
            export WINEPREFIX
            return 0
        fi
    done

    return 1
}

find_wow() {
    if [[ -n "${WOW_EXE:-}" && -f "${WOW_EXE}" ]]; then
        return 0
    fi

    if [[ -n "${WINEPREFIX:-}" &&
          -f "$WINEPREFIX/drive_c/Wow-64.exe" ]]; then
        WOW_EXE="$WINEPREFIX/drive_c/Wow-64.exe"
        export WOW_EXE
        return 0
    fi

    return 1
}

show_environment() {
    echo "Detected environment:"
    echo
    echo "  Wine:   $WINE"
    "$WINE" --version

    if [[ -n "${WINEPREFIX:-}" ]]; then
        echo "  Prefix: $WINEPREFIX"
    fi

    if [[ -n "${WOW_EXE:-}" ]]; then
        echo "  WoW:    $WOW_EXE"
    fi

    echo
}