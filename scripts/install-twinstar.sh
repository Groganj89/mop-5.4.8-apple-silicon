#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

LAUNCHER_URL="https://twinstar-wow.com/launcher/latest.zip"
DOWNLOAD_DIR="$HOME/Downloads/TwinStar-Launcher"
ZIP_FILE="$DOWNLOAD_DIR/twinstar-launcher.zip"

echo "========================================"
echo " TwinStar Launcher Installer for macOS"
echo "========================================"
echo

# ------------------------------------------------------------
# Detect Wine
# ------------------------------------------------------------

find_wine

echo "Wine detected:"
echo "  $WINE"
"$WINE" --version
echo

# ------------------------------------------------------------
# Find or create Wine prefix
# ------------------------------------------------------------

if ! find_prefix; then
    echo "No existing Wine prefix was detected."
    echo
    echo "Creating the default MoP prefix..."
    echo

    export WINEPREFIX="$HOME/Games/WoW-MoP/prefix"

    mkdir -p "$(dirname "$WINEPREFIX")"

    "$WINE" wineboot

    echo
    echo "Wine prefix created:"
    echo "  $WINEPREFIX"
    echo
fi

echo "Using Wine prefix:"
echo "  $WINEPREFIX"
echo

# ------------------------------------------------------------
# Check .NET 8 Desktop Runtime
# ------------------------------------------------------------

DOTNET="$WINEPREFIX/drive_c/Program Files/dotnet/dotnet.exe"

if [[ ! -f "$DOTNET" ]]; then
    echo "ERROR: Microsoft .NET was not found in this Wine prefix."
    echo
    echo "The TwinStar Launcher requires the Windows x64"
    echo ".NET 8 Desktop Runtime."
    echo
    echo "Install the .NET 8 Desktop Runtime into:"
    echo
    echo "  $WINEPREFIX"
    echo
    echo "Then run this script again."
    echo
    exit 1
fi

echo "Installed .NET runtimes:"
echo

"$WINE" "C:\\Program Files\\dotnet\\dotnet.exe" --list-runtimes || true

echo

if ! "$WINE" "C:\\Program Files\\dotnet\\dotnet.exe" --list-runtimes 2>/dev/null \
    | grep -q "Microsoft.WindowsDesktop.App 8."; then

    echo "ERROR: Microsoft.WindowsDesktop.App 8.x was not detected."
    echo
    echo "Install the Windows x64 .NET 8 Desktop Runtime"
    echo "and run this script again."
    exit 1
fi

echo ".NET 8 Desktop Runtime detected."
echo

# ------------------------------------------------------------
# Download TwinStar Launcher
# ------------------------------------------------------------

echo "Downloading the latest TwinStar Launcher..."
echo
echo "Source:"
echo "  $LAUNCHER_URL"
echo

mkdir -p "$DOWNLOAD_DIR"

curl \
    --fail \
    --location \
    --progress-bar \
    "$LAUNCHER_URL" \
    --output "$ZIP_FILE"

echo
echo "Download complete:"
echo "  $ZIP_FILE"
echo

# ------------------------------------------------------------
# Extract launcher
# ------------------------------------------------------------

echo "Extracting TwinStar Launcher..."
echo

rm -rf "$DOWNLOAD_DIR/extracted"
mkdir -p "$DOWNLOAD_DIR/extracted"

unzip -q -o "$ZIP_FILE" -d "$DOWNLOAD_DIR/extracted"

echo "Extracted."
echo

# ------------------------------------------------------------
# Locate launcher executable
# ------------------------------------------------------------

LAUNCHER=""

while IFS= read -r -d '' file; do
    LAUNCHER="$file"
    break
done < <(
    find "$DOWNLOAD_DIR/extracted" \
        -type f \
        \( -iname "*.exe" -o -iname "latest" \) \
        -print0
)

if [[ -z "$LAUNCHER" ]]; then
    echo "ERROR: Could not locate the TwinStar Launcher"
    echo "inside the downloaded archive."
    echo
    echo "Extracted files:"
    find "$DOWNLOAD_DIR/extracted" -maxdepth 3 -type f -print
    exit 1
fi

echo "TwinStar Launcher found:"
echo "  $LAUNCHER"
echo

# ------------------------------------------------------------
# Launch
# ------------------------------------------------------------

echo "Starting TwinStar Launcher..."
echo
echo "When selecting the WoW installation location,"
echo "choose a location inside the Wine C: drive."
echo
echo "Recommended:"
echo "  C:\\WoW"
echo
echo "This corresponds to:"
echo "  $WINEPREFIX/drive_c/WoW"
echo
echo "Once the game has finished downloading, close"
echo "the launcher and run:"
echo
echo "  ./scripts/isolate-user-folders.sh"
echo "  ./scripts/run-wow.sh"
echo

"$WINE" "$LAUNCHER"