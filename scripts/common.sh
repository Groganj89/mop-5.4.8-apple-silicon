#!/usr/bin/env bash

# ------------------------------------------------------------
# Wine discovery
# ------------------------------------------------------------

find_wine() {
    if [[ -n "${WINE:-}" && -x "${WINE}" ]]; then
        return 0
    fi

    local candidates=(
        "$HOME/Applications/Wine Staging.app/Contents/Resources/wine/bin/wine"
        "$HOME/Games/Wine/Wine Staging.app/Contents/Resources/wine/bin/wine"
        "/Applications/Wine Staging.app/Contents/Resources/wine/bin/wine"
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

# ------------------------------------------------------------
# Wine prefix discovery
# ------------------------------------------------------------

find_prefix() {
    if [[ -n "${WINEPREFIX:-}" && -d "${WINEPREFIX}" ]]; then
        export WINEPREFIX
        return 0
    fi

    local candidates=(
        "$HOME/Games/WoW-MoP/prefix"
        "$HOME/Games/TwinStar/prefix-wine11"
        "$HOME/Games/TwinStar/prefix"
        "$HOME/Games/WoW/prefix-wine11"
        "$HOME/Games/WoW/prefix"
        "$HOME/.wine"
    )

    local candidate

    # Prefer prefixes containing a known WoW installation.
    for candidate in "${candidates[@]}"; do
        if [[ -f "$candidate/drive_c/WoW/Wow-64.exe" ||
              -f "$candidate/drive_c/Wow-64.exe" ]]; then
            WINEPREFIX="$candidate"
            export WINEPREFIX
            return 0
        fi
    done

    # Otherwise accept an existing Wine prefix.
    for candidate in "${candidates[@]}"; do
        if [[ -d "$candidate/drive_c" ]]; then
            WINEPREFIX="$candidate"
            export WINEPREFIX
            return 0
        fi
    done

    return 1
}

# ------------------------------------------------------------
# WoW discovery
# ------------------------------------------------------------

find_wow() {
    if [[ -n "${WOW_EXE:-}" && -f "${WOW_EXE}" ]]; then
        export WOW_EXE
        return 0
    fi

    if [[ -z "${WINEPREFIX:-}" ]]; then
        return 1
    fi

    local candidates=(
        "$WINEPREFIX/drive_c/WoW/Wow-64.exe"
        "$WINEPREFIX/drive_c/Wow-64.exe"
    )

    local candidate

    for candidate in "${candidates[@]}"; do
        if [[ -f "$candidate" ]]; then
            WOW_EXE="$candidate"
            export WOW_EXE
            return 0
        fi
    done

    # Fallback for custom installations inside the prefix.
    WOW_EXE="$(
        find "$WINEPREFIX/drive_c" \
            -type f \
            -name "Wow-64.exe" \
            -print \
            -quit 2>/dev/null || true
    )"

    if [[ -n "$WOW_EXE" && -f "$WOW_EXE" ]]; then
        export WOW_EXE
        return 0
    fi

    unset WOW_EXE
    return 1
}

# ------------------------------------------------------------
# Environment summary
# ------------------------------------------------------------

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