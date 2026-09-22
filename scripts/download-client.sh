#!/usr/bin/env bash

set -euo pipefail

LOCALE="${WOW_LOCALE:-enUS}"
CLIENT_BASE="https://twinstar-wow.com/files/Clients/MoP/"
PATCH_URL="http://twinstar-wow.com/mop/patch"
USER_AGENT="TwinStar Launcher"

GAME_DIR="${WOW_GAME_DIR:-$HOME/Games/WoW-MoP/prefix/drive_c/WoW}"
WORK_DIR="${TMPDIR:-/tmp}/mop-5.4.8-downloader"

FILELIST="$WORK_DIR/filelist.json"
PATCH_RESPONSE="$WORK_DIR/patch.xml"
CONFIG_XML="$WORK_DIR/config.xml"
MANIFEST="$WORK_DIR/manifest.mfil"

mkdir -p "$WORK_DIR"
mkdir -p "$GAME_DIR"

echo
echo "========================================"
echo " TwinStar MoP 5.4.8 Client Downloader"
echo "========================================"
echo
echo "Locale:    $LOCALE"
echo "Game dir:  $GAME_DIR"
echo


# ------------------------------------------------------------
# Stage 1 - TwinStar bootstrap files
# ------------------------------------------------------------

echo "[1/5] Downloading TwinStar bootstrap manifest..."

curl \
    --fail \
    --silent \
    --show-error \
    --location \
    --user-agent "$USER_AGENT" \
    --output "$FILELIST" \
    "${CLIENT_BASE}filelist.json"

echo "Bootstrap manifest downloaded."
echo


# ------------------------------------------------------------
# Stage 2 - Download and verify bootstrap files
# ------------------------------------------------------------

echo "[2/5] Installing bootstrap files..."

cd "$GAME_DIR"

python3 - "$FILELIST" "$CLIENT_BASE" "$USER_AGENT" <<'PY'
import hashlib
import json
import os
import subprocess
import sys

manifest_path = sys.argv[1]
base_url = sys.argv[2]
user_agent = sys.argv[3]

with open(manifest_path, "r", encoding="utf-8") as f:
    entries = json.load(f)


def md5_file(path):
    digest = hashlib.md5()

    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            digest.update(chunk)

    return digest.hexdigest()


for entry in entries:
    filename = entry["fileName"]
    expected_md5 = entry["md5"].lower()

    if filename.lower() == "jsongen.ps1":
        continue

    download = False

    if not os.path.exists(filename):
        download = True

    elif filename.lower().endswith(".wtf"):
        # TwinStar leaves existing WTF files untouched.
        download = False

    elif md5_file(filename).lower() != expected_md5:
        download = True

    if not download:
        print(f"  OK   {filename}")
        continue

    print(f"  GET  {filename}")

    directory = os.path.dirname(filename)

    if directory:
        os.makedirs(directory, exist_ok=True)

    url = base_url + filename

    subprocess.run(
        [
            "curl",
            "--fail",
            "--silent",
            "--show-error",
            "--location",
            "--user-agent",
            user_agent,
            "--output",
            filename,
            url,
        ],
        check=True,
    )

    actual_md5 = md5_file(filename).lower()

    if actual_md5 != expected_md5:
        raise RuntimeError(
            f"MD5 mismatch for {filename}\n"
            f"Expected: {expected_md5}\n"
            f"Actual:   {actual_md5}"
        )

print()
print("Bootstrap files verified.")
PY

echo


# ------------------------------------------------------------
# Stage 3 - Discover current TwinStar CDN manifest
# ------------------------------------------------------------

echo "[3/5] Discovering current MoP CDN..."

PATCH_REQUEST="<version program=\"WoW\"><record program=\"Bnet\" component=\"Win\" version =\"1\" /><record program=\"WoW\" component=\"$LOCALE\" version=\"4\" /></version>"

curl \
    --fail \
    --silent \
    --show-error \
    --user-agent "$USER_AGENT" \
    --header "Content-Type: application/xml" \
    --data "$PATCH_REQUEST" \
    --output "$PATCH_RESPONSE" \
    "$PATCH_URL"

python3 - "$PATCH_RESPONSE" "$LOCALE" "$WORK_DIR/discovery.env" <<'PY'
import sys
import xml.etree.ElementTree as ET

patch_file = sys.argv[1]
locale = sys.argv[2]
output_file = sys.argv[3]

root = ET.parse(patch_file).getroot()

record = None

for candidate in root.findall("record"):
    if (
        candidate.attrib.get("program", "").lower() == "wow"
        and candidate.attrib.get("component", "").lower() == locale.lower()
    ):
        record = candidate
        break

