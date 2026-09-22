#!/usr/bin/env bash

set -euo pipefail

WINE_VERSION="11.17"

DOWNLOAD_URL="https://github.com/Gcenx/macOS_Wine_builds/releases/download/${WINE_VERSION}/wine-staging-${WINE_VERSION}-osx64.tar.xz"

DOWNLOAD_DIR="$HOME/Downloads/WoW-MoP-Setup"
ARCHIVE="$DOWNLOAD_DIR/wine-staging-${WINE_VERSION}-osx64.tar.xz"

APPLICATIONS_DIR="$HOME/Applications"
WINE_APP="$APPLICATIONS_DIR/Wine Staging.app"
WINE_BIN="$WINE_APP/Contents/Resources/wine/bin/wine"

echo
echo "=================================================="
echo " Wine Staging Installer"
echo "=================================================="
echo

# ------------------------------------------------------------
# Architecture
# ------------------------------------------------------------

ARCH="$(uname -m)"

echo "Architecture:"
echo "  $ARCH"
echo

if [[ "$ARCH" != "arm64" ]]; then
    echo "WARNING: This project is designed for Apple Silicon."
    echo
fi

# ------------------------------------------------------------
# Rosetta 2
# ------------------------------------------------------------

echo "Checking Rosetta 2..."
echo

if /usr/bin/pgrep oahd >/dev/null 2>&1; then

    echo "Rosetta 2 detected."

else

    echo "Installing Rosetta 2..."
    echo

    /usr/sbin/softwareupdate \
        --install-rosetta \
        --agree-to-license

fi

echo

# ------------------------------------------------------------
# Existing Wine
# ------------------------------------------------------------

CANDIDATES=(
    "$HOME/Games/Wine/Wine Staging.app/Contents/Resources/wine/bin/wine"
    "$HOME/Applications/Wine Staging.app/Contents/Resources/wine/bin/wine"
    "/Applications/Wine Staging.app/Contents/Resources/wine/bin/wine"
    "/opt/homebrew/bin/wine"
    "/usr/local/bin/wine"
)

for candidate in "${CANDIDATES[@]}"; do

    if [[ -x "$candidate" ]]; then

        echo "Wine already installed:"
        echo "  $candidate"
        echo

        "$candidate" --version

        echo
        exit 0

    fi

done

if command -v wine >/dev/null 2>&1; then

    echo "Wine already available:"
    echo "  $(command -v wine)"
    echo

    wine --version

    exit 0

fi

# ------------------------------------------------------------
# Download
# ------------------------------------------------------------

echo "Wine Staging was not found."
echo
echo "Downloading Wine Staging $WINE_VERSION..."
echo
echo "Source:"
echo "  $DOWNLOAD_URL"
echo

mkdir -p "$DOWNLOAD_DIR"
mkdir -p "$APPLICATIONS_DIR"

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
# Extract
# ------------------------------------------------------------

echo "Extracting Wine..."
echo

EXTRACT_DIR="$DOWNLOAD_DIR/wine-$WINE_VERSION"

rm -rf "$EXTRACT_DIR"
mkdir -p "$EXTRACT_DIR"

tar -xJf "$ARCHIVE" -C "$EXTRACT_DIR"

echo "Extraction complete."
echo

# ------------------------------------------------------------
# Locate Wine Staging.app
# ------------------------------------------------------------

EXTRACTED_APP="$(
    find "$EXTRACT_DIR" \
        -type d \
        -name "Wine Staging.app" \
        -print \
        -quit
)"

if [[ -z "$EXTRACTED_APP" ]]; then

    echo "ERROR: Wine Staging.app was not found"
    echo "inside the downloaded archive."
    echo
    echo "Extracted contents:"
    echo

    find "$EXTRACT_DIR" -maxdepth 3 -print

    exit 1

fi

echo "Found:"
echo "  $EXTRACTED_APP"
echo

# ------------------------------------------------------------
# Install
# ------------------------------------------------------------

echo "Installing Wine Staging into:"
echo "  $APPLICATIONS_DIR"
echo

rm -rf "$WINE_APP"

cp -R "$EXTRACTED_APP" "$WINE_APP"

# ------------------------------------------------------------
# Remove quarantine
# ------------------------------------------------------------

echo "Removing downloaded-file quarantine attribute..."
echo

xattr -dr com.apple.quarantine "$WINE_APP" 2>/dev/null || true

# ------------------------------------------------------------
# Verify
# ------------------------------------------------------------

if [[ ! -x "$WINE_BIN" ]]; then

    echo "ERROR: Wine was copied but the executable"
    echo "could not be found:"
    echo
    echo "  $WINE_BIN"

    exit 1

fi

echo "Verifying Wine..."
echo

"$WINE_BIN" --version

echo

# ------------------------------------------------------------
# Complete
# ------------------------------------------------------------

echo "=================================================="
echo " Wine Installation Complete"
echo "=================================================="
echo
echo "Installed:"
echo "  $WINE_APP"
echo
echo "Executable:"
echo "  $WINE_BIN"
echo