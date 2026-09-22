#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

LAUNCHER_URL="https://twinstar-wow.com/launcher/latest.zip"

DOWNLOAD_DIR="$HOME/Downloads/TwinStar-Launcher"
ZIP_FILE="$DOWNLOAD_DIR/twinstar-launcher.zip"
EXTRACT_DIR="$DOWNLOAD_DIR/extracted"

echo
echo "=================================================="
echo " TwinStar Launcher Installer"
echo "=================================================="
echo

# ------------------------------------------------------------
# Find Wine
# ------------------------------------------------------------

find_wine

echo "Wine detected:"
echo "  $WINE"
echo

"$WINE" --version

echo

# ------------------------------------------------------------
# Find/create Wine prefix
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
# Check .NET
# ------------------------------------------------------------

DOTNET="$WINEPREFIX/drive_c/Program Files/dotnet/dotnet.exe"

if [[ ! -f "$DOTNET" ]]; then

    echo "ERROR: Microsoft .NET was not found in this"
    echo "Wine prefix."
    echo
    echo "The TwinStar Launcher requires the Windows"
    echo "x64 .NET 8 Desktop Runtime."
    echo
    echo "Run:"
    echo
    echo "  ./scripts/install-dotnet.sh"
    echo
    echo "Then run this script again."
    echo

    exit 1

fi

echo "Checking installed .NET runtimes..."
echo

RUNTIMES="$(
    "$WINE" \
        "C:\\Program Files\\dotnet\\dotnet.exe" \
        --list-runtimes 2>/dev/null || true
)"

echo "$RUNTIMES"
echo

if ! echo "$RUNTIMES" \
    | grep -q "Microsoft.WindowsDesktop.App 8\."; then

    echo "ERROR: Microsoft.WindowsDesktop.App 8.x"
    echo "was not detected."
    echo
    echo "The TwinStar Launcher requires the Windows"
    echo "x64 .NET 8 Desktop Runtime."
    echo
    echo "Run:"
    echo
    echo "  ./scripts/install-dotnet.sh"
    echo

    exit 1

fi

echo ".NET 8 Desktop Runtime detected."
echo

# ------------------------------------------------------------
# Prepare download directory
# ------------------------------------------------------------

mkdir -p "$DOWNLOAD_DIR"

echo "TwinStar download directory:"
echo "  $DOWNLOAD_DIR"
echo

# ------------------------------------------------------------
# Download TwinStar Launcher
# ------------------------------------------------------------

echo "Downloading the latest TwinStar Launcher..."
echo
echo "Source:"
echo "  $LAUNCHER_URL"
echo

rm -f "$ZIP_FILE"

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
# Validate ZIP
# ------------------------------------------------------------

echo "Validating downloaded archive..."
echo

if ! unzip -tq "$ZIP_FILE" >/dev/null; then

    echo "ERROR: The downloaded TwinStar archive"
    echo "does not appear to be a valid ZIP file."
    echo
    echo "Downloaded file:"
    echo "  $ZIP_FILE"
    echo

    exit 1

fi

echo "Archive is valid."
echo

# ------------------------------------------------------------
# Extract TwinStar Launcher
# ------------------------------------------------------------

echo "Extracting TwinStar Launcher..."
echo

rm -rf "$EXTRACT_DIR"
mkdir -p "$EXTRACT_DIR"

unzip -q -o \
    "$ZIP_FILE" \
    -d "$EXTRACT_DIR"

echo "Extraction complete."
echo

# ------------------------------------------------------------
# Locate launcher
# ------------------------------------------------------------

echo "Locating TwinStar Launcher..."
echo

LAUNCHER=""

# Prefer an executable with TwinStar in the filename.

while IFS= read -r -d '' file; do

    LAUNCHER="$file"
    break

done < <(
    find "$EXTRACT_DIR" \
        -type f \
        -iname "*twinstar*.exe" \
        -print0
)

# If that failed, look for any EXE located beside
# appsettings.json. This is important because TwinStar
# expects appsettings.json in its working directory.

