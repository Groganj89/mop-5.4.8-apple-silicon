#!/usr/bin/env bash

set -euo pipefail

WINE_VERSION="11.17"
WINE_APP="Wine Staging.app"
INSTALL_DIR="$HOME/Applications"
INSTALL_PATH="$INSTALL_DIR/$WINE_APP"

DOWNLOAD_URL="https://github.com/Gcenx/macOS_Wine_builds/releases/download/${WINE_VERSION}/wine-staging-${WINE_VERSION}-osx64.tar.xz"

TMP_DIR="$(mktemp -d)"
ARCHIVE="$TMP_DIR/wine-staging.tar.xz"

cleanup() {
    rm -rf "$TMP_DIR"
}

trap cleanup EXIT

echo
echo "=================================================="
echo " Wine Staging Installer"
echo "=================================================="
echo

# ------------------------------------------------------------
# Check for an existing Wine installation
# ------------------------------------------------------------

WINE_CANDIDATES=(
    "$HOME/Applications/Wine Staging.app/Contents/Resources/wine/bin/wine"
    "$HOME/Games/Wine/Wine Staging.app/Contents/Resources/wine/bin/wine"
    "/Applications/Wine Staging.app/Contents/Resources/wine/bin/wine"
    "/opt/homebrew/bin/wine"
    "/opt/homebrew/bin/wine64"
    "/usr/local/bin/wine"
    "/usr/local/bin/wine64"
)

for candidate in "${WINE_CANDIDATES[@]}"; do
    if [[ -x "$candidate" ]]; then
        echo "Wine is already installed:"
        echo "  $candidate"
        echo
        "$candidate" --version
        echo
        echo "Skipping Wine installation."
        exit 0
    fi
done

if command -v wine >/dev/null 2>&1; then
    EXISTING_WINE="$(command -v wine)"

    echo "Wine is already installed:"
    echo "  $EXISTING_WINE"
    echo
    "$EXISTING_WINE" --version
    echo
    echo "Skipping Wine installation."
    exit 0
fi

if command -v wine64 >/dev/null 2>&1; then
    EXISTING_WINE="$(command -v wine64)"

    echo "Wine is already installed:"
    echo "  $EXISTING_WINE"
    echo
    "$EXISTING_WINE" --version
    echo
    echo "Skipping Wine installation."
    exit 0
fi

# ------------------------------------------------------------
# Check architecture
# ------------------------------------------------------------

ARCH="$(uname -m)"

if [[ "$ARCH" != "arm64" ]]; then
    echo "WARNING: This project is intended for Apple Silicon."
    echo
    echo "Detected architecture:"
    echo "  $ARCH"
    echo
fi

# ------------------------------------------------------------
# Check Rosetta
# ------------------------------------------------------------

echo "Checking Rosetta 2..."
echo

if /usr/bin/pgrep oahd >/dev/null 2>&1; then
    echo "Rosetta 2 detected."
else
    echo "Rosetta 2 was not detected."
    echo
    echo "Install Rosetta with:"
    echo
    echo "  softwareupdate --install-rosetta --agree-to-license"
    echo
    exit 1
fi

echo

# ------------------------------------------------------------
# Download Wine
# ------------------------------------------------------------

echo "Wine was not detected."
echo
echo "Installing Wine Staging $WINE_VERSION..."
echo
echo "Source:"
echo "  $DOWNLOAD_URL"
echo

curl \
    --fail \
    --location \
    --progress-bar \
    "$DOWNLOAD_URL" \
    --output "$ARCHIVE"

echo
echo "Download complete."
echo

# ------------------------------------------------------------
# Extract Wine
# ------------------------------------------------------------

mkdir -p "$INSTALL_DIR"

echo "Extracting Wine..."
echo

tar -xJf "$ARCHIVE" -C "$TMP_DIR"

EXTRACTED_APP="$(find "$TMP_DIR" \
    -maxdepth 3 \
    -type d \
    -name "$WINE_APP" \
    -print \
    -quit)"

if [[ -z "$EXTRACTED_APP" ]]; then
    echo "ERROR: Wine Staging.app was not found in the archive."
    exit 1
fi

rm -rf "$INSTALL_PATH"
mv "$EXTRACTED_APP" "$INSTALL_PATH"

echo "Wine installed:"
echo "  $INSTALL_PATH"
echo

# ------------------------------------------------------------
# Remove quarantine from this installation
# ------------------------------------------------------------

echo "Removing macOS quarantine attribute..."
echo

xattr -dr com.apple.quarantine "$INSTALL_PATH" 2>/dev/null || true

# ------------------------------------------------------------
# Verify installation
# ------------------------------------------------------------

WINE_BIN="$INSTALL_PATH/Contents/Resources/wine/bin/wine"

if [[ ! -x "$WINE_BIN" ]]; then
    echo "ERROR: Wine executable was not found after installation:"
    echo
    echo "  $WINE_BIN"
    exit 1
fi

echo "Wine installation verified:"
echo
echo "  $WINE_BIN"
echo
"$WINE_BIN" --version
echo

echo "Wine Staging installation complete."