if record is None or not record.text:
    raise RuntimeError(
        f"Could not find WoW/{locale} record in TwinStar patch response."
    )

parts = record.text.strip().split(";")

if len(parts) < 4:
    raise RuntimeError(
        f"Unexpected TwinStar patch record: {record.text!r}"
    )

config_url = parts[0]
manifest_hash = parts[2]
build = parts[3]

manifest_name = f"wow-{build}-{manifest_hash}.mfil"

with open(output_file, "w", encoding="utf-8") as f:
    f.write(f"CONFIG_URL={config_url}\n")
    f.write(f"BUILD={build}\n")
    f.write(f"MANIFEST_NAME={manifest_name}\n")

print(f"Build:     {build}")
print(f"Manifest:  {manifest_name}")
print(f"Config:    {config_url}")
PY

source "$WORK_DIR/discovery.env"

echo


# ------------------------------------------------------------
# Stage 4 - Discover twinwind CDN and download manifest
# ------------------------------------------------------------

echo "[4/5] Resolving TwinStar CDN..."

curl \
    --fail \
    --silent \
    --show-error \
    --location \
    --user-agent "$USER_AGENT" \
    --output "$CONFIG_XML" \
    "$CONFIG_URL"

python3 - "$CONFIG_XML" "$WORK_DIR/cdn.env" <<'PY'
import sys
import xml.etree.ElementTree as ET

config_file = sys.argv[1]
output_file = sys.argv[2]

root = ET.parse(config_file).getroot()

cdn_base = None

for server in root.iter("server"):
    if server.attrib.get("id", "").lower() == "twinwind":
        cdn_base = server.attrib.get("url")
        break

if not cdn_base:
    raise RuntimeError(
        "TwinStar CDN configuration does not contain server id=twinwind."
    )

with open(output_file, "w", encoding="utf-8") as f:
    f.write(f"CDN_BASE={cdn_base}\n")

print(f"CDN:       {cdn_base}")
PY

source "$WORK_DIR/cdn.env"

echo
echo "Downloading current manifest..."

curl \
    --fail \
    --silent \
    --show-error \
    --location \
    --user-agent "$USER_AGENT" \
    --output "$MANIFEST" \
    "${CDN_BASE}${MANIFEST_NAME}"

echo "Manifest downloaded."
echo


# ------------------------------------------------------------
# Stage 5 - Parse manifest
#
# IMPORTANT:
# For the first test we deliberately STOP before downloading
# ~22 GB of data.
#
# This validates discovery and locale filtering first.
# ------------------------------------------------------------

echo "[5/5] Parsing manifest for locale: $LOCALE"

python3 - "$MANIFEST" "$LOCALE" <<'PY'
import os
import sys

manifest_path = sys.argv[1]
locale = sys.argv[2]

records = []

file_name = None
size = None
file_locale = None
locale_from_path = None


def valid_record():
    if file_name is None or size is None or size <= 0:
        return False

    if file_locale is not None or locale_from_path is not None:
        if file_locale is not None and file_locale.lower() == locale.lower():
            return True

        if locale_from_path is not None and locale_from_path.lower() == locale.lower():
            return True

        return False

    return True


def finish_record():
    if valid_record():
        records.append((file_name, size))


with open(
    manifest_path,
    "r",
    encoding="utf-8-sig",
    errors="replace",
) as manifest:

    for raw_line in manifest:
        line = raw_line.rstrip("\r\n")

        if line.startswith("file="):
            finish_record()

            file_name = line[5:]

            # Match TwinStar's special Updates/ behaviour.
            if not file_name.startswith("Updates/"):
                size = None
                locale_from_path = None
                file_locale = None

                normalized = file_name.replace("\\", "/")
                parts = normalized.split("/")

                # TwinStar derives locale information from Data/<locale>/...
                if len(parts) >= 2 and parts[0].lower() == "data":
                    possible_locale = parts[1]

                    if len(possible_locale) == 4:
                        file_locale = possible_locale

        elif line.startswith("\tsize="):
            size = int(line[6:])

        elif line.startswith("\tpath=locale_"):
            locale_from_path = line[13:]

finish_record()

total_size = sum(size for _, size in records)

print()
print(f"Selected records: {len(records)}")
print(f"Total size:       {total_size:,} bytes")
print(f"Total size:       {total_size / 1024 / 1024 / 1024:.2f} GiB")
print()

print("First 20 selected records:")
print()

for name, size in records[:20]:
    print(f"  {size:>12,}  {name}")

print()
print("Discovery and manifest parsing completed successfully.")
print()
print("No CDN game-data files have been downloaded yet.")
PY

echo
echo "========================================"
echo " Bootstrap/discovery test complete"
echo "========================================"
echo