#!/usr/bin/env bash

set -euo pipefail

echo
echo "=================================================="
echo " Wine Staging Installer"
echo "=================================================="
echo

# ------------------------------------------------------------
# Check architecture
# ------------------------------------------------------------

ARCH="$(uname -m)"

echo "Mac architecture:"
echo "  $ARCH"
echo

if [[ "$ARCH" != "arm64" ]]; then
    echo "WARNING: This project is intended for Apple Silicon."
    echo "Detected architecture:"
    echo "  $ARCH"
    echo
fi

# ------------------------------------------------------------
# Check Rosetta
# ------------------------------------------------------------

if /usr/bin/pgrep oahd >/dev/null 2>&1; then
    echo "Rosetta 2 detected."
else
    echo "Rosetta 2 does not appear to be running/installed."
    echo
    echo "Installing Rosetta 2..."
    echo

    /usr/sbin/softwareupdate \
        --install-rosetta \
        --agree-to-license

    echo
    echo "Rosetta installation completed."
fi

echo

# ------------------------------------------------------------
# Check whether Wine already exists
# ------------------------------------------------------------

WINE_CANDIDATES=(
    "$HOME/Games/Wine/Wine Staging.app/Contents/Resources/wine/bin/wine"
    "/Applications/Wine Staging.app/Contents/Resources/wine/bin/wine"
    "$HOME/Applications/Wine Staging.app/Contents/Resources/wine/bin/wine"
    "/opt/homebrew/bin/wine"
    "/usr/local/bin/wine"
)

for candidate in "${WINE_CANDIDATES[@]}"; do
    if [[ -x "$candidate" ]]; then
        echo "Wine is already installed:"
        echo "  $candidate"
        echo
        "$candidate" --version
        echo
        echo "No Wine installation required."
        exit 0
    fi
done

if command -v wine >/dev/null 2>&1; then
    echo "Wine is already available in PATH:"
    echo "  $(command -v wine)"
    echo
    wine --version
    exit 0
fi

# ------------------------------------------------------------
# Check Homebrew
# ------------------------------------------------------------

if command -v brew >/dev/null 2>&1; then
    BREW="$(command -v brew)"

elif [[ -x "/opt/homebrew/bin/brew" ]]; then
    BREW="/opt/homebrew/bin/brew"

elif [[ -x "/usr/local/bin/brew" ]]; then
    BREW="/usr/local/bin/brew"

else
    echo "Homebrew is not installed."
    echo
    echo "Installing Homebrew..."
    echo
    echo "Homebrew may ask for your macOS administrator password."
    echo

    /bin/bash -c \
        "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    if [[ -x "/opt/homebrew/bin/brew" ]]; then
        BREW="/opt/homebrew/bin/brew"

    elif [[ -x "/usr/local/bin/brew" ]]; then
        BREW="/usr/local/bin/brew"

    else
        echo
        echo "ERROR: Homebrew installation completed but brew"
        echo "could not be located."
        exit 1
    fi
fi

echo "Homebrew:"
echo "  $BREW"
"$BREW" --version | head -n 1
echo

# ------------------------------------------------------------
# Install Wine Staging
# ------------------------------------------------------------

echo "Installing Wine Staging..."
echo

"$BREW" install --cask wine@staging

echo

# ------------------------------------------------------------
# Locate installed Wine
# ------------------------------------------------------------

WINE=""

WINE_CANDIDATES=(
    "/Applications/Wine Staging.app/Contents/Resources/wine/bin/wine"
    "/opt/homebrew/bin/wine"
    "/usr/local/bin/wine"
)

for candidate in "${WINE_CANDIDATES[@]}"; do
    if [[ -x "$candidate" ]]; then
        WINE="$candidate"
        break
    fi
done

if [[ -z "$WINE" ]] && command -v wine >/dev/null 2>&1; then
    WINE="$(command -v wine)"
fi

if [[ -z "$WINE" ]]; then
    echo "ERROR: Wine installation completed but the Wine"
    echo "executable could not be located."
    exit 1
fi

echo "=================================================="
echo " Wine Installation Complete"
echo "=================================================="
echo
echo "Wine:"
echo "  $WINE"
echo

"$WINE" --version

echo
echo "Wine Staging is ready."
echo