if [[ -z "$LAUNCHER" ]]; then

    while IFS= read -r -d '' settings; do

        SETTINGS_DIR="$(dirname "$settings")"

        while IFS= read -r -d '' file; do

            LAUNCHER="$file"
            break

        done < <(
            find "$SETTINGS_DIR" \
                -maxdepth 1 \
                -type f \
                -iname "*.exe" \
                -print0
        )

        if [[ -n "$LAUNCHER" ]]; then
            break
        fi

    done < <(
        find "$EXTRACT_DIR" \
            -type f \
            -iname "appsettings.json" \
            -print0
    )

fi

# Final fallback: first EXE in the archive.

if [[ -z "$LAUNCHER" ]]; then

    while IFS= read -r -d '' file; do

        LAUNCHER="$file"
        break

    done < <(
        find "$EXTRACT_DIR" \
            -type f \
            -iname "*.exe" \
            -print0
    )

fi

if [[ -z "$LAUNCHER" ]]; then

    echo "ERROR: Could not locate the TwinStar Launcher"
    echo "inside the downloaded archive."
    echo
    echo "Extracted files:"
    echo

    find "$EXTRACT_DIR" \
        -maxdepth 4 \
        -type f \
        -print

    exit 1

fi

echo "TwinStar Launcher found:"
echo "  $LAUNCHER"
echo

# ------------------------------------------------------------
# Determine launcher working directory
# ------------------------------------------------------------

LAUNCHER_DIR="$(dirname "$LAUNCHER")"
LAUNCHER_FILE="$(basename "$LAUNCHER")"

echo "Launcher working directory:"
echo "  $LAUNCHER_DIR"
echo

# ------------------------------------------------------------
# Validate appsettings.json
# ------------------------------------------------------------

APPSETTINGS="$LAUNCHER_DIR/appsettings.json"

if [[ ! -f "$APPSETTINGS" ]]; then

    echo "ERROR: TwinStar appsettings.json was not found."
    echo
    echo "The launcher requires appsettings.json in its"
    echo "current working directory."
    echo
    echo "Expected:"
    echo "  $APPSETTINGS"
    echo
    echo "Launcher directory contents:"
    echo

    ls -la "$LAUNCHER_DIR"

    echo
    exit 1

fi

echo "TwinStar configuration detected:"
echo "  $APPSETTINGS"
echo

# ------------------------------------------------------------
# Display installation information
# ------------------------------------------------------------

echo "=================================================="
echo " Starting TwinStar Launcher"
echo "=================================================="
echo
echo "When selecting the WoW installation location,"
echo "choose a location inside the Wine C: drive."
echo
echo "Recommended:"
echo
echo "  C:\\WoW"
echo
echo "This corresponds to:"
echo
echo "  $WINEPREFIX/drive_c/WoW"
echo
echo "Allow TwinStar to completely download/update"
echo "the World of Warcraft client."
echo
echo "When the download has finished, close TwinStar."
echo
echo "The setup process will then continue."
echo

# ------------------------------------------------------------
# Launch TwinStar
# ------------------------------------------------------------

#
# TwinStar loads appsettings.json relative to its current
# working directory.
#
# Running the EXE while the shell is still inside the Git
# repository causes .NET to search the repository root for
# appsettings.json and terminate with FileNotFoundException.
#
# Therefore we MUST change into the launcher directory before
# starting the application.
#

cd "$LAUNCHER_DIR"

"$WINE" "./$LAUNCHER_FILE"

LAUNCH_EXIT_CODE=$?

echo
echo "TwinStar Launcher exited."
echo "Exit code:"
echo "  $LAUNCH_EXIT_CODE"
echo

# ------------------------------------------------------------
# Look for downloaded WoW client
# ------------------------------------------------------------

echo "Checking for World of Warcraft..."
echo

WOW_EXE="$(
    find "$WINEPREFIX/drive_c" \
        -type f \
        -iname "Wow-64.exe" \
        -print \
        -quit 2>/dev/null || true
)"

if [[ -n "$WOW_EXE" ]]; then

    echo "World of Warcraft detected:"
    echo "  $WOW_EXE"
    echo

else

    echo "Wow-64.exe was not found yet."
    echo
    echo "If TwinStar has not finished downloading the"
    echo "client, run this script again:"
    echo
    echo "  ./scripts/install-twinstar.sh"
    echo

fi